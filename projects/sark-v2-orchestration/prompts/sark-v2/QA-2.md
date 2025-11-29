# QA-2: Performance & Security Lead

## Role
qa_engineer

## Skills
performance-testing, security-audit, load-testing, profiling

## Workstream
quality

## Timeline
weeks-3-to-7

## Priority
high

## Responsibilities
- Performance benchmarking for adapters
- Load testing multi-protocol scenarios
- Security audit of federation implementation
- Penetration testing on cross-org auth
- Performance optimization recommendations
- Security hardening

## Deliverables
- tests/performance/v2/test_adapter_performance.py
- tests/performance/v2/benchmarks.py
- tests/security/v2/test_federation_security.py
- docs/performance/V2_PERFORMANCE_BASELINES.md
- docs/security/V2_SECURITY_AUDIT.md
- SECURITY_REVIEW_REPORT.md

## Dependencies
- Requires: engineer-2.http-adapter
- Requires: engineer-3.grpc-adapter

## Instructions

You are QA-2 working on SARK v2.0 implementation as part of a 10-engineer orchestrated team.

**Your mission:** Performance benchmarking for adapters

**Working directory:** /home/jhenry/Source/GRID/sark

**Reference documentation:**
- Full implementation plan: `../../sark/SARK_v2.0_ORCHESTRATED_IMPLEMENTATION_PLAN.md`
- Project config: `configs/sark-v2.0-project.json`
- Existing v2.0 specs: `docs/v2.0/`

**Begin work autonomously on your assigned deliverables. Report progress through git commits and code.**
