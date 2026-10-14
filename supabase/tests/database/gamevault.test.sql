-- PREPARED, NOT EXECUTED. Run only in disposable local Supabase with pgTAP.
-- Entire fixture/configuration is rolled back. UUIDs here are TEST identities.
begin;
create extension if not exists pgtap with schema extensions;
set local search_path = public, extensions;
select no_plan();

insert into auth.users(id) values
  ('11111111-1111-4111-8111-111111111111'),
  ('22222222-2222-4222-8222-222222222222');

create temporary table fixture_ids (kind text primary key, id bigint);
grant select on fixture_ids to anon, authenticated;
insert into public.games(title, full_price, platform) values ('Fixture one', 10, 'PC');
insert into fixture_ids select 'game', game_id from public.games where title = 'Fixture one';
insert into public.games(title, full_price, platform) values ('Fixture two', 20, 'Switch');
insert into fixture_ids select 'game2', game_id from public.games where title = 'Fixture two';
insert into public.developers(name, country) values ('Fixture A', 'Estonia'), ('Fixture B', 'Finland');
insert into fixture_ids select 'dev', developer_id from public.developers where name = 'Fixture A';
insert into fixture_ids select 'dev2', developer_id from public.developers where name = 'Fixture B';
insert into public.game_developers values
  ((select id from fixture_ids where kind='game'), (select id from fixture_ids where kind='dev')),
  ((select id from fixture_ids where kind='game2'), (select id from fixture_ids where kind='dev2'));
insert into public.genres(name) values ('Fixture genre');
insert into fixture_ids select 'genre', genre_id from public.genres where name = 'Fixture genre';
insert into public.game_genres values ((select id from fixture_ids where kind='game'), (select id from fixture_ids where kind='genre'));
insert into public.achievements(game_id, name, description) values
  ((select id from fixture_ids where kind='game'), 'Fixture achievement', 'Test');
insert into fixture_ids select 'achievement', achievement_id from public.achievements where name='Fixture achievement';
set constraints all immediate;
set constraints all deferred;

select ok((select rating is null and release_date is null and last_played is null and cover_url is null
  from public.games where game_id=(select id from fixture_ids where kind='game')), 'Unknown game data accepted');
