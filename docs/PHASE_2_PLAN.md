# Phase 2: finalized database plan

Updated 2026-10-14. Owner model decisions are approved. Migration implementation and database execution remain separate steps. The application still uses mock data; review-only SQL files and prepared tests now accompany the plan; no database execution, Supabase connection, auth UI or CRUD has occurred.

## Original model review

Reviewed the actual [diagram](Eljas_Gert_Matthias_1etapp_er_mudel.png) visually and [report](Eljas_Gert_Matthias_1etapp_aruanne.pdf) by local PDF text extraction. The requested aliases ER_model.png/ER_report.pdf do not exist; originals are preserved.

The report confirms the supplied entities/attributes, multivalued genre, one main platform, regular/list prices, M:N developers, a minimum of one developer per game, games without achievements, exactly one parent game per achievement, unique developer names and achievement names within each game. It additionally says developers are only recorded when at least one of their games is in the collection: preserve reciprocal minimum participation.

The diagram's achievement relationship endpoint symbols appear reversed relative to the report's explicit prose. Follow the report and owner's confirmed one-game/many-achievements rule. The owner has clarified the report's duplicate wording as exact unordered developer-set uniqueness.

## Approved decisions and academic differences

- Games, developers and achievements: auto-generated PostgreSQL bigint identity primary keys. Auth user IDs remain UUIDs.
- Prices: EUR numeric(10,2), regular/full price, never purchase cost.
- NULL allowed for release_date, last_played, unlock_date, founded_year and cover_url. Release-date/founding-year nullability extends the diagram.
- Game extensions: cover_url, status, nullable rating. These are application fields, not original ER attributes.
- Exactly Not played, In progress, Completed. These are freely assignable classifications, not sequential steps. No status-dependent hour/date/achievement constraints.
- Collection, playtime, statistics and achievements publicly readable; only the verified owner writes. No public registration.
- Normalize multivalued genre and M:N developers into relational tables. Internal derived integrity keys are implementation metadata.

The report says actually unplayed records have zero hours and no last-played date. Keep that initial-data convention, but do not couple the independently assignable status to recorded hours. Rating is now approved as optional integer values 1?10. NULL means unrated. The schema uses an unscaled numeric CHECK to reject fractional input instead of rounding through an integer cast.

## Proposed PostgreSQL tables

All fields required unless marked nullable. Entity keys: bigint GENERATED ALWAYS AS IDENTITY; IDs immutable. Use the same identity convention for genres as a simple implementation choice. No multi-user ownership column.

| Table | Fields and constraints |
| --- | --- |
| games | game_id bigint PK; nonblank title text; nullable release_date date; finite nonnegative full_price numeric(10,2) EUR; nonblank platform text; finite nonnegative playtime_hours numeric(10,2) default 0; nullable last_played date; nullable cover_url text; status text default Not played with CHECK allowing exactly the three labels; nullable rating numeric, CHECK integer value between 1 and 10; internal title_key text and developer_set_key bigint[] |
| developers | developer_id bigint identity PK; nonblank unique name text; nullable founded_year smallint (positive four-digit year when known); nonblank country text |
| game_developers | Required game_id/developer_id bigint FKs; composite PK (game_id, developer_id) |
| genres | genre_id bigint identity PK; nonblank unique name text |
| game_genres | Required game_id/genre_id bigint FKs; composite PK (game_id, genre_id) |
| achievements | achievement_id bigint identity PK; required game_id bigint FK; nonblank name text; description text; unlocked boolean default false; nullable unlock_date date; unique (game_id, normalized name) |

Recommend trimmed/lowercase comparisons for title/name keys, preserving display spelling and punctuation/accents. This normalization is an implementation recommendation for migration review. Use a generated normalized title column for deferrable UNIQUE; name uniqueness may use expression indexes. Reject blanks and nonfinite/negative numeric values explicitly, including NaN. Locked achievements require NULL unlock_date; unlocked achievements may have unknown dates. Rating must be NULL or an integer value from 1 to 10. Future-date validation belongs at the write boundary, not in time-dependent CHECKs.

Game deletion cascades achievements and junction rows. Referenced developers/genres require explicit unlinking before deletion. Genre minimum is unspecified: allow zero rows. Platform remains one text attribute. Add reverse junction FK indexes; the achievement uniqueness index begins with game_id. No separate statistics, platform, user-library or play-session tables.

## Exact developer-set uniqueness and concurrency

Same title with A+B versus B+A: reject. A+B versus A+C: allow. A versus A+B: allow. Platform is not part of uniqueness: same title/set on another platform is still a duplicate.

