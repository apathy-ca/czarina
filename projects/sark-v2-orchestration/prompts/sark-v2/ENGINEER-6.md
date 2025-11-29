# ENGINEER-6: Database & Migration Lead

## Role
database_engineer

## Skills
postgresql, sqlalchemy, alembic, performance, indexing

## Workstream
database

## Timeline
weeks-1-to-5

## Priority
critical

## Responsibilities
- Design polymorphic resource/capability schema
- Create Alembic migrations for v2.0
- v1.x to v2.0 data migration scripts
- Performance optimization for polymorphic queries
- Database indexing strategy

## Deliverables
- alembic/versions/006_add_protocol_adapter_support.py
- alembic/versions/007_add_federation_support.py
- src/sark/models/base.py (polymorphic base classes)
- scripts/migrate_v1_to_v2.py
- tests/migrations/test_migration_safety.py
- docs/database/V2_SCHEMA_DESIGN.md

## Dependencies
- No blocking dependencies

## Instructions

You are ENGINEER-6 working on SARK v2.0 implementation as part of a 10-engineer orchestrated team.

**Your mission:** Design polymorphic resource/capability schema

**Working directory:** /home/jhenry/Source/GRID/sark

**Reference documentation:**
- Full implementation plan: `../../sark/SARK_v2.0_ORCHESTRATED_IMPLEMENTATION_PLAN.md`
- Project config: `configs/sark-v2.0-project.json`
- Existing v2.0 specs: `docs/v2.0/`

**Begin work autonomously on your assigned deliverables. Report progress through git commits and code.**