select is((select count(*) from public.achievements where game_id=(select id from fixture_ids where kind='game2')), 0::bigint, 'Game without achievements accepted');
select ok((select founded_year is null from public.developers where developer_id=(select id from fixture_ids where kind='dev')), 'Unknown founding year accepted');
select throws_ok($$insert into public.games(title,full_price,platform,rating) values ('Invalid rating',0,'PC',0)$$, '23514', null, 'Rating zero rejected');
select throws_ok($$insert into public.games(title,full_price,platform,rating) values ('Invalid rating',0,'PC',11)$$, '23514', null, 'Rating above ten rejected');
select throws_ok($$insert into public.games(title,full_price,platform,rating) values ('Invalid rating',0,'PC',1.5)$$, '23514', null, 'Fractional rating rejected without rounding');
select throws_ok($$insert into public.games(title,full_price,platform,rating) values ('Invalid rating',0,'PC','NaN')$$, '23514', null, 'NaN rating rejected');
select throws_ok($$insert into public.games(title,full_price,platform) values ('Negative',-1,'PC')$$, '23514', null, 'Negative full price rejected');
select throws_ok($$insert into public.games(title,full_price,platform) values ('NaN','NaN','PC')$$, '23514', null, 'NaN full price rejected');
select throws_ok($$insert into public.games(title,full_price,platform,playtime_hours) values ('Negative',0,'PC',-1)$$, '23514', null, 'Negative hours rejected');
select throws_ok($$insert into public.games(title,full_price,platform,playtime_hours) values ('NaN',0,'PC','NaN')$$, '23514', null, 'NaN hours rejected');
select throws_ok($$insert into public.games(title,full_price,platform,status) values ('Invalid status',0,'PC','Playing')$$, '23514', null, 'Unapproved status rejected');
select throws_ok($$insert into public.games(title,full_price,platform) values (' ',0,'PC')$$, '23514', null, 'Blank title rejected');
select throws_ok($$insert into public.developers(name,country) values (' fixture a ','Estonia')$$, '23505', null, 'Normalized developer name unique');
select throws_ok($$insert into public.genres(name) values (' FIXTURE GENRE ')$$, '23505', null, 'Normalized genre name unique');
select throws_ok($$insert into public.game_developers select id, (select id from fixture_ids where kind='dev') from fixture_ids where kind='game'$$, '23505', null, 'Repeated developer link rejected');
select throws_ok($$insert into public.game_genres select id, (select id from fixture_ids where kind='genre') from fixture_ids where kind='game'$$, '23505', null, 'Repeated genre link rejected');
select throws_ok($$insert into public.achievements(game_id,name,description) values (-1,'Orphan','Test')$$, '23503', null, 'Achievement requires existing parent');
select throws_ok($$insert into public.achievements(game_id,name,description,unlock_date) select id,'Locked dated','Test','2026-01-01' from fixture_ids where kind='game'$$, '23514', null, 'Locked achievement has no date');
select throws_ok($$insert into public.achievements(game_id,name,description) select id,' FIXTURE ACHIEVEMENT ','Test' from fixture_ids where kind='game'$$, '23505', null, 'Achievement name unique within game');
select lives_ok($$insert into public.achievements(game_id,name,description,unlocked) select id,'Fixture achievement','Test',true from fixture_ids where kind='game2'$$, 'Same achievement name across games; unlocked unknown date accepted');
select lives_ok($$update public.games set rating=1,status='Completed',playtime_hours=0,last_played=null where game_id=(select id from fixture_ids where kind='game')$$, 'Completed with zero tracked hours is allowed');
select lives_ok($$update public.games set rating=10,status='Not played',playtime_hours=100 where game_id=(select id from fixture_ids where kind='game')$$, 'Status can freely change with recorded hours');
select lives_ok($$update public.games set rating=null,status='In progress' where game_id=(select id from fixture_ids where kind='game')$$, 'Third classification and unrated accepted');

-- pgTAP executes strings in subtransactions, so expected failures roll back.
select throws_ok($$
  insert into public.games(title,full_price,platform) values ('Orphan game',0,'PC');
  set constraints all immediate;
$$, '23514', null, 'Game minimum developer count enforced at transaction boundary');
select throws_ok($$
  insert into public.developers(name,country) values ('Orphan developer','Estonia');
  set constraints all immediate;
$$, '23514', null, 'Developer must have a represented game');
select throws_ok($$
  delete from public.game_developers where game_id=(select id from fixture_ids where kind='game');
  set constraints all immediate;
$$, '23514', null, 'Removing final developer fails');
select throws_ok($$
  update public.games set developer_set_key=array[999::bigint] where game_id=(select id from fixture_ids where kind='game');
  set constraints all immediate;
$$, '23514', null, 'Even trusted raw key tampering fails final validation');
select throws_ok($$
  insert into public.games(title,full_price,platform) values (' FIXTURE ONE ',0,'Xbox');
  insert into public.game_developers
    select g.game_id,f.id from public.games g cross join fixture_ids f
    where g.title=' FIXTURE ONE ' and f.kind='dev';
  set constraints all immediate;
$$, '23505', null, 'Normalized title plus exact set unique, regardless of platform');
select lives_ok($$
  insert into public.games(title,full_price,platform) values ('Fixture one',0,'PC');
  insert into public.game_developers
    select max(game_id),(select id from fixture_ids where kind='dev2') from public.games;
  set constraints all immediate;
  set constraints all deferred;
$$, 'Same title with a different developer combination allowed');
select throws_ok($$update public.games set game_id=game_id+10000 where game_id=(select id from fixture_ids where kind='game')$$, '23514', null, 'Entity IDs immutable');
select lives_ok($$
  insert into public.games(title,full_price,platform) values ('Multi fixture',0,'PC');
  insert into public.game_developers select g.game_id,f.id from public.games g cross join fixture_ids f
    where g.title='Multi fixture' and f.kind in ('dev','dev2') order by f.id desc;
  set constraints all immediate;
  set constraints all deferred;
$$, 'Multi-developer game accepts links in any input order');
select throws_ok($$
  insert into public.games(title,full_price,platform) values (' multi fixture ',0,'Xbox');
  insert into public.game_developers select g.game_id,f.id from public.games g cross join fixture_ids f
    where g.title=' multi fixture ' and f.kind in ('dev','dev2') order by f.id;
  set constraints all immediate;
$$, '23505', null, 'Reordered exact multi-developer set is a duplicate');
select throws_ok($$
  update public.games set title='Fixture one' where game_id=(select id from fixture_ids where kind='game2');
  set constraints all immediate;
$$, '23505', null, 'Title edit cannot create duplicate identity');
select throws_ok($$
  update public.game_developers set developer_id=(select id from fixture_ids where kind='dev2')
    where game_id=(select id from fixture_ids where kind='game');
  set constraints all immediate;
$$, '23505', null, 'Developer reassignment cannot create duplicate identity');

