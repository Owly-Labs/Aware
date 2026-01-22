"""
AwarePython - LLM-Centric Debugging Framework

Cross-platform debugging for iOS ↔ Python backend correlation.
Optimized for LLM consumption (~300-400 tokens per debug bundle).

Usage:
    from fastapi import FastAPI
    from aware_python import AwarePythonMiddleware, router as debug_router, trace

    app = FastAPI()

    # Add middleware for automatic tracing
    app.add_middleware(AwarePythonMiddleware)

    # Add debug API routes
    app.include_router(debug_router)

    # Trace individual functions
    @trace("youtube.download")
    async def download_video(video_id: str):
        ...

Querying debug sessions:
    GET /debug/sessions                    # List recent sessions
    GET /debug/sessions/{trace_id}         # Get full session
    GET /debug/sessions/{trace_id}/compact # Get LLM-optimized format
    GET /debug/errors                      # Get sessions with errors
    WS  /debug/ws/live                     # Real-time updates
"""

__version__ = "0.1.0"

# Core types
from .types import (
    TraceContext,
    IOSContext,
    Span,
    SpanStatus,
    LogEntry,
    LogLevel,
    DebugSession,
    SuggestedFix,
    DebugSessionSummary,
    DebugQueryResponse,
)

# Middleware
from .middleware import (
    AwarePythonMiddleware,
    CorrelatedLogFilter,
    CorrelatedLogFormatter,
    get_current_trace_id,
    get_current_span_id,
    get_current_session,
)

# Tracer
from .tracer import (
    SpanTracer,
    trace,
    span,
    get_tracer,
    add_suggested_fix,
    add_related_code,
    log_to_session,
)

# Storage
from .storage import (
    DebugStorage,
    get_storage,
    set_storage,
)

# API
from .api.routes import router
from .api import websocket

__all__ = [
    # Version
    "__version__",
    # Types
    "TraceContext",
    "IOSContext",
    "Span",
    "SpanStatus",
    "LogEntry",
    "LogLevel",
    "DebugSession",
    "SuggestedFix",
    "DebugSessionSummary",
    "DebugQueryResponse",
    # Middleware
    "AwarePythonMiddleware",
    "CorrelatedLogFilter",
    "CorrelatedLogFormatter",
    "get_current_trace_id",
    "get_current_span_id",
    "get_current_session",
    # Tracer
    "SpanTracer",
    "trace",
    "span",
    "get_tracer",
    "add_suggested_fix",
    "add_related_code",
    "log_to_session",
    # Storage
    "DebugStorage",
    "get_storage",
    "set_storage",
    # API
    "router",
    "websocket",
]
