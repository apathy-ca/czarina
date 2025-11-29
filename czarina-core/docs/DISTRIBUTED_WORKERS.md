# 🌐 Distributed Workers (Future Feature)

**Status**: Planned for v2.1+
**Complexity**: High
**Value**: Extreme

## The Vision

Workers running on **different machines** via SSH, each optimized for their task.

## Use Cases

### Build Optimization
```bash
WORKER_DEFINITIONS=(
    "frontend|feat/v1.1-ui|ui_TASKS.txt|UI Development|remote:build-server-1"
    "backend|feat/v1.1-api|api_TASKS.txt|API Development|remote:build-server-2"
    "ml-training|feat/v1.1-ml|ml_TASKS.txt|ML Model Training|remote:gpu-server"
    "docs|feat/v1.1-docs|docs_TASKS.txt|Documentation|local"
)
```

**Benefits**:
- Frontend builds on fast machine with Node.js optimized
- Backend builds on machine with compiled language toolchain
- ML training on GPU-equipped server
- Docs locally (no heavy compute needed)

### Geographic Distribution
```bash
WORKER_DEFINITIONS=(
    "us-east|feat/v1.1-api|api_TASKS.txt|API (US East)|remote:aws-us-east"
    "eu-west|feat/v1.1-api|api_TASKS.txt|API (EU West)|remote:aws-eu-west"
    "ap-south|feat/v1.1-api|api_TASKS.txt|API (AP South)|remote:aws-ap-south"
)
```

**Benefits**:
- Test multi-region deployments
- Parallel integration testing
- Regional compliance testing

### Cost Optimization
```bash
WORKER_DEFINITIONS=(
    "architect|feat/v2.0-design|arch_TASKS.txt|Architecture|local"
    "backend|feat/v2.0-api|api_TASKS.txt|Backend|remote:cheap-spot-instance"
    "frontend|feat/v2.0-ui|ui_TASKS.txt|Frontend|remote:cheap-spot-instance"
    "ml|feat/v2.0-models|ml_TASKS.txt|ML Training|remote:gpu-spot-instance"
)
```

**Benefits**:
- Expensive compute only when needed
- Spot instances for cost savings
- Local for light work (free)

## Technical Design

### Extended Worker Definition Format

```bash
# Current format:
"worker_id|branch|task_file|description"

# Extended format (v2.1+):
"worker_id|branch|task_file|description|remote:host"
"worker_id|branch|task_file|description|remote:user@host:port"
"worker_id|branch|task_file|description|local"  # explicit local
```

### SSH Configuration

**Option 1: SSH Config File**
```bash
# ~/.ssh/config
Host build-server-1
    HostName 10.0.1.50
    User builder
    IdentityFile ~/.ssh/build_key

Host gpu-server
    HostName gpu.example.com
    User ml-worker
    Port 2222
    IdentityFile ~/.ssh/gpu_key
```

Then in Czarina:
```bash
"ml|feat/v1.1-ml|ml_TASKS.txt|ML Training|remote:gpu-server"
```

**Option 2: Direct Specification**
```bash
"ml|feat/v1.1-ml|ml_TASKS.txt|ML Training|remote:ml-worker@gpu.example.com:2222"
```

### Implementation Approach

#### 1. Remote Tmux Sessions
```bash
# Current (local):
tmux new-session -d -s "czar-worker-engineer1"

# Future (remote):
ssh build-server-1 "tmux new-session -d -s 'czar-worker-engineer1'"
```

#### 2. Remote Git Operations
```bash
# Clone repo on remote
ssh remote-host "git clone git@github.com:user/repo.git /path/to/work"

# Or use existing checkout
ssh remote-host "cd /path/to/repo && git checkout -b feat/v1.1-backend"
```

#### 3. Remote Status Monitoring
```bash
# Check remote worker status
ssh remote-host "cd /path/to/repo && git log -1 --format=%s"

# Capture remote tmux pane
ssh remote-host "tmux capture-pane -t czar-worker-engineer1 -p"
```

#### 4. Task Injection
```bash
# Inject task to remote worker
ssh remote-host "tmux load-buffer /tmp/task.txt && tmux paste-buffer -t czar-worker-engineer1"
```

### Dashboard Integration

The dashboard would show:
```
┌────────────────────────────────────────────────────────┐
│ Worker Status                                          │
├────────────┬─────────┬───────────┬──────────────────────┤
│ Worker     │ Status  │ Location  │ Last Activity        │
├────────────┼─────────┼───────────┼──────────────────────┤
│ engineer1  │ Working │ Local     │ 2 mins ago          │
│ engineer2  │ Working │ Remote-1  │ 5 mins ago          │
│ ml-worker  │ Working │ GPU-East  │ 10 mins ago         │
│ docs       │ Idle    │ Local     │ 1 hour ago          │
└────────────┴─────────┴───────────┴──────────────────────┘
```

## Configuration Example