-- Regression fixtures: cascades, moved links and IMMEDIATE trigger ordering.
select lives_ok($$
  insert into public.games(title,full_price,platform) values ('Cascade fixture',0,'PC');
  insert into fixture_ids select 'cascade_game',game_id from public.games where title='Cascade fixture';
  insert into public.developers(name,country) values ('Cascade studio','Estonia');
  insert into public.game_developers select g.game_id,d.developer_id from public.games g cross join public.developers d
    where g.title='Cascade fixture' and d.name='Cascade studio';
  insert into public.game_genres select f.id,(select id from fixture_ids where kind='genre') from fixture_ids f where kind='cascade_game';
  insert into public.achievements(game_id,name,description) select id,'Cascade achievement','Test' from fixture_ids where kind='cascade_game';
  set constraints all immediate;
  set constraints all deferred;
  delete from public.games where title='Cascade fixture';
  delete from public.developers where name='Cascade studio';
  set constraints all immediate;
  set constraints all deferred;
$$, 'Cascading game delete plus orphan developer cleanup succeeds');
select is((select count(*) from public.achievements where game_id=(select id from fixture_ids where kind='cascade_game')), 0::bigint, 'Achievement cascade verified');
select is((select count(*) from public.game_genres where game_id=(select id from fixture_ids where kind='cascade_game')), 0::bigint, 'Genre-link cascade verified');
select is((select count(*) from public.game_developers where game_id=(select id from fixture_ids where kind='cascade_game')), 0::bigint, 'Developer-link cascade verified');
select lives_ok($$
  insert into public.games(title,full_price,platform) values ('Move source',0,'PC'),('Move target',0,'PC');
  insert into public.developers(name,country) values ('Move studio','Estonia');
  insert into public.game_developers select game_id,(select id from fixture_ids where kind='dev') from public.games where title='Move source';
  insert into public.game_developers select game_id,(select id from fixture_ids where kind='dev2') from public.games where title='Move target';
  insert into public.game_developers select g.game_id,d.developer_id from public.games g cross join public.developers d
    where g.title='Move source' and d.name='Move studio';
  set constraints all immediate;
  update public.game_developers set game_id=(select game_id from public.games where title='Move target')
    where developer_id=(select developer_id from public.developers where name='Move studio');
  set constraints all deferred;
$$, 'Moving link validates OLD/NEW games and developer in IMMEDIATE mode');
select ok((select bool_and(g.developer_set_key=(select array_agg(gd.developer_id order by gd.developer_id) from public.game_developers gd where gd.game_id=g.game_id)) from public.games g where title in ('Move source','Move target')), 'Both moved-link sets are refreshed');
select lives_ok($$
  delete from public.games where title in ('Move source','Move target');
  delete from public.developers where name='Move studio';
  set constraints all immediate;
  set constraints all deferred;
$$, 'Move fixture cleans up with deferred checks');

