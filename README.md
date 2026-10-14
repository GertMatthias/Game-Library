# GameVault

A dark, responsive public personal game library built with Next.js App Router, TypeScript and Tailwind CSS. The read-only Supabase integration is prepared; auth and CRUD are postponed. The owner manages records manually in Supabase SQL Editor. Search, combined filters, sorting, runtime detail pages and derived statistics share the repository data.

## Setup

Requires Node.js 20.9+ and npm. Follow [manual Supabase setup](docs/SUPABASE_SETUP.md) to review/apply the three migrations yourself and add your first game. No migration has been executed by Codex.

Create ignored `.env.local` from `.env.example`:

```dotenv
GAMEVAULT_DATA_SOURCE=supabase
NEXT_PUBLIC_SUPABASE_URL=https://lwgzsamxxedxtalatyxm.supabase.co
NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY=replace_with_your_publishable_key
```

Supply your `sb_publishable_...` key locally. Never use a secret/service-role key or database password. Restart after changing environment variables.

```sh
npm install
npm run dev
```

Open http://localhost:3000. The database may be empty; absent configuration/schema produces an error state. There is no silent mock fallback. Explicit `GAMEVAULT_DATA_SOURCE=mock` runs the clearly labeled twelve-game offline demo with fictional metadata and EUR prices.

## Verification

```sh
npm run lint
npm run typecheck
npm test
npm run build
```

Confirm real data by adding a recognizable title in SQL Editor, refreshing the Supabase-labeled library, opening its numeric-ID detail page and checking derived statistics. See [setup and verification steps](docs/SUPABASE_SETUP.md). Current adapter tests use fixtures; hosted queries/database tests were not run.

## Architecture and scope

`lib/repositories/games.ts` selects an explicit mock or server-only Supabase adapter. The read-only SECURITY INVOKER projection preserves RLS, nested relationships and bigint IDs as strings. Pure filters/statistics remain in `lib/game-utils.ts`. Runtime pages use uncached anonymous reads; builds need no database connection. Dates, nullable 1?10 ratings, EUR list prices and three freely assignable statuses are preserved. Covers fall back to local CSS artwork.

No authentication UI, registration, real write endpoint or automatically imported records. Anonymous writes remain denied by existing grants/RLS; the owner UUID stays unconfigured for this SQL-Editor-only stage. Database SQL and prepared tests: [supabase/README.md](supabase/README.md). Model decisions: [Phase 2 plan](docs/PHASE_2_PLAN.md), [DECISIONS.md](DECISIONS.md). No secrets or `.env.local` in Git.
