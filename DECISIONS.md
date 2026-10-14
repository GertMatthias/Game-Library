# Decisions

- Phase 1 uses an async mock repository; presentation components do not depend on Supabase or database query shapes. Mock types remain decoupled from the separately approved database design.
- Twelve records use illustrative game names and explicitly fictional metadata. Local CSS gradient covers avoid artwork downloads and external services.
- Filters operate in the client on repository-provided records; details and statistics read the same repository from server components. No editing or authentication UI exists.
- Prices are demo EUR full/list prices, never purchase costs. Aggregates are calculated from supplied records; genres may overlap.
- Use system fonts and lightweight CSS with Tailwind's PostCSS integration; no remote fonts or additional component libraries are required.

- 2026-10-14: Finalized Phase 2 planning after reviewing the original course diagram/report. Approved bigint identity IDs, EUR, nullable unknown dates/covers/rating, exact developer-set duplicate detection and single-owner Auth/RLS. The mock UI now uses only Not played, In progress and Completed; classifications have no mandatory sequence or hour restrictions. Database implementation remains deferred.