create temporary table guard_baseline as select revision from gamevault_private.integrity_guard;

-- RLS tests use actual restricted roles and request JWT identity, never only postgres.
set local role authenticated;
select set_config('request.jwt.claim.sub', '11111111-1111-4111-8111-111111111111', true);
select throws_ok($$insert into public.genres(name) values ('No owner configured')$$, '42501', null, 'Empty owner config denies writes');
reset role;
update gamevault_private.administrator set user_id='11111111-1111-4111-8111-111111111111' where singleton;

set local role anon;
select set_config('request.jwt.claim.sub', '', true);
select ok(not gamevault_private.is_administrator(), 'Anonymous is not administrator');
select results_eq($$select count(*) from public.games where title='Fixture two'$$, array[1::bigint], 'Anonymous public read');
select throws_ok($$insert into public.genres(name) values ('Unauthorized')$$, '42501', null, 'Anonymous insert denied');
select throws_ok($$update public.genres set name='Unauthorized'$$, '42501', null, 'Anonymous update denied');
select throws_ok($$delete from public.genres$$, '42501', null, 'Anonymous delete denied');
reset role;

set local role authenticated;
select set_config('request.jwt.claim.sub', '22222222-2222-4222-8222-222222222222', true);
select set_config('request.jwt.claims', '{"sub":"22222222-2222-4222-8222-222222222222","user_metadata":{"is_admin":true}}', true);
select ok(not gamevault_private.is_administrator(), 'Non-owner metadata cannot grant ownership');
select throws_ok($$select * from gamevault_private.administrator$$, '42501', null, 'Private owner config not readable');
select throws_ok($$update gamevault_private.administrator set user_id='22222222-2222-4222-8222-222222222222'$$, '42501', null, 'Owner config cannot be changed by client');
select throws_ok($$select gamevault_private.refresh_developer_sets()$$, '42501', null, 'Internal definer function cannot be invoked');
select results_eq($$with changed as (update public.genres set name='Unauthorized' returning *) select count(*) from changed$$, array[0::bigint], 'Non-owner updates affect no rows');
select results_eq($$with changed as (delete from public.genres returning *) select count(*) from changed$$, array[0::bigint], 'Non-owner deletes affect no rows');
select throws_ok($$insert into public.genres(name) values ('Unauthorized')$$, '42501', null, 'Non-owner insert denied by RLS');
select throws_ok($$truncate public.games cascade$$, '42501', null, 'No client TRUNCATE');
reset role;

