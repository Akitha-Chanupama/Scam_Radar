-- ============================================================
-- SCAM RADAR — Supabase Database Schema
-- Run this SQL in your Supabase SQL Editor (Dashboard → SQL)
-- ============================================================

-- 1. PROFILES TABLE (extends Supabase Auth users)
CREATE TABLE IF NOT EXISTS profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  name TEXT NOT NULL DEFAULT '',
  email TEXT NOT NULL DEFAULT '',
  avatar_url TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can view profiles"
  ON profiles FOR SELECT
  USING (true);

CREATE POLICY "Users can update own profile"
  ON profiles FOR UPDATE
  USING (auth.uid() = id);

CREATE POLICY "Users can insert own profile"
  ON profiles FOR INSERT
  WITH CHECK (auth.uid() = id);

-- 2. SCAM MESSAGES TABLE
CREATE TABLE IF NOT EXISTS scam_messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  message_text TEXT NOT NULL,
  scam_score INT NOT NULL DEFAULT 0 CHECK (scam_score >= 0 AND scam_score <= 100),
  reasons TEXT[] DEFAULT '{}',
  is_reported BOOLEAN NOT NULL DEFAULT false,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE scam_messages ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can view scam messages"
  ON scam_messages FOR SELECT
  USING (true);

CREATE POLICY "Authenticated users can insert scam messages"
  ON scam_messages FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own messages"
  ON scam_messages FOR UPDATE
  USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own messages"
  ON scam_messages FOR DELETE
  USING (auth.uid() = user_id);

-- 3. SCAM NUMBERS TABLE
CREATE TABLE IF NOT EXISTS scam_numbers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  phone_number TEXT NOT NULL,
  scam_type TEXT NOT NULL DEFAULT 'other',
  reported_by UUID REFERENCES profiles(id) ON DELETE SET NULL,
  reports_count INT NOT NULL DEFAULT 1,
  region TEXT,
  latitude DOUBLE PRECISION,
  longitude DOUBLE PRECISION,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT unique_phone_number UNIQUE (phone_number)
);

ALTER TABLE scam_numbers ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can view scam numbers"
  ON scam_numbers FOR SELECT
  USING (true);

CREATE POLICY "Authenticated users can insert scam numbers"
  ON scam_numbers FOR INSERT
  WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "Authenticated users can update scam numbers"
  ON scam_numbers FOR UPDATE
  USING (auth.role() = 'authenticated');

-- 4. COMMUNITY REPORTS TABLE
CREATE TABLE IF NOT EXISTS community_reports (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  reporter_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  report_type TEXT NOT NULL CHECK (report_type IN ('message', 'number')),
  scam_message_id UUID REFERENCES scam_messages(id) ON DELETE SET NULL,
  scam_number_id UUID REFERENCES scam_numbers(id) ON DELETE SET NULL,
  description TEXT DEFAULT '',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE community_reports ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can view community reports"
  ON community_reports FOR SELECT
  USING (true);

CREATE POLICY "Authenticated users can insert reports"
  ON community_reports FOR INSERT
  WITH CHECK (auth.uid() = reporter_id);

CREATE POLICY "Users can delete own reports"
  ON community_reports FOR DELETE
  USING (auth.uid() = reporter_id);

-- 5. INDEXES for performance
CREATE INDEX IF NOT EXISTS idx_scam_messages_user_id ON scam_messages(user_id);
CREATE INDEX IF NOT EXISTS idx_scam_messages_created_at ON scam_messages(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_scam_numbers_phone ON scam_numbers(phone_number);
CREATE INDEX IF NOT EXISTS idx_scam_numbers_region ON scam_numbers(region);
CREATE INDEX IF NOT EXISTS idx_community_reports_created_at ON community_reports(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_community_reports_reporter ON community_reports(reporter_id);

-- 6. FUNCTION: Auto-create profile on user sign up
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO profiles (id, name, email, created_at)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data ->> 'name', ''),
    COALESCE(NEW.email, ''),
    now()
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger: fires after a new auth user is created
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION handle_new_user();

-- 7. FUNCTION: Report a scam number (upsert — insert or increment)
CREATE OR REPLACE FUNCTION report_scam_number(
  p_phone_number TEXT,
  p_scam_type TEXT,
  p_reported_by UUID,
  p_region TEXT DEFAULT NULL,
  p_latitude DOUBLE PRECISION DEFAULT NULL,
  p_longitude DOUBLE PRECISION DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
  v_id UUID;
BEGIN
  INSERT INTO scam_numbers (phone_number, scam_type, reported_by, region, latitude, longitude)
  VALUES (p_phone_number, p_scam_type, p_reported_by, p_region, p_latitude, p_longitude)
  ON CONFLICT (phone_number) DO UPDATE
    SET reports_count = scam_numbers.reports_count + 1
  RETURNING id INTO v_id;

  RETURN v_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 8. FUNCTION: Get scam statistics
CREATE OR REPLACE FUNCTION get_scam_stats()
RETURNS JSON AS $$
DECLARE
  result JSON;
BEGIN
  SELECT json_build_object(
    'total_messages_analyzed', (SELECT COUNT(*) FROM scam_messages),
    'total_numbers_reported', (SELECT COUNT(*) FROM scam_numbers),
    'total_community_reports', (SELECT COUNT(*) FROM community_reports),
    'high_risk_messages',     (SELECT COUNT(*) FROM scam_messages WHERE scam_score > 60)
  ) INTO result;

  RETURN result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 9. ENABLE REALTIME on tables
ALTER PUBLICATION supabase_realtime ADD TABLE community_reports;
ALTER PUBLICATION supabase_realtime ADD TABLE scam_numbers;

-- 10. STORAGE BUCKET for screenshots (run in Dashboard → Storage if SQL doesn't work)
-- INSERT INTO storage.buckets (id, name, public) VALUES ('screenshots', 'screenshots', true);

-- ============================================================
-- SETUP INSTRUCTIONS:
-- 1. Go to https://supabase.com/dashboard and create a new project
-- 2. Go to SQL Editor in your project dashboard
-- 3. Paste this entire SQL and click "Run"
-- 4. Go to Authentication → Providers → Enable Email/Password
-- 5. Go to Storage → Create bucket "screenshots" (public)
-- 6. Copy your Project URL and anon key from Settings → API
-- 7. Paste them into lib/config/supabase_config.dart
-- ============================================================
