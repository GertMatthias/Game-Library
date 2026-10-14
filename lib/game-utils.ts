import { statuses, type Game } from './models';
export type Sort = 'title' | 'playtime' | 'release';
export interface Filters { search: string; status: string; genre: string; platform: string; sort: Sort }
export const defaultFilters: Filters = { search: '', status: 'All', genre: 'All', platform: 'All', sort: 'title' };
export function filterGames(games: Game[], filters: Filters) {
  return games.filter(game => game.title.toLowerCase().includes(filters.search.trim().toLowerCase()) &&
    (filters.status === 'All' || game.status === filters.status) &&
    (filters.genre === 'All' || game.genres.includes(filters.genre)) &&
    (filters.platform === 'All' || game.platform === filters.platform))
    .sort((a, b) => (filters.sort === 'playtime' ? b.playtimeHours - a.playtimeHours : filters.sort === 'release' ? (b.releaseDate ?? '').localeCompare(a.releaseDate ?? '') : 0) || a.title.localeCompare(b.title));
}
export function getStatistics(games: Game[]) {
  return {
    total: games.length,
    hours: games.reduce((sum, game) => sum + game.playtimeHours, 0),
    fullPrice: games.reduce((sum, game) => sum + game.fullPrice, 0),
    byStatus: statuses.map(status => ({ name: status, count: games.filter(game => game.status === status).length })),
    genres: [...new Set(games.flatMap(game => game.genres))].map(name => ({ name, count: games.filter(game => game.genres.includes(name)).length })).sort((a, b) => b.count - a.count || a.name.localeCompare(b.name)),
    mostPlayed: [...games].filter(game => game.playtimeHours > 0).sort((a, b) => b.playtimeHours - a.playtimeHours).slice(0, 5),
  };
}
export const formatDate = (value: string | null) => value === null ? 'Unknown' : new Intl.DateTimeFormat('en', { year: 'numeric', month: 'short', day: 'numeric', timeZone: 'UTC' }).format(new Date(`${value}T00:00:00Z`));
export const formatPrice = (value: number) => new Intl.NumberFormat('en', { style: 'currency', currency: 'EUR' }).format(value);
