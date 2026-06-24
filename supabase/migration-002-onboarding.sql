-- ============================================================
-- GRIA — Migration 002: Onboarding Jemaat
-- Jalankan di Supabase SQL Editor SETELAH schema.sql (dan fix RLS rekursi
-- via fungsi public.is_admin() yang sudah ada di project ini).
--
-- Migration ini menambahkan kolom-kolom data jemaat dan flag onboarding.
-- Aman dijalankan berulang kali (idempoten) — pakai IF NOT EXISTS dan
-- DO blocks untuk CHECK constraint.
-- ============================================================

-- 1. Kolom baru di profiles
ALTER TABLE profiles
  ADD COLUMN IF NOT EXISTS jenis_kelamin TEXT,
  ADD COLUMN IF NOT EXISTS tempat_lahir TEXT,
  ADD COLUMN IF NOT EXISTS tanggal_lahir DATE,
  ADD COLUMN IF NOT EXISTS alamat TEXT,
  ADD COLUMN IF NOT EXISTS pekerjaan TEXT,
  ADD COLUMN IF NOT EXISTS nomor_wa TEXT,
  ADD COLUMN IF NOT EXISTS onboarding_selesai BOOLEAN NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS disetujui_pada TIMESTAMPTZ;

-- 2. CHECK constraint untuk jenis_kelamin (idempoten)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'profiles_jenis_kelamin_check'
  ) THEN
    ALTER TABLE profiles
      ADD CONSTRAINT profiles_jenis_kelamin_check
      CHECK (jenis_kelamin IS NULL OR jenis_kelamin IN ('Laki-laki', 'Perempuan'));
  END IF;
END $$;

-- ============================================================
-- Catatan RLS:
-- Policy "Users can update own profile" yang sudah ada di schema.sql
-- bersifat row-level (USING auth.uid() = id), BUKAN column-level.
-- Artinya user otomatis bisa update kolom-kolom baru di atas selama
-- baris itu miliknya sendiri. Tidak perlu policy tambahan.
--
-- JANGAN menambahkan policy admin baru dengan pola subquery langsung
-- ke profiles (SELECT 1 FROM profiles WHERE ... role = 'admin') —
-- itu memicu "infinite recursion detected in policy for relation
-- profiles". Pakai fungsi public.is_admin() (SECURITY DEFINER) yang
-- sudah ada di project jika perlu policy admin baru.
-- ============================================================
