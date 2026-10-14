'use client';
export default function Error({ reset }: { reset: () => void }) { return <div className="empty"><h1>Couldn’t open the vault</h1><p>The collection could not be loaded. Check the Supabase environment settings and migrations, then try again.</p><button className="button" onClick={reset}>Try again</button></div>; }
