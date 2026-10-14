# GameVault – product and implementation specification

**Status:** Project brief approved in principle. Database ER diagram/schema is **not attached or finalized**. **CURRENT PHASE: 1 (UI with typed mock data)**.

## 1. Vision
Build a polished, dark-themed, responsive personal game-library website: a mix of a Steam library overview and a game-backlog tracker. The owner curates a collection, and anyone with the URL can explore it. Focus on browsing experience, individual game information and a few honest statistics. This is a learning project using AI-assisted coding, Git feature branches, React/Next.js, and later Supabase.

## 2. Roles and permissions
- **Public visitor:** No login; may browse games, see details, search, sort, filter, and view aggregated public statistics.
- **Owner/admin (one account):** Later signs in via Supabase Auth and may add/edit/delete games, assign developers, and manage achievements. No public registration, no accounts for visitors.
- **Security model for later:** Public read policies for intended public tables; write access only to the owner's verified Supabase Auth user ID, enforced in PostgreSQL RLS (and checked in server operations). Hide owner-only navigation where appropriate, but never rely on UI hiding for authorization. Deny other authenticated users as well as anonymous users.
- Never expose sensitive private account information or session tokens publicly.

## 3. Technologies
- **Framework:** Next.js with App Router and TypeScript.
- **Presentation:** Tailwind CSS; consider a small number of shadcn/ui components if they clearly reduce work.
- **Persistence (later):** Supabase PostgreSQL; Supabase Auth for a single owner login; RLS for enforcement.
- **Project:** `GameVault` (working title), npm, Git/GitHub.
- Keep components decoupled from database-specific query shapes by a typed repository/data-access layer.

## 4. Current university ER-model concepts (DO NOT treat as final SQL schema)
The database-course model has the following entities and relationships:

### Game
- `title`: game title; current academic requirement is uniqueness in combination with developer (see unresolved constraint below)
- `release_date`: release date
- `genres`: multiple genres per game
- `full_price`: regular/full price (NOT the user's purchase cost)
- `main_platform`: primary gaming platform
- `playtime_hours`: nonnegative number; `0` if not played
- `last_played_date`: nullable date

### Developer
- `id`: identifier
- `name`: unique developer name
- `country`: country

### Achievement
- `title`: achievement title
- `description`: description
- `unlocked`: boolean
- `unlocked_date`: nullable date (only if unlocked)

### Relationships / open modeling questions
- Game–Developer is **many-to-many**.
- Achievements belong to games (confirm multiplicity/details with the actual ER diagram later).
- The academic requirement “game title + developer is unique” needs careful treatment with a many-to-many developer relationship; **do not invent or prematurely implement a database constraint**.
- Confirm actual field names, relationship cardinalities and SQL normalization after inspecting the course ER diagram.

### Proposed app-only additions to discuss before DB work
- `cover_url`: image URL / artwork reference
- `status`: backlog, playing, completed, paused, dropped (candidate set)
- `personal_rating`: optional score
- Public record identifier (`id`), timestamps, and ownership configuration as required
- Do not introduce these into real tables yet; mock types can include them for display.

## 5. MVP functionality: public UI
### Library screen (`/` or `/library`)
- Clean sidebar/top navigation; clear GameVault branding.
- Search titles, filter by status and genre (platform optional), and sort by title, playtime, release date.
- Display a responsive grid of visually appealing game cards. Each card contains a cover placeholder/gradient, title, platform or genre, status, and optionally playtime.
- Helpful empty search state, loading-ready structure, and responsive mobile layout.

### Game detail screen (`/games/[id]`)
- Title, placeholder cover art, status, developer(s), genres, main platform, release date, full price, playtime, last played, and mock achievements when available.
- Provide a clear back-to-library action.

### Stats screen (`/stats`)
- Total games, count by status, total playtime, perhaps favorite genres and highest-playtime games.
- If summing full prices, label it **“combined full/list price”**, never “money spent” or “collection purchase value.”
- Stats must derive from the same mock dataset; avoid hardcoded statistics.

### Mock data
- Supply about 10–12 plausible example records with varied platforms, genres, statuses and hours; mark all data as demonstration data in the README. Some real game names are acceptable, but metadata and playtime are fictional for demo purposes.
- Use locally implemented cover placeholders or gradients; no unlicensed scraper/API requirement.
- Use typed model interfaces and simple pure utility functions for filters, sorting and stats. Keep a boundary such as `lib/repositories/games.ts` providing `listGames()`/`getGameById()` and a mock implementation, so a Supabase implementation can replace it later.

## 6. Visual direction
- Modern, polished, gaming-inspired aesthetic; not pixel-art and not a cluttered enterprise dashboard.
- Dark charcoal/near-black background, restrained violet/indigo or teal accents, generous spacing, readable typography.
- Cards with cover-art aspect ratios, rounded corners and subtle hover states, tasteful charts/bars for stats.
- Desktop-first quality, but usable at mobile widths. Prefer lightweight CSS over complex animations.
- Navigation and UI labels in English.

## 7. Phases and stopping rules
### PHASE 1 — NOW: Scaffold and read-only UI
Create Next.js app, basic structure, clean styling, typed data models, mock repository, library grid, detail page and stats page. Optional minimal tests for filters/stats. Provide local run commands. **Stop here.** No live Supabase queries, no tables, no auth or real writes.

### PHASE 2 — AFTER OWNER SUPPLIES ER DIAGRAM
Review ER model; agree on normalized relational schema and optional app fields; write proposed migrations as reviewable files; add RLS/grants and tests. Do not apply migrations or edit Supabase until the owner explicitly approves.

### PHASE 3 — AFTER DB APPROVAL
Use real Supabase reads; create a single-owner Supabase Auth sign-in; protect all writes with tested RLS + authorization. Add owner CRUD for games/developers/achievements, proper validation and loading/error handling. Public reading continues to work without authentication.

### PHASE 4 — LATER / OPTIONAL
Cover art enrichment via a legitimate API, Steam import, enhanced achievements, favorites, advanced insights, accessible polish, deployment. These are **not required for the first deliverable**.

## 8. Quality and verification
- `npm run dev` works locally.
- TypeScript and lint checks pass; no obvious console/runtime errors.
- Search/filter/sort functions work together and have sensible empty states.
- Detail links work for all sample games; invalid IDs show a useful not-found state.
- Stats derive from the dataset.
- No real write operations or insecure fake admin authentication.
- `.env.local` excluded from Git; `.env.example` uses placeholders only.
- README states clearly that Phase 1 uses mock data and changes are not persisted.

## 9. Supabase connection reference (for later, not to be used in Phase 1)
The project URL is `https://lwgzsamxxedxtalatyxm.supabase.co` (**not** the `/rest/v1/` endpoint). Local development will eventually use:

```dotenv
NEXT_PUBLIC_SUPABASE_URL=https://lwgzsamxxedxtalatyxm.supabase.co
NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY=replace_with_your_publishable_key
```

The owner holds the actual publishable key separately. Never commit local secrets, Supabase database password, or secret/service-role keys. A publishable key is public by design but grants only what RLS permits.

## 10. Git workflow for course
Use feature branches once scaffolding is established. Suggested tasks: `feature/library-ui`, `feature/game-detail`, `feature/stats`, `feature/supabase-schema`, `feature/owner-auth`, `feature/admin-crud`. Each branch should contain a focused change. Owner reviews and merges to `main`. Do not push/merge on your own.

## 11. Definition of done for current phase
A good-looking, functional read-only GameVault demonstration that can be navigated, searched and filtered locally, with all information sourced from typed mock data, ready for later real database integration. No premature persistence or security shortcuts.
