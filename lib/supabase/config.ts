export type DataSource = 'supabase' | 'mock';
export function getDataSource(value = process.env.GAMEVAULT_DATA_SOURCE): DataSource {
  if (!value || value === 'supabase') return 'supabase';
  if (value === 'mock') return 'mock';
  throw new Error('GAMEVAULT_DATA_SOURCE must be supabase or mock.');
}
export function readSupabaseConfig(env: Record<string, string | undefined>) {
  const url = env.NEXT_PUBLIC_SUPABASE_URL;
  const key = env.NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY;
  if (!url || !key || key.includes('replace_with') || url.includes('your-project')) throw new Error('Set the Supabase URL and publishable key in .env.local.');
  const parsed = new URL(url);
  if (parsed.protocol !== 'https:' || parsed.pathname !== '/' || parsed.username || parsed.password) throw new Error('Use the HTTPS project URL, not a REST endpoint.');
  if (!key.startsWith('sb_publishable_')) throw new Error('Use a publishable key; secret/service-role keys are not accepted.');
  return { url, key };
}
