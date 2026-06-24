// GRIA Supabase Configuration
// PENTING: Ganti nilai di bawah dengan URL dan Anon Key dari project Supabase Anda.
// Anon Key AMAN untuk dipublish di repo publik SELAMA Row Level Security (RLS) sudah aktif.
// Lihat: https://supabase.com/docs/guides/auth#api-keys
const SUPABASE_URL = 'https://sdlzgekgjdpleiknwenj.supabase.co';
const SUPABASE_ANON_KEY = 'sb_publishable_sxbY07LylMa-w2ebAy6p1g_qFfCQ3_D';

// PENTING: nama variabel sengaja "supabaseClient", BUKAN "supabase" —
// karena "supabase" sudah dipakai oleh objek window.supabase dari CDN library.
// Memakai nama yang sama menyebabkan "Identifier has already been declared".
const supabaseClient = window.supabase.createClient(SUPABASE_URL, SUPABASE_ANON_KEY);