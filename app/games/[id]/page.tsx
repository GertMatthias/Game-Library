import Link from 'next/link';
import { notFound } from 'next/navigation';
import { getGameById, listGames } from '@/lib/repositories/games';
import { Cover, StatusBadge } from '@/components/game-card';
import { formatDate, formatPrice } from '@/lib/game-utils';
export const dynamicParams = false;
export async function generateStaticParams() { return (await listGames()).map(game => ({ id: game.id })); }
export async function generateMetadata({ params }: { params: Promise<{ id: string }> }) { const game = await getGameById((await params).id); return { title: game?.title ?? 'Game not found' }; }
export default async function GameDetail({ params }: { params: Promise<{ id: string }> }) {
  const game = await getGameById((await params).id);
  if (!game) notFound();
  const unlocked = game.achievements.filter(a => a.unlocked).length;
  const facts = [['Main platform', game.platform], ['Release date', formatDate(game.releaseDate)], ['Full / list price', formatPrice(game.fullPrice)], ['Playtime', `${game.playtimeHours} hours`], ['Last played', game.lastPlayedDate ? formatDate(game.lastPlayedDate) : 'Not played yet'], ['Genres', game.genres.join(' · ')]];
  return <><Link href="/" className="back-link">← Back to library</Link><div className="detail-grid"><Cover game={game} large/><section><p className="eyebrow">GAME DETAILS · FICTIONAL DEMO METADATA</p><h1>{game.title}</h1><p className="detail-subtitle">{game.subtitle}</p><StatusBadge status={game.status}/><dl className="facts">{facts.map(([label, value]) => <div key={label}><dt>{label}</dt><dd>{value}</dd></div>)}<div><dt>Developers</dt><dd>{game.developers.map(d => `${d.name} (${d.country})`).join(', ')}</dd></div></dl></section></div><section className="panel achievement-panel"><div className="section-heading"><h2>Achievements</h2><span className="muted">{unlocked} / {game.achievements.length} unlocked</span></div><progress aria-label="Achievement completion" value={unlocked} max={game.achievements.length}/><div className="achievements">{game.achievements.map(achievement => <div className="achievement" key={achievement.title}><span className={achievement.unlocked ? 'unlocked achievement-icon' : 'achievement-icon'} aria-hidden>{achievement.unlocked ? '★' : '◇'}</span><div><h3>{achievement.title}</h3><p>{achievement.description}</p><small>{achievement.unlocked && achievement.unlockedDate ? `Unlocked ${formatDate(achievement.unlockedDate)}` : 'Locked'}</small></div></div>)}</div></section></>;
}
