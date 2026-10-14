import 'server-only';
import { createClient } from '@supabase/supabase-js';
import { readSupabaseConfig } from './config';
export function createPublicSupabaseClient() {
  const { url, key } = readSupabaseConfig(process.env);
  return createClient(url, key, {
    auth: { persistSession: false, autoRefreshToken: false, detectSessionInUrl: false },
    global: { fetch: (input, init) => fetch(input, { ...init, cache: 'no-store', signal: AbortSignal.timeout(15000) }) },
  });
}
