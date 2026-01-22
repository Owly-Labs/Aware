# AwarePython

**LLM-centric debugging framework for Python backends**

AwarePython enables cross-platform debugging correlation between iOS apps and Python backends. Unlike traditional observability tools (Datadog, Sentry, OpenTelemetry) designed for human operators, AwarePython optimizes for LLM consumption with compact output (~300-400 tokens per debug bundle).

## Features

- **Cross-platform correlation**: Link iOS requests to backend spans via W3C Trace Context
- **LLM-optimized output**: Compact debug bundles with suggested fixes
- **Automatic tracing**: Middleware and decorators for zero-config tracing
- **Real-time debugging**: WebSocket streaming for live session monitoring
- **Smart error context**: Automatic file:line extraction and fix suggestions

## Installation

```bash
pip install aware-python
```

Or with WebSocket support:

```bash
pip install aware-python[websocket]
```

## Quick Start

```python
from fastapi import FastAPI
from aware_python import AwarePythonMiddleware, router as debug_router, trace

app = FastAPI()

# Add middleware for automatic tracing
app.add_middleware(AwarePythonMiddleware, always_trace=True)

# Add debug API routes
app.include_router(debug_router)

# Trace individual functions
@trace("youtube.download")
async def download_video(video_id: str):
    # Your code here
    pass
```

## API Endpoints

| Endpoint | Description |
|----------|-------------|
| `GET /debug/sessions` | List recent debug sessions |
| `GET /debug/sessions/{trace_id}` | Get full session with compact format |
| `GET /debug/sessions/{trace_id}/compact` | Get LLM-optimized format only |
| `GET /debug/sessions/{trace_id}/spans` | Get span tree |
| `GET /debug/sessions/{trace_id}/logs` | Get correlated logs |
| `GET /debug/errors` | Get sessions with errors |
| `WS /debug/ws/live` | Real-time updates (all sessions) |
| `WS /debug/ws/trace/{trace_id}` | Real-time updates (specific trace) |

## LLM-Optimized Output

When an LLM queries "What happened with trace abc123?", AwarePython returns:

```
TRACE:abc123 duration=2450ms status=OK
iOS:LibraryView→SongCardView action=processVideo

SPANS:
  POST /process/youtube/xyz [2450ms OK]
    ├─ youtube.download [1200ms OK]
    ├─ vocal.separate [800ms OK]
    └─ pitch.extract [400ms OK]

LOGS:
  INFO youtube_extractor.py:142 "Starting download"
  INFO bs_roformer.py:89 "Separation complete"

ERRORS: none
```

On error:

```
TRACE:abc123 duration=1850ms status=ERROR
iOS:LibraryView→SongCardView action=processVideo

SPANS:
  POST /process/youtube/xyz [1850ms ERROR]
    ├─ youtube.download [1200ms OK]
    └─ vocal.separate [650ms ERROR]
        error="BSRoFormer OOM: insufficient GPU memory"
        file=bs_roformer.py:156

ERRORS:
  1. OOM during vocal separation

SUGGESTED_FIXES:
  1. Reduce ROFORMER_CHUNK_SIZE in config.py
  2. Add audio chunking before separation

RELATED_CODE:
  - bs_roformer.py:150-160
  - config.py:45
```

## iOS Integration

iOS apps send trace context via HTTP headers:

```
traceparent: 00-{traceId}-{spanId}-01
X-Correlation-ID: {traceId}
X-Debug-Context: {base64 JSON with viewStack, action, deviceId}
```

See `AetherSing/Services/AwarePython/` for the iOS client implementation.

## Advanced Usage

### Manual Span Creation

```python
from aware_python import get_tracer

tracer = get_tracer()

async def process_video():
    async with tracer.span("video.process") as span:
        span.attributes["video_id"] = "abc123"
        # Your code here
```

### Adding Suggested Fixes

```python
from aware_python import add_suggested_fix, add_related_code

try:
    process_large_file()
except MemoryError:
    add_suggested_fix(
        "Reduce CHUNK_SIZE in config.py",
        file="config.py",
        line=45,
    )
    add_related_code("config.py:40-50")
    raise
```

### Correlated Logging

```python
import logging
from aware_python import CorrelatedLogFilter, CorrelatedLogFormatter

handler = logging.StreamHandler()
handler.addFilter(CorrelatedLogFilter())
handler.setFormatter(CorrelatedLogFormatter())
logging.getLogger().addHandler(handler)

# Logs now include trace ID:
# 2026-01-21 10:30:00 [abc12345] INFO youtube.py:142 Starting download
```

## Configuration

```python
from aware_python import AwarePythonMiddleware, DebugStorage, set_storage

# Custom storage with TTL
storage = DebugStorage(
    max_sessions=1000,
    ttl_hours=24,
)
set_storage(storage)

# Middleware options
app.add_middleware(
    AwarePythonMiddleware,
    storage=storage,
    exclude_paths=["/health", "/metrics"],
    always_trace=True,  # Trace even without X-Correlation-ID
)
```

## License

MIT
