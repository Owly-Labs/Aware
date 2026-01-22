"""
AwarePython WebSocket Handlers

Real-time streaming of debug sessions for live debugging.
"""

import asyncio
import json
import logging
from typing import Optional

from fastapi import APIRouter, WebSocket, WebSocketDisconnect

from ..storage import get_storage
from ..middleware import get_current_trace_id

logger = logging.getLogger("aware_python.websocket")

router = APIRouter(tags=["debug-ws"])


class ConnectionManager:
    """Manages WebSocket connections for real-time debugging."""

    def __init__(self):
        # trace_id -> list of connections
        self._connections: dict[str, list[WebSocket]] = {}
        # Global connections (receive all updates)
        self._global_connections: list[WebSocket] = []

    async def connect(self, websocket: WebSocket, trace_id: Optional[str] = None):
        """Accept a WebSocket connection."""
        await websocket.accept()

        if trace_id:
            if trace_id not in self._connections:
                self._connections[trace_id] = []
            self._connections[trace_id].append(websocket)
            logger.debug(f"WebSocket connected for trace: {trace_id[:8]}")
        else:
            self._global_connections.append(websocket)
            logger.debug("WebSocket connected (global)")

    def disconnect(self, websocket: WebSocket, trace_id: Optional[str] = None):
        """Remove a WebSocket connection."""
        if trace_id and trace_id in self._connections:
            if websocket in self._connections[trace_id]:
                self._connections[trace_id].remove(websocket)
                if not self._connections[trace_id]:
                    del self._connections[trace_id]
        elif websocket in self._global_connections:
            self._global_connections.remove(websocket)

    async def broadcast(self, message: dict, trace_id: Optional[str] = None):
        """Broadcast message to relevant connections."""
        data = json.dumps(message, default=str)

        # Send to trace-specific connections
        if trace_id and trace_id in self._connections:
            for connection in self._connections[trace_id]:
                try:
                    await connection.send_text(data)
                except Exception:
                    pass

        # Send to global connections
        for connection in self._global_connections:
            try:
                await connection.send_text(data)
            except Exception:
                pass


# Global connection manager
manager = ConnectionManager()


@router.websocket("/debug/ws/live")
async def websocket_live_debug(websocket: WebSocket):
    """
    WebSocket endpoint for live debugging.

    Receives real-time updates for all debug sessions.

    Messages:
        - session_start: New session started
        - span_start: Span started
        - span_end: Span completed
        - log: New log entry
        - error: Error occurred
        - session_end: Session completed
    """
    await manager.connect(websocket)

    try:
        while True:
            # Keep connection alive, handle any incoming messages
            data = await websocket.receive_text()
            try:
                message = json.loads(data)
                # Handle ping/pong
                if message.get("type") == "ping":
                    await websocket.send_text(json.dumps({"type": "pong"}))
            except json.JSONDecodeError:
                pass

    except WebSocketDisconnect:
        manager.disconnect(websocket)
        logger.debug("WebSocket disconnected (global)")


@router.websocket("/debug/ws/trace/{trace_id}")
async def websocket_trace_debug(websocket: WebSocket, trace_id: str):
    """
    WebSocket endpoint for debugging a specific trace.

    Subscribe to updates for a single trace ID.
    """
    await manager.connect(websocket, trace_id)

    # Send current session state if exists
    storage = get_storage()
    session = await storage.get_session(trace_id)
    if session:
        await websocket.send_text(json.dumps({
            "type": "session_state",
            "trace_id": trace_id,
            "compact_format": session.to_compact_format(),
        }, default=str))

    try:
        while True:
            data = await websocket.receive_text()
            try:
                message = json.loads(data)
                if message.get("type") == "ping":
                    await websocket.send_text(json.dumps({"type": "pong"}))
                elif message.get("type") == "refresh":
                    # Re-send current state
                    session = await storage.get_session(trace_id)
                    if session:
                        await websocket.send_text(json.dumps({
                            "type": "session_state",
                            "trace_id": trace_id,
                            "compact_format": session.to_compact_format(),
                        }, default=str))
            except json.JSONDecodeError:
                pass

    except WebSocketDisconnect:
        manager.disconnect(websocket, trace_id)
        logger.debug(f"WebSocket disconnected for trace: {trace_id[:8]}")


# Event broadcasting functions (called from middleware/tracer)

async def broadcast_session_start(trace_id: str, ios_context: Optional[dict] = None):
    """Broadcast session start event."""
    await manager.broadcast({
        "type": "session_start",
        "trace_id": trace_id,
        "ios_context": ios_context,
    }, trace_id)


async def broadcast_span_start(trace_id: str, span_id: str, name: str):
    """Broadcast span start event."""
    await manager.broadcast({
        "type": "span_start",
        "trace_id": trace_id,
        "span_id": span_id,
        "name": name,
    }, trace_id)


async def broadcast_span_end(
    trace_id: str,
    span_id: str,
    name: str,
    duration_ms: float,
    status: str,
    error: Optional[str] = None,
):
    """Broadcast span end event."""
    await manager.broadcast({
        "type": "span_end",
        "trace_id": trace_id,
        "span_id": span_id,
        "name": name,
        "duration_ms": duration_ms,
        "status": status,
        "error": error,
    }, trace_id)


async def broadcast_log(trace_id: str, level: str, message: str, source: str):
    """Broadcast log event."""
    await manager.broadcast({
        "type": "log",
        "trace_id": trace_id,
        "level": level,
        "message": message,
        "source": source,
    }, trace_id)


async def broadcast_error(trace_id: str, error: str, suggested_fixes: list[str]):
    """Broadcast error event."""
    await manager.broadcast({
        "type": "error",
        "trace_id": trace_id,
        "error": error,
        "suggested_fixes": suggested_fixes,
    }, trace_id)


async def broadcast_session_end(trace_id: str, compact_format: str):
    """Broadcast session end event."""
    await manager.broadcast({
        "type": "session_end",
        "trace_id": trace_id,
        "compact_format": compact_format,
    }, trace_id)
