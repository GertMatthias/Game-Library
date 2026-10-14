# GameVault

Phase 1: a responsive, read-only public game collection built with Next.js App Router, TypeScript and Tailwind CSS. All 12 records use fictional demonstration metadata, developers, EUR full/list prices, playtime and achievements. Game names are illustrative; cover artwork is implemented locally with CSS gradients and symbols.

## Local setup

Requires Node.js 20.9 or newer and npm.

```sh
npm install
npm run dev
```

Open http://localhost:3000. Browse `/`, `/games/[id]`, and `/stats`.

```sh
npm run lint
npm run typecheck
npm test
npm run build
```

The library supports combined title search, status/genre/platform filters, and title/playtime/release sorting. Statistics derive from the same repository data. Invalid IDs, empty search results, loading and error states have recovery UI.

## Data boundary and scope

`lib/models.ts` defines mock domain models; the approved database design is documented separately. `lib/repositories/games.ts` supplies asynchronous `listGames()` and `getGameById()` through a replaceable repository implementation. `lib/game-utils.ts` holds pure filtering, sorting and statistics functions.

No data changes are persisted. There are no write endpoints, admin controls, authentication, Supabase integration, external game APIs or remote artwork. No environment variables are required. `.env.example` contains unused future placeholders; `.env.local` is ignored. Keep actual credentials out of tracked files.

The finalized [Phase 2 plan](docs/PHASE_2_PLAN.md) records the approved bigint IDs, EUR prices, nullable unknown dates, exact developer-set uniqueness, rating, and single-owner RLS design. Both original course documents have been reviewed under their actual filenames. The app uses exactly **Not played**, **In progress**, and **Completed** as freely assignable classifications. Unknown release dates display as Unknown and sort last.

The running application still uses mock data. No database migrations, authentication or CRUD have been implemented. Next: prepare reviewable schema/RLS migrations and tests on `feature/supabase-schema`; execution against any database requires separate approval.
