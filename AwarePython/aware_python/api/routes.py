"""
AwarePython REST API Routes

Endpoints for querying and managing debug sessions.
Designed for LLM consumption.
"""

from datetime import datetime, timedelta
from typing import Optional

from fastapi import APIRouter, HTTPException, Query

from ..storage import get_storage
from ..types import (
    DebugSession,
    DebugSessionSummary,
    DebugQueryResponse,
    SpanStatus,
)

router = APIRouter(prefix="/debug", tags=["debug"])


@router.get("/sessions", response_model=list[DebugSessionSummary])
async def list_sessions(
    limit: int = Query(50, ge=1, le=200),
    status: Optional[SpanStatus] = None,
    hours: Optional[int] = Query(None, ge=1, le=168, description="Filter sessions from last N hours"),
):
    """
    List recent debug sessions.

    Returns summaries optimized for quick scanning.
    """
    storage = get_storage()
    since = datetime.utcnow() - timedelta(hours=hours) if hours else None
    return await storage.list_sessions(limit=limit, status=status, since=since)


@router.get("/sessions/{trace_id}", response_model=DebugQueryResponse)
async def get_session(trace_id: str):
    """
    Get full debug session by trace ID.

    Returns both the structured session and LLM-optimized compact format.
    """
    storage = get_storage()
    session = await storage.get_session(trace_id)

    if not session:
        raise HTTPException(status_code=404, detail=f"Session not found: {trace_id}")

    return DebugQueryResponse(
        session=session,
        compact_format=session.to_compact_format(),
    )


@router.get("/sessions/{trace_id}/compact")
async def get_session_compact(trace_id: str) -> str:
    """
    Get LLM-optimized compact format for a session.

    This is the preferred endpoint for LLM consumption (~300-400 tokens).
    """
    storage = get_storage()
    session = await storage.get_session(trace_id)

    if not session:
        raise HTTPException(status_code=404, detail=f"Session not found: {trace_id}")

    return session.to_compact_format()


@router.get("/sessions/{trace_id}/spans")
async def get_session_spans(trace_id: str):
    """
    Get span tree for a session.

    Returns hierarchical span structure for detailed analysis.
    """
    storage = get_storage()
    session = await storage.get_session(trace_id)

    if not session:
        raise HTTPException(status_code=404, detail=f"Session not found: {trace_id}")

    if not session.root_span:
        return {"spans": [], "count": 0}

    def span_to_dict(span):
        return {
            "span_id": span.span_id,
            "name": span.name,
            "duration_ms": span.duration_ms,
            "status": span.status.value,
            "error": span.error,
            "error_file": span.error_file,
            "children": [span_to_dict(c) for c in span.children],
        }

    return {
        "spans": span_to_dict(session.root_span),
        "count": session.span_count,
    }


@router.get("/sessions/{trace_id}/logs")
async def get_session_logs(
    trace_id: str,
    level: Optional[str] = None,
    limit: int = Query(100, ge=1, le=500),
):
    """
    Get correlated logs for a session.

    Optionally filter by log level.
    """
    storage = get_storage()
    session = await storage.get_session(trace_id)

    if not session:
        raise HTTPException(status_code=404, detail=f"Session not found: {trace_id}")

    logs = session.logs
    if level:
        logs = [log for log in logs if log.level.value == level.lower()]

    return {
        "logs": [
            {
                "level": log.level.value.upper(),
                "message": log.message,
                "source": log.format_source(),
                "timestamp": log.timestamp.isoformat(),
            }
            for log in logs[-limit:]
        ],
        "total": len(session.logs),
        "filtered": len(logs),
    }


@router.get("/errors")
async def get_recent_errors(limit: int = Query(20, ge=1, le=100)):
    """
    Get sessions with errors.

    Useful for finding recent failures to debug.
    """
    storage = get_storage()
    sessions = await storage.get_sessions_with_errors(limit=limit)

    return {
        "error_sessions": [
            {
                "trace_id": s.trace_id,
                "created_at": s.created_at.isoformat(),
                "duration_ms": s.duration_ms,
                "ios_action": s.ios_context.action if s.ios_context else None,
                "errors": s.errors,
                "suggested_fixes": [f.description for f in s.suggested_fixes],
                "related_code": s.related_code,
            }
            for s in sessions
        ],
        "count": len(sessions),
    }


@router.delete("/sessions/{trace_id}")
async def delete_session(trace_id: str):
    """Delete a debug session."""
    storage = get_storage()
    deleted = await storage.delete_session(trace_id)

    if not deleted:
        raise HTTPException(status_code=404, detail=f"Session not found: {trace_id}")

    return {"deleted": True, "trace_id": trace_id}


@router.post("/sessions/cleanup")
async def cleanup_sessions():
    """
    Manually trigger cleanup of expired sessions.

    Returns count of removed sessions.
    """
    storage = get_storage()
    removed = await storage.cleanup_expired()
    return {"removed": removed}


@router.get("/stats")
async def get_stats():
    """Get storage statistics."""
    storage = get_storage()
    return storage.stats()


@router.get("/health")
async def health_check():
    """Health check for debug API."""
    storage = get_storage()
    stats = storage.stats()

    return {
        "status": "healthy",
        "total_sessions": stats["total_sessions"],
        "error_sessions": stats["error_sessions"],
    }
