import Link from 'next/link';
import type { CSSProperties } from 'react';
import type { Game } from '@/lib/models';
export function Cover({ game, large = false }: { game: Game; large?: boolean }) {
  return <div className={`cover ${large ? 'cover-large' : ''}`} style={{ '--cover-color': game.cover } as CSSProperties}><span className="cover-orbit"/><span className="cover-symbol" aria-hidden="true">{game.symbol}</span><span className="cover-caption">GAMEVAULT / DEMO ART</span><div className="cover-title">{game.title}</div><span className="cover-platform">{game.platform}</span></div>;
}
export function StatusBadge({ status }: { status: Game['status'] }) { return <span className={`status status-${status.toLowerCase()}`}><span aria-hidden="true">●</span> {status}</span>; }
export function GameCard({ game }: { game: Game }) {
  return <Link href={`/games/${game.id}`} className="game-card"><Cover game={game}/><div className="card-info"><h3>{game.title}</h3><p>{game.genres.slice(0, 2).join(' · ')}</p><div className="card-footer"><StatusBadge status={game.status}/><span>{game.playtimeHours ? `${game.playtimeHours} hrs` : 'Unplayed'}</span></div></div></Link>;
}
