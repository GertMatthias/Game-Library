export const statuses = ['Not played', 'In progress', 'Completed'] as const;
export type Status = typeof statuses[number];
export interface Developer { id: string; name: string; country: string; foundedYear: number | null }
export interface Achievement { id: string; title: string; description: string; unlocked: boolean; unlockedDate: string | null }
export interface Game {
  id: string; title: string; subtitle: string; developers: Developer[];
  releaseDate: string | null; genres: string[]; fullPrice: number; platform: string;
  playtimeHours: number; lastPlayedDate: string | null; status: Status;
  cover: string; coverUrl: string | null; rating: number | null; symbol: string; achievements: Achievement[];
}
