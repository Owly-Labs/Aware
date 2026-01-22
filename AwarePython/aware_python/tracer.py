"""
AwarePython Span Tracer

Manages span creation, nesting, and completion.
Provides decorators for automatic tracing.
"""

import functools
import inspect
import traceback
from contextlib import asynccontextmanager, contextmanager
from datetime import datetime
from typing import Any, Callable, Optional, TypeVar

from .types import Span, SpanStatus, SuggestedFix
from .middleware import (
    get_current_trace_id,
    get_current_session,
    generate_span_id,
)

T = TypeVar("T")


class SpanTracer:
    """
    Manages span creation and tracking.

    Usage:
        tracer = SpanTracer()

        async with tracer.span("youtube.download") as span:
            # Your code here
            span.attributes["file_size"] = "45MB"
    """

    def __init__(self):
        self._active_spans: dict[str, Span] = {}

    @asynccontextmanager
    async def span(
        self,
        name: str,
        service: Optional[str] = None,
        attributes: Optional[dict[str, Any]] = None,
    ):
        """
        Create a traced span (async context manager).

        Args:
            name: Operation name (e.g., "youtube.download")
            service: Service name (e.g., "job_service")
            attributes: Initial attributes
        """
        trace_id = get_current_trace_id()
        session = get_current_session()

        if not trace_id:
            # No tracing active, just execute
            yield None
            return

        span = Span(
            span_id=generate_span_id(),
            trace_id=trace_id,
            name=name,
            service=service,
            attributes=attributes or {},
        )

        # Link to parent span or root
        parent_span_id = self._get_parent_span_id(trace_id)
        if parent_span_id:
            span.parent_span_id = parent_span_id
            parent = self._active_spans.get(parent_span_id)
            if parent:
                parent.children.append(span)
        elif session and not session.root_span:
            session.root_span = span

        # Track active span
        self._active_spans[span.span_id] = span

        try:
            yield span
            span.finish(SpanStatus.OK)
        except Exception as e:
            # Capture error details
            tb = traceback.extract_tb(e.__traceback__)
            if tb:
                last_frame = tb[-1]
                span.error_file = f"{last_frame.filename}:{last_frame.lineno}"

            span.finish(SpanStatus.ERROR, str(e))

            # Add to session errors
            if session:
                session.errors.append(str(e))
                session.related_code.append(span.error_file or "unknown")

            raise
        finally:
            self._active_spans.pop(span.span_id, None)
            if session:
                session.span_count += 1

    @contextmanager
    def sync_span(
        self,
        name: str,
        service: Optional[str] = None,
        attributes: Optional[dict[str, Any]] = None,
    ):
        """
        Create a traced span (sync context manager).

        For synchronous code that can't use async with.
        """
        trace_id = get_current_trace_id()
        session = get_current_session()

        if not trace_id:
            yield None
            return

        span = Span(
            span_id=generate_span_id(),
            trace_id=trace_id,
            name=name,
            service=service,
            attributes=attributes or {},
        )

        parent_span_id = self._get_parent_span_id(trace_id)
        if parent_span_id:
            span.parent_span_id = parent_span_id
            parent = self._active_spans.get(parent_span_id)
            if parent:
                parent.children.append(span)
        elif session and not session.root_span:
            session.root_span = span

        self._active_spans[span.span_id] = span

        try:
            yield span
            span.finish(SpanStatus.OK)
        except Exception as e:
            tb = traceback.extract_tb(e.__traceback__)
            if tb:
                last_frame = tb[-1]
                span.error_file = f"{last_frame.filename}:{last_frame.lineno}"

            span.finish(SpanStatus.ERROR, str(e))

            if session:
                session.errors.append(str(e))
                session.related_code.append(span.error_file or "unknown")

            raise
        finally:
            self._active_spans.pop(span.span_id, None)
            if session:
                session.span_count += 1

    def _get_parent_span_id(self, trace_id: str) -> Optional[str]:
        """Find the most recent active span for this trace."""
        for span_id, span in reversed(list(self._active_spans.items())):
            if span.trace_id == trace_id:
                return span_id
        return None


# Global tracer instance
_tracer = SpanTracer()


def trace(name: Optional[str] = None, service: Optional[str] = None):
    """
    Decorator for automatic span tracing.

    Usage:
        @trace("youtube.download")
        async def download_video(video_id: str):
            ...

        @trace()  # Uses function name
        def process_audio():
            ...
    """
    def decorator(func: Callable[..., T]) -> Callable[..., T]:
        span_name = name or func.__name__
        is_async = inspect.iscoroutinefunction(func)

        if is_async:
            @functools.wraps(func)
            async def async_wrapper(*args, **kwargs):
                async with _tracer.span(span_name, service=service) as span:
                    if span:
                        # Add function arguments as attributes
                        span.attributes["args"] = str(args)[:100]
                        span.attributes["kwargs"] = str(kwargs)[:100]
                    return await func(*args, **kwargs)
            return async_wrapper
        else:
            @functools.wraps(func)
            def sync_wrapper(*args, **kwargs):
                with _tracer.sync_span(span_name, service=service) as span:
                    if span:
                        span.attributes["args"] = str(args)[:100]
                        span.attributes["kwargs"] = str(kwargs)[:100]
                    return func(*args, **kwargs)
            return sync_wrapper

    return decorator


def add_suggested_fix(
    description: str,
    file: Optional[str] = None,
    line: Optional[int] = None,
    code_snippet: Optional[str] = None,
):
    """
    Add a suggested fix to the current debug session.

    Call this when you catch an error and know how to fix it.

    Usage:
        try:
            process_large_file()
        except MemoryError:
            add_suggested_fix(
                "Reduce CHUNK_SIZE in config.py",
                file="config.py",
                line=45,
            )
            raise
    """
    session = get_current_session()
    if session:
        session.suggested_fixes.append(SuggestedFix(
            description=description,
            file=file,
            line=line,
            code_snippet=code_snippet,
        ))


def add_related_code(file_line: str):
    """
    Add a related code reference to the current debug session.

    Usage:
        add_related_code("bs_roformer.py:150-160")
    """
    session = get_current_session()
    if session and file_line not in session.related_code:
        session.related_code.append(file_line)


def log_to_session(level: str, message: str, **context):
    """
    Add a log entry to the current debug session.

    Usage:
        log_to_session("INFO", "Download complete", file_size="45MB")
    """
    from .types import LogEntry, LogLevel
    import uuid

    session = get_current_session()
    if not session:
        return

    # Get caller info
    frame = inspect.currentframe()
    if frame and frame.f_back:
        caller = frame.f_back
        file = caller.f_code.co_filename.split("/")[-1]
        line = caller.f_lineno
        function = caller.f_code.co_name
    else:
        file, line, function = None, None, None

    entry = LogEntry(
        id=str(uuid.uuid4())[:8],
        trace_id=get_current_trace_id(),
        level=LogLevel(level.lower()),
        message=message,
        file=file,
        line=line,
        function=function,
        context=context,
    )

    session.logs.append(entry)


# Convenience functions
async def span(name: str, **kwargs):
    """Shorthand for creating a span."""
    return _tracer.span(name, **kwargs)


def get_tracer() -> SpanTracer:
    """Get the global tracer instance."""
    return _tracer
