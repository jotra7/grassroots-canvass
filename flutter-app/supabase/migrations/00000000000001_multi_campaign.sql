-- ========================================
-- MULTI-CAMPAIGN SUPPORT
-- Adds campaign isolation for multi-tenant usage
-- ========================================

-- ========================================
-- CAMPAIGNS TABLE
-- ========================================

CREATE TABLE IF NOT EXISTS public.campaigns (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  description TEXT,
  -- Branding
  organization_name TEXT,
  candidate_name TEXT,
  election_date DATE,
  district TEXT,
  -- Map defaults
  default_latitude DOUBLE PRECISION DEFAULT 33.4484,
  default_longitude DOUBLE PRECISION DEFAULT -112.0740,
  default_zoom INTEGER DEFAULT 12,
  -- Theme colors (hex)
  primary_color TEXT DEFAULT '#2563eb',
  secondary_color TEXT DEFAULT '#16a34a',
  -- Status
  is_active BOOLEAN DEFAULT true,
  created_by UUID REFERENCES public.user_profiles(id),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_campaigns_active ON public.campaigns(is_active) WHERE is_active = true;

ALTER TABLE public.campaigns ENABLE ROW LEVEL SECURITY;

-- ========================================
-- CAMPAIGN MEMBERS (user <-> campaign)
-- ========================================

CREATE TABLE IF NOT EXISTS public.campaign_members (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  campaign_id UUID NOT NULL REFERENCES public.campaigns(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  role TEXT NOT NULL DEFAULT 'canvasser' CHECK (role IN ('admin', 'team_lead', 'canvasser')),
  invited_by UUID REFERENCES public.user_profiles(id),
  joined_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(campaign_id, user_id)
);

CREATE INDEX IF NOT EXISTS idx_campaign_members_user ON public.campaign_members(user_id);
CREATE INDEX IF NOT EXISTS idx_campaign_members_campaign ON public.campaign_members(campaign_id);

ALTER TABLE public.campaign_members ENABLE ROW LEVEL SECURITY;

-- ========================================
-- HELPER FUNCTIONS FOR CAMPAIGN ACCESS
-- ========================================

-- Check if user is member of a campaign
CREATE OR REPLACE FUNCTION public.is_campaign_member(campaign_uuid UUID)
RETURNS BOOLEAN
LANGUAGE sql
SECURITY DEFINER
STABLE
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.campaign_members
    WHERE campaign_id = campaign_uuid AND user_id = auth.uid()
  );
$$;

-- Check if user is admin of a campaign
CREATE OR REPLACE FUNCTION public.is_campaign_admin(campaign_uuid UUID)
RETURNS BOOLEAN
LANGUAGE sql
SECURITY DEFINER
STABLE
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.campaign_members
    WHERE campaign_id = campaign_uuid
      AND user_id = auth.uid()
      AND role = 'admin'
  );
$$;

-- Check if user is admin or team_lead of a campaign
CREATE OR REPLACE FUNCTION public.is_campaign_admin_or_lead(campaign_uuid UUID)
RETURNS BOOLEAN
LANGUAGE sql
SECURITY DEFINER
STABLE
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.campaign_members
    WHERE campaign_id = campaign_uuid
      AND user_id = auth.uid()
      AND role IN ('admin', 'team_lead')
  );
$$;

-- Get user's campaigns
CREATE OR REPLACE FUNCTION public.user_campaign_ids()
RETURNS SETOF UUID
LANGUAGE sql
SECURITY DEFINER
STABLE
SET search_path = public
AS $$
  SELECT campaign_id FROM public.campaign_members
  WHERE user_id = auth.uid();
$$;

-- ========================================
-- ADD campaign_id TO EXISTING TABLES
-- ========================================

-- Add campaign_id to voters
ALTER TABLE public.voters
  ADD COLUMN IF NOT EXISTS campaign_id UUID REFERENCES public.campaigns(id) ON DELETE CASCADE;

CREATE INDEX IF NOT EXISTS idx_voters_campaign ON public.voters(campaign_id);

-- Add campaign_id to cut_lists
ALTER TABLE public.cut_lists
  ADD COLUMN IF NOT EXISTS campaign_id UUID REFERENCES public.campaigns(id) ON DELETE CASCADE;

CREATE INDEX IF NOT EXISTS idx_cut_lists_campaign ON public.cut_lists(campaign_id);

-- Add campaign_id to text_templates
ALTER TABLE public.text_templates
  ADD COLUMN IF NOT EXISTS campaign_id UUID REFERENCES public.campaigns(id) ON DELETE CASCADE;

CREATE INDEX IF NOT EXISTS idx_text_templates_campaign ON public.text_templates(campaign_id);

-- Add campaign_id to candidates
ALTER TABLE public.candidates
  ADD COLUMN IF NOT EXISTS campaign_id UUID REFERENCES public.campaigns(id) ON DELETE CASCADE;

CREATE INDEX IF NOT EXISTS idx_candidates_campaign ON public.candidates(campaign_id);

-- ========================================
-- CAMPAIGN RLS POLICIES
-- ========================================

-- Users can see campaigns they're members of
CREATE POLICY "Users can read their campaigns"
  ON public.campaigns FOR SELECT
  TO authenticated
  USING (public.is_campaign_member(id) OR public.is_admin());

-- Campaign admins can update their campaigns
CREATE POLICY "Campaign admins can update campaigns"
  ON public.campaigns FOR UPDATE
  TO authenticated
  USING (public.is_campaign_admin(id) OR public.is_admin());