```bash
# config.sh (v2.1+)

# Define remote hosts
export REMOTE_HOSTS=(
    "build-server-1:builder@10.0.1.50:22:/home/builder/projects"
    "build-server-2:builder@10.0.1.51:22:/home/builder/projects"
    "gpu-server:ml@gpu.example.com:2222:/mnt/projects"
)

# Worker definitions with remotes
export WORKER_DEFINITIONS=(
    # Local workers
    "architect|feat/v2.0-design|arch_TASKS.txt|Architecture|local"
    "docs|feat/v2.0-docs|docs_TASKS.txt|Documentation|local"

    # Remote workers
    "backend|feat/v2.0-api|api_TASKS.txt|Backend API|remote:build-server-1"
    "frontend|feat/v2.0-ui|ui_TASKS.txt|Frontend UI|remote:build-server-2"
    "ml|feat/v2.0-models|ml_TASKS.txt|ML Training|remote:gpu-server"

    # Auto-assign (Czar chooses based on load)
    "qa|feat/v2.0-testing|qa_TASKS.txt|Testing|auto"
)
```

## Challenges & Solutions

### Challenge 1: Network Latency
**Problem**: SSH operations slow down orchestration
**Solution**:
- Async operations
- Connection pooling
- Local caching of remote status

### Challenge 2: SSH Key Management
**Problem**: Multiple SSH keys for different hosts
**Solution**:
- Use SSH config file
- SSH agent forwarding
- Per-host key specification

### Challenge 3: Firewall/NAT
**Problem**: Can't SSH to some workers (behind firewall)
**Solution**:
- Reverse SSH tunnels
- VPN/Tailscale integration
- Hybrid mode (some local, some remote)

### Challenge 4: Filesystem Sync
**Problem**: Local and remote filesystems diverge
**Solution**:
- Git as source of truth (all workers clone)
- No shared filesystems needed
- Each worker operates on git repo

### Challenge 5: Cost Tracking
**Problem**: Expensive remote compute costs money
**Solution**:
- Track worker uptime
- Auto-shutdown idle workers
- Cost reporting in dashboard

## Advanced Features

### Auto-Scaling
```bash
# Start with 3 workers, auto-add more if needed
MIN_WORKERS=3
MAX_WORKERS=12
AUTO_SCALE=true

# Czar spawns additional workers on idle capacity
```

### Spot Instance Integration
```bash
# Use AWS spot instances for workers
WORKER_CLOUD_CONFIG=(
    "backend|aws-spot:t3.large:us-east-1"
    "frontend|aws-spot:t3.large:us-west-2"
)

# Czar launches instances, deploys workers, terminates when done
```

### Kubernetes Integration
```bash
# Deploy workers as K8s pods
WORKER_K8S_CONFIG=(
    "backend|k8s:build-worker:backend-pod"
    "frontend|k8s:build-worker:frontend-pod"
)
```

## Migration Path

### Phase 1: SSH Support (v2.1)
- Remote tmux sessions
- Remote git operations
- Remote status monitoring
- Manual remote configuration

### Phase 2: Cloud Integration (v2.2)
- AWS/GCP/Azure instance launching
- Spot instance support
- Auto-scaling
- Cost tracking

### Phase 3: Container Orchestration (v2.3)
- Kubernetes pod workers
- Docker Swarm workers
- Auto-deployment pipelines

## Testing Strategy

### Unit Tests
- Mock SSH operations
- Test remote command generation
- Test status parsing

### Integration Tests
- Test with actual SSH to localhost
- Test with Docker containers as "remotes"
- Test failure scenarios (network drop, host down)

### Load Tests
- 12 workers across 6 different hosts
- Measure latency impact
- Optimize connection pooling

## Documentation Needed

- SSH setup guide
- Remote host requirements
- Security best practices
- Troubleshooting remote workers
- Cost optimization guide

## User Stories

### Story 1: Heavy Build Distribution
> As a developer building a monorepo, I want to distribute builds across multiple powerful machines so compilation completes faster.

### Story 2: GPU Acceleration
> As an ML engineer, I want my ML training worker on a GPU server while other workers run locally so I optimize cost and performance.

### Story 3: CI/CD Integration
> As a DevOps engineer, I want workers to run on our CI/CD infrastructure so builds use existing resources.

### Story 4: Global Testing
> As a QA lead, I want test workers distributed globally so we validate multi-region deployments.

## Bottom Line

**Distributed workers** transform Czarina from a **local orchestrator** to a **distributed build system**.

**Value**:
- ⭐⭐⭐⭐⭐ Build optimization
- ⭐⭐⭐⭐⭐ GPU/specialized hardware
- ⭐⭐⭐⭐⭐ Cost optimization
- ⭐⭐⭐⭐ Global distribution
- ⭐⭐⭐⭐ Auto-scaling

**Complexity**: High (SSH, networking, security, cost tracking)
**Timeline**: 2-3 weeks development
**Priority**: High (after v2.0 stabilizes)

This could be **the** killer feature that makes Czarina enterprise-ready! 🚀

---

*Great idea! Let's add it to the roadmap.* 🎭
