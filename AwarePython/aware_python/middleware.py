"""
AwarePython FastAPI Middleware

Extracts trace context from iOS requests and propagates correlation IDs.
Automatically starts debug sessions and correlates all logs.
"""

import uuid
import time
import logging
from contextvars import ContextVar
from typing import Callable, Optional

from starlette.middleware.base import BaseHTTPMiddleware
from starlette.requests import Request
from starlette.responses import Response

from .types import TraceContext, IOSContext, DebugSession, SpanStatus

# Context variables for trace propagation
_current_trace_id: ContextVar[Optional[str]] = ContextVar("trace_id", default=None)
_current_span_id: ContextVar[Optional[str]] = ContextVar("span_id", default=None)
_current_session: ContextVar[Optional[DebugSession]] = ContextVar("debug_session", default=None)

logger = logging.getLogger("aware_python")


def get_current_trace_id() -> Optional[str]:
    """Get current trace ID from context."""
    return _current_trace_id.get()


def get_current_span_id() -> Optional[str]:
    """Get current span ID from context."""
    return _current_span_id.get()


def get_current_session() -> Optional[DebugSession]:
    """Get current debug session from context."""
    return _current_session.get()


def generate_trace_id() -> str:
    """Generate a 32-char hex trace ID."""
    return uuid.uuid4().hex


def generate_span_id() -> str:
    """Generate a 16-char hex span ID."""
    return uuid.uuid4().hex[:16]


class AwarePythonMiddleware(BaseHTTPMiddleware):
    """
    FastAPI middleware for LLM-centric tracing.

    Extracts/generates trace context and creates debug sessions.
    All logs within the request are automatically correlated.

    Usage:
        from aware_python import AwarePythonMiddleware

        app = FastAPI()
        app.add_middleware(AwarePythonMiddleware)
    """

    def __init__(
        self,
        app,
        storage=None,
        exclude_paths: Optional[list[str]] = None,
        always_trace: bool = False,
    ):
        """
        Initialize middleware.

        Args:
            app: FastAPI/Starlette app
            storage: Optional DebugStorage instance for persisting sessions
            exclude_paths: Paths to exclude from tracing (e.g., ["/health", "/metrics"])
            always_trace: If True, trace all requests even without X-Correlation-ID
        """
        super().__init__(app)
        self.storage = storage
        self.exclude_paths = exclude_paths or ["/health", "/metrics", "/docs", "/openapi.json"]
        self.always_trace = always_trace

    async def dispatch(self, request: Request, call_next: Callable) -> Response:
        # Skip excluded paths
        if any(request.url.path.startswith(p) for p in self.exclude_paths):
            return await call_next(request)

        # Extract trace context from headers
        trace_context = self._extract_trace_context(request)

        # Generate new context if not provided (and always_trace is True)
        if not trace_context and self.always_trace:
            trace_context = TraceContext(
                trace_id=generate_trace_id(),
                span_id=generate_span_id(),
            )

        if not trace_context:
            # No tracing for this request
            return await call_next(request)

        # Extract iOS context if provided
        ios_context = self._extract_ios_context(request)

        # Create debug session
        session = DebugSession(
            trace_id=trace_context.trace_id,
            ios_context=ios_context,
        )

        # Set context variables
        trace_token = _current_trace_id.set(trace_context.trace_id)
        span_token = _current_span_id.set(trace_context.span_id)
        session_token = _current_session.set(session)

        start_time = time.time()

        try:
            # Store request in session for later reference
            request.state.aware_session = session
            request.state.aware_trace_id = trace_context.trace_id

            # Process request
            response = await call_next(request)

            # Complete session
            duration_ms = (time.time() - start_time) * 1000
            session.duration_ms = duration_ms
            session.status = SpanStatus.OK if response.status_code < 400 else SpanStatus.ERROR

            # Add trace headers to response
            response.headers["X-Correlation-ID"] = trace_context.trace_id
            response.headers["X-Trace-ID"] = trace_context.trace_id

            return response

        except Exception as e:
            # Record error in session
            duration_ms = (time.time() - start_time) * 1000
            session.duration_ms = duration_ms
            session.status = SpanStatus.ERROR
            session.errors.append(str(e))

            logger.error(
                f"Request failed: {e}",
                extra={"trace_id": trace_context.trace_id}
            )
            raise

        finally:
            # Persist session if storage is configured
            if self.storage:
                try:
                    await self.storage.save_session(session)
                except Exception as e:
                    logger.warning(f"Failed to save debug session: {e}")

            # Reset context variables
            _current_trace_id.reset(trace_token)
            _current_span_id.reset(span_token)
            _current_session.reset(session_token)

    def _extract_trace_context(self, request: Request) -> Optional[TraceContext]:
        """Extract W3C Trace Context from headers."""
        # Try W3C traceparent header first
        traceparent = request.headers.get("traceparent")
        if traceparent:
            ctx = TraceContext.from_traceparent(traceparent)
            if ctx:
                return ctx

        # Fall back to X-Correlation-ID
        correlation_id = request.headers.get("X-Correlation-ID") or request.headers.get("x-correlation-id")
        if correlation_id:
            return TraceContext(
                trace_id=correlation_id.replace("-", "")[:32].ljust(32, "0"),
                span_id=generate_span_id(),
            )

        return None

    def _extract_ios_context(self, request: Request) -> Optional[IOSContext]:
        """Extract iOS debug context from headers."""
        # Try X-Debug-Context header (base64 JSON)
        debug_context = request.headers.get("X-Debug-Context")
        if debug_context:
            try:
                import base64
                import json
                decoded = base64.b64decode(debug_context).decode("utf-8")
                data = json.loads(decoded)
                return IOSContext(
                    view_stack=data.get("viewStack", []),
                    action=data.get("action", "unknown"),
                    device_id=data.get("deviceId"),
                    app_version=data.get("appVersion"),
                    os_version=data.get("osVersion"),
                )
            except Exception:
                pass

        # Try individual headers
        device_id = request.headers.get("X-Device-ID") or request.headers.get("device-id")
        if device_id:
            return IOSContext(
                action=request.method + " " + request.url.path,
                device_id=device_id,
            )

        return None


class CorrelatedLogFilter(logging.Filter):
    """
    Logging filter that adds trace context to log records.

    Usage:
        import logging
        from aware_python import CorrelatedLogFilter

        handler = logging.StreamHandler()
        handler.addFilter(CorrelatedLogFilter())
        logging.getLogger().addHandler(handler)
    """

    def filter(self, record: logging.LogRecord) -> bool:
        record.trace_id = get_current_trace_id() or "-"
        record.span_id = get_current_span_id() or "-"
        return True


class CorrelatedLogFormatter(logging.Formatter):
    """
    Log formatter that includes trace context.

    Example output:
        2026-01-21 10:30:00 [abc12345] INFO youtube_extractor.py:142 Starting download
    """

    def __init__(self):
        super().__init__(
            fmt="%(asctime)s [%(trace_id).8s] %(levelname)s %(filename)s:%(lineno)d %(message)s",
            datefmt="%Y-%m-%d %H:%M:%S"
        )
