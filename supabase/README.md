> For the current SQL-Editor-only workflow, use [manual setup instructions](../docs/SUPABASE_SETUP.md). No CLI, owner Auth account or Docker is required for that workflow. Older local-testing/owner-configuration instructions below are optional future work, not performed by this integration.

# GameVault database review package

**Migrations and database tests are prepared, not applied.** The frontend now has an explicit read-only Supabase mode and an explicit offline mock mode. No auth UI, CRUD endpoint or transactional write RPC is included. Never run tests against production.

## Files

| File | Purpose |
| --- | --- |
| `migrations/20261014000100_gamevault_schema.sql` | Six public tables, private fail-closed administrator configuration, indexes, identity guards, exact-set refresh and deferred membership checks |
| `migrations/20261014000200_gamevault_rls.sql` | Explicit public reads and UUID-specific owner write policies/grants |
| `migrations/20261014000300_gamevault_public_reads.sql` | Caller-RLS read projection with lossless string IDs and nested relationships |
| `examples/add_first_game.sql` | Manual transactional example; not automatic seed data |
| `tests/database/gamevault.test.sql` | Rollback-only pgTAP constraints, grants and restricted-role RLS tests |
| `tests/concurrency.py` | Local-only two-session races for duplicates and game/developer minimum participation |

## Integrity and security design

Prices are EUR `numeric(10,2)`. Rating is nullable, integer-valued **1–10**. Its unscaled numeric CHECK rejects fractional input rather than rounding it through an integer cast. IDs are generated bigint identities. Release/last-played/unlock dates and founding years can be unknown. Locked achievements cannot have dates. The three exact status labels have no transition/hour restrictions.

Normalized title plus a sorted exact bigint developer array is UNIQUE DEFERRABLE INITIALLY DEFERRED. Junction rows are authoritative. Row refreshes recalculate only OLD/NEW game IDs; deferred triggers inspect only affected game/developer IDs. They ensure each game has developers and every developer is represented by a game, including after deletes and bulk moves. Delete unused developers in the same transaction as deleting their final game. Games can have no achievements; achievement names are normalized-unique within a game. Game deletes cascade related rows; referenced developers/genres are restricted.

**Concurrency refinement to the plan:** statement triggers acquire one private row-write fence before authorized games/developers/developer-link mutations. Authenticated non-owners and anonymous callers skip the fence without acquiring its lock or advancing its revision; RLS still denies their writes. Zero visible rows cause no row refresh/validation. Owner or trusted zero-row statements still take the fence: deciding row visibility before serialization could weaken concurrency safety. This deliberately serializes this small single-owner collection instead of a more complex per-parent lock hierarchy. READ COMMITTED refreshes use fresh snapshots; overlapping REPEATABLE READ/SERIALIZABLE writes fail with serialization errors. Deferred UNIQUE additionally prevents matching sets across distinct games. Reads do not acquire the fence. Transactions must retry deadlock/serialization failures (`40P01`/`40001`) and treat `23505`/`23514` as validation failures. This implementation has not been database-tested yet.

The six public tables have RLS. Anonymous and authenticated visitors read the collection; only the verified configured Auth UUID can write. Internal keys/entity IDs are excluded from client column write grants. Private tables and trigger helpers are inaccessible to clients; the only executable helper returns whether the current identity is the configured owner. SECURITY DEFINER helpers have an empty search path, qualified references and no general RPC access. Keep `gamevault_private` out of Supabase's exposed schemas. Schema USAGE for the policy helper does not grant access to private tables/functions.

## Before any application

