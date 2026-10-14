'use client';
import Link from 'next/link';
import { usePathname } from 'next/navigation';
export function Navigation({ demo }: { demo: boolean }) {
  const pathname = usePathname();
  return <aside className="sidebar"><Link href="/" className="brand"><span className="brand-icon">G</span>GameVault<span className="brand-dot">.</span></Link><p className="nav-label">YOUR COLLECTION</p><nav aria-label="Main navigation"><Link className={pathname !== '/stats' ? 'nav-item active' : 'nav-item'} href="/" aria-current={pathname !== '/stats' ? 'page' : undefined}><span aria-hidden>▦</span> Game library</Link><Link className={pathname === '/stats' ? 'nav-item active' : 'nav-item'} href="/stats" aria-current={pathname === '/stats' ? 'page' : undefined}><span aria-hidden>▥</span> Statistics</Link></nav><div className="sidebar-bottom"><div className="demo-dot"/><strong>A collection to explore</strong><p>Public library · {demo ? 'Demo edition' : 'Supabase edition'}</p><small>Built for the love of games.</small></div></aside>;
}
