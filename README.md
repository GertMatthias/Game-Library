# GameVault

Phase 1: a responsive, read-only public game collection built with Next.js App Router, TypeScript and Tailwind CSS. All 12 records use fictional demonstration metadata, developers, USD full/list prices, playtime and achievements. Game names are illustrative; cover artwork is implemented locally with CSS gradients and symbols.

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

`lib/models.ts` defines provisional UI models, not an approved database schema. `lib/repositories/games.ts` supplies asynchronous `listGames()` and `getGameById()` through a replaceable repository implementation. `lib/game-utils.ts` holds pure filtering, sorting and statistics functions.

No data changes are persisted. There are no write endpoints, admin controls, authentication, Supabase integration, external game APIs or remote artwork. No environment variables are required. `.env.example` contains unused future placeholders; `.env.local` is ignored. Keep actual credentials out of tracked files.

Phase 2 starts only after the owner supplies the course ER diagram: review and document the proposed schema before any approved database work. See `PROJECT_SPEC.md` and `DECISIONS.md`.
