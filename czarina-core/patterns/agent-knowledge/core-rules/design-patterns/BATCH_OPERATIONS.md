# Batch Operations Patterns for Agent Development

**Purpose**: Proven patterns for efficient batch processing, bulk operations, and high-throughput data handling in AI agent systems.

**Value**: 3-10x performance improvement through efficient batching, parallel processing, and optimized resource utilization.

**Source**: SARK project (bulk operations, batch processing, audit event batching)

---

## 🎯 Philosophy

**Good batch operations**:
- Process multiple items efficiently
- Handle partial failures gracefully
- Provide clear progress tracking
- Support both transactional and best-effort modes
- Include backpressure mechanisms

**Bad batch operations**:
- Process items one at a time unnecessarily
- Fail entire batch on single error
- Provide no progress feedback
- Ignore memory constraints
- Block on slow operations

---

## 📋 Table of Contents

1. [Batch Handler Pattern](#batch-handler-pattern)
2. [Bulk Operations with Transactions](#bulk-operations-with-transactions)
3. [Best-Effort Batch Processing](#best-effort-batch-processing)
4. [Batch Policy Evaluation](#batch-policy-evaluation)
5. [Queue-Based Batching](#queue-based-batching)
6. [Batch Result Tracking](#batch-result-tracking)
7. [Time and Size Based Flushing](#time-and-size-based-flushing)
8. [Batch Progress Monitoring](#batch-progress-monitoring)
9. [Memory-Aware Batching](#memory-aware-batching)
10. [Anti-Patterns](#anti-patterns)

---

## Batch Handler Pattern

### Overview

Event aggregation and batching for efficient forwarding to external systems.

### Implementation

**File Reference**: `sark/src/sark/services/audit/siem/batch_handler.py:25-102`

```python
from dataclasses import dataclass
import asyncio
from datetime import UTC, datetime
from typing import Callable, List
import structlog

logger = structlog.get_logger()

@dataclass
class BatchConfig:
    """Configuration for batch processing"""
    batch_size: int = 100
    batch_timeout_seconds: float = 5.0
    max_queue_size: int = 10000

class BatchHandler:
    """
    Handles batching of events for efficient forwarding.

    Collects events and forwards them in batches based on either
    batch size or timeout, whichever occurs first.
    """

    def __init__(
        self,
        send_batch_callback: Callable[[List[AuditEvent]], bool],
        config: BatchConfig | None = None,
    ):
        """
        Initialize batch handler.

        Args:
            send_batch_callback: Async callback to send batch of events
            config: Batch configuration (uses defaults if None)
        """
        self.config = config or BatchConfig()
        self._send_batch_callback = send_batch_callback
        self._logger = logger.bind(component="batch_handler")

        # Event queue and batch state
        self._event_queue: asyncio.Queue[AuditEvent] = asyncio.Queue(
            maxsize=self.config.max_queue_size
        )
        self._current_batch: List[AuditEvent] = []
        self._last_flush_time: datetime = datetime.now(UTC)
        self._running = False
        self._worker_task: asyncio.Task | None = None

        # Metrics
        self._batches_sent = 0
        self._batches_failed = 0
        self._events_queued = 0
        self._events_dropped = 0

    async def start(self):
        """Start the batch processing worker"""
        if self._running:
            self._logger.warning("batch_handler_already_running")
            return

        self._running = True
        self._worker_task = asyncio.create_task(self._batch_worker())
        self._logger.info(
            "batch_handler_started",
            batch_size=self.config.batch_size,
            batch_timeout=self.config.batch_timeout_seconds,
        )

    async def stop(self, flush: bool = True):
        """
        Stop the batch processing worker.

        Args:
            flush: If True, flush remaining events before stopping
        """
        if not self._running:
            return

        self._running = False

        if flush:
            await self._flush_current_batch()

        if self._worker_task:
            self._worker_task.cancel()
            with contextlib.suppress(asyncio.CancelledError):
                await self._worker_task

        self._logger.info(
            "batch_handler_stopped",
            batches_sent=self._batches_sent,
            batches_failed=self._batches_failed,
            events_queued=self._events_queued,
            events_dropped=self._events_dropped,
        )
```

### Key Features

1. **Dual flush trigger** - size-based AND time-based
2. **Graceful shutdown** - flush pending events before stopping
3. **Metrics tracking** - batches sent, failed, events queued/dropped
4. **Backpressure** - bounded queue with max size
5. **Async background worker** - non-blocking event processing

### Best Practices

- Set `batch_size` based on downstream system limits (100-1000 typical)
- Set `batch_timeout_seconds` to balance latency vs. efficiency (1-10s typical)
- Set `max_queue_size` to prevent memory exhaustion (10000+ typical)
- Always flush on shutdown to prevent data loss
- Monitor `events_dropped` metric for queue overflow

**File Reference**: `sark/src/sark/services/audit/siem/batch_handler.py:103-124`

---

## Bulk Operations with Transactions

### Overview

All-or-nothing batch processing with database transaction support.

### Implementation

**File Reference**: `sark/src/sark/services/bulk/__init__.py:117-214`

```python
async def bulk_register_servers(
    self,
    servers: List[dict],
    fail_on_first_error: bool = False,
) -> BulkOperationResult:
    """
    Bulk register MCP servers with transaction support.

    Args:
        servers: List of server registration requests
        fail_on_first_error: If True, rollback all on first error

    Returns:
        BulkOperationResult with success/failure details
    """
    result = BulkOperationResult()
    result.total = len(servers)

    if fail_on_first_error:
        # All-or-nothing: use transaction
        return await self._bulk_register_transactional(servers)
    else:
        # Best-effort: process individually
        return await self._bulk_register_best_effort(servers)

async def _bulk_register_transactional(
    self,
    servers: List[dict],
) -> BulkOperationResult:
    """
    Register servers in a single transaction (all-or-nothing).

    Args:
        servers: List of server registration requests

    Returns:
        BulkOperationResult
    """
    result = BulkOperationResult()
    result.total = len(servers)

    try:
        # 1. Batch policy evaluation FIRST
        policy_results = await self._batch_evaluate_policies(
            servers,
            action="server:register"
        )

        # 2. Check if any denied
        denied = [r for r in policy_results if not r["allowed"]]
        if denied:
            for server_data, policy_result in zip(servers, policy_results):
                if not policy_result["allowed"]:
                    result.add_failure(
                        {"name": server_data.get("name")},
                        f"Policy denied: {policy_result.get('reason')}"
                    )
                else:
                    result.add_failure(
                        {"name": server_data.get("name")},
                        "Transaction rolled back due to policy failures"
                    )
            return result

        # 3. All policies approved, register in transaction
        async with self.db.begin_nested():
            for server_data in servers:
                try:
                    server = await self.discovery_service.register_server(
                        name=server_data["name"],
                        transport=TransportType(server_data["transport"]),
                        mcp_version=server_data.get("version", "2025-06-18"),
                        capabilities=server_data.get("capabilities", []),
                        tools=server_data.get("tools", []),
                        # ... other fields
                    )

                    result.add_success({
                        "server_id": str(server.id),
                        "name": server.name,
                        "status": server.status.value,
                    })

                    # Log audit event
                    await self.audit_service.log_event(
                        event_type=AuditEventType.SERVER_REGISTERED,
                        severity=SeverityLevel.MEDIUM,
                        user_id=self.user_id,
                        server_id=server.id,
                        details={"bulk_operation": True}
                    )

                except Exception as e:
                    # Rollback entire transaction
                    logger.error("bulk_register_failed",
                                server=server_data, error=str(e))
                    raise

            await self.db.commit()

        logger.info("bulk_register_success",
                   total=result.total,
                   succeeded=result.success_count)

    except Exception as e:
        # Transaction failed, mark all as failed
        await self.db.rollback()
        for server_data in servers:
            result.add_failure(
                {"name": server_data.get("name")},
                f"Transaction failed: {str(e)}"
            )
        logger.error("bulk_register_transaction_failed", error=str(e))

    return result
```

### Transaction Workflow

1. **Pre-validate all items** - batch policy evaluation before transaction
2. **Fail fast on denial** - don't start transaction if any policy denied
3. **Nested transaction** - use `begin_nested()` for savepoints
4. **Audit logging** - log each success within transaction
5. **All-or-nothing rollback** - single failure rolls back entire batch

### Best Practices

- **Validate before transaction** - catch errors early
- **Use nested transactions** - for better control
- **Log within transaction** - audit events part of atomic unit
- **Clear error messages** - distinguish policy failures from system errors
- **Limit batch size** - very large transactions can lock database

**File Reference**: `sark/src/sark/services/bulk/__init__.py:117-214`

---

## Best-Effort Batch Processing

### Overview

Process as many items as possible, continue on individual failures.

### Implementation

**File Reference**: `sark/src/sark/services/bulk/__init__.py:216-299`

```python
async def _bulk_register_best_effort(
    self,
    servers: List[dict],
) -> BulkOperationResult:
    """
    Register servers with best-effort (continue on errors).

    Args:
        servers: List of server registration requests

    Returns:
        BulkOperationResult
    """
    result = BulkOperationResult()
    result.total = len(servers)

    # Batch policy evaluation
    policy_results = await self._batch_evaluate_policies(
        servers,
        action="server:register"
    )

    # Process each server individually
    for server_data, policy_result in zip(servers, policy_results):
        try:
            # Check policy
            if not policy_result["allowed"]:
                result.add_failure(
                    {"name": server_data.get("name")},
                    f"Policy denied: {policy_result.get('reason')}"
                )
                continue

            # Register server
            server = await self.discovery_service.register_server(
                name=server_data["name"],
                transport=TransportType(server_data["transport"]),
                # ... other fields
            )

            result.add_success({
                "server_id": str(server.id),
                "name": server.name,
                "status": server.status.value,
            })

            # Log audit event
            await self.audit_service.log_event(
                event_type=AuditEventType.SERVER_REGISTERED,
                severity=SeverityLevel.MEDIUM,
                user_id=self.user_id,
                server_id=server.id,
                details={"bulk_operation": True}
            )

        except Exception as e:
            result.add_failure(
                {"name": server_data.get("name")},
                str(e)
            )
            logger.warning(
                "server_registration_failed",
                server=server_data.get("name"),
                error=str(e)
            )

    logger.info(
        "bulk_register_complete",
        total=result.total,
        succeeded=result.success_count,
        failed=result.failure_count
    )

    return result
```

### Best-Effort Characteristics

1. **Individual processing** - each item processed independently
2. **Continue on failure** - one failure doesn't stop others
3. **Detailed error tracking** - each failure recorded with reason
4. **Batch optimization** - still uses batch policy evaluation
5. **Comprehensive results** - returns both successes and failures

### When to Use

- **User-initiated bulk imports** - want partial success feedback
- **API batch endpoints** - caller expects partial results
- **Data migration** - process as much as possible
- **Retry operations** - reprocess only failed items

### Best Practices

- **Batch pre-validation** - policy checks, even in best-effort mode
- **Detailed failure tracking** - include item context in errors
- **Progress logging** - log after every N items or time interval
- **Return structured results** - separate succeeded/failed lists
- **Enable retry** - include enough context for client to retry failures

---

## Batch Policy Evaluation

### Overview

Evaluate policies for entire batch in single call to reduce overhead.

### Implementation

```python
async def _batch_evaluate_policies(
    self,
    items: List[dict],
    action: str
) -> List[dict]:
    """
    Evaluate policy for batch of items in single OPA call.

    Args:
        items: List of items to evaluate
        action: Action being performed (e.g., "server:register")

    Returns:
        List of policy results aligned with input items
    """
    # Build batch policy request
    policy_requests = [
        {
            "input": {
                "user": {
                    "id": str(self.user_id),
                    "email": self.user_email,
                    "role": self.user_role,
                    "teams": self.user_teams,
                },
                "action": action,
                "resource": {
                    "type": "mcp_server",
                    "name": item.get("name"),
                    "sensitivity_level": item.get("sensitivity_level", "medium"),
                    "metadata": item.get("metadata", {}),
                }
            }
        }
        for item in items
    ]

    # Single OPA batch call
    results = await self.opa_client.batch_evaluate(
        policy_path="rbac/allow",
        requests=policy_requests
    )

    return results
```

### Batch Policy Benefits

1. **Reduced network calls** - 1 call instead of N calls
2. **Lower latency** - single round-trip time
3. **Consistent evaluation** - same policy version for all items
4. **Better throughput** - policy engine can optimize batch
5. **Simplified error handling** - single failure point

### Best Practices

- **Batch size limits** - OPA may have max batch size (check docs)
- **Timeout scaling** - increase timeout for larger batches
- **Result alignment** - ensure results align with input order
- **Partial failure handling** - some policy engines support partial results
- **Caching consideration** - batch calls may bypass cache

---

## Queue-Based Batching

### Overview

Background worker pattern for continuous batch processing.

### Implementation

**File Reference**: `sark/src/sark/services/audit/siem/batch_handler.py:125-169`

```python
async def _batch_worker(self):
    """Background worker that processes batches"""
    self._logger.info("batch_worker_started")

    while self._running:
        try:
            # Check if we should flush based on timeout
            time_since_flush = (
                datetime.now(UTC) - self._last_flush_time
            ).total_seconds()

            should_flush_timeout = (
                time_since_flush >= self.config.batch_timeout_seconds
                and len(self._current_batch) > 0
            )

            if should_flush_timeout:
                await self._flush_current_batch()
                continue

            # Calculate remaining timeout
            remaining_timeout = max(
                0.1,
                self.config.batch_timeout_seconds - time_since_flush
            )

            # Wait for an event with timeout
            try:
                event = await asyncio.wait_for(
                    self._event_queue.get(),
                    timeout=remaining_timeout
                )
                self._current_batch.append(event)

                # Check if batch is full
                if len(self._current_batch) >= self.config.batch_size:
                    await self._flush_current_batch()

            except TimeoutError:
                # Timeout occurred, check if we should flush
                if len(self._current_batch) > 0:
                    await self._flush_current_batch()

        except Exception as e:
            self._logger.error(
                "batch_worker_error",
                error_type=type(e).__name__,
                error_message=str(e)
            )
            await asyncio.sleep(1)  # Brief pause before retrying

    self._logger.info("batch_worker_stopped")
```

### Worker Pattern Features

1. **Dual trigger logic** - size OR timeout triggers flush
2. **Dynamic timeout** - adjusts remaining timeout based on last flush
3. **Graceful error handling** - worker continues on errors
4. **Clean shutdown** - stop signal respected
5. **Continuous operation** - processes events as they arrive

### Best Practices

- **Minimum timeout** - use `max(0.1, calculated_timeout)` to prevent busy loops
- **Error recovery** - brief sleep after errors prevents tight error loops
- **Metrics tracking** - track queue depth, batch sizes, flush frequency
- **Graceful shutdown** - check `_running` flag regularly
- **Context manager support** - implement `__aenter__` and `__aexit__`

---

## Batch Result Tracking

### Overview

Structured result tracking for bulk operations with success/failure details.

### Implementation

**File Reference**: `sark/src/sark/services/bulk/__init__.py:22-57`

```python
class BulkOperationResult:
    """Result of a bulk operation with success/failure tracking"""

    def __init__(self):
        """Initialize bulk operation result"""
        self.succeeded: List[dict] = []
        self.failed: List[dict] = []
        self.total: int = 0

    def add_success(self, item: dict):
        """Add successful operation"""
        self.succeeded.append(item)

    def add_failure(self, item: dict, error: str):
        """Add failed operation"""
        self.failed.append({**item, "error": error})

    @property
    def success_count(self) -> int:
        """Get count of successful operations"""
        return len(self.succeeded)

    @property
    def failure_count(self) -> int:
        """Get count of failed operations"""
        return len(self.failed)

    def to_dict(self) -> dict:
        """Convert to dictionary for API response"""
        return {
            "total": self.total,
            "succeeded": self.success_count,
            "failed": self.failure_count,
            "succeeded_items": self.succeeded,
            "failed_items": self.failed,
        }
```

### Result Tracking Benefits

1. **Clear summary** - total, succeeded, failed counts
2. **Detailed failures** - each failure includes item context and error
3. **Retry support** - failed items include enough data to retry
4. **API-ready** - `to_dict()` for JSON responses
5. **Type safety** - dataclass with clear structure

### Best Practices

- **Include item identifiers** - name, ID, or unique key in each result
- **Preserve error context** - full error message, not just type
- **Limit detail size** - truncate very large items in results
- **Progress tracking** - emit events at milestones (every 100 items)
- **Persistent storage** - log detailed results for large batches

---

## Time and Size Based Flushing

### Overview

Dual trigger mechanism for optimal batch processing.

### Implementation

**File Reference**: `sark/src/sark/services/audit/siem/batch_handler.py:171-214`

```python
async def _flush_current_batch(self):
    """Flush the current batch of events"""
    if not self._current_batch:
        return

    batch_to_send = self._current_batch.copy()
    batch_size = len(batch_to_send)

    self._logger.info("flushing_batch", batch_size=batch_size)

    try:
        # Send the batch
        success = await self._send_batch_callback(batch_to_send)

        if success:
            self._batches_sent += 1
            self._logger.info(
                "batch_sent_successfully",
                batch_size=batch_size,
                total_batches_sent=self._batches_sent
            )
        else:
            self._batches_failed += 1
            self._logger.error(
                "batch_send_failed",
                batch_size=batch_size,
                total_batches_failed=self._batches_failed
            )

        # Clear the batch regardless of success/failure
        self._current_batch.clear()
        self._last_flush_time = datetime.now(UTC)

    except Exception as e:
        self._batches_failed += 1
        self._logger.error(
            "batch_send_exception",
            batch_size=batch_size,
            error_type=type(e).__name__,
            error_message=str(e)
        )
        # Clear the batch to avoid retrying same failed events infinitely
        self._current_batch.clear()
        self._last_flush_time = datetime.now(UTC)
```

### Flush Strategy

1. **Size trigger** - flush when batch reaches `batch_size`
2. **Time trigger** - flush when `batch_timeout_seconds` elapsed
3. **Shutdown trigger** - flush on graceful shutdown
4. **Error handling** - clear batch even on failure (prevents infinite retry)
5. **Metrics update** - track success/failure rates

### Best Practices

- **Copy before send** - use `batch_to_send = batch.copy()` to prevent race conditions
- **Clear on failure** - avoid infinite retry loops
- **Update timestamp** - always update `last_flush_time` after flush
- **Log batch size** - helps tune batch_size and timeout
- **Monitor flush frequency** - too frequent = inefficient, too rare = high latency

---

## Batch Progress Monitoring

### Overview

Track and report progress for long-running batch operations.

### Implementation

```python
class BatchProgressMonitor:
    """Monitor and report batch operation progress"""

    def __init__(
        self,
        total_items: int,
        report_interval: int = 100,
        progress_callback: Optional[Callable[[dict], None]] = None
    ):
        self.total_items = total_items
        self.report_interval = report_interval
        self.progress_callback = progress_callback

        self.processed = 0
        self.succeeded = 0
        self.failed = 0
        self.start_time = time.time()
        self.last_report_time = self.start_time

    def record_success(self):
        """Record a successful item"""
        self.processed += 1
        self.succeeded += 1
        self._check_report()

    def record_failure(self):
        """Record a failed item"""
        self.processed += 1
        self.failed += 1
        self._check_report()

    def _check_report(self):
        """Check if we should emit progress report"""
        if self.processed % self.report_interval == 0:
            self._emit_progress()

    def _emit_progress(self):
        """Emit progress report"""
        now = time.time()
        elapsed = now - self.start_time

        progress_data = {
            "total": self.total_items,
            "processed": self.processed,
            "succeeded": self.succeeded,
            "failed": self.failed,
            "percent_complete": (self.processed / self.total_items) * 100,
            "elapsed_seconds": elapsed,
            "items_per_second": self.processed / elapsed if elapsed > 0 else 0,
            "estimated_remaining_seconds": self._estimate_remaining()
        }

        logger.info("batch_progress", **progress_data)

        if self.progress_callback:
            self.progress_callback(progress_data)

    def _estimate_remaining(self) -> float:
        """Estimate remaining time in seconds"""
        elapsed = time.time() - self.start_time
        if self.processed == 0 or elapsed == 0:
            return 0

        rate = self.processed / elapsed
        remaining = self.total_items - self.processed
        return remaining / rate

    def get_final_report(self) -> dict:
        """Get final progress report"""
        elapsed = time.time() - self.start_time
        return {
            "total": self.total_items,
            "processed": self.processed,
            "succeeded": self.succeeded,
            "failed": self.failed,
            "elapsed_seconds": elapsed,
            "average_rate": self.processed / elapsed if elapsed > 0 else 0
        }
```

### Usage Example

```python
async def bulk_process_items(items: List[dict]):
    monitor = BatchProgressMonitor(
        total_items=len(items),
        report_interval=100,
        progress_callback=emit_websocket_update
    )

    result = BulkOperationResult()

    for item in items:
        try:
            await process_item(item)
            result.add_success(item)
            monitor.record_success()
        except Exception as e:
            result.add_failure(item, str(e))
            monitor.record_failure()

    logger.info("batch_complete", **monitor.get_final_report())
    return result
```

### Best Practices

- **Configurable intervals** - allow caller to set report frequency
- **Rate calculation** - items per second helps capacity planning
- **Time estimation** - ETA helpful for user experience
- **WebSocket updates** - real-time progress for UI
- **Final report** - always emit completion summary

---

## Memory-Aware Batching

### Overview

Adaptive batch sizing based on memory constraints.

### Implementation

```python
import sys
from typing import List, TypeVar, Iterator

T = TypeVar('T')

class MemoryAwareBatcher:
    """Batch items with memory constraints"""

    def __init__(
        self,
        max_batch_bytes: int = 10 * 1024 * 1024,  # 10MB default
        max_batch_items: int = 1000,
        size_estimator: Optional[Callable[[T], int]] = None
    ):
        self.max_batch_bytes = max_batch_bytes
        self.max_batch_items = max_batch_items
        self.size_estimator = size_estimator or sys.getsizeof

    def batch_items(self, items: List[T]) -> Iterator[List[T]]:
        """
        Split items into memory-safe batches.

        Yields:
            Batches of items that fit within memory constraints
        """
        current_batch = []
        current_size = 0

        for item in items:
            item_size = self.size_estimator(item)

            # Check if adding this item would exceed limits
            would_exceed_size = (current_size + item_size) > self.max_batch_bytes
            would_exceed_count = len(current_batch) >= self.max_batch_items

            if current_batch and (would_exceed_size or would_exceed_count):
                # Yield current batch and start new one
                yield current_batch
                current_batch = [item]
                current_size = item_size
            else:
                # Add to current batch
                current_batch.append(item)
                current_size += item_size

        # Yield final batch
        if current_batch:
            yield current_batch
```

### Usage Example

```python
async def process_large_dataset(items: List[dict]):
    """Process items with memory constraints"""

    def estimate_size(item: dict) -> int:
        # Custom size estimation for dict items
        return len(json.dumps(item).encode())

    batcher = MemoryAwareBatcher(
        max_batch_bytes=5 * 1024 * 1024,  # 5MB batches
        max_batch_items=500,
        size_estimator=estimate_size
    )

    total_result = BulkOperationResult()

    for batch in batcher.batch_items(items):
        batch_result = await process_batch(batch)
        total_result.merge(batch_result)

    return total_result
```

### Best Practices

- **Custom size estimator** - `sys.getsizeof` may not be accurate for all types
- **Account for overhead** - serialization, network buffers add size
- **Set conservative limits** - leave headroom for processing
- **Monitor actual sizes** - log batch sizes to tune limits
- **Fallback to count** - always enforce max item count as backup

---

## Anti-Patterns

### ❌ Anti-Pattern 1: Sequential Processing

**Bad:**
```python
# Process items one at a time
for item in items:
    await process_item(item)  # Slow, no batching
```

**Good:**
```python
# Batch items for efficient processing
for batch in chunk_items(items, batch_size=100):
    await process_batch(batch)  # Much faster
```

---

### ❌ Anti-Pattern 2: No Progress Feedback

**Bad:**
```python
# Silent processing, no feedback
for item in items:
    await process_item(item)
# User waits with no updates
```

**Good:**
```python
# Report progress regularly
monitor = BatchProgressMonitor(len(items), report_interval=100)
for item in items:
    await process_item(item)
    monitor.record_success()
```

---

### ❌ Anti-Pattern 3: Unbounded Batches

**Bad:**
```python
# No size limit on batches
batch = []
while True:
    item = await queue.get()
    batch.append(item)  # Can grow forever
```

**Good:**
```python
# Size and time limits
if len(batch) >= MAX_BATCH_SIZE or time_expired:
    await process_batch(batch)
    batch.clear()
```

---

### ❌ Anti-Pattern 4: Losing Failed Items

**Bad:**
```python
# Errors disappear
try:
    await process_batch(items)
except Exception:
    pass  # Lost which items failed
```

**Good:**
```python
# Track failures with context
for item in items:
    try:
        await process_item(item)
        result.add_success(item)
    except Exception as e:
        result.add_failure(item, str(e))
```

---

### ❌ Anti-Pattern 5: No Backpressure

**Bad:**
```python
# Unbounded queue
queue = asyncio.Queue()  # Can consume all memory
for item in items:
    await queue.put(item)
```

**Good:**
```python
# Bounded queue with backpressure
queue = asyncio.Queue(maxsize=1000)
try:
    queue.put_nowait(item)
except asyncio.QueueFull:
    # Handle backpressure
    await handle_queue_full()
```

---

### ❌ Anti-Pattern 6: Ignoring Partial Failures

**Bad:**
```python
# All-or-nothing with no choice
async with db.begin():
    for item in items:
        await db.insert(item)  # One failure = all fail
```

**Good:**
```python
# Offer both modes
if fail_on_first_error:
    return await process_transactional(items)
else:
    return await process_best_effort(items)
```

---

### ❌ Anti-Pattern 7: Inefficient Policy Checks

**Bad:**
```python
# Check policy for each item individually
for item in items:
    allowed = await policy.evaluate(item)  # N network calls
    if allowed:
        await process_item(item)
```

**Good:**
```python
# Batch policy evaluation
policy_results = await policy.batch_evaluate(items)  # 1 network call
for item, allowed in zip(items, policy_results):
    if allowed:
        await process_item(item)
```

---

## 🔗 Related Patterns

- [ERROR_RECOVERY.md](ERROR_RECOVERY.md) - Retry strategies for batch failures
- [CACHING_PATTERNS.md](CACHING_PATTERNS.md) - Cache batch results
- [STREAMING_PATTERNS.md](STREAMING_PATTERNS.md) - Stream-based batch processing
- [TOOL_USE_PATTERNS.md](TOOL_USE_PATTERNS.md) - Tool composition for batches
- Cross-reference: `agent-rules/python/ASYNC_PATTERNS.md` (from foundation worker)

---

**Last Updated**: 2025-12-26
**Patterns**: 9 documented
**Source**: SARK (v2.0+)
**Lines of Code Analyzed**: ~800 lines

*"Batch operations: process many, fail few, report all."*
