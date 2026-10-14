import { isDatabaseId, mapGames } from '../supabase/map-games';
export function createSupabaseRepository(read: (id: string | null) => Promise<unknown>) {
  return {
    async listGames() { return mapGames(await read(null)); },
    async getGameById(id: string) {
      if (!isDatabaseId(id)) return null;
      return mapGames(await read(id))[0] ?? null;
    },
  };
}