1. Junction rows are authoritative. Database triggers maintain a sorted, distinct bigint array developer_set_key, never a collision-prone hash. Normalize title into title_key.
2. A DEFERRABLE INITIALLY DEFERRED UNIQUE constraint on (title_key, developer_set_key) arbitrates duplicates across different game rows, including concurrent inserts/title changes/membership changes. A frontend lookup or trigger-only SELECT does not prevent races.
3. Lock affected game rows before any membership edit and recompute the key after edits. Handle old and new game IDs on reassignment. Use stable ascending lock order across multi-game operations; parent-row locks serialize simultaneous edits to one set.
4. Deferred constraint triggers validate final transaction state: every surviving game has at least one developer and its stored key exactly equals its junction set. Queue validation on insertion and every relevant game/link update/delete; read final rows instead of stale OLD/NEW values. Skip parents deleted in the transaction. Internal keys cannot be forged through direct API updates: combine narrow column privileges/trigger-controlled maintenance and final validation. Prevent recursive trigger updates.
5. Preserve reciprocal developer participation from the report: every surviving developer must have a game. Lock affected developer rows before link mutations too, using a consistent global order. Deferred validation covers developer insertion and link deletion/reassignment, including game cascades. Deleting a final associated game requires deleting its now-unused developer in the same transaction; otherwise fail. Do not silently remove reusable developer records.
6. Atomic create/reassignment/delete-cleanup requires one transaction, later provided through a narrowly authorized security-invoker RPC. Separate REST requests cannot insert a parent and mandatory links safely. All direct authorized mutation paths must also invoke database integrity checks.

Locks must precede membership reads; use fresh reads under READ COMMITTED and abort/retry serialization failures under stronger isolation. Unique indexes coordinate concurrent duplicate writes to different game IDs. Stable lock ordering reduces deadlocks; bounded retries may handle them without accepting an invalid state. Verify two-transaction behavior, cascades, bulk edits, title changes, tampering and dump/restore against the target PostgreSQL version. This is the enforcement design, not an implemented/tested guarantee.

