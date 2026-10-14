-- Review-only migration. Apply only to an explicitly approved target.
begin;

create schema gamevault_private;
revoke all on schema gamevault_private from public, anon, authenticated;

-- Not exposed through the Data API. Empty configuration fails closed.
create table gamevault_private.administrator (
  singleton boolean primary key default true check (singleton),
  user_id uuid unique references auth.users(id) on delete restrict
);
insert into gamevault_private.administrator(singleton, user_id) values (true, null);

-- A transaction-held row write serializes integrity-changing operations.
-- Writing (rather than only advisory locking) also detects stale RR snapshots.
create table gamevault_private.integrity_guard (
  singleton boolean primary key default true check (singleton),
  revision bigint not null default 0
);
insert into gamevault_private.integrity_guard(singleton) values (true);
revoke all on all tables in schema gamevault_private from public, anon, authenticated;

create table public.games (
  game_id bigint generated always as identity primary key,
  title text not null check (btrim(title) <> ''),
  release_date date,
  full_price numeric(10,2) not null check (full_price >= 0 and full_price <> 'NaN'::numeric),
  platform text not null check (btrim(platform) <> ''),
  playtime_hours numeric(10,2) not null default 0
    check (playtime_hours >= 0 and playtime_hours <> 'NaN'::numeric),
  last_played date,
  cover_url text check (cover_url is null or btrim(cover_url) <> ''),
  status text not null default 'Not played'
    check (status in ('Not played', 'In progress', 'Completed')),
  -- Unscaled numeric rejects fractional input instead of rounding on integer casts.
  rating numeric check (rating between 1 and 10 and rating = trunc(rating)),
  title_key text generated always as (lower(btrim(title))) stored,
  developer_set_key bigint[] not null default '{}'::bigint[],
  constraint games_title_developer_set_unique unique (title_key, developer_set_key)
    deferrable initially deferred
);
comment on column public.games.full_price is 'Regular/list price in EUR, not purchase cost.';
comment on column public.games.status is 'Freely assignable classification; no transition or playtime restrictions.';
comment on column public.games.developer_set_key is 'Database-maintained exact sorted developer set; junction rows are authoritative.';

create table public.developers (
  developer_id bigint generated always as identity primary key,
  name text not null check (btrim(name) <> ''),
  founded_year smallint check (founded_year between 1000 and 9999),
  country text not null check (btrim(country) <> '')
);
create unique index developers_name_unique on public.developers (lower(btrim(name)));

create table public.genres (
  genre_id bigint generated always as identity primary key,
  name text not null check (btrim(name) <> '')
);
create unique index genres_name_unique on public.genres (lower(btrim(name)));

create table public.game_developers (
  game_id bigint not null references public.games(game_id) on delete cascade,
  developer_id bigint not null references public.developers(developer_id) on delete restrict,
  primary key (game_id, developer_id)
);
create index game_developers_developer_idx on public.game_developers (developer_id, game_id);

create table public.game_genres (
  game_id bigint not null references public.games(game_id) on delete cascade,
  genre_id bigint not null references public.genres(genre_id) on delete restrict,
  primary key (game_id, genre_id)
);
create index game_genres_genre_idx on public.game_genres (genre_id, game_id);

create table public.achievements (
  achievement_id bigint generated always as identity primary key,
  game_id bigint not null references public.games(game_id) on delete cascade,
  name text not null check (btrim(name) <> ''),
  description text not null,
  unlocked boolean not null default false,
  unlock_date date,
  constraint achievements_locked_date_check check (unlocked or unlock_date is null)
);
create unique index achievements_game_name_unique
  on public.achievements (game_id, lower(btrim(name)));

-- All mutation statements on the membership graph take the same fence first.
create function gamevault_private.serialize_integrity_writes()
returns trigger language plpgsql security definer set search_path = '' as $$
begin
  -- SECURITY DEFINER changes current_user, so inspect the caller's SET ROLE.
  -- RLS filters all rows for these denied clients; avoid writing the fence.
  if current_setting('role') in ('anon', 'authenticated') and not exists (
    select 1 from gamevault_private.administrator a
    where a.singleton and a.user_id = (select auth.uid())
  ) then
    return null;
  end if;
  update gamevault_private.integrity_guard set revision = revision + 1 where singleton;
  if not found then raise exception 'Integrity guard missing' using errcode = '23514'; end if;
  return null;
end;
$$;

create function gamevault_private.refresh_developer_sets()
returns trigger language plpgsql security definer set search_path = '' as $$
declare
  affected_games bigint[] := '{}'::bigint[];
  affected_game bigint;
  canonical_set bigint[];
