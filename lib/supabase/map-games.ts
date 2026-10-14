import { statuses, type Game } from '../models';
function object(value: unknown): Record<string, unknown> {
  if (!value || typeof value !== 'object' || Array.isArray(value)) throw new Error('Invalid game response.');
  return value as Record<string, unknown>;
}
function text(value: unknown): string {
  if (typeof value !== 'string' || !value.trim()) throw new Error('Invalid response text.');
  return value;
}
export function isDatabaseId(value: string) {
  return /^[1-9]\d{0,18}$/.test(value) && BigInt(value) <= BigInt('9223372036854775807');
}
function id(value: unknown): string {
  const result = text(value);
  if (!isDatabaseId(result)) throw new Error('Invalid database ID.');
  return result;
}
function date(value: unknown): string | null {
  if (value === null) return null;
  const result = text(value);
  if (!/^\d{4}-\d{2}-\d{2}$/.test(result) || !Number.isFinite(Date.parse(result)) || new Date(result).toISOString().slice(0, 10) !== result) throw new Error('Invalid response date.');
  return result;
}
function number(value: unknown): number {
  if (typeof value !== 'number' || !Number.isFinite(value) || value < 0) throw new Error('Invalid response number.');
  return value;
}
function array(value: unknown): unknown[] {
  if (!Array.isArray(value)) throw new Error('Invalid relationship.');
  return value;
}
export function mapGames(value: unknown): Game[] {
  return array(value).map(value => {
    const row = object(value);
    const status = statuses.find(status => status === row.status);
    if (!status) throw new Error('Invalid game status.');
    const rating = row.rating === null ? null : number(row.rating);
    if (rating !== null && (!Number.isInteger(rating) || rating < 1 || rating > 10)) throw new Error('Invalid rating.');
    const developers = array(row.developers).map(value => {
      const d = object(value);
      const foundedYear = d.foundedYear === null ? null : number(d.foundedYear);
      if (foundedYear !== null && (!Number.isInteger(foundedYear) || foundedYear < 1000 || foundedYear > 9999)) throw new Error('Invalid founding year.');
      return { id: id(d.id), name: text(d.name), country: text(d.country), foundedYear };
    });
    if (!developers.length) throw new Error('Game has no developers.');
    return {
      id: id(row.id), title: text(row.title), subtitle: 'A world in your collection.',
      releaseDate: date(row.releaseDate), fullPrice: number(row.fullPrice), platform: text(row.platform),
      playtimeHours: number(row.playtimeHours), lastPlayedDate: date(row.lastPlayedDate), status, rating,
      coverUrl: row.coverUrl === null ? null : text(row.coverUrl), cover: '#9373be', symbol: '◇',
      developers, genres: array(row.genres).map(text),
      achievements: array(row.achievements).map(value => {
        const a = object(value);
        if (typeof a.unlocked !== 'boolean' || typeof a.description !== 'string') throw new Error('Invalid achievement.');
        const unlockedDate = date(a.unlockedDate);
        if (!a.unlocked && unlockedDate !== null) throw new Error('Locked achievement has a date.');
        return { id: id(a.id), title: text(a.title), description: a.description, unlocked: a.unlocked, unlockedDate };
      }),
    };
  });
}
