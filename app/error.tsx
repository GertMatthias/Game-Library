'use client';
export default function Error({ reset }: { reset: () => void }) { return <div className="empty"><h1>Couldn’t open the vault</h1><p>Something went wrong while loading this page.</p><button className="button" onClick={reset}>Try again</button></div>; }
