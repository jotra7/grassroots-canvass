-- ========================================
-- GRASSROOTS CANVASS - INITIAL SCHEMA
-- Complete database setup for voter canvassing app
-- ========================================

-- ========================================
-- HELPER FUNCTIONS
-- ========================================

-- Check if current user is admin (bypasses RLS)
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS BOOLEAN
LANGUAGE sql
SECURITY DEFINER
STABLE
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.user_profiles
    WHERE id = auth.uid() AND role = 'admin'
  );
$$;

-- Check if current user is admin or team_lead
CREATE OR REPLACE FUNCTION public.is_admin_or_team_lead()
RETURNS BOOLEAN
LANGUAGE sql
SECURITY DEFINER
STABLE
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.user_profiles
    WHERE id = auth.uid() AND role IN ('admin', 'team_lead')
  );
$$;

-- ========================================
-- USER PROFILES TABLE
-- ========================================
-- Roles: admin, team_lead, canvasser, pending

CREATE TABLE IF NOT EXISTS public.user_profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email TEXT NOT NULL,
  full_name TEXT,
  role TEXT NOT NULL DEFAULT 'pending' CHECK (role IN ('admin', 'team_lead', 'canvasser', 'pending')),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.user_profiles ENABLE ROW LEVEL SECURITY;

-- All authenticated users can read profiles
CREATE POLICY "Authenticated users can read all profiles"
  ON public.user_profiles FOR SELECT
  TO authenticated
  USING (true);

-- Users can create their own profile
CREATE POLICY "Users can create their own profile"
  ON public.user_profiles FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = id);

-- Users can update own profile, admins can update any
CREATE POLICY "Users can update own or admin updates any"
  ON public.user_profiles FOR UPDATE
  TO authenticated
  USING (auth.uid() = id OR public.is_admin());

-- Users can delete own profile, admins can delete any
CREATE POLICY "Users can delete own or admin deletes any"
  ON public.user_profiles FOR DELETE
  TO authenticated
  USING (auth.uid() = id OR public.is_admin());

-- ========================================
-- VOTERS TABLE
-- ========================================

