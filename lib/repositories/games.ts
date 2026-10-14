import 'server-only';
import { connection } from 'next/server';
import { cache } from 'react';
import { getDataSource } from '../supabase/config';
import { createPublicSupabaseClient } from '../supabase/client';
import { createSupabaseRepository } from './supabase-games';
import { mockRepository } from './mock-games';
import type { Game } from '../models';

export interface GameRepository {
  listGames(): Promise<Game[]>;
  getGameById(id: string): Promise<Game | null>;
}
const readGames = cache(async (id: string | null): Promise<unknown> => {
  await connection();
  const { data, error } = await createPublicSupabaseClient().rpc('gamevault_read_games', { p_game_id: id });
  if (error) throw new Error('Unable to read Supabase. Check configuration and apply the three migrations.');
  return data;
});
const supabaseRepository: GameRepository = createSupabaseRepository(readGames);
const repository = () => getDataSource() === 'mock' ? mockRepository : supabaseRepository;
export const listGames = () => repository().listGames();
export const getGameById = (id: string) => repository().getGameById(id);
