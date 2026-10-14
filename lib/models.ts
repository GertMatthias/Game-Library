export const statuses = ['Not played', 'In progress', 'Completed'] as const;
export type Status = typeof statuses[number];
export interface Achievement { title: string; description: string; unlocked: boolean; unlockedDate: string | null }
export interface Game {
  id: string; title: string; subtitle: string; developers: { name: string; country: string }[];
  releaseDate: string | null; genres: string[]; fullPrice: number; platform: string;
  playtimeHours: number; lastPlayedDate: string | null; status: Status;
  cover: string; symbol: string; achievements: Achievement[];
}
