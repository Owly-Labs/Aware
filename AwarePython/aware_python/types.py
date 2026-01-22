"""
AwarePython Type Definitions

LLM-optimized Pydantic models for cross-platform debugging.
W3C Trace Context compatible.
"""

from datetime import datetime
from enum import Enum
from typing import Any, Optional
from pydantic import BaseModel, Field


class SpanStatus(str, Enum):
    """Span execution status."""
    PENDING = "pending"
    OK = "ok"
    ERROR = "error"


class LogLevel(str, Enum):
    """Log severity levels."""
    TRACE = "trace"
    DEBUG = "debug"
    INFO = "info"
    WARN = "warn"
    ERROR = "error"


# --- Trace Context (W3C Compatible) ---

class TraceContext(BaseModel):
    """
    W3C Trace Context for correlation.

    Header format: traceparent: 00-{traceId}-{spanId}-{flags}
    Example: 00-4bf92f3577b34da6a3ce929d0e0e4736-00f067aa0ba902b7-01
    """
    trace_id: str = Field(..., description="32-char hex trace ID")
    span_id: str = Field(..., description="16-char hex span ID")
    parent_span_id: Optional[str] = Field(None, description="Parent span ID if nested")
    flags: str = Field("01", description="Trace flags (01 = sampled)")

    @classmethod
    def from_traceparent(cls, header: str) -> Optional["TraceContext"]:
        """Parse W3C traceparent header."""
        try:
            parts = header.split("-")
            if len(parts) != 4 or parts[0] != "00":
                return None
            return cls(
                trace_id=parts[1],
                span_id=parts[2],
                flags=parts[3]
            )
        except Exception:
            return None

    def to_traceparent(self) -> str:
        """Generate W3C traceparent header."""
        return f"00-{self.trace_id}-{self.span_id}-{self.flags}"


class IOSContext(BaseModel):
    """Context captured from iOS client."""
    view_stack: list[str] = Field(default_factory=list, description="View hierarchy")
    action: str = Field(..., description="User action that triggered request")
    device_id: Optional[str] = None
    app_version: Optional[str] = None
    os_version: Optional[str] = None
    timestamp: datetime = Field(default_factory=datetime.utcnow)


# --- Span Model ---

class Span(BaseModel):
    """
    A single operation span in the trace tree.

    Spans form a tree: root span has children, each child may have sub-children.
    """
    span_id: str = Field(..., description="Unique span identifier")
    parent_span_id: Optional[str] = Field(None, description="Parent span if nested")
    trace_id: str = Field(..., description="Trace this span belongs to")

    name: str = Field(..., description="Operation name (e.g., 'youtube.download')")
    service: Optional[str] = Field(None, description="Service name")
    method: Optional[str] = Field(None, description="Method name")

    start_time: datetime = Field(default_factory=datetime.utcnow)
    end_time: Optional[datetime] = None
    duration_ms: Optional[float] = None

    status: SpanStatus = SpanStatus.PENDING
    error: Optional[str] = None
    error_file: Optional[str] = Field(None, description="File:line where error occurred")

    attributes: dict[str, Any] = Field(default_factory=dict)
    children: list["Span"] = Field(default_factory=list)

    def finish(self, status: SpanStatus = SpanStatus.OK, error: Optional[str] = None):
        """Complete the span."""
        self.end_time = datetime.utcnow()
        self.duration_ms = (self.end_time - self.start_time).total_seconds() * 1000
        self.status = status
        self.error = error


# --- Log Entry ---

class LogEntry(BaseModel):
    """Log entry with correlation."""
    id: str
    trace_id: Optional[str] = None
    span_id: Optional[str] = None

    timestamp: datetime = Field(default_factory=datetime.utcnow)
    level: LogLevel = LogLevel.INFO
    message: str

    # Source location
    file: Optional[str] = None
    line: Optional[int] = None
    function: Optional[str] = None

    # Additional context
    context: dict[str, Any] = Field(default_factory=dict)

    def format_source(self) -> str:
        """Format source location for LLM output."""
        if self.file and self.line:
            return f"{self.file}:{self.line}"
        return ""


# --- Debug Session ---

class SuggestedFix(BaseModel):
    """A suggested fix for an error."""
    description: str
    file: Optional[str] = None
    line: Optional[int] = None
    code_snippet: Optional[str] = None


