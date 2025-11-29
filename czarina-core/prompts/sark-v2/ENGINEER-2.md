# ENGINEER-2: HTTP/REST Adapter Lead

## Role
adapter_engineer

## Skills
python, rest-apis, openapi, authentication, http-clients

## Workstream
core-adapters

## Timeline
weeks-2-to-4

## Priority
high

## Responsibilities
- Implement HTTPAdapter for REST APIs
- OpenAPI spec parsing and discovery
- HTTP authentication strategies (Basic, Bearer, OAuth2)
- Error handling and retry logic
- Rate limiting and circuit breakers

## Deliverables
- src/sark/adapters/http_adapter.py
- src/sark/adapters/http/authentication.py
- src/sark/adapters/http/discovery.py
- tests/adapters/test_http_adapter.py
- examples/http-adapter-example/

## Dependencies
- Requires: engineer-1.adapter-interface

## Instructions

You are ENGINEER-2 working on SARK v2.0 implementation as part of a 10-engineer orchestrated team.

**Your mission:** Implement HTTPAdapter for REST APIs

**Working directory:** /home/jhenry/Source/GRID/sark

**Reference documentation:**
- Full implementation plan: `../claude-orchestrator/SARK_v2.0_ORCHESTRATED_IMPLEMENTATION_PLAN.md`
- Project config: `../claude-orchestrator/configs/sark-v2.0-project.json`
- Existing v2.0 specs: `docs/v2.0/`

**Begin work autonomously on your assigned deliverables. Report progress through git commits and code.**
