begin;

-- Admin identity is private, database-managed configuration, never user metadata.
-- NULL configuration denies every writer; configure via trusted SQL only.
create function gamevault_private.is_administrator()
returns boolean language sql stable security definer set search_path = '' as $$
  select exists (
    select 1 from gamevault_private.administrator a
    where a.singleton and a.user_id = (select auth.uid())
  );
$$;
revoke all on function gamevault_private.is_administrator() from public, anon, authenticated;
grant usage on schema gamevault_private to anon, authenticated;
grant execute on function gamevault_private.is_administrator() to anon, authenticated;

do $$
declare target text;
begin
  foreach target in array array['games','developers','genres','game_developers','game_genres','achievements'] loop
    execute format('create policy public_read on public.%I for select to anon, authenticated using (true)', target);
    execute format('create policy owner_insert on public.%I for insert to authenticated with check ((select gamevault_private.is_administrator()))', target);
    execute format('create policy owner_update on public.%I for update to authenticated using ((select gamevault_private.is_administrator())) with check ((select gamevault_private.is_administrator()))', target);
    execute format('create policy owner_delete on public.%I for delete to authenticated using ((select gamevault_private.is_administrator()))', target);
  end loop;
end;
$$;

grant usage on schema public to anon, authenticated;
grant select on public.games, public.developers, public.genres,
  public.game_developers, public.game_genres, public.achievements to anon, authenticated;

-- No table-wide games INSERT/UPDATE: internal keys and IDs stay inaccessible.
grant insert (title, release_date, full_price, platform, playtime_hours, last_played,
  cover_url, status, rating), update (title, release_date, full_price, platform,
  playtime_hours, last_played, cover_url, status, rating) on public.games to authenticated;
grant delete on public.games to authenticated;
grant insert (name, founded_year, country), update (name, founded_year, country)
  on public.developers to authenticated;
grant delete on public.developers to authenticated;
grant insert (name), update (name), delete on public.genres to authenticated;
grant insert (game_id, name, description, unlocked, unlock_date),
  update (game_id, name, description, unlocked, unlock_date), delete
  on public.achievements to authenticated;
grant insert, update, delete on public.game_developers, public.game_genres to authenticated;
-- USAGE permits generated inserts but not setval or sequence reset.
grant usage on sequence public.games_game_id_seq, public.developers_developer_id_seq,
  public.genres_genre_id_seq, public.achievements_achievement_id_seq to authenticated;

comment on table gamevault_private.administrator is
  'Configure the single verified owner Auth UUID using a trusted database connection. NULL disables all client writes.';
commit;
