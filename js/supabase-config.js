// GRIA Supabase Configuration
// PENTING: Ganti nilai di bawah dengan URL dan Anon Key dari project Supabase Anda.
// Anon Key AMAN untuk dipublish di repo publik SELAMA Row Level Security (RLS) sudah aktif.
// Lihat: https://supabase.com/docs/guides/auth#api-keys

const SUPABASE_URL = 'https://YOUR_PROJECT_ID.supabase.co';
const SUPABASE_ANON_KEY = 'YOUR_ANON_KEY_HERE';

const supabase = window.supabase.createClient(SUPABASE_URL, SUPABASE_ANON_KEY);
