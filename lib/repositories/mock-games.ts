import { mockGames } from '../mock-games';
export const mockRepository = {
  async listGames() { return structuredClone(mockGames); },
  async getGameById(id: string) { return structuredClone(mockGames.find(game => game.id === id) ?? null); },
};
