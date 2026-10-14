'use client';
import Image from 'next/image';
import { useState } from 'react';
export function CoverImage({ url }: { url: string | null }) {
  const [failedUrl, setFailedUrl] = useState<string | null>(null);
  if (!url || failedUrl === url) return null;
  const local = url.startsWith('/') && !url.startsWith('//');
  if (!local) {
    try {
      const parsed = new URL(url);
      if (parsed.protocol !== 'https:' || parsed.username || parsed.password) return null;
    } catch { return null; }
  }
  // Browser fetch only; no image proxy or arbitrary server-side URL fetching.
  return <Image src={url} alt="" fill sizes="(max-width: 550px) 50vw, 340px" unoptimized
    className="cover-image" onError={() => setFailedUrl(url)}/>;
}
