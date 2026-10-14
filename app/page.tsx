import { listGames } from '@/lib/repositories/games';
import { getDataSource } from '@/lib/supabase/config';
import { Library } from '@/components/library';
export default async function Home() { return <Library games={await listGames()} demo={getDataSource() === 'mock'}/>; }
