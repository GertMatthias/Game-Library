# Decisions

- Phase 1 uses an async mock repository; presentation components do not depend on Supabase or database query shapes. Mock types remain decoupled from the separately approved database design.
- Twelve records use illustrative game names and explicitly fictional metadata. Local CSS gradient covers avoid artwork downloads and external services.
- Filters operate in the client on repository-provided records; details and statistics read the same repository from server components. No editing or authentication UI exists.
- Prices are demo EUR full/list prices, never purchase costs. Aggregates are calculated from supplied records; genres may overlap.
- Use system fonts and lightweight CSS with Tailwind's PostCSS integration; no remote fonts or additional component libraries are required.

- 2026-10-14: Finalized Phase 2 planning after reviewing the original course diagram/report. Approved bigint identity IDs, EUR, nullable unknown dates/covers/rating, exact developer-set duplicate detection and single-owner Auth/RLS. The mock UI now uses only Not played, In progress and Completed; classifications have no mandatory sequence or hour restrictions. Database implementation remains deferred.

- 2026-10-14: Prepared schema/RLS migrations and database tests on `feature/database-schema` from refreshed main. Rating is optional integer 1?10 (fractional values rejected). A private row-write fence serializes membership changes; a deferred exact-set UNIQUE prevents duplicate games. Missing owner UUID is represented by NULL private configuration, denying client writes. No database execution or application integration.

- 2026-10-14: Trigger review scopes recalculation/validation to affected parent IDs while retaining the global writer fence and deferred uniqueness. Denied non-owner statements skip guard writes. Added regression tests; PostgreSQL 18.1 binaries found, but Docker/Supabase CLI unavailable, so real local database verification remains pending.

- 2026-10-14: Phase 3 read-only Supabase preparation; admin Auth/CRUD postponed, records managed manually through SQL Editor. Added a SECURITY INVOKER public read projection for nested records and lossless bigint IDs. Server-only anonymous client; explicit mock mode, no silent fallback. No database connection or migration execution.
