-- ============================================================
-- GRIA Bible Reading Tracker — Supabase Schema
-- Jalankan SQL ini di Supabase SQL Editor (Dashboard > SQL Editor > New Query)
-- ============================================================

-- 1. TABEL: profiles
-- Terhubung ke auth.users Supabase, dibuat otomatis saat user baru mendaftar
CREATE TABLE IF NOT EXISTS profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  nama TEXT NOT NULL DEFAULT '',
  email TEXT NOT NULL DEFAULT '',
  tanggal_daftar TIMESTAMPTZ NOT NULL DEFAULT now(),
  tanggal_mulai_baca DATE,  -- hari pertama user mulai program baca
  role TEXT NOT NULL DEFAULT 'jemaat' CHECK (role IN ('jemaat', 'admin'))
);

-- 2. TABEL: rencana_baca_harian
-- Berisi 365 hari bacaan (PL + PB sederhana)
CREATE TABLE IF NOT EXISTS rencana_baca_harian (
  urutan_hari INTEGER PRIMARY KEY CHECK (urutan_hari BETWEEN 1 AND 365),
  referensi_ayat TEXT NOT NULL
);

-- 3. TABEL: progres_baca
-- Mencatat progres baca tiap jemaat
CREATE TABLE IF NOT EXISTS progres_baca (
  id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  urutan_hari INTEGER NOT NULL REFERENCES rencana_baca_harian(urutan_hari),
  tanggal_ditandai TIMESTAMPTZ NOT NULL DEFAULT now(),
  sudah_baca BOOLEAN NOT NULL DEFAULT true,
  UNIQUE(user_id, urutan_hari)
);

-- Index untuk query performa
CREATE INDEX IF NOT EXISTS idx_progres_user ON progres_baca(user_id);

-- ============================================================
-- ROW LEVEL SECURITY (RLS)
-- ============================================================

-- Aktifkan RLS pada semua tabel
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE rencana_baca_harian ENABLE ROW LEVEL SECURITY;
ALTER TABLE progres_baca ENABLE ROW LEVEL SECURITY;

-- PROFILES: user hanya bisa lihat/edit profil sendiri, admin bisa lihat semua
CREATE POLICY "Users can view own profile"
  ON profiles FOR SELECT
  USING (auth.uid() = id);

CREATE POLICY "Users can update own profile"
  ON profiles FOR UPDATE
  USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id);

CREATE POLICY "Admin can view all profiles"
  ON profiles FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- RENCANA_BACA_HARIAN: semua user yang sudah login bisa baca (read-only)
CREATE POLICY "Authenticated users can read reading plan"
  ON rencana_baca_harian FOR SELECT
  USING (auth.role() = 'authenticated');

-- PROGRES_BACA: user hanya bisa lihat/edit progres sendiri, admin bisa lihat semua
CREATE POLICY "Users can view own progress"
  ON progres_baca FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own progress"
  ON progres_baca FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own progress"
  ON progres_baca FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete own progress"
  ON progres_baca FOR DELETE
  USING (auth.uid() = user_id);

CREATE POLICY "Admin can view all progress"
  ON progres_baca FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- ============================================================
-- TRIGGER: Auto-create profile saat user baru sign up
-- ============================================================

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, email, nama, tanggal_daftar)
  VALUES (
    NEW.id,
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'nama', split_part(NEW.email, '@', 1)),
    now()
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- ============================================================
-- DATA: Rencana Baca 365 Hari (PL + PB Sederhana)
-- ============================================================

