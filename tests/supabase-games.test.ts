import { test } from 'node:test';
import assert from 'node:assert/strict';
import { mapGames, isDatabaseId } from '../lib/supabase/map-games';
import { readSupabaseConfig, getDataSource } from '../lib/supabase/config';
import { createSupabaseRepository } from '../lib/repositories/supabase-games';
const record = {
  id: '9007199254740993', title: 'Live fixture', releaseDate: null, fullPrice: 19.99,
  platform: 'PC', playtimeHours: 12.5, lastPlayedDate: null, coverUrl: null,
  rating: 7, status: 'In progress', genres: ['Adventure', 'Puzzle'],
  developers: [{ id: '9223372036854775807', name: 'Studio', country: 'Estonia', foundedYear: null }],
  achievements: [{ id: '1', title: 'First step', description: '', unlocked: true, unlockedDate: null }],
};
test('live projection preserves bigint IDs, nullable fields, ratings and relationships', () => {
  const game = mapGames([record])[0];
  assert.equal(game.id, '9007199254740993');
  assert.equal(game.developers[0].id, '9223372036854775807');
  assert.equal(game.releaseDate, null); assert.equal(game.coverUrl, null);
  assert.equal(game.rating, 7); assert.equal(game.playtimeHours, 12.5);
  assert.equal(game.achievements[0].unlockedDate, null);
  assert.deepEqual(game.genres, ['Adventure', 'Puzzle']);
  assert.deepEqual(mapGames([]), []);
  assert.equal(mapGames([{ ...record, rating: null, achievements: [] }])[0].rating, null);
});
test('malformed records are rejected instead of disguised as demo games', () => {
  for (const change of [{ id: 9007199254740992 }, { status: 'Playing' }, { rating: 1.5 }, { rating: 0 }, { rating: 11 }, { fullPrice: NaN }, { developers: [] }, { releaseDate: '2026-02-30' }]) {
    assert.throws(() => mapGames([{ ...record, ...change }]));
  }
  assert.throws(() => mapGames(null));
  assert.throws(() => mapGames([{ ...record, achievements: [{ ...record.achievements[0], unlocked: false, unlockedDate: '2026-01-01' }] }]));
});
test('runtime IDs are range validated before querying', async () => {
  let calls = 0;
  const repo = createSupabaseRepository(async id => { calls++; assert.equal(id, record.id); return [record]; });
  for (const id of ['elden-ring', '0', '-1', '1.5', '01', '9223372036854775808']) {
    assert.equal(isDatabaseId(id), false); assert.equal(await repo.getGameById(id), null);
  }
  assert.equal(calls, 0);
  assert.equal((await repo.getGameById(record.id))?.title, record.title);
  assert.equal(calls, 1);
});
test('empty and missing data remain empty; transport failures propagate', async () => {
  const empty = createSupabaseRepository(async () => []);
  assert.deepEqual(await empty.listGames(), []); assert.equal(await empty.getGameById('1'), null);
  const failed = createSupabaseRepository(async () => { throw new Error('Query failed'); });
  await assert.rejects(failed.listGames(), /Query failed/);
  await assert.rejects(failed.getGameById('1'), /Query failed/);
});
test('configuration explicitly selects demo; no fallback or privileged keys', () => {
  assert.equal(getDataSource('supabase'), 'supabase'); assert.equal(getDataSource('mock'), 'mock');
  assert.throws(() => getDataSource('invalid'));
  assert.throws(() => readSupabaseConfig({}));
  const env = { NEXT_PUBLIC_SUPABASE_URL: 'https://example.supabase.co', NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY: 'sb_publishable_test_only' };
  assert.equal(readSupabaseConfig(env).url, env.NEXT_PUBLIC_SUPABASE_URL);
  assert.throws(() => readSupabaseConfig({ ...env, NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY: 'sb_secret_test_only' }));
  assert.throws(() => readSupabaseConfig({ ...env, NEXT_PUBLIC_SUPABASE_URL: 'https://example.supabase.co/rest/v1/' }));
});
