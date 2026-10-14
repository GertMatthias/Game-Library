import type { Metadata } from 'next';
import { Navigation } from '@/components/navigation';
import './globals.css';
export const metadata: Metadata = { title: { default: 'GameVault — Your game collection', template: '%s | GameVault' }, description: 'Explore a public game library. Phase 1 demonstration with fictional metadata and local gradient artwork.' };
export default function RootLayout({ children }: Readonly<{ children: React.ReactNode }>) {
  return <html lang="en"><body><a className="skip-link" href="#main">Skip to content</a><Navigation/><div className="main-shell"><header className="topbar"><span>PERSONAL GAME COLLECTION</span><span><i className="live-dot"/> Public view <span className="avatar" aria-hidden>GV</span></span></header><main id="main" className="main-content">{children}</main><footer>GameVault <span>Made for the journey, not just the finish line.</span><span>Fictional demo data · Read-only</span></footer></div></body></html>;
}