set local role anon;
select set_config('request.jwt.claim.sub', '', true);
select ok((select count(*) > 0 from public.games), 'anon reads games');
select throws_ok($$insert into public.games(title,full_price,platform) values ('Denied game',0,'PC')$$, '42501', null, 'anon cannot insert games');
select throws_ok($$update public.games set title=title$$, '42501', null, 'anon cannot update games');
select throws_ok($$delete from public.games$$, '42501', null, 'anon cannot delete games');
select ok((select count(*) > 0 from public.developers), 'anon reads developers');
select throws_ok($$insert into public.developers(name,country) values ('Denied developer','Estonia')$$, '42501', null, 'anon cannot insert developers');
select throws_ok($$update public.developers set name=name$$, '42501', null, 'anon cannot update developers');
select throws_ok($$delete from public.developers$$, '42501', null, 'anon cannot delete developers');
select ok((select count(*) > 0 from public.genres), 'anon reads genres');
select throws_ok($$insert into public.genres(name) values ('Denied genre')$$, '42501', null, 'anon cannot insert genres');
select throws_ok($$update public.genres set name=name$$, '42501', null, 'anon cannot update genres');
select throws_ok($$delete from public.genres$$, '42501', null, 'anon cannot delete genres');
select ok((select count(*) > 0 from public.achievements), 'anon reads achievements');
select throws_ok($$insert into public.achievements(game_id,name,description) select id,'Denied achievement','Test' from fixture_ids where kind='game'$$, '42501', null, 'anon cannot insert achievements');
select throws_ok($$update public.achievements set name=name$$, '42501', null, 'anon cannot update achievements');
select throws_ok($$delete from public.achievements$$, '42501', null, 'anon cannot delete achievements');
select ok((select count(*) > 0 from public.game_developers), 'anon reads game_developers');
select throws_ok($$insert into public.game_developers select (select id from fixture_ids where kind='game'),(select id from fixture_ids where kind='dev2')$$, '42501', null, 'anon cannot insert game_developers');
select throws_ok($$update public.game_developers set game_id=game_id$$, '42501', null, 'anon cannot update game_developers');
select throws_ok($$delete from public.game_developers$$, '42501', null, 'anon cannot delete game_developers');
select ok((select count(*) > 0 from public.game_genres), 'anon reads game_genres');
select throws_ok($$insert into public.game_genres select (select id from fixture_ids where kind='game2'),(select id from fixture_ids where kind='genre')$$, '42501', null, 'anon cannot insert game_genres');
select throws_ok($$update public.game_genres set game_id=game_id$$, '42501', null, 'anon cannot update game_genres');
select throws_ok($$delete from public.game_genres$$, '42501', null, 'anon cannot delete game_genres');
reset role;
set local role authenticated;
select set_config('request.jwt.claim.sub', '22222222-2222-4222-8222-222222222222', true);
select ok((select count(*) > 0 from public.games), 'authenticated reads games');
select throws_ok($$insert into public.games(title,full_price,platform) values ('Denied game',0,'PC')$$, '42501', null, 'authenticated cannot insert games');
select results_eq($$with changed as (update public.games set title=title returning 1) select count(*) from changed$$, array[0::bigint], 'non-owner update games affects no rows');
select results_eq($$with changed as (delete from public.games returning 1) select count(*) from changed$$, array[0::bigint], 'non-owner delete games affects no rows');
select ok((select count(*) > 0 from public.developers), 'authenticated reads developers');
select throws_ok($$insert into public.developers(name,country) values ('Denied developer','Estonia')$$, '42501', null, 'authenticated cannot insert developers');
select results_eq($$with changed as (update public.developers set name=name returning 1) select count(*) from changed$$, array[0::bigint], 'non-owner update developers affects no rows');
select results_eq($$with changed as (delete from public.developers returning 1) select count(*) from changed$$, array[0::bigint], 'non-owner delete developers affects no rows');
select ok((select count(*) > 0 from public.genres), 'authenticated reads genres');
select throws_ok($$insert into public.genres(name) values ('Denied genre')$$, '42501', null, 'authenticated cannot insert genres');
select results_eq($$with changed as (update public.genres set name=name returning 1) select count(*) from changed$$, array[0::bigint], 'non-owner update genres affects no rows');
select results_eq($$with changed as (delete from public.genres returning 1) select count(*) from changed$$, array[0::bigint], 'non-owner delete genres affects no rows');
select ok((select count(*) > 0 from public.achievements), 'authenticated reads achievements');
select throws_ok($$insert into public.achievements(game_id,name,description) select id,'Denied achievement','Test' from fixture_ids where kind='game'$$, '42501', null, 'authenticated cannot insert achievements');
select results_eq($$with changed as (update public.achievements set name=name returning 1) select count(*) from changed$$, array[0::bigint], 'non-owner update achievements affects no rows');
select results_eq($$with changed as (delete from public.achievements returning 1) select count(*) from changed$$, array[0::bigint], 'non-owner delete achievements affects no rows');
select ok((select count(*) > 0 from public.game_developers), 'authenticated reads game_developers');
select throws_ok($$insert into public.game_developers select (select id from fixture_ids where kind='game'),(select id from fixture_ids where kind='dev2')$$, '42501', null, 'authenticated cannot insert game_developers');
select results_eq($$with changed as (update public.game_developers set game_id=game_id returning 1) select count(*) from changed$$, array[0::bigint], 'non-owner update game_developers affects no rows');
select results_eq($$with changed as (delete from public.game_developers returning 1) select count(*) from changed$$, array[0::bigint], 'non-owner delete game_developers affects no rows');
select ok((select count(*) > 0 from public.game_genres), 'authenticated reads game_genres');
select throws_ok($$insert into public.game_genres select (select id from fixture_ids where kind='game2'),(select id from fixture_ids where kind='genre')$$, '42501', null, 'authenticated cannot insert game_genres');
select results_eq($$with changed as (update public.game_genres set game_id=game_id returning 1) select count(*) from changed$$, array[0::bigint], 'non-owner update game_genres affects no rows');
select results_eq($$with changed as (delete from public.game_genres returning 1) select count(*) from changed$$, array[0::bigint], 'non-owner delete game_genres affects no rows');
reset role;

