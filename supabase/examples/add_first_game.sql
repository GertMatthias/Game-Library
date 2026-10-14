-- MANUAL EXAMPLE ONLY. Replace example metadata before use in SQL Editor.
-- One transaction satisfies both sides' mandatory developer participation.
-- Not a migration or automatic seed; running twice is intentionally rejected.
begin;
do $$
declare
  developer bigint;
  game bigint;
  genre bigint;
  genre_name text;
begin
  insert into public.developers(name, founded_year, country)
    values ('Your Studio Name', null, 'Estonia') returning developer_id into developer;
  insert into public.games(title, release_date, full_price, platform,
    playtime_hours, last_played, cover_url, status, rating)
    values ('Your First Game', null, 19.99, 'PC', 0, null, null, 'Not played', null)
    returning game_id into game;
  insert into public.game_developers(game_id, developer_id) values (game, developer);
  foreach genre_name in array array['Adventure', 'Puzzle'] loop
    select genre_id into genre from public.genres where lower(btrim(name)) = lower(genre_name);
    if genre is null then
      insert into public.genres(name) values (genre_name) returning genre_id into genre;
    end if;
    insert into public.game_genres(game_id, genre_id) values (game, genre);
  end loop;
  -- Optional: remove these two inserts if this game has no achievements.
  insert into public.achievements(game_id, name, description, unlocked, unlock_date)
    values (game, 'First steps', 'Start the adventure.', false, null),
           (game, 'The finish line', 'Complete the game.', false, null);
end;
$$;
commit;