class DebugSession(BaseModel):
    """
    Complete debug bundle for a trace.

    This is what the LLM receives when querying "What happened with trace X?"
    Optimized for ~300-400 tokens.
    """
    trace_id: str
    created_at: datetime = Field(default_factory=datetime.utcnow)
    completed_at: Optional[datetime] = None

    # Overall status
    status: SpanStatus = SpanStatus.PENDING
    duration_ms: Optional[float] = None

    # iOS context (from request headers)
    ios_context: Optional[IOSContext] = None

    # Span tree
    root_span: Optional[Span] = None
    span_count: int = 0

    # Correlated logs
    logs: list[LogEntry] = Field(default_factory=list)

    # Errors and fixes
    errors: list[str] = Field(default_factory=list)
    suggested_fixes: list[SuggestedFix] = Field(default_factory=list)
    related_code: list[str] = Field(default_factory=list, description="file:line references")

    def to_compact_format(self) -> str:
        """
        Generate LLM-optimized compact format (~300-400 tokens).

        Example output:
        ```
        TRACE:abc123 duration=2450ms status=OK
        iOS:LibraryView→SongCardView action=processVideo

        SPANS:
          POST /process/youtube/xyz [2450ms OK]
            ├─ youtube.download [1200ms OK]
            └─ vocal.separate [800ms OK]

        LOGS:
          INFO youtube_extractor.py:142 "Starting download"

        ERRORS: none
        ```
        """
        lines = []

        # Header
        status = self.status.value.upper()
        duration = f"duration={self.duration_ms:.0f}ms" if self.duration_ms else "duration=pending"
        lines.append(f"TRACE:{self.trace_id[:8]} {duration} status={status}")

        # iOS context
        if self.ios_context:
            view_path = "→".join(self.ios_context.view_stack) if self.ios_context.view_stack else "unknown"
            lines.append(f"iOS:{view_path} action={self.ios_context.action}")

        lines.append("")

        # Spans
        lines.append("SPANS:")
        if self.root_span:
            self._format_span_tree(self.root_span, lines, indent=2, is_last=True)
        else:
            lines.append("  (no spans)")

        lines.append("")

        # Logs (last 5)
        lines.append("LOGS:")
        recent_logs = self.logs[-5:] if self.logs else []
        if recent_logs:
            for log in recent_logs:
                src = log.format_source()
                lines.append(f"  {log.level.value.upper()} {src} \"{log.message[:50]}\"")
        else:
            lines.append("  (no logs)")

        lines.append("")

        # Errors
        if self.errors:
            lines.append("ERRORS:")
            for i, err in enumerate(self.errors, 1):
                lines.append(f"  {i}. {err}")

            if self.suggested_fixes:
                lines.append("")
                lines.append("SUGGESTED_FIXES:")
                for i, fix in enumerate(self.suggested_fixes, 1):
                    lines.append(f"  {i}. {fix.description}")

            if self.related_code:
                lines.append("")
                lines.append("RELATED_CODE:")
                for ref in self.related_code:
                    lines.append(f"  - {ref}")
        else:
            lines.append("ERRORS: none")

        return "\n".join(lines)

    def _format_span_tree(self, span: Span, lines: list[str], indent: int, is_last: bool):
        """Recursively format span tree."""
        prefix = " " * indent
        status = span.status.value.upper()
        duration = f"{span.duration_ms:.0f}ms" if span.duration_ms else "pending"

        # Tree connector
        connector = "└─" if is_last else "├─"
        if indent == 2:
            connector = ""  # Root span has no connector

        line = f"{prefix}{connector} {span.name} [{duration} {status}]"
        if span.error:
            line += f"\n{prefix}    error=\"{span.error[:40]}\""
            if span.error_file:
                line += f"\n{prefix}    file={span.error_file}"
        lines.append(line)

        # Children
        for i, child in enumerate(span.children):
            is_child_last = i == len(span.children) - 1
            self._format_span_tree(child, lines, indent + 4, is_child_last)


# --- API Response Models ---

class DebugSessionSummary(BaseModel):
    """Summary for listing sessions."""
    trace_id: str
    status: SpanStatus
    duration_ms: Optional[float]
    created_at: datetime
    ios_action: Optional[str] = None
    error_count: int = 0


class DebugQueryResponse(BaseModel):
    """Response for debug session queries."""
    session: DebugSession
    compact_format: str = Field(..., description="LLM-optimized compact format")
