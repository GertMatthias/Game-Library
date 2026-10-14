# First Codex instruction – paste this into Codex in the GameVault folder

Please read `AGENTS.md` and `PROJECT_SPEC.md` in the repository root. These define the project and the exact allowed scope.

Implement **PHASE 1 ONLY** from `PROJECT_SPEC.md`: initialize a new Next.js App Router + TypeScript + Tailwind project in this folder if necessary, create a polished dark-themed GameVault public game library UI, a game detail page and a statistics page, and use typed mock data behind a replaceable data-access/repository layer. Implement working search, filters and sorting, and derive statistics from the same mock data. Use cover-art gradient placeholders and clear demo data. Keep responsive layout and loading/empty/error states sensible.

Important: Do not create or connect Supabase tables, auth, RLS, migrations, external game APIs, or real CRUD yet. There must be no insecure pseudo-admin functionality. The Supabase database model is intentionally postponed until I supply my ER diagram. Add `.env.example` only with placeholders and make sure `.env.local` is ignored. Please do not use my real key in source files or commits.

Work within this one phase rather than spending output tokens on long explanations. Make reasonable implementation decisions. Run the available checks, fix errors you introduced, and at the end give me only: (1) short summary of what works, (2) exact command to start it, (3) tests/checks you ran, (4) remaining limitations and suggested next branch. Do not push/deploy or apply database changes. Please leave Git commits/merges to me.