select is((select revision from gamevault_private.integrity_guard),
  (select revision from guard_baseline), 'Denied/non-owner zero-row writes leave private guard unchanged');

-- Each table has RLS enabled, four policies, read grants and no anon writes.
select ok(c.relrowsecurity, c.relname || ' enables RLS')
from pg_class c join pg_namespace n on n.oid=c.relnamespace
where n.nspname='public' and c.relname in ('games','developers','genres','game_developers','game_genres','achievements');
select is(count(*)::integer, 4, tablename || ' has the four explicit policies')
from pg_policies where schemaname='public' and tablename in ('games','developers','genres','game_developers','game_genres','achievements') group by tablename;
select ok(not has_table_privilege('anon', 'public.' || t, 'INSERT,UPDATE,DELETE'), t || ' has no anonymous write grants')
from unnest(array['games','developers','genres','game_developers','game_genres','achievements']) as t;

set local role authenticated;
select set_config('request.jwt.claim.sub', '11111111-1111-4111-8111-111111111111', true);
select ok(gamevault_private.is_administrator(), 'Configured owner recognized');
select throws_ok($$update public.games set developer_set_key='{}'$$, '42501', null, 'Owner cannot directly edit internal set');
select throws_ok($$select setval('public.games_game_id_seq',1)$$, '42501', null, 'Owner cannot reset identity sequence');
select lives_ok($$
  insert into public.games(title,full_price,platform,rating) values ('Owner atomic create',42,'PC',7);
  insert into public.developers(name,country) values ('Owner studio','Estonia');
  insert into public.game_developers
    select g.game_id,d.developer_id from public.games g cross join public.developers d
    where g.title='Owner atomic create' and d.name='Owner studio';
  set constraints all immediate;
  set constraints all deferred;
$$, 'Owner can atomically create game/developer/links through RLS');
select lives_ok($$update public.games set status='Completed',rating=10 where title='Owner atomic create'$$, 'Owner update permitted');
select lives_ok($$
  insert into public.genres(name) values ('Owner genre');
  insert into public.game_genres select g.game_id,ge.genre_id from public.games g cross join public.genres ge
    where g.title='Owner atomic create' and ge.name='Owner genre';
  insert into public.achievements(game_id,name,description) select game_id,'Owner achievement','Test' from public.games where title='Owner atomic create';
  update public.developers set founded_year=2000 where name='Owner studio';
  update public.genres set name='Owner genre updated' where name='Owner genre';
  update public.achievements set unlocked=true where name='Owner achievement';
  update public.game_developers set developer_id=developer_id
    where game_id=(select game_id from public.games where title='Owner atomic create');
  update public.game_genres set genre_id=genre_id
    where game_id=(select game_id from public.games where title='Owner atomic create');
  delete from public.achievements where name='Owner achievement';
  delete from public.game_genres where game_id=(select game_id from public.games where title='Owner atomic create');
  delete from public.genres where name='Owner genre updated';
  set constraints all immediate;
  set constraints all deferred;
$$, 'Owner related-table insert/update/delete permissions work');
select lives_ok($$
  delete from public.games where title='Owner atomic create';
  delete from public.developers where name='Owner studio';
  set constraints all immediate;
  set constraints all deferred;
$$, 'Owner can atomically delete game and orphan developer');
reset role;

select * from finish();
rollback;
