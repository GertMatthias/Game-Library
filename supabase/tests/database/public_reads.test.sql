-- Prepared only; no hosted execution. Rollback-only projection/RLS checks.
begin;
create extension if not exists pgtap with schema extensions;
set local search_path = public, extensions;
select no_plan();
insert into public.games(game_id,title,full_price,platform,rating)
  overriding system value values (9007199254740993,'Read projection fixture',19.99,'PC',7);
insert into public.developers(developer_id,name,country)
  overriding system value values (9007199254740993,'Read projection studio','Estonia');
insert into public.game_developers values (9007199254740993,9007199254740993);
set constraints all immediate;
select ok(not prosecdef, 'Projection is SECURITY INVOKER')
  from pg_proc where oid='public.gamevault_read_games(bigint)'::regprocedure;
set local role anon;
select is(public.gamevault_read_games(9007199254740993)->0->>'id',
  '9007199254740993', 'Anonymous reader receives a lossless ID string');
select is(jsonb_typeof(public.gamevault_read_games(9007199254740993)->0->'id'),
  'string', 'ID is serialized as text before JSON parsing');
select is(public.gamevault_read_games(9007199254740993)->0->'developers'->0->>'id',
  '9007199254740993', 'Developer relationship uses a lossless ID');
select is(public.gamevault_read_games(9007199254740993)->0->'achievements',
  '[]'::jsonb, 'Missing achievements return an empty array');
select is(public.gamevault_read_games(-1), '[]'::jsonb, 'Missing game returns an empty result');
select throws_ok($$insert into public.genres(name) values ('Unauthorized projection writer')$$,
  '42501', null, 'Read function does not grant anonymous writes');
reset role;
select * from finish();
rollback;
