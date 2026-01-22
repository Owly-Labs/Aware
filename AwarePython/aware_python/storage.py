"""
AwarePython Debug Session Storage

In-memory storage with optional SQLite persistence.
Supports TTL-based cleanup for memory efficiency.
"""

import asyncio
import json
import logging
from collections import OrderedDict
from datetime import datetime, timedelta
from pathlib import Path
from typing import Optional

from .types import DebugSession, DebugSessionSummary, SpanStatus

logger = logging.getLogger("aware_python.storage")


class DebugStorage:
    """
    In-memory debug session storage with LRU eviction.

    Usage:
        storage = DebugStorage(max_sessions=1000, ttl_hours=24)

        # Save session
        await storage.save_session(session)

        # Query session
        session = await storage.get_session("trace_id")
    """

    def __init__(
        self,
        max_sessions: int = 1000,
        ttl_hours: int = 24,
        persist_path: Optional[Path] = None,
    ):
        """
        Initialize storage.

        Args:
            max_sessions: Maximum sessions to keep in memory
            ttl_hours: Time-to-live for sessions in hours
            persist_path: Optional path for SQLite persistence
        """
        self.max_sessions = max_sessions
        self.ttl = timedelta(hours=ttl_hours)
        self.persist_path = persist_path

        # LRU cache using OrderedDict
        self._sessions: OrderedDict[str, DebugSession] = OrderedDict()
        self._lock = asyncio.Lock()

        # Start cleanup task
        self._cleanup_task: Optional[asyncio.Task] = None

    async def save_session(self, session: DebugSession) -> None:
        """Save a debug session."""
        async with self._lock:
            # Remove oldest if at capacity
            while len(self._sessions) >= self.max_sessions:
                self._sessions.popitem(last=False)

            # Mark completion time if not set
            if session.status != SpanStatus.PENDING and not session.completed_at:
                session.completed_at = datetime.utcnow()

            # Add/update session
            self._sessions[session.trace_id] = session
            self._sessions.move_to_end(session.trace_id)

            logger.debug(f"Saved debug session: {session.trace_id[:8]}")

    async def get_session(self, trace_id: str) -> Optional[DebugSession]:
        """Get a debug session by trace ID."""
        async with self._lock:
            session = self._sessions.get(trace_id)
            if session:
                # Move to end (LRU)
                self._sessions.move_to_end(trace_id)
            return session

    async def list_sessions(
        self,
        limit: int = 50,
        status: Optional[SpanStatus] = None,
        since: Optional[datetime] = None,
    ) -> list[DebugSessionSummary]:
        """List recent debug sessions."""
        async with self._lock:
            sessions = list(self._sessions.values())

        # Filter
        if status:
            sessions = [s for s in sessions if s.status == status]
        if since:
            sessions = [s for s in sessions if s.created_at >= since]

        # Sort by creation time (newest first)
        sessions.sort(key=lambda s: s.created_at, reverse=True)

        # Convert to summaries
        return [
            DebugSessionSummary(
                trace_id=s.trace_id,
                status=s.status,
                duration_ms=s.duration_ms,
                created_at=s.created_at,
                ios_action=s.ios_context.action if s.ios_context else None,
                error_count=len(s.errors),
            )
            for s in sessions[:limit]
        ]

    async def get_sessions_with_errors(self, limit: int = 20) -> list[DebugSession]:
        """Get recent sessions that have errors."""
        async with self._lock:
            sessions = [
                s for s in self._sessions.values()
                if s.errors
            ]

        sessions.sort(key=lambda s: s.created_at, reverse=True)
        return sessions[:limit]

    async def delete_session(self, trace_id: str) -> bool:
        """Delete a debug session."""
        async with self._lock:
            if trace_id in self._sessions:
                del self._sessions[trace_id]
                return True
            return False

    async def clear(self) -> int:
        """Clear all sessions. Returns count of cleared sessions."""
        async with self._lock:
            count = len(self._sessions)
            self._sessions.clear()
            return count

    async def cleanup_expired(self) -> int:
        """Remove expired sessions. Returns count of removed sessions."""
        cutoff = datetime.utcnow() - self.ttl
        removed = 0

        async with self._lock:
            expired = [
                trace_id
                for trace_id, session in self._sessions.items()
                if session.created_at < cutoff
            ]

            for trace_id in expired:
                del self._sessions[trace_id]
                removed += 1

        if removed:
            logger.info(f"Cleaned up {removed} expired debug sessions")

        return removed

    async def start_cleanup_task(self, interval_minutes: int = 15):
        """Start background cleanup task."""
        async def cleanup_loop():
            while True:
                await asyncio.sleep(interval_minutes * 60)
                try:
                    await self.cleanup_expired()
                except Exception as e:
                    logger.error(f"Cleanup error: {e}")

        self._cleanup_task = asyncio.create_task(cleanup_loop())

    async def stop_cleanup_task(self):
        """Stop background cleanup task."""
        if self._cleanup_task:
            self._cleanup_task.cancel()
            try:
                await self._cleanup_task
            except asyncio.CancelledError:
                pass

    def stats(self) -> dict:
        """Get storage statistics."""
        sessions = list(self._sessions.values())
        error_count = sum(1 for s in sessions if s.errors)
        pending_count = sum(1 for s in sessions if s.status == SpanStatus.PENDING)

        return {
            "total_sessions": len(sessions),
            "error_sessions": error_count,
            "pending_sessions": pending_count,
            "max_sessions": self.max_sessions,
            "ttl_hours": self.ttl.total_seconds() / 3600,
        }


# Global storage instance
_storage: Optional[DebugStorage] = None


def get_storage() -> DebugStorage:
    """Get global storage instance."""
    global _storage
    if _storage is None:
        _storage = DebugStorage()
    return _storage


def set_storage(storage: DebugStorage) -> None:
    """Set global storage instance."""
    global _storage
    _storage = storage
