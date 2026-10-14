import type { Metadata } from 'next';
import { getDataSource } from '@/lib/supabase/config';
import { Navigation } from '@/components/navigation';
import './globals.css';
export const metadata: Metadata = { title: { default: 'GameVault — Your game collection', template: '%s | GameVault' }, description: 'Explore a public game library. A read-only public collection with games, achievements and statistics.' };
export default function RootLayout({ children }: Readonly<{ children: React.ReactNode }>) {
  return <html lang="en"><body><a className="skip-link" href="#main">Skip to content</a><Navigation demo={getDataSource() === 'mock'}/><div className="main-shell"><header className="topbar"><span>PERSONAL GAME COLLECTION</span><span><i className="live-dot"/> Public view <span className="avatar" aria-hidden>GV</span></span></header><main id="main" className="main-content">{children}</main><footer>GameVault <span>Made for the journey, not just the finish line.</span><span>{getDataSource() === 'mock' ? 'Fictional demo data' : 'Supabase collection'} · Read-only</span></footer></div></body></html>;
}