CREATE TABLE IF NOT EXISTS public.voters (
  unique_id TEXT PRIMARY KEY,
  visitor_id TEXT,
  -- Contact info
  owner_name TEXT,
  first_name TEXT,
  middle_name TEXT,
  last_name TEXT,
  phone TEXT,
  cell_phone TEXT,
  -- Address
  street_num TEXT,
  street_dir TEXT,
  street_name TEXT,
  city TEXT,
  zip TEXT,
  residence_address TEXT,
  -- Location
  latitude DOUBLE PRECISION,
  longitude DOUBLE PRECISION,
  -- Voter data
  voter_id TEXT,
  party TEXT,
  voter_age INTEGER,
  gender TEXT,
  registration_date TEXT,
  is_mail_voter BOOLEAN DEFAULT false,
  lives_elsewhere BOOLEAN DEFAULT false,
  -- Mailing address
  mail_address TEXT,
  mail_city TEXT,
  mail_state TEXT,
  mail_zip TEXT,
  -- Canvass data
  canvass_result TEXT,
  canvass_notes TEXT,
  canvass_date TIMESTAMPTZ,
  canvassed_by UUID REFERENCES public.user_profiles(id),
  -- Contact tracking
  contact_attempts INTEGER DEFAULT 0,
  last_contact_attempt TIMESTAMPTZ,
  last_contact_method TEXT,
  last_contact_date TIMESTAMPTZ,
  voicemail_left BOOLEAN DEFAULT false,
  -- SMS tracking
  last_sms_response TEXT,
  last_sms_response_date TIMESTAMPTZ,
  -- Metadata
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_voters_city ON public.voters(city);
CREATE INDEX IF NOT EXISTS idx_voters_zip ON public.voters(zip);
CREATE INDEX IF NOT EXISTS idx_voters_party ON public.voters(party);
CREATE INDEX IF NOT EXISTS idx_voters_canvass_result ON public.voters(canvass_result);
CREATE INDEX IF NOT EXISTS idx_voters_location ON public.voters(latitude, longitude);

ALTER TABLE public.voters ENABLE ROW LEVEL SECURITY;

-- All authenticated users can read voters
CREATE POLICY "Authenticated users can read voters"
  ON public.voters FOR SELECT
  TO authenticated
  USING (true);

-- All authenticated users can update voters (for canvass results)
CREATE POLICY "Authenticated users can update voters"
  ON public.voters FOR UPDATE
  TO authenticated
  USING (true)
  WITH CHECK (true);

-- INSERT/DELETE only via service_role (admin imports)

-- ========================================
-- CUT LISTS TABLE
-- ========================================

CREATE TABLE IF NOT EXISTS public.cut_lists (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  description TEXT,
  boundary_polygon JSONB,
  voter_count INTEGER DEFAULT 0,
  created_by UUID REFERENCES public.user_profiles(id),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.cut_lists ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Authenticated users can read cut lists"
  ON public.cut_lists FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Admins and team leads can insert cut lists"
  ON public.cut_lists FOR INSERT
  TO authenticated
  WITH CHECK (public.is_admin_or_team_lead());

CREATE POLICY "Admins and team leads can update cut lists"
  ON public.cut_lists FOR UPDATE
  TO authenticated
  USING (public.is_admin_or_team_lead());

CREATE POLICY "Admins and team leads can delete cut lists"
  ON public.cut_lists FOR DELETE
  TO authenticated
  USING (public.is_admin_or_team_lead());

-- ========================================
-- CUT LIST VOTERS (many-to-many)
-- ========================================

CREATE TABLE IF NOT EXISTS public.cut_list_voters (
  cut_list_id UUID NOT NULL REFERENCES public.cut_lists(id) ON DELETE CASCADE,
  voter_unique_id TEXT NOT NULL REFERENCES public.voters(unique_id) ON DELETE CASCADE,
  PRIMARY KEY (cut_list_id, voter_unique_id)
);

CREATE INDEX IF NOT EXISTS idx_cut_list_voters_voter ON public.cut_list_voters(voter_unique_id);

ALTER TABLE public.cut_list_voters ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Authenticated users can read cut list voters"
  ON public.cut_list_voters FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Admins and team leads can insert cut list voters"
  ON public.cut_list_voters FOR INSERT
  TO authenticated
  WITH CHECK (public.is_admin_or_team_lead());

CREATE POLICY "Admins and team leads can delete cut list voters"
  ON public.cut_list_voters FOR DELETE
  TO authenticated
  USING (public.is_admin_or_team_lead());

-- ========================================
-- CUT LIST ASSIGNMENTS (user -> cut list)
-- ========================================

CREATE TABLE IF NOT EXISTS public.cut_list_assignments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  cut_list_id UUID NOT NULL REFERENCES public.cut_lists(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  assigned_by UUID REFERENCES public.user_profiles(id),
  assigned_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(cut_list_id, user_id)
);

CREATE INDEX IF NOT EXISTS idx_cut_list_assignments_user ON public.cut_list_assignments(user_id);

ALTER TABLE public.cut_list_assignments ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Authenticated users can read cut list assignments"
  ON public.cut_list_assignments FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Admins and team leads can insert cut list assignments"
  ON public.cut_list_assignments FOR INSERT
  TO authenticated
  WITH CHECK (public.is_admin_or_team_lead());

CREATE POLICY "Admins and team leads can delete cut list assignments"
  ON public.cut_list_assignments FOR DELETE
  TO authenticated
  USING (public.is_admin_or_team_lead());

-- ========================================
-- CONTACT HISTORY TABLE
-- ========================================

CREATE TABLE IF NOT EXISTS public.contact_history (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  unique_id TEXT NOT NULL REFERENCES public.voters(unique_id) ON DELETE CASCADE,
  method TEXT NOT NULL CHECK (method IN ('call', 'text', 'door', 'email')),
  result TEXT NOT NULL,
  notes TEXT,
  contacted_at TIMESTAMPTZ DEFAULT NOW(),
  contacted_by UUID REFERENCES public.user_profiles(id)
);

CREATE INDEX IF NOT EXISTS idx_contact_history_voter ON public.contact_history(unique_id);
CREATE INDEX IF NOT EXISTS idx_contact_history_date ON public.contact_history(contacted_at);

ALTER TABLE public.contact_history ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Authenticated users can read contact history"
  ON public.contact_history FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Authenticated users can insert contact history"
  ON public.contact_history FOR INSERT
  TO authenticated
  WITH CHECK (true);

-- ========================================
-- CANDIDATES TABLE
-- ========================================

CREATE TABLE IF NOT EXISTS public.candidates (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  district TEXT NOT NULL,
  position TEXT NOT NULL,
  organization TEXT,
  website TEXT,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_candidates_district ON public.candidates(district);
CREATE INDEX IF NOT EXISTS idx_candidates_active ON public.candidates(is_active) WHERE is_active = true;

ALTER TABLE public.candidates ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Authenticated users can read candidates"
  ON public.candidates FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Admins and team leads can insert candidates"
  ON public.candidates FOR INSERT
  TO authenticated
  WITH CHECK (public.is_admin_or_team_lead());

CREATE POLICY "Admins and team leads can update candidates"
  ON public.candidates FOR UPDATE
  TO authenticated
  USING (public.is_admin_or_team_lead());

CREATE POLICY "Admins and team leads can delete candidates"
  ON public.candidates FOR DELETE
  TO authenticated
  USING (public.is_admin_or_team_lead());

-- ========================================
-- TEXT TEMPLATES TABLE
-- ========================================

CREATE TABLE IF NOT EXISTS public.text_templates (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  candidate_id UUID REFERENCES public.candidates(id) ON DELETE SET NULL,
  district TEXT NOT NULL,
  position TEXT,
  category TEXT NOT NULL CHECK (category IN ('introduction', 'follow_up', 'reminder', 'thank_you')),
  name TEXT NOT NULL,
  message TEXT NOT NULL,
  icon_name TEXT NOT NULL DEFAULT 'message',
  is_active BOOLEAN DEFAULT true,
  display_order INT DEFAULT 0,
  created_by UUID REFERENCES public.user_profiles(id),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_text_templates_district ON public.text_templates(district);
CREATE INDEX IF NOT EXISTS idx_text_templates_candidate ON public.text_templates(candidate_id);
CREATE INDEX IF NOT EXISTS idx_text_templates_category ON public.text_templates(category);
CREATE INDEX IF NOT EXISTS idx_text_templates_active ON public.text_templates(is_active) WHERE is_active = true;

ALTER TABLE public.text_templates ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Authenticated users can read active templates"
  ON public.text_templates FOR SELECT
  TO authenticated
  USING (is_active = true);

CREATE POLICY "Admins and team leads can read all templates"
  ON public.text_templates FOR SELECT
  TO authenticated
  USING (public.is_admin_or_team_lead());

CREATE POLICY "Admins and team leads can insert templates"
  ON public.text_templates FOR INSERT
  TO authenticated
  WITH CHECK (public.is_admin_or_team_lead());

CREATE POLICY "Admins and team leads can update templates"
  ON public.text_templates FOR UPDATE
  TO authenticated
  USING (public.is_admin_or_team_lead());

CREATE POLICY "Admins and team leads can delete templates"
  ON public.text_templates FOR DELETE
  TO authenticated
  USING (public.is_admin_or_team_lead());

-- ========================================
-- TEXT TEMPLATE ASSIGNMENTS
-- ========================================

-- User assignments
CREATE TABLE IF NOT EXISTS public.text_template_user_assignments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  template_id UUID NOT NULL REFERENCES public.text_templates(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  assigned_by UUID REFERENCES public.user_profiles(id),
  assigned_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(template_id, user_id)
);

CREATE INDEX IF NOT EXISTS idx_template_user_assignments_user ON public.text_template_user_assignments(user_id);

ALTER TABLE public.text_template_user_assignments ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Authenticated users can read template user assignments"
  ON public.text_template_user_assignments FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Admins and team leads can insert template user assignments"
  ON public.text_template_user_assignments FOR INSERT
  TO authenticated
  WITH CHECK (public.is_admin_or_team_lead());

CREATE POLICY "Admins and team leads can delete template user assignments"
  ON public.text_template_user_assignments FOR DELETE
  TO authenticated
  USING (public.is_admin_or_team_lead());

-- Cut list assignments
CREATE TABLE IF NOT EXISTS public.text_template_cut_list_assignments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  template_id UUID NOT NULL REFERENCES public.text_templates(id) ON DELETE CASCADE,
  cut_list_id UUID NOT NULL REFERENCES public.cut_lists(id) ON DELETE CASCADE,
  assigned_by UUID REFERENCES public.user_profiles(id),
  assigned_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(template_id, cut_list_id)
);

CREATE INDEX IF NOT EXISTS idx_template_cutlist_assignments_cutlist ON public.text_template_cut_list_assignments(cut_list_id);

ALTER TABLE public.text_template_cut_list_assignments ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Authenticated users can read template cut list assignments"
  ON public.text_template_cut_list_assignments FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Admins and team leads can insert template cut list assignments"
  ON public.text_template_cut_list_assignments FOR INSERT
  TO authenticated
  WITH CHECK (public.is_admin_or_team_lead());

CREATE POLICY "Admins and team leads can delete template cut list assignments"
  ON public.text_template_cut_list_assignments FOR DELETE
  TO authenticated
  USING (public.is_admin_or_team_lead());

-- ========================================
-- NOTES
-- ========================================
-- Template placeholders:
--   {name} - Voter's first name
--   {full_name} - Voter's full name
--   {address} - Voter's address
--
-- Template categories:
--   'introduction' - First contact messages
--   'follow_up' - Messages after initial contact
--   'reminder' - Voting reminders (ballot, election day)
--   'thank_you' - Thank you messages for supporters
--
-- User roles:
--   'admin' - Full access to everything
--   'team_lead' - Can manage cut lists and see all data
--   'canvasser' - Can only see assigned cut lists
--   'pending' - Awaiting approval