INSERT INTO rencana_baca_harian (urutan_hari, referensi_ayat) VALUES
  (1, 'Kejadian 1-3 | Matius 1'),
  (2, 'Kejadian 4-6 | Matius 2'),
  (3, 'Kejadian 7-8 | Matius 3'),
  (4, 'Kejadian 9-11'),
  (5, 'Kejadian 12-13 | Matius 4'),
  (6, 'Kejadian 14-16 | Matius 5'),
  (7, 'Kejadian 17-18'),
  (8, 'Kejadian 19-21 | Matius 6'),
  (9, 'Kejadian 22-23 | Matius 7'),
  (10, 'Kejadian 24-26 | Matius 8'),
  (11, 'Kejadian 27-28'),
  (12, 'Kejadian 29-31 | Matius 9'),
  (13, 'Kejadian 32-34 | Matius 10'),
  (14, 'Kejadian 35-36'),
  (15, 'Kejadian 37-39 | Matius 11'),
  (16, 'Kejadian 40-41 | Matius 12'),
  (17, 'Kejadian 42-44 | Matius 13'),
  (18, 'Kejadian 45-46'),
  (19, 'Kejadian 47-49 | Matius 14'),
  (20, 'Kejadian 50; Keluaran 1 | Matius 15'),
  (21, 'Keluaran 2-4'),
  (22, 'Keluaran 5-6 | Matius 16'),
  (23, 'Keluaran 7-9 | Matius 17'),
  (24, 'Keluaran 10-12 | Matius 18'),
  (25, 'Keluaran 13-14'),
  (26, 'Keluaran 15-17 | Matius 19'),
  (27, 'Keluaran 18-19 | Matius 20'),
  (28, 'Keluaran 20-22'),
  (29, 'Keluaran 23-24 | Matius 21'),
  (30, 'Keluaran 25-27 | Matius 22'),
  (31, 'Keluaran 28-29 | Matius 23'),
  (32, 'Keluaran 30-32'),
  (33, 'Keluaran 33-34 | Matius 24'),
  (34, 'Keluaran 35-37 | Matius 25'),
  (35, 'Keluaran 38-40'),
  (36, 'Imamat 1-2 | Matius 26'),
  (37, 'Imamat 3-5 | Matius 27'),
  (38, 'Imamat 6-7 | Matius 28'),
  (39, 'Imamat 8-10'),
  (40, 'Imamat 11-12 | Markus 1'),
  (41, 'Imamat 13-15 | Markus 2'),
  (42, 'Imamat 16-17'),
  (43, 'Imamat 18-20 | Markus 3'),
  (44, 'Imamat 21-22 | Markus 4'),
  (45, 'Imamat 23-25 | Markus 5'),
  (46, 'Imamat 26-27; Bilangan 1'),
  (47, 'Bilangan 2-3 | Markus 6'),
  (48, 'Bilangan 4-6 | Markus 7'),
  (49, 'Bilangan 7-8'),
  (50, 'Bilangan 9-11 | Markus 8'),
  (51, 'Bilangan 12-13 | Markus 9'),
  (52, 'Bilangan 14-16 | Markus 10'),
  (53, 'Bilangan 17-18'),
  (54, 'Bilangan 19-21 | Markus 11'),
  (55, 'Bilangan 22-23 | Markus 12'),
  (56, 'Bilangan 24-26'),
  (57, 'Bilangan 27-29 | Markus 13'),
  (58, 'Bilangan 30-31 | Markus 14'),
  (59, 'Bilangan 32-34 | Markus 15'),
  (60, 'Bilangan 35-36'),
  (61, 'Ulangan 1-3 | Markus 16'),
  (62, 'Ulangan 4-5 | Lukas 1'),
  (63, 'Ulangan 6-8'),
  (64, 'Ulangan 9-10 | Lukas 2'),
  (65, 'Ulangan 11-13 | Lukas 3'),
  (66, 'Ulangan 14-15 | Lukas 4'),
  (67, 'Ulangan 16-18'),
  (68, 'Ulangan 19-21 | Lukas 5'),
  (69, 'Ulangan 22-23 | Lukas 6'),
  (70, 'Ulangan 24-26'),
  (71, 'Ulangan 27-28 | Lukas 7'),
  (72, 'Ulangan 29-31 | Lukas 8'),
  (73, 'Ulangan 32-33'),
  (74, 'Ulangan 34; Yosua 1-2 | Lukas 9'),
  (75, 'Yosua 3-4 | Lukas 10'),
  (76, 'Yosua 5-7 | Lukas 11'),
  (77, 'Yosua 8-9'),
  (78, 'Yosua 10-12 | Lukas 12'),
  (79, 'Yosua 13-15 | Lukas 13'),
  (80, 'Yosua 16-17'),
  (81, 'Yosua 18-20 | Lukas 14'),
  (82, 'Yosua 21-22 | Lukas 15'),
  (83, 'Yosua 23-24; Hakim-hakim 1 | Lukas 16'),
  (84, 'Hakim-hakim 2-3'),
  (85, 'Hakim-hakim 4-6 | Lukas 17'),
  (86, 'Hakim-hakim 7-8 | Lukas 18'),
  (87, 'Hakim-hakim 9-11'),
  (88, 'Hakim-hakim 12-13 | Lukas 19'),
  (89, 'Hakim-hakim 14-16 | Lukas 20'),
  (90, 'Hakim-hakim 17-19 | Lukas 21'),
  (91, 'Hakim-hakim 20-21'),
  (92, 'Rut 1-3 | Lukas 22'),
  (93, 'Rut 4; 1 Samuel 1 | Lukas 23'),
  (94, '1 Samuel 2-4'),
  (95, '1 Samuel 5-6 | Lukas 24'),
  (96, '1 Samuel 7-9 | Yohanes 1'),
  (97, '1 Samuel 10-11 | Yohanes 2'),
  (98, '1 Samuel 12-14'),
  (99, '1 Samuel 15-16 | Yohanes 3'),
  (100, '1 Samuel 17-19 | Yohanes 4'),
  (101, '1 Samuel 20-22'),
  (102, '1 Samuel 23-24 | Yohanes 5'),
  (103, '1 Samuel 25-27 | Yohanes 6'),
  (104, '1 Samuel 28-29 | Yohanes 7'),
  (105, '1 Samuel 30-31; 2 Samuel 1'),
  (106, '2 Samuel 2-3 | Yohanes 8'),
  (107, '2 Samuel 4-6 | Yohanes 9'),
  (108, '2 Samuel 7-8'),
  (109, '2 Samuel 9-11 | Yohanes 10'),
  (110, '2 Samuel 12-13 | Yohanes 11'),
  (111, '2 Samuel 14-16 | Yohanes 12'),
  (112, '2 Samuel 17-19'),
  (113, '2 Samuel 20-21 | Yohanes 13'),
  (114, '2 Samuel 22-24 | Yohanes 14'),
  (115, '1 Raja-raja 1-2'),
  (116, '1 Raja-raja 3-5 | Yohanes 15'),
  (117, '1 Raja-raja 6-7 | Yohanes 16'),
  (118, '1 Raja-raja 8-10 | Yohanes 17'),
  (119, '1 Raja-raja 11-12'),
  (120, '1 Raja-raja 13-15 | Yohanes 18'),
  (121, '1 Raja-raja 16-17 | Yohanes 19'),
  (122, '1 Raja-raja 18-20'),
  (123, '1 Raja-raja 21-22; 2 Raja-raja 1 | Yohanes 20'),
  (124, '2 Raja-raja 2-3 | Yohanes 21'),
  (125, '2 Raja-raja 4-6 | Kisah Para Rasul 1'),
  (126, '2 Raja-raja 7-8'),
  (127, '2 Raja-raja 9-11 | Kisah Para Rasul 2'),
  (128, '2 Raja-raja 12-13 | Kisah Para Rasul 3'),
  (129, '2 Raja-raja 14-16'),
  (130, '2 Raja-raja 17-18 | Kisah Para Rasul 4'),
  (131, '2 Raja-raja 19-21 | Kisah Para Rasul 5'),
  (132, '2 Raja-raja 22-23 | Kisah Para Rasul 6'),
  (133, '2 Raja-raja 24-25; 1 Tawarikh 1'),
  (134, '1 Tawarikh 2-4 | Kisah Para Rasul 7'),
  (135, '1 Tawarikh 5-6 | Kisah Para Rasul 8'),
  (136, '1 Tawarikh 7-9'),
  (137, '1 Tawarikh 10-11 | Kisah Para Rasul 9'),
  (138, '1 Tawarikh 12-14 | Kisah Para Rasul 10'),
  (139, '1 Tawarikh 15-16 | Kisah Para Rasul 11'),
  (140, '1 Tawarikh 17-19'),
  (141, '1 Tawarikh 20-21 | Kisah Para Rasul 12'),
  (142, '1 Tawarikh 22-24 | Kisah Para Rasul 13'),
  (143, '1 Tawarikh 25-26'),
  (144, '1 Tawarikh 27-29 | Kisah Para Rasul 14'),
  (145, '2 Tawarikh 1-3 | Kisah Para Rasul 15'),
  (146, '2 Tawarikh 4-5'),
  (147, '2 Tawarikh 6-8 | Kisah Para Rasul 16'),
  (148, '2 Tawarikh 9-10 | Kisah Para Rasul 17'),
  (149, '2 Tawarikh 11-13 | Kisah Para Rasul 18'),
  (150, '2 Tawarikh 14-15'),
  (151, '2 Tawarikh 16-18 | Kisah Para Rasul 19'),
  (152, '2 Tawarikh 19-20 | Kisah Para Rasul 20'),
  (153, '2 Tawarikh 21-23'),
  (154, '2 Tawarikh 24-25 | Kisah Para Rasul 21'),
  (155, '2 Tawarikh 26-28 | Kisah Para Rasul 22'),
  (156, '2 Tawarikh 29-31 | Kisah Para Rasul 23'),
  (157, '2 Tawarikh 32-33'),
  (158, '2 Tawarikh 34-36 | Kisah Para Rasul 24'),
  (159, 'Ezra 1-2 | Kisah Para Rasul 25'),
  (160, 'Ezra 3-5'),
  (161, 'Ezra 6-7 | Kisah Para Rasul 26'),
  (162, 'Ezra 8-10 | Kisah Para Rasul 27'),
  (163, 'Nehemia 1-2 | Kisah Para Rasul 28'),
  (164, 'Nehemia 3-5'),
  (165, 'Nehemia 6-7 | Roma 1'),
  (166, 'Nehemia 8-10 | Roma 2'),
  (167, 'Nehemia 11-13'),
  (168, 'Ester 1-2 | Roma 3'),
  (169, 'Ester 3-5 | Roma 4'),
  (170, 'Ester 6-7 | Roma 5'),
  (171, 'Ester 8-10'),
  (172, 'Ayub 1-2 | Roma 6'),
  (173, 'Ayub 3-5 | Roma 7'),
  (174, 'Ayub 6-7'),
  (175, 'Ayub 8-10 | Roma 8'),
  (176, 'Ayub 11-12 | Roma 9'),
  (177, 'Ayub 13-15 | Roma 10'),
  (178, 'Ayub 16-18'),
  (179, 'Ayub 19-20 | Roma 11'),
  (180, 'Ayub 21-23 | Roma 12'),
  (181, 'Ayub 24-25'),
  (182, 'Ayub 26-28 | Roma 13'),
  (183, 'Ayub 29-30 | Roma 14'),
  (184, 'Ayub 31-33 | Roma 15'),
  (185, 'Ayub 34-35'),
  (186, 'Ayub 36-38 | Roma 16'),
  (187, 'Ayub 39-40 | 1 Korintus 1'),
  (188, 'Ayub 41-42; Mazmur 1'),
  (189, 'Mazmur 2-4 | 1 Korintus 2'),
  (190, 'Mazmur 5-6 | 1 Korintus 3'),
  (191, 'Mazmur 7-9 | 1 Korintus 4'),
  (192, 'Mazmur 10-11'),
  (193, 'Mazmur 12-14 | 1 Korintus 5'),
  (194, 'Mazmur 15-16 | 1 Korintus 6'),
  (195, 'Mazmur 17-19'),
  (196, 'Mazmur 20-21 | 1 Korintus 7'),
  (197, 'Mazmur 22-24 | 1 Korintus 8'),
  (198, 'Mazmur 25-26 | 1 Korintus 9'),
  (199, 'Mazmur 27-29'),
  (200, 'Mazmur 30-32 | 1 Korintus 10'),
  (201, 'Mazmur 33-34 | 1 Korintus 11'),
  (202, 'Mazmur 35-37'),
  (203, 'Mazmur 38-39 | 1 Korintus 12'),
  (204, 'Mazmur 40-42 | 1 Korintus 13'),
  (205, 'Mazmur 43-44 | 1 Korintus 14'),
  (206, 'Mazmur 45-47'),
  (207, 'Mazmur 48-49 | 1 Korintus 15'),
  (208, 'Mazmur 50-52 | 1 Korintus 16'),
  (209, 'Mazmur 53-54'),
  (210, 'Mazmur 55-57 | 2 Korintus 1'),
  (211, 'Mazmur 58-60 | 2 Korintus 2'),
  (212, 'Mazmur 61-62 | 2 Korintus 3'),
  (213, 'Mazmur 63-65'),
  (214, 'Mazmur 66-67 | 2 Korintus 4'),
  (215, 'Mazmur 68-70 | 2 Korintus 5'),
  (216, 'Mazmur 71-72'),
  (217, 'Mazmur 73-75 | 2 Korintus 6'),
  (218, 'Mazmur 76-77 | 2 Korintus 7'),
  (219, 'Mazmur 78-80'),
  (220, 'Mazmur 81-82 | 2 Korintus 8'),
  (221, 'Mazmur 83-85 | 2 Korintus 9'),
  (222, 'Mazmur 86-88 | 2 Korintus 10'),
  (223, 'Mazmur 89-90'),
  (224, 'Mazmur 91-93 | 2 Korintus 11'),
  (225, 'Mazmur 94-95 | 2 Korintus 12'),
  (226, 'Mazmur 96-98'),
  (227, 'Mazmur 99-100 | 2 Korintus 13'),
  (228, 'Mazmur 101-103 | Galatia 1'),
  (229, 'Mazmur 104-105 | Galatia 2'),
  (230, 'Mazmur 106-108'),
  (231, 'Mazmur 109-110 | Galatia 3'),
  (232, 'Mazmur 111-113 | Galatia 4'),
  (233, 'Mazmur 114-116'),
  (234, 'Mazmur 117-118 | Galatia 5'),
  (235, 'Mazmur 119-121 | Galatia 6'),
  (236, 'Mazmur 122-123 | Efesus 1'),
  (237, 'Mazmur 124-126'),
  (238, 'Mazmur 127-128 | Efesus 2'),
  (239, 'Mazmur 129-131 | Efesus 3'),
  (240, 'Mazmur 132-133'),
  (241, 'Mazmur 134-136 | Efesus 4'),
  (242, 'Mazmur 137-138 | Efesus 5'),
  (243, 'Mazmur 139-141 | Efesus 6'),
  (244, 'Mazmur 142-144'),
  (245, 'Mazmur 145-146 | Filipi 1'),
  (246, 'Mazmur 147-149 | Filipi 2'),
  (247, 'Mazmur 150; Amsal 1'),
  (248, 'Amsal 2-4 | Filipi 3'),
  (249, 'Amsal 5-6 | Filipi 4'),
  (250, 'Amsal 7-9 | Kolose 1'),
  (251, 'Amsal 10-11'),
  (252, 'Amsal 12-14 | Kolose 2'),
  (253, 'Amsal 15-16 | Kolose 3'),
  (254, 'Amsal 17-19'),
  (255, 'Amsal 20-22 | Kolose 4'),
  (256, 'Amsal 23-24 | 1 Tesalonika 1'),
  (257, 'Amsal 25-27 | 1 Tesalonika 2'),
  (258, 'Amsal 28-29'),
  (259, 'Amsal 30-31; Pengkhotbah 1 | 1 Tesalonika 3'),
  (260, 'Pengkhotbah 2-3 | 1 Tesalonika 4'),
  (261, 'Pengkhotbah 4-6'),
  (262, 'Pengkhotbah 7-8 | 1 Tesalonika 5'),
  (263, 'Pengkhotbah 9-11 | 2 Tesalonika 1'),
  (264, 'Pengkhotbah 12; Kidung Agung 1 | 2 Tesalonika 2'),
  (265, 'Kidung Agung 2-4'),
  (266, 'Kidung Agung 5-7 | 2 Tesalonika 3'),
  (267, 'Kidung Agung 8; Yesaya 1 | 1 Timotius 1'),
  (268, 'Yesaya 2-4'),
  (269, 'Yesaya 5-6 | 1 Timotius 2'),
  (270, 'Yesaya 7-9 | 1 Timotius 3'),
  (271, 'Yesaya 10-11 | 1 Timotius 4'),
  (272, 'Yesaya 12-14'),
  (273, 'Yesaya 15-16 | 1 Timotius 5'),
  (274, 'Yesaya 17-19 | 1 Timotius 6'),
  (275, 'Yesaya 20-21'),
  (276, 'Yesaya 22-24 | 2 Timotius 1'),
  (277, 'Yesaya 25-27 | 2 Timotius 2'),
  (278, 'Yesaya 28-29 | 2 Timotius 3'),
  (279, 'Yesaya 30-32'),
  (280, 'Yesaya 33-34 | 2 Timotius 4'),
  (281, 'Yesaya 35-37 | Titus 1'),
  (282, 'Yesaya 38-39'),
  (283, 'Yesaya 40-42 | Titus 2'),
  (284, 'Yesaya 43-44 | Titus 3'),
  (285, 'Yesaya 45-47 | Filemon 1'),
  (286, 'Yesaya 48-49'),
  (287, 'Yesaya 50-52 | Ibrani 1'),
  (288, 'Yesaya 53-55 | Ibrani 2'),
  (289, 'Yesaya 56-57'),
  (290, 'Yesaya 58-60 | Ibrani 3'),
  (291, 'Yesaya 61-62 | Ibrani 4'),
  (292, 'Yesaya 63-65'),
  (293, 'Yesaya 66; Yeremia 1 | Ibrani 5'),
  (294, 'Yeremia 2-4 | Ibrani 6'),
  (295, 'Yeremia 5-6 | Ibrani 7'),
  (296, 'Yeremia 7-9'),
  (297, 'Yeremia 10-11 | Ibrani 8'),
  (298, 'Yeremia 12-14 | Ibrani 9'),
  (299, 'Yeremia 15-17'),
  (300, 'Yeremia 18-19 | Ibrani 10'),
  (301, 'Yeremia 20-22 | Ibrani 11'),
  (302, 'Yeremia 23-24 | Ibrani 12'),
  (303, 'Yeremia 25-27'),
  (304, 'Yeremia 28-29 | Ibrani 13'),
  (305, 'Yeremia 30-32 | Yakobus 1'),
  (306, 'Yeremia 33-34'),
  (307, 'Yeremia 35-37 | Yakobus 2'),
  (308, 'Yeremia 38-39 | Yakobus 3'),
  (309, 'Yeremia 40-42 | Yakobus 4'),
  (310, 'Yeremia 43-45'),
  (311, 'Yeremia 46-47 | Yakobus 5'),
  (312, 'Yeremia 48-50 | 1 Petrus 1'),
  (313, 'Yeremia 51-52'),
  (314, 'Ratapan 1-3 | 1 Petrus 2'),
  (315, 'Ratapan 4-5 | 1 Petrus 3'),
  (316, 'Yehezkiel 1-3 | 1 Petrus 4'),
  (317, 'Yehezkiel 4-5'),
  (318, 'Yehezkiel 6-8 | 1 Petrus 5'),
  (319, 'Yehezkiel 9-10 | 2 Petrus 1'),
  (320, 'Yehezkiel 11-13'),
  (321, 'Yehezkiel 14-16 | 2 Petrus 2'),
  (322, 'Yehezkiel 17-18 | 2 Petrus 3'),
  (323, 'Yehezkiel 19-21 | 1 Yohanes 1'),
  (324, 'Yehezkiel 22-23'),
  (325, 'Yehezkiel 24-26 | 1 Yohanes 2'),
  (326, 'Yehezkiel 27-28 | 1 Yohanes 3'),
  (327, 'Yehezkiel 29-31'),
  (328, 'Yehezkiel 32-33 | 1 Yohanes 4'),
  (329, 'Yehezkiel 34-36 | 1 Yohanes 5'),
  (330, 'Yehezkiel 37-38 | 2 Yohanes 1'),
  (331, 'Yehezkiel 39-41'),
  (332, 'Yehezkiel 42-44 | 3 Yohanes 1'),
  (333, 'Yehezkiel 45-46 | Yudas 1'),
  (334, 'Yehezkiel 47-48; Daniel 1'),
  (335, 'Daniel 2-3 | Wahyu 1'),
  (336, 'Daniel 4-6 | Wahyu 2'),
  (337, 'Daniel 7-8 | Wahyu 3'),
  (338, 'Daniel 9-11'),
  (339, 'Daniel 12; Hosea 1 | Wahyu 4'),
  (340, 'Hosea 2-4 | Wahyu 5'),
  (341, 'Hosea 5-6'),
  (342, 'Hosea 7-9 | Wahyu 6'),
  (343, 'Hosea 10-12 | Wahyu 7'),
  (344, 'Hosea 13-14 | Wahyu 8'),
  (345, 'Yoel 1-3'),
  (346, 'Amos 1-2 | Wahyu 9'),
  (347, 'Amos 3-5 | Wahyu 10'),
  (348, 'Amos 6-7'),
  (349, 'Amos 8-9; Obaja 1 | Wahyu 11'),
  (350, 'Yunus 1-2 | Wahyu 12'),
  (351, 'Yunus 3-4; Mikha 1 | Wahyu 13'),
  (352, 'Mikha 2-3'),
  (353, 'Mikha 4-6 | Wahyu 14'),
  (354, 'Mikha 7; Nahum 1-2 | Wahyu 15'),
  (355, 'Nahum 3; Habakuk 1'),
  (356, 'Habakuk 2-3; Zefanya 1 | Wahyu 16'),
  (357, 'Zefanya 2-3 | Wahyu 17'),
  (358, 'Hagai 1-2; Zakharia 1 | Wahyu 18'),
  (359, 'Zakharia 2-3'),
  (360, 'Zakharia 4-6 | Wahyu 19'),
  (361, 'Zakharia 7-8 | Wahyu 20'),
  (362, 'Zakharia 9-11'),
  (363, 'Zakharia 12-13 | Wahyu 21'),
  (364, 'Zakharia 14; Maleakhi 1-2 | Wahyu 22'),
  (365, 'Maleakhi 3-4');
