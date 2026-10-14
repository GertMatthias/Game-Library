# Database trigger review and local test status

2026-10-14, branch `feature/database-schema`. Hosted Supabase, Auth users/settings, frontend and Git commits/merges were not changed. The existing migrations are still unexecuted, so fixes are incorporated in the original review migration rather than an applied-schema upgrade.

## Findings and fixes

1. **Non-owner zero-row statements caused internal writes.** The old BEFORE STATEMENT trigger advanced the guard even when RLS excluded every row; the old AFTER STATEMENT refresh could scan all games. This follows PostgreSQL's documented behavior: [statement triggers run even for zero rows](https://www.postgresql.org/docs/current/trigger-definition.html). The fence now checks the original SET ROLE identity and configured Auth UUID before writing. It returns without touching/locking the guard for denied `anon`/`authenticated` callers. SECURITY DEFINER changes `current_user`, so that is not used to identify the caller. The separate RLS policies remain authoritative and unchanged. Failed authorized transactions roll back guard writes; they can still generate transient work/WAL. Authorized zero-row statements intentionally retain the fence to serialize before row selection.
2. **Collection-wide refresh/validation was unnecessary.** The refresh is now AFTER ROW and handles distinct OLD/NEW game IDs only. Deferred validation captures affected games and developers from each queued row event and examines their final state using indexed IDs/FKs. It skips deleted parents. Link reassignment checks both sides; cascaded game-link deletes still queue checks on surviving developers. Direct game-key tampering remains validated for the affected game.
3. **Immediate constraint ordering needs explicit handling.** The refresh trigger is named `game_developers_00_refresh` so it runs before the membership constraint trigger when constraints are immediate. This avoids validating a stale canonical key on an otherwise valid link edit. [PostgreSQL trigger ordering](https://www.postgresql.org/docs/current/sql-createtrigger.html) is alphabetical among triggers for the same event.

The simple global row-write fence is retained. Only calculations are scoped; concurrency protection has not been replaced with a weaker precheck. The deferred UNIQUE on normalized title plus exact sorted developer set remains unchanged. A single-owner collection does not need dirty-ID queues, transition-table machinery or per-parent lock orchestration. Very large bulk writes can recheck the same affected parent more than once; this is an accepted tradeoff pending real measurements.

## Prepared regression coverage

The pgTAP suite now additionally checks:

- Private guard revision is unchanged across denied inserts and anonymous/non-owner UPDATE/DELETE tests for all public tables.
- Cascades remove achievements and both link types, with explicit orphan-developer cleanup in the same transaction.
- Moving a developer link recalculates both OLD/NEW game sets and works with constraints set IMMEDIATE.

Existing tests cover public reads, owner/non-owner grants/RLS, missing-owner denial, key tampering, exact-set duplicates, rating/status/date rules and atomic owner writes. The Python suite prepares three two-session races: matching duplicate inserts, final game-developer removal and final developer-game removal.

These tests are **prepared, not executed**. In particular, the guard revision assertions are not yet empirical confirmation of deployed RLS behavior. No benchmark was run; the performance conclusion is based on removing full-table queries from the trigger bodies.

## Checks actually executed

- `psql --version`: PostgreSQL 18.1, installed at `C:/Program Files/PostgreSQL/18/bin/psql.exe`; `pg_ctl.exe` also exists. These binaries are not currently on PATH.
- Tool discovery: no Docker or Supabase CLI on PATH or in the checked standard installation locations.
- Static PostgreSQL parser: both migration files and the updated pgTAP SQL parse successfully.
- Static PL/pgSQL parser: all four trigger-function definitions parse successfully.
- `git diff --check`: passed. Existing frontend files were not edited.

No database connection was opened. No migrations, pgTAP tests, Python race tests, Auth fixtures/settings, local services, dump/restore tests or stronger-isolation tests were run. Static parsing cannot prove runtime permissions, trigger semantics or race behavior.

## Required next steps and readiness

**Not ready for hosted deployment yet.** Install/enable Docker Desktop and Supabase CLI after owner approval; no large dependencies were installed for this task. Put the existing PostgreSQL bin directory on the test shell PATH. Use the disposable local Supabase instructions in `supabase/README.md`, then run the complete pgTAP and Python suites, including the added regressions.

The pgTAP suite creates synthetic Auth identities inside its rolled-back local transaction. The current instruction forbids modifying Auth users/settings, so that fixture provisioning must also be explicitly permitted for the disposable local test environment before running it. It must never target existing or hosted Auth users.

Remaining gates: real execution of both migrations, all restricted-role tests and concurrency races; stronger-isolation and dump/restore verification; approved owner UUID configuration; signup prevention and direct API checks in a separately approved environment. No claim of hosted security or correctness is made before those checks pass.