begin
  if tg_op <> 'INSERT' then affected_games := array_append(affected_games, old.game_id); end if;
  if tg_op <> 'DELETE' then affected_games := array_append(affected_games, new.game_id); end if;
  for affected_game in select distinct id from unnest(affected_games) as id order by id loop
    select coalesce(array_agg(gd.developer_id order by gd.developer_id), '{}'::bigint[])
    into canonical_set from public.game_developers gd where gd.game_id = affected_game;
    update public.games set developer_set_key = canonical_set
      where game_id = affected_game and developer_set_key is distinct from canonical_set;
  end loop;
  return null;
end;
$$;

create function gamevault_private.validate_membership()
returns trigger language plpgsql security definer set search_path = '' as $$
declare
  affected_games bigint[] := '{}'::bigint[];
  affected_developers bigint[] := '{}'::bigint[];
begin
  -- Queue identifiers from both sides of a move; inspect their FINAL state.
  if tg_table_name in ('games', 'game_developers') then
    if tg_op <> 'INSERT' then affected_games := array_append(affected_games, old.game_id); end if;
    if tg_op <> 'DELETE' then affected_games := array_append(affected_games, new.game_id); end if;
  end if;
  if tg_table_name in ('developers', 'game_developers') then
    if tg_op <> 'INSERT' then affected_developers := array_append(affected_developers, old.developer_id); end if;
    if tg_op <> 'DELETE' then affected_developers := array_append(affected_developers, new.developer_id); end if;
  end if;
  -- Deleted parent rows are deliberately absent from these scoped queries.
  if exists (
    select 1 from public.games g where g.game_id = any(affected_games) and (
      not exists (select 1 from public.game_developers gd where gd.game_id = g.game_id)
      or g.developer_set_key is distinct from (
        select array_agg(gd.developer_id order by gd.developer_id)
        from public.game_developers gd where gd.game_id = g.game_id
      )
    )
  ) then
    raise exception 'Each game requires its exact nonempty developer set'
      using errcode = '23514', constraint = 'games_developer_membership_check';
  end if;
  if exists (
    select 1 from public.developers d where d.developer_id = any(affected_developers)
      and not exists (select 1 from public.game_developers gd where gd.developer_id = d.developer_id)
  ) then
    raise exception 'Each developer must belong to a game'
      using errcode = '23514', constraint = 'developers_game_membership_check';
  end if;
  return null;
end;
$$;

create function gamevault_private.prevent_identity_update()
returns trigger language plpgsql set search_path = '' as $$
begin
  if (to_jsonb(new) -> tg_argv[0]) is distinct from (to_jsonb(old) -> tg_argv[0]) then
    raise exception 'Entity identifiers are immutable' using errcode = '23514';
  end if;
  return new;
end;
$$;

create trigger games_serialize before insert or update or delete on public.games
  for each statement execute function gamevault_private.serialize_integrity_writes();
create trigger developers_serialize before insert or update or delete on public.developers
  for each statement execute function gamevault_private.serialize_integrity_writes();
create trigger game_developers_serialize before insert or update or delete on public.game_developers
  for each statement execute function gamevault_private.serialize_integrity_writes();
-- Sort before the membership constraint trigger, including in IMMEDIATE mode.
create trigger game_developers_00_refresh after insert or update or delete on public.game_developers
  for each row execute function gamevault_private.refresh_developer_sets();

create constraint trigger games_membership_check after insert or update or delete on public.games
  deferrable initially deferred for each row execute function gamevault_private.validate_membership();
create constraint trigger developers_membership_check after insert or update or delete on public.developers
  deferrable initially deferred for each row execute function gamevault_private.validate_membership();
create constraint trigger game_developers_membership_check after insert or update or delete on public.game_developers
  deferrable initially deferred for each row execute function gamevault_private.validate_membership();

create trigger games_immutable_id before update on public.games
  for each row execute function gamevault_private.prevent_identity_update('game_id');
create trigger developers_immutable_id before update on public.developers
  for each row execute function gamevault_private.prevent_identity_update('developer_id');
create trigger genres_immutable_id before update on public.genres
  for each row execute function gamevault_private.prevent_identity_update('genre_id');
create trigger achievements_immutable_id before update on public.achievements
  for each row execute function gamevault_private.prevent_identity_update('achievement_id');

-- Immediately remove Supabase defaults, even before the grants migration.
revoke all on table public.games, public.developers, public.genres,
  public.game_developers, public.game_genres, public.achievements from public, anon, authenticated;
revoke all on sequence public.games_game_id_seq, public.developers_developer_id_seq,
  public.genres_genre_id_seq, public.achievements_achievement_id_seq from public, anon, authenticated;
revoke all on all functions in schema gamevault_private from public, anon, authenticated;
alter table public.games enable row level security;
alter table public.developers enable row level security;
alter table public.genres enable row level security;
alter table public.game_developers enable row level security;
alter table public.game_genres enable row level security;
alter table public.achievements enable row level security;
commit;
