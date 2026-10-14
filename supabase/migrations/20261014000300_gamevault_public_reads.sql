-- Public read-only projection with caller RLS and lossless bigint IDs.
begin;
create function public.gamevault_read_games(p_game_id bigint default null)
returns jsonb language sql stable security invoker set search_path = '' as $$
  select coalesce(jsonb_agg(record order by title, game_id), '[]'::jsonb)
  from (
    select g.game_id, g.title, jsonb_build_object(
      'id', g.game_id::text, 'title', g.title, 'releaseDate', g.release_date,
      'fullPrice', g.full_price, 'platform', g.platform,
      'playtimeHours', g.playtime_hours, 'lastPlayedDate', g.last_played,
      'coverUrl', g.cover_url, 'status', g.status, 'rating', g.rating,
      'developers', coalesce((
        select jsonb_agg(jsonb_build_object('id', d.developer_id::text,
          'name', d.name, 'country', d.country, 'foundedYear', d.founded_year)
          order by d.name, d.developer_id)
        from public.game_developers gd join public.developers d using (developer_id)
        where gd.game_id = g.game_id
      ), '[]'::jsonb),
      'genres', coalesce((
        select jsonb_agg(ge.name order by ge.name)
        from public.game_genres gg join public.genres ge using (genre_id)
        where gg.game_id = g.game_id
      ), '[]'::jsonb),
      'achievements', coalesce((
        select jsonb_agg(jsonb_build_object('id', a.achievement_id::text,
          'title', a.name, 'description', a.description, 'unlocked', a.unlocked,
          'unlockedDate', a.unlock_date) order by a.name, a.achievement_id)
        from public.achievements a where a.game_id = g.game_id
      ), '[]'::jsonb)
    ) as record
    from public.games g where p_game_id is null or g.game_id = p_game_id
  ) projected;
$$;
revoke all on function public.gamevault_read_games(bigint) from public, anon, authenticated;
grant execute on function public.gamevault_read_games(bigint) to anon, authenticated;
comment on function public.gamevault_read_games(bigint) is
  'Caller-RLS read projection with string IDs. NULL returns the complete small collection.';
notify pgrst, 'reload schema';
commit;