-- Only system admins can create campaigns
CREATE POLICY "Admins can create campaigns"
  ON public.campaigns FOR INSERT
  TO authenticated
  WITH CHECK (public.is_admin());

-- Campaign admins can delete their campaigns
CREATE POLICY "Campaign admins can delete campaigns"
  ON public.campaigns FOR DELETE
  TO authenticated
  USING (public.is_campaign_admin(id) OR public.is_admin());

-- ========================================
-- CAMPAIGN MEMBERS RLS POLICIES
-- ========================================

-- Users can see members of campaigns they belong to
CREATE POLICY "Users can read campaign members"
  ON public.campaign_members FOR SELECT
  TO authenticated
  USING (public.is_campaign_member(campaign_id) OR public.is_admin());

-- Campaign admins can add members
CREATE POLICY "Campaign admins can add members"
  ON public.campaign_members FOR INSERT
  TO authenticated
  WITH CHECK (public.is_campaign_admin(campaign_id) OR public.is_admin());

-- Campaign admins can update member roles
CREATE POLICY "Campaign admins can update members"
  ON public.campaign_members FOR UPDATE
  TO authenticated
  USING (public.is_campaign_admin(campaign_id) OR public.is_admin());

-- Campaign admins can remove members (or users can remove themselves)
CREATE POLICY "Campaign admins or self can delete members"
  ON public.campaign_members FOR DELETE
  TO authenticated
  USING (
    public.is_campaign_admin(campaign_id)
    OR public.is_admin()
    OR user_id = auth.uid()
  );

-- ========================================
-- UPDATE EXISTING RLS POLICIES FOR CAMPAIGN SCOPE
-- ========================================

-- Note: These policies work alongside existing ones.
-- For new deployments, the existing "all authenticated" policies
-- will still work. For multi-campaign setups, admins should
-- ensure all data has campaign_id set, then these policies
-- provide proper isolation.

-- Additional voter policy for campaign isolation
CREATE POLICY "Users can read voters in their campaigns"
  ON public.voters FOR SELECT
  TO authenticated
  USING (
    campaign_id IS NULL  -- Legacy data without campaign
    OR campaign_id IN (SELECT public.user_campaign_ids())
    OR public.is_admin()
  );

-- Additional cut_lists policy for campaign isolation
CREATE POLICY "Users can read cut lists in their campaigns"
  ON public.cut_lists FOR SELECT
  TO authenticated
  USING (
    campaign_id IS NULL
    OR campaign_id IN (SELECT public.user_campaign_ids())
    OR public.is_admin()
  );

-- Additional text_templates policy for campaign isolation
CREATE POLICY "Users can read templates in their campaigns"
  ON public.text_templates FOR SELECT
  TO authenticated
  USING (
    campaign_id IS NULL
    OR campaign_id IN (SELECT public.user_campaign_ids())
    OR public.is_admin()
  );

-- Additional candidates policy for campaign isolation
CREATE POLICY "Users can read candidates in their campaigns"
  ON public.candidates FOR SELECT
  TO authenticated
  USING (
    campaign_id IS NULL
    OR campaign_id IN (SELECT public.user_campaign_ids())
    OR public.is_admin()
  );

-- ========================================
-- CALL SCRIPTS TABLE
-- ========================================

CREATE TABLE IF NOT EXISTS public.call_scripts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  campaign_id UUID REFERENCES public.campaigns(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  section TEXT NOT NULL CHECK (section IN ('greeting', 'introduction', 'issues', 'ask', 'objections', 'closing')),
  content TEXT NOT NULL,
  display_order INT DEFAULT 0,
  is_active BOOLEAN DEFAULT true,
  created_by UUID REFERENCES public.user_profiles(id),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_call_scripts_campaign ON public.call_scripts(campaign_id);
CREATE INDEX IF NOT EXISTS idx_call_scripts_section ON public.call_scripts(section);

ALTER TABLE public.call_scripts ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can read call scripts in their campaigns"
  ON public.call_scripts FOR SELECT
  TO authenticated
  USING (
    campaign_id IS NULL
    OR campaign_id IN (SELECT public.user_campaign_ids())
    OR public.is_admin()
  );

CREATE POLICY "Campaign admins can manage call scripts"
  ON public.call_scripts FOR ALL
  TO authenticated
  USING (
    public.is_campaign_admin_or_lead(campaign_id)
    OR public.is_admin()
  );

-- ========================================
-- USER ACTIVE CAMPAIGN (which campaign user is currently viewing)
-- ========================================

ALTER TABLE public.user_profiles
  ADD COLUMN IF NOT EXISTS active_campaign_id UUID REFERENCES public.campaigns(id) ON DELETE SET NULL;

-- ========================================
-- NOTES
-- ========================================
--
-- Multi-campaign setup:
-- 1. System admin creates campaigns
-- 2. System admin adds first campaign admin
-- 3. Campaign admins invite team members
-- 4. All data (voters, cut lists, templates) is scoped to campaigns
--
-- For single-campaign deployments:
-- - Leave campaign_id as NULL on all records
-- - Existing RLS policies continue to work
-- - No changes needed to app behavior
--
-- Campaign member roles:
--   'admin' - Full control of campaign (settings, members, data)
--   'team_lead' - Can manage territories, see all data
--   'canvasser' - Can only see assigned territories
