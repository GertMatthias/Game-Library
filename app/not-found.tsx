import Link from 'next/link';
export default function NotFound() { return <div className="empty"><p className="eyebrow">404 · UNCHARTED TERRITORY</p><h1>This game isn’t in the vault</h1><p>The page may have moved, or this game ID doesn’t exist.</p><Link className="button" href="/">Back to library</Link></div>; }
