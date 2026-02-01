# Streaming Patterns for Agent Development

**Purpose**: Proven patterns for implementing efficient streaming operations in AI agent systems.

**Value**: Real-time data processing, reduced memory footprint, and improved responsiveness through streaming architectures.

**Source**: SARK project (gRPC streaming, async iteration, backpressure handling)

---

## 🎯 Philosophy

**Good streaming**:
- Processes data incrementally
- Handles backpressure appropriately
- Provides progress feedback
- Manages resources efficiently
- Fails gracefully on stream errors

**Bad streaming**:
- Buffers entire stream in memory
- Ignores backpressure signals
- Provides no progress indication
- Leaks resources on errors
- Loses data on failures

---

## 📋 Table of Contents

1. [Server Streaming Pattern](#server-streaming-pattern)
2. [Client Streaming Pattern](#client-streaming-pattern)
3. [Bidirectional Streaming](#bidirectional-streaming)
4. [Async Iterator Pattern](#async-iterator-pattern)
5. [Stream Processing Pipeline](#stream-processing-pipeline)
6. [Backpressure Handling](#backpressure-handling)
7. [Stream Error Recovery](#stream-error-recovery)
8. [Stream Metrics and Monitoring](#stream-metrics-and-monitoring)
9. [Chunked Processing](#chunked-processing)
10. [Anti-Patterns](#anti-patterns)

---

## Server Streaming Pattern

### Overview

Single request, stream of responses pattern for real-time data delivery.

### Implementation

**File Reference**: `sark/src/sark/adapters/grpc/streaming.py:142-227`

```python
import asyncio
from collections.abc import AsyncIterator
from typing import Any, Callable
import grpc
from grpc import aio
import structlog

logger = structlog.get_logger(__name__)

class GRPCStreamHandler:
    """Handler for gRPC streaming operations"""

    def __init__(self, channel: aio.Channel):
        """
        Initialize stream handler.

        Args:
            channel: gRPC channel to use for calls
        """
        self._channel = channel
        logger.debug("grpc_stream_handler_initialized")

    async def invoke_server_streaming(
        self,
        service_name: str,
        method_name: str,
        request_data: dict[str, Any],
        timeout: float | None = None,
        metadata: dict[str, str] | None = None,
    ) -> AsyncIterator[dict[str, Any]]:
        """
        Invoke a server streaming RPC.

        Single request → stream of responses

        Args:
            service_name: Fully-qualified service name
            method_name: Method name
            request_data: Request data as dictionary
            timeout: Optional timeout in seconds
            metadata: Optional metadata headers

        Yields:
            Response messages as dictionaries

        Example:
            >>> async for response in handler.invoke_server_streaming(
            ...     service_name="myapp.v1.EventService",
            ...     method_name="StreamEvents",
            ...     request_data={"topic": "user.created"}
            ... ):
            ...     print(response)
            {'event_id': '1', 'data': {...}}
            {'event_id': '2', 'data': {...}}
        """
        logger.debug(
            "invoking_server_streaming_rpc",
            service=service_name,
            method=method_name,
        )

        method_path = f"/{service_name}/{method_name}"
        import json
        request_bytes = json.dumps(request_data).encode("utf-8")
        grpc_metadata = self._build_metadata(metadata)

        try:
            # Create unary-stream call
            call = self._channel.unary_stream(
                method=method_path,
                request_serializer=lambda x: x,
                response_deserializer=lambda x: x,
            )

            # Execute call
            response_stream = call(request_bytes, metadata=grpc_metadata)

            # Stream responses
            count = 0
            async for response_bytes in response_stream:
                response_data = json.loads(response_bytes.decode("utf-8"))
                count += 1
                logger.debug(
                    "server_streaming_message_received",
                    service=service_name,
                    method=method_name,
                    message_count=count,
                )
                yield response_data

            logger.debug(
                "server_streaming_completed",
                service=service_name,
                method=method_name,
                total_messages=count,
            )

        except grpc.RpcError as e:
            logger.error(
                "server_streaming_failed",
                service=service_name,
                method=method_name,
                code=e.code().name,
                details=e.details(),
            )
            raise
```

### Server Streaming Use Cases

- **Event streams** - real-time events from server
- **Log tailing** - continuous log output
- **Progress updates** - long-running operation status
- **Data feeds** - continuous data delivery (prices, metrics)
- **Search results** - incremental search result delivery

### Best Practices

- **Track message count** - useful for metrics and debugging
- **Handle disconnection** - detect and reconnect on stream breaks
- **Set timeouts** - prevent indefinite waiting
- **Log completion** - track total messages received
- **Resource cleanup** - ensure stream closed on exit

**File Reference**: `sark/src/sark/adapters/grpc/streaming.py:142-227`

---

## Client Streaming Pattern

### Overview

Stream of requests, single response pattern for aggregating client data.

### Implementation

**File Reference**: `sark/src/sark/adapters/grpc/streaming.py:229-327`

```python
async def invoke_client_streaming(
    self,
    service_name: str,
    method_name: str,
    request_iterator: Iterable[dict[str, Any]],
    timeout: float | None = None,
    metadata: dict[str, str] | None = None,
) -> dict[str, Any]:
    """
    Invoke a client streaming RPC.

    Stream of requests → single response

    Args:
        service_name: Fully-qualified service name
        method_name: Method name
        request_iterator: Iterable of request data dictionaries
        timeout: Optional timeout in seconds
        metadata: Optional metadata headers

    Returns:
        Response data as dictionary

    Example:
        >>> requests = [
        ...     {"value": 1},
        ...     {"value": 2},
        ...     {"value": 3}
        ... ]
        >>> response = await handler.invoke_client_streaming(
        ...     service_name="myapp.v1.CalculatorService",
        ...     method_name="Sum",
        ...     request_iterator=requests
        ... )
        >>> print(response)
        {'sum': 6}
    """
    logger.debug(
        "invoking_client_streaming_rpc",
        service=service_name,
        method=method_name,
    )

    method_path = f"/{service_name}/{method_name}"
    grpc_metadata = self._build_metadata(metadata)

    async def request_generator():
        """Generator to stream requests"""
        import json
        count = 0
        for request_data in request_iterator:
            request_bytes = json.dumps(request_data).encode("utf-8")
            count += 1
            logger.debug(
                "client_streaming_sending_message",
                service=service_name,
                method=method_name,
                message_count=count,
            )
            yield request_bytes

    try:
        # Create stream-unary call
        call = self._channel.stream_unary(
            method=method_path,
            request_serializer=lambda x: x,
            response_deserializer=lambda x: x,
        )

        # Execute call
        response_bytes = await asyncio.wait_for(
            call(request_generator(), metadata=grpc_metadata),
            timeout=timeout,
        )

        # Deserialize response
        import json
        response_data = json.loads(response_bytes.decode("utf-8"))

        logger.debug(
            "client_streaming_completed",
            service=service_name,
            method=method_name,
        )

        return response_data

    except grpc.RpcError as e:
        logger.error(
            "client_streaming_failed",
            service=service_name,
            method=method_name,
            code=e.code().name,
            details=e.details(),
        )
        raise
```

### Client Streaming Use Cases

- **Bulk upload** - stream large datasets to server
- **Log aggregation** - send logs in stream, get summary
- **Metric collection** - stream metrics, get aggregated stats
- **File upload** - stream file chunks, get completion status
- **Batch processing** - stream items for batch processing

### Best Practices

- **Use async generator** - for efficient memory usage
- **Track progress** - log message count as streaming
- **Set timeout** - based on expected stream duration
- **Handle cancellation** - cleanup on client cancel
- **Chunk large data** - split big items into smaller messages

---

## Bidirectional Streaming

### Overview

Stream of requests and responses simultaneously.

### Implementation

**File Reference**: `sark/src/sark/adapters/grpc/streaming.py:329-433`

```python
async def invoke_bidirectional_streaming(
    self,
    service_name: str,
    method_name: str,
    request_iterator: Iterable[dict[str, Any]],
    timeout: float | None = None,
    metadata: dict[str, str] | None = None,
) -> AsyncIterator[dict[str, Any]]:
    """
    Invoke a bidirectional streaming RPC.

    Stream of requests ↔ stream of responses

    Args:
        service_name: Fully-qualified service name
        method_name: Method name
        request_iterator: Iterable of request data dictionaries
        timeout: Optional timeout in seconds
        metadata: Optional metadata headers

    Yields:
        Response messages as dictionaries

    Example:
        >>> requests = [
        ...     {"query": "hello"},
        ...     {"query": "world"}
        ... ]
        >>> async for response in handler.invoke_bidirectional_streaming(
        ...     service_name="myapp.v1.ChatService",
        ...     method_name="Chat",
        ...     request_iterator=requests
        ... ):
        ...     print(response)
        {'message': 'Hello!'}
        {'message': 'World!'}
    """
    logger.debug(
        "invoking_bidirectional_streaming_rpc",
        service=service_name,
        method=method_name,
    )

    method_path = f"/{service_name}/{method_name}"
    grpc_metadata = self._build_metadata(metadata)

    async def request_generator():
        """Generator to stream requests"""
        import json
        count = 0
        for request_data in request_iterator:
            request_bytes = json.dumps(request_data).encode("utf-8")
            count += 1
            logger.debug(
                "bidirectional_streaming_sending_message",
                service=service_name,
                method=method_name,
                message_count=count,
            )
            yield request_bytes

    try:
        # Create stream-stream call
        call = self._channel.stream_stream(
            method=method_path,
            request_serializer=lambda x: x,
            response_deserializer=lambda x: x,
        )

        # Execute call
        response_stream = call(request_generator(), metadata=grpc_metadata)

        # Stream responses
        count = 0
        async for response_bytes in response_stream:
            import json
            response_data = json.loads(response_bytes.decode("utf-8"))
            count += 1
            logger.debug(
                "bidirectional_streaming_message_received",
                service=service_name,
                method=method_name,
                message_count=count,
            )
            yield response_data

        logger.debug(
            "bidirectional_streaming_completed",
            service=service_name,
            method=method_name,
            total_messages=count,
        )

    except grpc.RpcError as e:
        logger.error(
            "bidirectional_streaming_failed",
            service=service_name,
            method=method_name,
            code=e.code().name,
            details=e.details(),
        )
        raise
```

### Bidirectional Streaming Use Cases

- **Chat systems** - send/receive messages simultaneously
- **Real-time collaboration** - bidirectional updates
- **Interactive AI agents** - streaming conversation
- **Live data processing** - stream data and receive results
- **Multiplayer games** - bidirectional state updates

### Best Practices

- **Separate send/receive logic** - decouple request generation from response handling
- **Handle race conditions** - responses may not align with requests
- **Monitor both directions** - track sent and received message counts
- **Implement heartbeat** - detect connection issues
- **Clean shutdown** - gracefully close both directions

---

## Async Iterator Pattern

### Overview

Python async iterator protocol for streaming data.

### Implementation

```python
from collections.abc import AsyncIterator
from typing import TypeVar, Generic

T = TypeVar('T')

class AsyncDataStream(Generic[T]):
    """Async iterator for streaming data"""

    def __init__(self, source: AsyncIterator[T]):
        """
        Initialize async data stream.

        Args:
            source: Source async iterator
        """
        self._source = source
        self._count = 0

    def __aiter__(self):
        """Return async iterator (self)"""
        return self

    async def __anext__(self) -> T:
        """
        Get next item from stream.

        Returns:
            Next item

        Raises:
            StopAsyncIteration: When stream is exhausted
        """
        try:
            item = await self._source.__anext__()
            self._count += 1
            return item
        except StopAsyncIteration:
            logger.info(f"Stream completed, {self._count} items processed")
            raise

    async def map(self, func: Callable[[T], Any]) -> AsyncIterator:
        """Apply function to each item in stream"""
        async for item in self:
            yield func(item)

    async def filter(self, predicate: Callable[[T], bool]) -> AsyncIterator:
        """Filter stream by predicate"""
        async for item in self:
            if predicate(item):
                yield item

    async def take(self, n: int) -> AsyncIterator:
        """Take first n items from stream"""
        count = 0
        async for item in self:
            if count >= n:
                break
            yield item
            count += 1

    async def collect(self) -> list[T]:
        """Collect all items into a list (use cautiously)"""
        return [item async for item in self]
```

### Usage Example

```python
# Create stream
async def data_source():
    for i in range(100):
        await asyncio.sleep(0.1)
        yield {"id": i, "value": i * 2}

stream = AsyncDataStream(data_source())

# Transform stream
filtered = stream.filter(lambda x: x["value"] > 50)
mapped = filtered.map(lambda x: {**x, "processed": True})

# Consume stream
async for item in mapped:
    await process_item(item)

# Or collect (careful with large streams)
items = await stream.take(10).collect()
```

### Best Practices

- **Lazy evaluation** - transform without loading entire stream
- **Resource cleanup** - implement `__aenter__` and `__aexit__`
- **Error handling** - wrap operations in try/except
- **Backpressure** - respect consumer's processing speed
- **Limit collection** - avoid `collect()` on unbounded streams

---

## Stream Processing Pipeline

### Overview

Composable pipeline for stream transformations.

### Implementation

```python
class StreamPipeline:
    """Composable stream processing pipeline"""

    def __init__(self, source: AsyncIterator):
        self.source = source
        self._transforms = []

    def map(self, func: Callable):
        """Add map transformation"""
        async def _map():
            async for item in self.source:
                yield func(item)
        self.source = _map()
        return self

    def filter(self, predicate: Callable):
        """Add filter transformation"""
        async def _filter():
            async for item in self.source:
                if predicate(item):
                    yield item
        self.source = _filter()
        return self

    def batch(self, size: int):
        """Batch items"""
        async def _batch():
            batch = []
            async for item in self.source:
                batch.append(item)
                if len(batch) >= size:
                    yield batch
                    batch = []
            if batch:
                yield batch
        self.source = _batch()
        return self

    async def for_each(self, func: Callable):
        """Apply function to each item"""
        async for item in self.source:
            await func(item)

    async def collect(self) -> list:
        """Collect all items"""
        return [item async for item in self.source]

# Usage
pipeline = StreamPipeline(event_stream)
await (
    pipeline
    .filter(lambda e: e["type"] == "user_action")
    .map(lambda e: {"event_id": e["id"], "timestamp": e["ts"]})
    .batch(100)
    .for_each(process_batch)
)
```

### Pipeline Patterns

```python
# Pattern 1: Transform → Filter → Batch
await (
    StreamPipeline(source)
    .map(transform_item)
    .filter(is_valid)
    .batch(100)
    .for_each(process_batch)
)

# Pattern 2: Multiple filters
await (
    StreamPipeline(source)
    .filter(lambda x: x["type"] == "event")
    .filter(lambda x: x["priority"] == "high")
    .for_each(handle_event)
)

# Pattern 3: Map → Batch → Parallel process
await (
    StreamPipeline(source)
    .map(enrich_data)
    .batch(50)
    .for_each(lambda batch: asyncio.gather(*[process(i) for i in batch]))
)
```

### Best Practices

- **Method chaining** - return `self` for fluent interface
- **Lazy execution** - transforms applied on iteration
- **Async generators** - use async def for transformations
- **Error propagation** - let errors bubble up
- **Resource cleanup** - close streams on completion

---

## Backpressure Handling

### Overview

Control flow to prevent overwhelming slow consumers.

### Implementation

```python
class BackpressureStream:
    """Stream with backpressure support"""

    def __init__(
        self,
        source: AsyncIterator,
        buffer_size: int = 100,
        timeout: float = 30.0
    ):
        """
        Initialize backpressure stream.

        Args:
            source: Source iterator
            buffer_size: Maximum buffered items
            timeout: Timeout for buffer operations
        """
        self.source = source
        self.buffer = asyncio.Queue(maxsize=buffer_size)
        self.timeout = timeout
        self._producer_task = None
        self._stopped = False

    async def start(self):
        """Start background producer"""
        self._producer_task = asyncio.create_task(self._produce())

    async def _produce(self):
        """Background task to fill buffer"""
        try:
            async for item in self.source:
                if self._stopped:
                    break
                # This blocks when buffer is full (backpressure)
                await asyncio.wait_for(
                    self.buffer.put(item),
                    timeout=self.timeout
                )
        except asyncio.TimeoutError:
            logger.error("Producer timeout - consumer too slow")
        except Exception as e:
            logger.error(f"Producer error: {e}")
        finally:
            await self.buffer.put(None)  # Sentinel

    async def __aiter__(self):
        """Async iterator"""
        while True:
            item = await self.buffer.get()
            if item is None:  # Sentinel
                break
            yield item

    async def stop(self):
        """Stop stream"""
        self._stopped = True
        if self._producer_task:
            await self._producer_task

# Usage
stream = BackpressureStream(event_source, buffer_size=50)
await stream.start()

async for event in stream:
    # Slow consumer - backpressure prevents producer from racing ahead
    await slow_process(event)
    await asyncio.sleep(0.1)

await stream.stop()
```

### Backpressure Strategies

1. **Buffering** - bounded queue between producer/consumer
2. **Throttling** - slow down producer based on consumer speed
3. **Dropping** - discard items when consumer can't keep up
4. **Sampling** - send every Nth item when overloaded
5. **Batching** - group items to reduce per-item overhead

### Best Practices

- **Set buffer size** - based on memory constraints and latency needs
- **Monitor queue depth** - alert when consistently near full
- **Implement timeout** - prevent indefinite blocking
- **Graceful degradation** - handle buffer full scenarios
- **Metrics** - track dropped items, buffer utilization

---

## Stream Error Recovery

### Overview

Resilient streaming with error handling and recovery.

### Implementation

```python
class ResilientStream:
    """Stream with automatic error recovery"""

    def __init__(
        self,
        source_factory: Callable[[], AsyncIterator],
        max_retries: int = 3,
        retry_delay: float = 1.0,
    ):
        """
        Initialize resilient stream.

        Args:
            source_factory: Function that creates new source iterator
            max_retries: Maximum retry attempts
            retry_delay: Delay between retries (seconds)
        """
        self.source_factory = source_factory
        self.max_retries = max_retries
        self.retry_delay = retry_delay
        self._items_processed = 0

    async def __aiter__(self):
        """Async iterator with retry logic"""
        retries = 0
        source = self.source_factory()

        while retries <= self.max_retries:
            try:
                async for item in source:
                    self._items_processed += 1
                    yield item
                # Stream completed successfully
                break

            except Exception as e:
                retries += 1
                logger.error(
                    f"Stream error (attempt {retries}/{self.max_retries}): {e}"
                )

                if retries > self.max_retries:
                    logger.error("Max retries exceeded, giving up")
                    raise

                # Wait before retry
                await asyncio.sleep(self.retry_delay * retries)

                # Create new source for retry
                source = self.source_factory()
                logger.info(f"Retrying stream from position {self._items_processed}")

# Usage
def create_event_stream():
    return grpc_client.stream_events()

resilient = ResilientStream(
    source_factory=create_event_stream,
    max_retries=3,
    retry_delay=2.0
)

async for event in resilient:
    await process_event(event)
```

### Error Recovery Patterns

```python
# Pattern 1: Retry from beginning
async def retry_from_start():
    retries = 0
    while retries < max_retries:
        try:
            async for item in create_stream():
                yield item
            break
        except Exception as e:
            retries += 1
            await asyncio.sleep(retry_delay)

# Pattern 2: Resume from checkpoint
async def resume_from_checkpoint():
    checkpoint = load_checkpoint()
    while True:
        try:
            async for item in create_stream(start_from=checkpoint):
                yield item
                checkpoint = item["id"]
                save_checkpoint(checkpoint)
        except Exception as e:
            logger.error(f"Stream error at {checkpoint}, retrying...")
            await asyncio.sleep(retry_delay)

# Pattern 3: Skip failed items
async def skip_failed_items():
    async for item in stream:
        try:
            yield await process_item(item)
        except Exception as e:
            logger.warning(f"Skipping failed item {item['id']}: {e}")
            continue
```

### Best Practices

- **Exponential backoff** - increase delay on repeated failures
- **Checkpoint progress** - resume from last successful position
- **Log failures** - track what failed and why
- **Max retries** - prevent infinite retry loops
- **Circuit breaker** - stop trying after sustained failures

---

## Stream Metrics and Monitoring

### Overview

Track stream performance and health.

### Implementation

```python
class MonitoredStream:
    """Stream with built-in metrics"""

    def __init__(self, source: AsyncIterator):
        self.source = source
        self.items_processed = 0
        self.bytes_processed = 0
        self.errors = 0
        self.start_time = time.time()

    async def __aiter__(self):
        async for item in self.source:
            self.items_processed += 1
            self.bytes_processed += len(str(item))
            yield item

    def get_metrics(self) -> dict:
        elapsed = time.time() - self.start_time
        return {
            "items_processed": self.items_processed,
            "bytes_processed": self.bytes_processed,
            "errors": self.errors,
            "elapsed_seconds": elapsed,
            "items_per_second": self.items_processed / elapsed if elapsed > 0 else 0,
            "throughput_mbps": (self.bytes_processed / elapsed / 1024 / 1024) if elapsed > 0 else 0,
        }

# Usage with periodic reporting
stream = MonitoredStream(event_source)
report_interval = 100

async for idx, item in enumerate(stream):
    await process_item(item)

    if idx % report_interval == 0:
        logger.info("stream_metrics", **stream.get_metrics())

logger.info("stream_complete", **stream.get_metrics())
```

### Key Metrics

- **Items per second** - throughput rate
- **Bytes per second** - data throughput
- **Latency** - time from produce to consume
- **Error rate** - failed items / total items
- **Buffer utilization** - queue depth percentage

### Best Practices

- **Report periodically** - every N items or M seconds
- **Track latency** - measure end-to-end delay
- **Monitor backpressure** - queue depth alerts
- **Log completions** - final metrics summary
- **Use structured logging** - JSON for easy parsing

---

## Chunked Processing

### Overview

Process streams in fixed-size chunks for efficiency.

### Implementation

```python
async def chunked_stream(
    source: AsyncIterator[T],
    chunk_size: int
) -> AsyncIterator[list[T]]:
    """
    Chunk stream into fixed-size batches.

    Args:
        source: Source async iterator
        chunk_size: Number of items per chunk

    Yields:
        Lists of items (chunks)
    """
    chunk = []

    async for item in source:
        chunk.append(item)

        if len(chunk) >= chunk_size:
            yield chunk
            chunk = []

    # Yield final partial chunk
    if chunk:
        yield chunk

# Usage
async for chunk in chunked_stream(event_stream, chunk_size=100):
    # Process chunk in parallel
    await asyncio.gather(*[process_item(item) for item in chunk])
```

### Best Practices

- **Choose chunk size wisely** - balance latency vs. throughput
- **Handle partial chunks** - last chunk may be smaller
- **Parallel processing** - process chunk items concurrently
- **Memory awareness** - don't make chunks too large
- **Track chunk metrics** - monitor chunk sizes and processing times

---

## Anti-Patterns

### ❌ Anti-Pattern 1: Buffering Entire Stream

**Bad:**
```python
# Load entire stream into memory
items = [item async for item in stream]  # OOM on large streams
for item in items:
    process(item)
```

**Good:**
```python
# Process incrementally
async for item in stream:
    await process(item)
```

---

### ❌ Anti-Pattern 2: Blocking Async Stream

**Bad:**
```python
# Block on sync operation in async stream
async for item in stream:
    result = sync_blocking_call(item)  # Blocks event loop
```

**Good:**
```python
# Use async operations
async for item in stream:
    result = await async_call(item)
```

---

### ❌ Anti-Pattern 3: Ignoring Backpressure

**Bad:**
```python
# Producer races ahead of consumer
async def produce():
    for i in range(1000000):
        await queue.put(i)  # No limit
```

**Good:**
```python
# Bounded queue with backpressure
queue = asyncio.Queue(maxsize=100)
async def produce():
    for i in range(1000000):
        await queue.put(i)  # Blocks when full
```

---

### ❌ Anti-Pattern 4: No Error Handling

**Bad:**
```python
# Stream breaks on first error
async for item in stream:
    await process(item)  # Uncaught exception stops stream
```

**Good:**
```python
# Resilient stream processing
async for item in stream:
    try:
        await process(item)
    except Exception as e:
        logger.error(f"Processing error: {e}")
        continue
```

---

### ❌ Anti-Pattern 5: Resource Leaks

**Bad:**
```python
# No cleanup on errors
stream = create_stream()
async for item in stream:
    await process(item)
# Stream never closed on exception
```

**Good:**
```python
# Proper cleanup
stream = create_stream()
try:
    async for item in stream:
        await process(item)
finally:
    await stream.close()
```

---

## 🔗 Related Patterns

- [BATCH_OPERATIONS.md](BATCH_OPERATIONS.md) - Batch stream processing
- [ERROR_RECOVERY.md](ERROR_RECOVERY.md) - Stream error recovery
- [CACHING_PATTERNS.md](CACHING_PATTERNS.md) - Cache stream results
- [TOOL_USE_PATTERNS.md](TOOL_USE_PATTERNS.md) - Streaming tool responses
- Cross-reference: `agent-rules/python/ASYNC_PATTERNS.md` (from foundation worker)

---

**Last Updated**: 2025-12-26
**Patterns**: 9 documented
**Source**: SARK (v2.0+)
**Lines of Code Analyzed**: ~540 lines

*"Stream don't buffer - process incrementally, fail gracefully, monitor constantly."*
