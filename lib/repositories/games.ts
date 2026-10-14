import { mockGames } from '../mock-games';
import type { Game } from '../models';

export interface GameRepository {
  listGames(): Promise<Game[]>;
  getGameById(id: string): Promise<Game | null>;
}
// Replace this implementation after the ER model and integration are approved.
const repository: GameRepository = {
  async listGames() { return structuredClone(mockGames); },
  async getGameById(id) { return structuredClone(mockGames.find(game => game.id === id) ?? null); },
};
export const listGames = () => repository.listGames();
export const getGameById = (id: string) => repository.getGameById(id);
