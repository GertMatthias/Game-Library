# Manual Supabase setup and read-only integration

No hosted connection or SQL execution was performed by Codex. Existing migration files 001/002 were reviewed and preserved. They target a Supabase PostgreSQL project with standard `anon`, `authenticated`, `auth.users` and `auth.uid()` objects. They intentionally fail on conflicting application objects instead of silently overwriting them. Local database/RLS/concurrency tests remain unexecuted; see `DATABASE_REVIEW.md` before deciding to apply the reviewed SQL.

## 1. Review the target and apply SQL yourself

1. Open your existing project in Supabase Dashboard. Confirm the project ref is `lwgzsamxxedxtalatyxm` and check Table Editor for existing application tables. An empty application database still contains Supabase's managed Auth/storage schemas; leave them alone.
2. Open SQL Editor and create a query named `GameVault 001 schema`. Paste the **entire** `supabase/migrations/20261014000100_gamevault_schema.sql`, including BEGIN/COMMIT. Review it and click Run. If it fails, stop and examine the error; don't proceed, delete tables, or repeatedly rerun successful migrations.
3. In a second query, paste/run all of `20261014000200_gamevault_rls.sql`. This enables public reads while keeping client writes denied until an owner is configured. You do **not** need to create an Auth user or configure the owner UUID for SQL Editor management. Leave the private owner configuration NULL for now.
4. In a third query, paste/run `20261014000300_gamevault_public_reads.sql`. This additive read-only function returns nested public records and casts bigint IDs to strings before JSON serialization. It is SECURITY INVOKER: it preserves caller RLS and grants no write permission. It also reloads the Data API schema cache.
5. Check all six public tables and RLS policies in Dashboard. Keep `gamevault_private` out of exposed Data API schemas. Do not modify Supabase-managed objects.

The read projection is needed because JavaScript JSON parsing can lose precision for bigint IDs. It returns the complete small collection, avoiding silently truncated statistics; pagination can be added if the library becomes large. It selects data only. See [Supabase database functions](https://supabase.com/docs/guides/database/functions).

Each migration is transaction-wrapped. If SQL Editor reports an aborted transaction, roll it back before retrying the failed file. If 001 succeeds but 002 fails, the application tables remain inaccessible to clients until grants/policies are applied; do not substitute permissive policies. Do not rerun 001 after it succeeds.

SQL Editor execution does not populate Supabase CLI migration history. Record which files you ran in your project notes. Before future CLI migration management, reconcile that history explicitly; don't run `db push` over manually applied files blindly.

## 2. Add your first game manually

Open `supabase/examples/add_first_game.sql`, replace the illustrative title/studio/country/price/platform/genres with your real values, then paste/run the full transaction in SQL Editor. This creates one developer, one game, the mandatory developer link, two genre links and optional achievements. Remove achievement inserts if unnecessary. It is not an automatic seed or migration, and running it twice is deliberately rejected by uniqueness constraints.

If the developer already exists, select its ID instead of inserting it. Existing genres are reused by normalized name. Use NULL for unknown dates, cover URL, founding year or rating. Prices are EUR full/list prices, rating is NULL or integer 1–10, and status is exactly Not played, In progress or Completed. Status can be changed independently of hours.

Keep parent/link operations in one transaction: inserting a game or developer without linking it fails at commit. Likewise, deleting a developer's last game requires deleting/reassigning that developer in the same transaction. SQL Editor uses trusted database privileges; it is intentionally separate from anonymous application access.

## 3. Configure the local app

Copy `.env.example` to `.env.local` locally. Set:

```dotenv
GAMEVAULT_DATA_SOURCE=supabase
NEXT_PUBLIC_SUPABASE_URL=https://lwgzsamxxedxtalatyxm.supabase.co
NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY=replace_with_your_publishable_key
```

Replace the key placeholder with the project's **publishable** key (`sb_publishable_...`) from Dashboard project API settings. This implementation accepts that format and rejects secret/service-role keys. Never put database passwords or service-role/secret keys in this file. `.env.local` is ignored; do not paste its contents into Git or logs.

The URL is the project root, not `/rest/v1/`. No authentication, browser client, cookies or SSR auth helper is needed: the server-only client makes anonymous reads with session persistence disabled. It uses the official [Supabase JS client](https://supabase.com/docs/reference/javascript/initializing). Requests are uncached and time-limited. Public fields alone reach client components; no environment keys are passed as component props.

```sh
npm install
npm run dev
```

Open http://localhost:3000 and restart the dev server after environment changes. `GAMEVAULT_DATA_SOURCE=mock` deliberately selects the offline demonstration and displays demo labels. Supabase is the default. A missing key, missing function/tables, query/network failure or invalid returned data causes an error state, never a mock fallback.

## 4. Verify the source of data

- Supabase mode labels the collection/sidebar/statistics accordingly. A successfully initialized empty database shows an empty collection and zero statistics.
- Add a uniquely recognizable real title using SQL Editor. Refresh the app: it must appear in search and filters. Open its `/games/<numeric-id>` link; no rebuilding is required.
- Change its price/playtime/status in SQL Editor, refresh, and check that detail and statistics agree. Try all three statuses and unknown release dates. Unrated games show Unrated; no achievements is a valid empty state.
- Missing/failed/local placeholder covers retain the existing gradient fallback. Actual covers load in the browser from local paths or HTTPS URLs, without a server image proxy. Only use artwork you can legitimately serve.
- Use an invalid or nonexistent numeric ID to check the not-found page. If the schema isn't initialized, the error screen points to environment/migration setup rather than displaying demo records.
- Before trusting security, verify anonymous reads and denied INSERT/UPDATE/DELETE directly using the publishable key in your own API tooling. Never use SQL Editor or a service-role request as evidence of RLS enforcement; trusted roles bypass it.

No login/registration/write UI or API is implemented. Public signup remains an independent Supabase Auth setting: when reviewing project configuration yourself, keep registration and anonymous sign-in disabled. Owner Auth setup is postponed, and Codex has changed no Auth settings/users.

## Verification limits

The adapter is exercised with deterministic fixture responses, not your hosted database. The production build can succeed without credentials because reads happen at request time. SQL syntax checking is not execution or proof of RLS/concurrency correctness. The existing real database test suite remains prepared only; no Docker/local database is installed or started for this task. Hosted end-to-end verification awaits your manual migrations, real record and environment configuration.

## Checks executed in this implementation

Lint, TypeScript, all 11 fixture/unit tests and the production build passed. New SQL migration/example/projection tests passed static SQL parsing; the manual example DO body passed PL/pgSQL parsing. Offline production-route checks rendered the library, statistics, demo detail and missing-game recovery page. Next.js can return HTTP 200 for streamed not-found responses; the missing-game page still renders recovery UI and noindex metadata. No hosted query, migration, real database test or SQL example was executed.
