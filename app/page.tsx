import { listGames } from '@/lib/repositories/games';
import { Library } from '@/components/library';
export default async function Home() { return <Library games={await listGames()}/>; }
