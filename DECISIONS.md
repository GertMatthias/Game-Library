# Decisions

- Phase 1 uses an async mock repository; presentation components do not depend on Supabase or database query shapes. UI fields remain provisional until the ER model review.
- Twelve records use illustrative game names and explicitly fictional metadata. Local CSS gradient covers avoid artwork downloads and external services.
- Filters operate in the client on repository-provided records; details and statistics read the same repository from server components. No editing or authentication UI exists.
- Prices are demo USD full/list prices, never purchase costs. Aggregates are calculated from supplied records; genres may overlap.
- Use system fonts and lightweight CSS with Tailwind's PostCSS integration; no remote fonts or additional component libraries are required.
