# GameVault – instructions for Codex

## Project identity
GameVault is a personal, publicly browsable video-game collection website. It is a university AI-assisted development project that will later reuse an ER model from a separate database course. Read `PROJECT_SPEC.md` whenever planning a new feature or changing the data model.

## Non-negotiable rules
- Follow the **CURRENT PHASE** in `PROJECT_SPEC.md`; do not implement deferred phases prematurely.
- For now **do not create Supabase tables, migrations, seed SQL, authentication, RLS policies, real write APIs or deployed services**. The database model has not been finalized.
- Never fabricate a database schema and treat it as approved. Describe any proposals in documentation as provisional.
- Implement the UI using typed mock data behind a repository/data-access boundary so it can later be replaced with Supabase without rewriting UI components.
- All visitors can read the future public collection; **only the single owner** may create, edit, or delete server-side data. Never use a frontend-only admin flag as access control. No public sign-up or multi-user libraries.
- Until Supabase Auth + correctly tested RLS are complete, keep any admin/editing UI disabled, clearly marked as a preview, or absent. Do not claim it is secured or functional.
- No secret/service-role keys in browser code, Git history, logs, screenshots or README. Do not commit `.env.local`. Publishable key is not an authorization system.
- Prefer simple, idiomatic Next.js/React code; minimize dependencies and avoid overengineering.
- Write production-quality TypeScript, sensible component structure, basic accessibility and responsive layouts.
- Keep game/data logic independent of presentation components. Validate user inputs before future writes.
- Avoid speculative external APIs (including Steam) and copyrighted third-party cover downloads during the first phase. Use local visual placeholders and explicit demo values.
- Do not overwrite user work, rewrite Git history, push to a remote, deploy or incur costs without asking.

## Working style and token efficiency
- At the start of a task, inspect only the relevant existing files and follow the spec.
- Work on the requested scope; avoid refactors and unrelated changes.
- Make reasonable small decisions independently; ask only if a security or architectural choice materially blocks the work.
- If possible, run lint, typecheck, and relevant tests; fix problems from your changes.
- End each task with a concise report: files changed, what works, commands to run, tests executed, and remaining limitations. Do not print whole source files in chat.
- Maintain `README.md` with setup instructions and record significant decisions in `DECISIONS.md` (short entries only).
- Use feature branches for standalone changes once the initial scaffold is committed; never push or merge without approval.

## Tech choices
- Next.js App Router, TypeScript, Tailwind CSS; shadcn/ui only if actually useful.
- Supabase PostgreSQL + Auth planned for later; use `@supabase/supabase-js` and server/client helpers only when integration begins.
- Default UI text in English (game terms and page navigation). Code and comments in English. Documentation can be English.
- Use npm scripts and explain local start with `npm run dev`.

<!-- BEGIN:nextjs-agent-rules -->

## This is NOT the Next.js you know

This version has breaking changes — APIs, conventions, and file structure may all differ from your training data. Read the relevant guide in `node_modules/next/dist/docs/` (resolved from this file's directory; in monorepos the `next` package may not be visible from the repo root) before writing any code. Heed deprecation notices.

This block is written and re-added by `next dev` — verify at `node_modules/next/dist/server/lib/generate-agent-files.js`. Removing it from a diff only re-creates the uncommitted change; committing it with your work keeps the tree clean.

<!-- END:nextjs-agent-rules -->
