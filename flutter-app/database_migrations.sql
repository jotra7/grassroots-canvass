-- Database migrations for new Flutter app features
-- Run these in the Supabase SQL Editor

-- ================================================================
-- 1. User Devices table (for push notifications)
-- ================================================================
CREATE TABLE IF NOT EXISTS user_devices (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES user_profiles(id) ON DELETE CASCADE NOT NULL,
  fcm_token TEXT NOT NULL,
  device_type TEXT CHECK (device_type IN ('android', 'ios')),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, fcm_token)
);

-- Enable RLS
ALTER TABLE user_devices ENABLE ROW LEVEL SECURITY;

-- Users can manage their own devices
CREATE POLICY "Users can manage own devices" ON user_devices
  FOR ALL USING (auth.uid() = user_id);

-- ================================================================
-- 2. Callback Reminders table
-- ================================================================
CREATE TABLE IF NOT EXISTS callback_reminders (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES user_profiles(id) ON DELETE CASCADE NOT NULL,
  voter_unique_id TEXT NOT NULL,
  reminder_at TIMESTAMPTZ NOT NULL,
  sent BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE callback_reminders ENABLE ROW LEVEL SECURITY;

-- Users can manage their own reminders
CREATE POLICY "Users can manage own reminders" ON callback_reminders
  FOR ALL USING (auth.uid() = user_id);

-- Index for finding pending reminders
CREATE INDEX idx_callback_reminders_pending
  ON callback_reminders (reminder_at)
  WHERE sent = FALSE;

-- ================================================================
-- 3. Voice Notes table
-- ================================================================
CREATE TABLE IF NOT EXISTS voice_notes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  contact_history_id UUID REFERENCES contact_history(id) ON DELETE CASCADE,
  voter_unique_id TEXT NOT NULL,
  audio_url TEXT NOT NULL,
  duration_seconds INTEGER,
  transcription TEXT,
  recorded_by UUID REFERENCES user_profiles(id) NOT NULL,
  recorded_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE voice_notes ENABLE ROW LEVEL SECURITY;

-- Users can view all voice notes for voters they have access to
CREATE POLICY "Users can view voice notes" ON voice_notes
  FOR SELECT USING (true);

-- Users can insert their own voice notes
CREATE POLICY "Users can insert own voice notes" ON voice_notes
  FOR INSERT WITH CHECK (auth.uid() = recorded_by);

-- Users can delete their own voice notes
CREATE POLICY "Users can delete own voice notes" ON voice_notes
  FOR DELETE USING (auth.uid() = recorded_by);

-- Index for finding voice notes by voter
CREATE INDEX idx_voice_notes_voter ON voice_notes (voter_unique_id);

-- ================================================================
-- 4. Create voice-notes storage bucket
-- ================================================================
-- Run this in Supabase Dashboard -> Storage -> New Bucket
-- Or use the following if you have admin access:

INSERT INTO storage.buckets (id, name, public)
VALUES ('voice-notes', 'voice-notes', true)
ON CONFLICT (id) DO NOTHING;

-- Storage policy for voice notes bucket
CREATE POLICY "Anyone can view voice notes" ON storage.objects
  FOR SELECT USING (bucket_id = 'voice-notes');

CREATE POLICY "Authenticated users can upload voice notes" ON storage.objects
  FOR INSERT WITH CHECK (
    bucket_id = 'voice-notes'
    AND auth.role() = 'authenticated'
  );

CREATE POLICY "Users can delete own voice notes" ON storage.objects
  FOR DELETE USING (
    bucket_id = 'voice-notes'
    AND auth.uid()::text = (storage.foldername(name))[1]
  );