1. Review the SQL and target PostgreSQL version. Use a trusted migration role (normally Supabase's `postgres`), which owns these tables/functions; do not change definer ownership to `anon`/`authenticated`. Check existing public objects for name conflicts; migrations intentionally fail rather than silently modify unrelated tables.
2. Confirm Auth owner provisioning, recovery, public data visibility, normalized-name comparisons and cover origins. No service-role secret is required in application code.
3. Obtain approval for the target. Database execution, owner configuration, Auth settings and deployment are separate from reviewing these files.

## Disposable local verification (after approval)

Requires Docker, Supabase CLI, Python 3 and `psql`. These tools are not added as application dependencies. No local services are started by this repository.

```sh
supabase init
supabase start
supabase migration up --local
supabase test db
```

`supabase init` creates local configuration; review it before keeping it. Ensure pgTAP is available in the local `extensions` schema (standard local Supabase supports it). The test transaction switches to actual `anon`/`authenticated` roles and rolls back fixtures/owner configuration. Test UUIDs are disposable identities, not the administrator configuration.

For concurrency tests in PowerShell, set nonsecret connection options and supply the **local-only** password in your shell environment without committing it:

```powershell
$env:PGHOST = '127.0.0.1'
$env:PGPORT = '54322'
$env:PGDATABASE = 'postgres'
$env:PGUSER = 'postgres'
# Set PGPASSWORD privately to your disposable local database password.
python supabase/tests/concurrency.py
```

The script refuses non-loopback PGHOST, uses two simultaneous connections, waits until the second writer is blocked before committing the first, and cleans its tagged fixtures. It makes committed local fixture writes; pgTAP instead rolls back everything. Run only on a disposable local database. Also review dump/restore and stronger-isolation behavior before hosted application; these are not covered by the default race suite.

## Hosted application (instructions only; do not run yet)

After local tests pass and the owner explicitly approves the exact migrations and target:

```sh
supabase login
supabase link --project-ref YOUR_APPROVED_PROJECT_REF
supabase db push --dry-run
# Review the pending migration list and obtain final execution approval.
supabase db push
```

Use secure CLI credential prompts/environment; never paste database passwords or service-role keys into tracked files. `db push` applies only the versioned migration files. Do not run database tests against the hosted collection. No automatic rollback is supplied: review backups and forward fixes before applying; dropping tables would lose data.

### Required owner configuration — no invented UUID

After approval, create the single owner in Supabase Auth using trusted administrative tooling. Disable **Allow new users to sign up**, anonymous sign-in, and unnecessary providers in Auth settings. SQL table policies cannot disable Supabase Auth signup by themselves; verify direct signup requests are denied. There is no public registration UI now.

Copy the actual verified Auth user UUID. The migration deliberately leaves it NULL, so **all client writes are denied** until configured. In a trusted SQL session, replace the placeholder below with the verified existing Auth UUID (a UUID is an identity, not a password):

```sql
UPDATE gamevault_private.administrator
SET user_id = 'REPLACE_WITH_VERIFIED_OWNER_AUTH_UUID'::uuid
WHERE singleton = true;
```

The placeholder is intentionally invalid; do not execute it unchanged. The FK requires an existing Auth user. Only trusted database administrators can update this configuration; clients cannot self-promote. Setting it to NULL disables writes again. A single row/check prevents multiple owners. Keep Auth emails/tokens/secrets out of public data and repository files.

Before Phase 3, verify anonymous SELECT and denied writes, non-owner denial, owner writes, and signup denial using the deployed API. Do not use a service-role request as proof that owner RLS works: service roles bypass RLS. Multi-table owner creation/deletion later needs a transaction/RPC; separate REST requests fail deferred minimum checks. No such CRUD RPC is implemented in this schema-only phase.

## Verification performed for this review

Executed: PostgreSQL parser syntax checks for both migrations and the pgTAP file; static PL/pgSQL parsing of all four trigger functions; Python syntax compilation of the concurrency script; frontend lint, TypeScript, six unit tests and production build. The application/data source is unchanged.

Not executed: migrations, pgTAP database tests, two-session races, Auth configuration/signup checks, live REST/RPC security verification, stronger-isolation/dump-restore tests. On this review, PostgreSQL 18.1 tools were found at `C:/Program Files/PostgreSQL/18/bin` (not on PATH). Docker and Supabase CLI are missing, so no disposable local Supabase instance or real database tests were run. Syntax parsing does not verify schema execution, RLS correctness or concurrency guarantees.

See [the trigger and local-testing review](../docs/DATABASE_REVIEW.md) for current findings, checks and outstanding deployment gates.
