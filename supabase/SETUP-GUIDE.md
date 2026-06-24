# Panduan Setup Supabase untuk GRIA Bible Tracker

## Checklist Langkah Manual

Ikuti langkah-langkah di bawah ini secara berurutan. Semua bisa dilakukan dari browser.

---

### 1. Buat Project Supabase

1. Buka https://supabase.com dan login/daftar (gratis)
2. Klik **"New Project"**
3. Isi:
   - **Name**: `gria-bible-tracker` (atau nama apapun)
   - **Database Password**: catat password ini (untuk admin DB, bukan untuk jemaat)
   - **Region**: pilih yang terdekat (Singapore)
4. Tunggu project selesai dibuat (~2 menit)

---

### 2. Jalankan SQL Schema

1. Di dashboard Supabase, buka menu **SQL Editor** (ikon di sidebar kiri)
2. Klik **"New Query"**
3. Copy-paste SELURUH isi file `schema.sql` yang ada di folder ini
4. Klik **"Run"** (atau Ctrl+Enter)
5. Pastikan tidak ada error (harusnya muncul "Success")

---

### 3. Ambil URL dan Anon Key

1. Buka menu **Settings** > **API** (di sidebar kiri)
2. Anda akan melihat:
   - **Project URL**: seperti `https://abcdefgh.supabase.co`
   - **anon (public) key**: string panjang yang dimulai dengan `eyJ...`
3. Copy kedua nilai tersebut

---

### 4. Update File Konfigurasi

1. Buka file `js/supabase-config.js` di repo ini
2. Ganti:
   ```javascript
   const SUPABASE_URL = 'https://YOUR_PROJECT_ID.supabase.co';
   const SUPABASE_ANON_KEY = 'YOUR_ANON_KEY_HERE';
   ```
   dengan nilai asli dari langkah 3.

**PENTING tentang keamanan:**
- **Anon Key AMAN** untuk dipublish di repo publik. Ini memang didesain untuk dipasang di client-side code.
- Keamanan data dijaga oleh **Row Level Security (RLS)** yang sudah disetup di schema.sql.
- Yang TIDAK BOLEH dipublish: **service_role key** (jangan pernah pakai key ini di frontend).

---

### 5. Setting Magic Link (Email Auth)

1. Di dashboard Supabase, buka **Authentication** > **URL Configuration**
2. Set **Site URL** ke:
   ```
   https://moneybonde-bit.github.io/website-gria
   ```
3. Di **Redirect URLs**, tambahkan:
   ```
   https://moneybonde-bit.github.io/website-gria/dashboard.html
   ```
   (Klik "Add URL" lalu paste)

4. Buka **Authentication** > **Email Templates**
   - (Opsional) Anda bisa edit template email magic link agar berbahasa Indonesia
   - Subject contoh: "Link Login GRIA Bible Tracker"
   - Body: ganti teks default dengan bahasa Indonesia

5. Buka **Authentication** > **Providers**
   - Pastikan **Email** sudah enabled (biasanya sudah default)
   - Di bagian Email, pastikan **"Enable Magic Link"** tercentang

---

### 6. Tambahkan Jemaat Pertama (Test)

1. Coba buka halaman login di website Anda: `https://moneybonde-bit.github.io/website-gria/login.html`
2. Masukkan email Anda sendiri
3. Cek inbox (atau spam), klik link yang masuk
4. Anda akan diarahkan ke dashboard

---

### 7. Menjadikan Seseorang Admin

Untuk saat ini (tanpa dashboard admin), lakukan via SQL Editor di Supabase:

```sql
UPDATE profiles SET role = 'admin' WHERE email = 'email_admin@example.com';
```

---

## FAQ

**Q: Apakah anon key aman di repo publik?**
A: Ya. Supabase anon key setara dengan "public API key" — dia hanya bisa melakukan apa yang diizinkan oleh Row Level Security. Tanpa login, key ini tidak bisa mengakses data apapun.

**Q: Bagaimana kalau jemaat lupa email yang dipakai?**
A: Anda (admin) bisa cek di Supabase Dashboard > Authentication > Users untuk melihat daftar email terdaftar.

**Q: Biaya Supabase?**
A: Free tier mencakup 50.000 monthly active users dan 500MB database — sangat cukup untuk 40 jemaat.

**Q: Bagaimana kalau jemaat bergabung di tengah tahun?**
A: Sistem ini dirancang supaya tiap orang mulai dari hari ke-1 saat pertama kali login. Jadi kapanpun bergabung, mereka tetap mulai dari Kejadian 1.