[PostgreSQL constraint triggers](https://www.postgresql.org/docs/current/sql-createtrigger.html) permit end-of-transaction validation. [Cross-table CHECKs](https://www.postgresql.org/docs/current/ddl-constraints.html) cannot express membership invariants.

## Application architecture and alignment

Reviewed models, cloned async mock repository, pure filter/statistics helpers, library/cards and detail/statistics routes. Keep GameRepository.listGames()/getGameById() as the replacement boundary and keep Supabase row types separate from domain objects.

The current frontend now uses exactly the three approved labels in mock records, filters, summary counts, charts and badges. Safe hyphenated CSS classes preserve styling. No transition restrictions or admin controls. EUR formatting and demo labels replace USD; fictional amounts are not currency conversions. Nullable releaseDate displays Unknown and sorts last. The twelve mock slug IDs preserve existing demo links.

Later adapter work:

- Named Developer/Achievement interfaces with IDs and nullable foundedYear; map achievement name to existing display title, unlock_date to unlockedDate, release_date/last_played to nullable date-only strings.
- Map database bigint IDs to decimal strings in domain objects/URLs. Never use unchecked JS numbers or JSON-unsafe JS bigint. Configure lossless transport or cast IDs to text in a security-invoker query/RPC; converting an already rounded JSON number to string cannot recover precision. Test beyond Number.MAX_SAFE_INTEGER. Generated database types alone do not solve transport precision.
- Add nullable coverUrl/rating alongside local visual fallback when implementing the live adapter. Subtitle is optional presentation content, not another unapproved database field. Later show a local fallback image when real cover URLs are missing/fail; preserve gradients now. Approve image origins and licensing before image fetching. No external game APIs or upload/storage service now.
- Map bounded nested relations without N+1 queries; validate finite decimals/nulls/dates. Missing game is null; query failures reach error UI, never silently substitute demo data. Missing last_played should display Unknown rather than imply zero playtime.
- Keep client filters and derived statistics on the same complete public list; account for API row limits. Keep mock adapter for tests.
- Live integration must remove dynamicParams=false/build-only ID restrictions. New IDs must work without rebuilding. Prefer request-time reads initially; any later caching must invalidate library/detail/metadata/stats coherently after writes.

## Owner Auth and RLS strategy

Provision one owner account out of band after approval; disable signup and anonymous sign-in/unneeded providers. No public registration page. Authorize by verified owner Auth UUID, not email, user metadata or hidden buttons. Fix the approved UUID in policies, with matching server configuration; owner replacement requires an explicit policy update. No public role-management tables.

Enable RLS and explicit grants on all six tables, including junctions:

| Caller | SELECT | INSERT / UPDATE / DELETE |
| --- | --- | --- |
| Anonymous | Public collection | Denied; no write grants |
| Authenticated non-owner | Public collection | Denied by RLS |
| Verified owner UUID | Allowed | Owner-specific policies |

INSERT uses WITH CHECK; UPDATE uses USING and WITH CHECK; DELETE uses USING. auth.uid() must equal the configured owner UUID; NULL/other user fails. No permissive write policy, DDL/TRUNCATE/policy-changing rights or private Auth/contact/token fields in public output. Grant only necessary identity-sequence privileges if the chosen path requires them, never sequence reset rights.

Publishable key for public reads and verified owner session for writes. Service-role credentials are not ordinary application write credentials because they bypass RLS. Later server operations validate verified claims/user, compare owner UUID, validate all write inputs and protect cross-origin writes; RLS also denies direct API requests that bypass the server/UI. [Supabase RLS documentation](https://supabase.com/docs/guides/database/postgres/row-level-security) explains policy/grant enforcement and service-key bypass.

Atomic functions use security invoker with narrow EXECUTE grants. Revoke unwanted PUBLIC/anon function execution. Any elevated internal trigger helper has fixed search path, qualified objects, narrow purpose and no general callable write/RPC surface; explicitly review privileges. Views must preserve caller RLS. No admin UI until verified auth and direct-access denial tests pass.

## Implementation checklist and gates

- [x] Rating scale finalized: optional integer 1?10.
- [x] Review-only schema/RLS migrations and database tests prepared under `supabase/`.
- [ ] The `feature/database-schema` branch drafts migrations, constraints/triggers, grants/RLS and tests as reviewable files. Do not seed real records from fictional mock data.
- [ ] Review exact files, owner UUID provisioning and data-preservation/rollback approach.
- [ ] Obtain approval for a disposable local database; run integrity/RLS/concurrency tests against the target PostgreSQL version.
- [ ] Obtain separate explicit approval before applying migrations to hosted Supabase or changing Auth settings.
- [ ] Phase 3 feature/supabase-reads: only needed client/SSR dependencies, domain adapter, bigint transport, runtime detail IDs and coherent freshness.
- [ ] Phase 3 feature/owner-auth: verified sessions and owner checks; disable signup in Auth configuration.
- [ ] Phase 3 feature/admin-crud: validated atomic writes, recovery/revalidation and full denial tests. Deployment remains separately approved.

## Required database verification

- SELECT and each write/RPC for anonymous, authenticated non-owner and owner on every table. Assert row changes too: denied UPDATE/DELETE can return zero rows rather than errors. Test expired/missing sessions, forged metadata, direct API access and disabled signup; do not test only as superuser.
- Atomic create/replacement/delete cleanup; rejection of games without developers, developers without games, orphan achievements and duplicate links; accept games with no achievements.
- Exact-set duplicates/reordered sets/title edits/link edits/tampered keys/concurrent duplicate creation rejected; different combinations allowed. Two concurrent unlink operations cannot leave either parent without required participation.
- Unique developer/per-game achievement names; same achievement names across games allowed. Reject negatives/NaN and locked dates; accept unknown dates/founding years and unlocked-unknown dates.
- Free reassignment of all three statuses with unchanged hours/dates/achievements. Exact counts, filters, styling and completion stats.
- Bigint IDs beyond JS precision, EUR/null/date mappings, missing covers/IDs, query failure and complete statistics. Newly created IDs work without build.
- Lint, typecheck, unit/adapter tests and production build after code changes.

## Readiness

Phase 2 schema/RLS migrations, pgTAP tests and a two-session concurrency suite are now prepared for review. No database tests or migrations have been executed; separate local/hosted execution approval remains required. The current application continues to use typed mock data.

## Schema implementation refinement

The review package is in `supabase/README.md`. For this small single-owner collection, statement triggers use one private row-write fence before all membership-graph mutations instead of per-game/developer locking. This serializes concurrent graph writers and prevents stale-snapshot membership checks; the deferred exact-set UNIQUE still arbitrates duplicate game identities. This is a deliberate simpler implementation of the plan's concurrency requirement. Database behavior remains unexecuted and must pass the prepared local tests before application.

The designated owner UUID has not been supplied. A private singleton configuration starts NULL; RLS denies all client writes until a trusted administrator configures a verified existing Auth UUID. This refines the original fixed-policy UUID approach without permitting client role management. Signup prevention requires Supabase Auth configuration in addition to SQL; no remote settings were changed.

## Trigger review refinement

The unexecuted first schema migration now refreshes only affected OLD/NEW game IDs and validates only affected games/developers, including moved and cascaded links. Global writer serialization and exact-set UNIQUE remain intact. Statement fences skip denied anonymous/authenticated non-owner calls; RLS remains the authorization mechanism. Prepared regression tests check the guard revision, cascades, OLD/NEW sets and immediate constraint mode. See `docs/DATABASE_REVIEW.md`; real local Supabase testing is still blocked by missing Docker/CLI.
