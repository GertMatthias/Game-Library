import { test } from 'node:test';
import assert from 'node:assert/strict';
import { defaultFilters, filterGames, getStatistics, formatDate, formatPrice } from '../lib/game-utils';
import { statuses } from '../lib/models';
import { mockGames } from '../lib/mock-games';
import { getGameById, listGames } from '../lib/repositories/games';
test('search is trimmed and case insensitive; filters compose', () => {
  assert.deepEqual(filterGames(mockGames, { ...defaultFilters, search: '  HADES ', status: 'In progress', genre: 'Action', platform: 'PC' }).map(g => g.id), ['hades']);
  assert.equal(filterGames(mockGames, { ...defaultFilters, search: 'hades', platform: 'Switch' }).length, 0);
  assert.equal(filterGames(mockGames, { ...defaultFilters, search: 'no such game' }).length, 0);
});
test('all sorting modes order results without mutating input', () => {
  const before = mockGames.map(g => g.id);
  for (const sort of ['title', 'playtime', 'release'] as const) {
    const result = filterGames(mockGames, { ...defaultFilters, sort });
    for (let i = 1; i < result.length; i++) {
      if (sort === 'title') assert.ok(result[i - 1].title.localeCompare(result[i].title) <= 0);
      if (sort === 'playtime') assert.ok(result[i - 1].playtimeHours >= result[i].playtimeHours);
      if (sort === 'release') assert.ok((result[i - 1].releaseDate ?? '') >= (result[i].releaseDate ?? ''));
    }
  }
  assert.deepEqual(mockGames.map(g => g.id), before);
});
test('exactly three classifications filter and aggregate every mock game', () => {
  assert.deepEqual(statuses, ['Not played', 'In progress', 'Completed']);
  assert.deepEqual(getStatistics(mockGames).byStatus, [
    { name: 'Not played', count: 3 }, { name: 'In progress', count: 4 }, { name: 'Completed', count: 5 },
  ]);
  for (const status of statuses) {
    const filtered = filterGames(mockGames, { ...defaultFilters, status });
    assert.ok(filtered.length > 0);
    assert.ok(filtered.every(game => game.status === status));
  }
  // Classification is independent of hours and achievement completion.
  const reclassified = { ...mockGames[0], status: 'Not played' as const };
  assert.equal(getStatistics([reclassified]).byStatus[0].count, 1);
  assert.equal(reclassified.playtimeHours, 124);
});
test('unknown release dates sort last; dates and EUR prices display correctly', () => {
  const unknown = { ...mockGames[0], id: 'unknown', releaseDate: null };
  assert.equal(filterGames([unknown, mockGames[1]], { ...defaultFilters, sort: 'release' })[1].id, 'unknown');
  assert.equal(formatDate(null), 'Unknown');
  assert.equal(formatDate('2020-01-02'), 'Jan 2, 2020');
  assert.equal(formatPrice(14.99), '€14.99');
});
test('statistics derive from supplied records and handle empty data', () => {
  const data = [mockGames[0], mockGames[1]];
  const stats = getStatistics(data);
  assert.equal(stats.total, 2); assert.equal(stats.hours, 172);
  assert.equal(stats.fullPrice, 74.98);
  assert.equal(stats.byStatus.reduce((sum, s) => sum + s.count, 0), 2);
  assert.equal(stats.genres.find(g => g.name === 'Adventure')?.count, 2);
  assert.equal(stats.mostPlayed[0].id, 'elden-ring');
  const empty = getStatistics([]);
  assert.equal(empty.total, 0); assert.equal(empty.hours, 0); assert.equal(empty.fullPrice, 0);
  assert.deepEqual(empty.genres, []); assert.deepEqual(empty.mostPlayed, []);
});
test('repository resolves every demo ID and isolates returned records', async () => {
  const games = await listGames();
  for (const game of games) assert.equal((await getGameById(game.id))?.id, game.id);
  assert.equal(await getGameById('missing'), null);
  games[0].title = 'Changed';
  assert.equal((await getGameById('elden-ring'))?.title, 'Elden Ring');
});
