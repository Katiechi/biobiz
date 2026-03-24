-- ============================================
-- BioBiz Initial Schema Migration
-- Source: _bmad-output/technical-architecture-biobiz/3-database-schema.md
-- ============================================

-- ============================================
-- USERS & AUTH
-- ============================================

CREATE TABLE public.profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  first_name TEXT NOT NULL,
  last_name TEXT,
  email TEXT,
  phone TEXT,
  avatar_url TEXT,
  onboarding_completed BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- CARDS
-- ============================================

CREATE TABLE public.cards (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  slug TEXT UNIQUE NOT NULL,
  card_name TEXT DEFAULT 'My Card',

  -- Personal Details
  first_name TEXT NOT NULL,
  last_name TEXT,
  middle_name TEXT,
  prefix TEXT,
  suffix TEXT,
  pronoun TEXT,
  preferred_name TEXT,
  maiden_name TEXT,

  -- Professional Details
  job_title TEXT,
  department TEXT,
  company TEXT,
  company_website TEXT,
  headline TEXT,

  -- Images
  profile_image_url TEXT,
  logo_url TEXT,
  cover_image_url TEXT,
  image_layout TEXT DEFAULT 'default',

  -- Appearance
  card_color TEXT DEFAULT '#000000'
    CHECK (card_color ~ '^#[0-9a-fA-F]{6}$'),
  custom_color BOOLEAN DEFAULT FALSE,

  -- QR Code
  qr_code_url TEXT,
  qr_logo_enabled BOOLEAN DEFAULT FALSE,

  -- Settings
  remove_branding BOOLEAN DEFAULT FALSE,
  is_active BOOLEAN DEFAULT TRUE,
  location_tagging_enabled BOOLEAN DEFAULT FALSE,

  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_cards_user_id ON public.cards(user_id);
CREATE INDEX idx_cards_slug ON public.cards(slug);

-- ============================================
-- CARD EVENTS (analytics)
-- ============================================

CREATE TABLE public.card_events (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  card_id UUID NOT NULL REFERENCES public.cards(id) ON DELETE CASCADE,
  event_type TEXT NOT NULL CHECK (event_type IN ('view', 'share', 'save_contact', 'exchange')),
  metadata JSONB,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_card_events_card_id ON public.card_events(card_id);
CREATE INDEX idx_card_events_type_created ON public.card_events(card_id, event_type, created_at);

-- ============================================
-- CARD CONTACT FIELDS
-- ============================================

CREATE TABLE public.card_contact_fields (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  card_id UUID NOT NULL REFERENCES public.cards(id) ON DELETE CASCADE,
  field_type TEXT NOT NULL,
  value TEXT NOT NULL,
  label TEXT,
  extension TEXT,
  sort_order INTEGER NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE (card_id, sort_order)
);

CREATE INDEX idx_card_contact_fields_card_id ON public.card_contact_fields(card_id);

-- ============================================
-- CARD SOCIAL LINKS
-- ============================================

CREATE TABLE public.card_social_links (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  card_id UUID NOT NULL REFERENCES public.cards(id) ON DELETE CASCADE,
  platform TEXT NOT NULL,
  url TEXT NOT NULL,
  sort_order INTEGER NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_card_social_links_card_id ON public.card_social_links(card_id);

-- ============================================
-- CARD ACCREDITATIONS
-- ============================================

CREATE TABLE public.card_accreditations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  card_id UUID NOT NULL REFERENCES public.cards(id) ON DELETE CASCADE,
  value TEXT NOT NULL,
  sort_order INTEGER NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- CARD SHARES
-- ============================================

CREATE TABLE public.card_shares (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  card_id UUID NOT NULL REFERENCES public.cards(id) ON DELETE CASCADE,
  share_method TEXT NOT NULL,
  recipient_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
  latitude DOUBLE PRECISION CHECK (latitude IS NULL OR (latitude BETWEEN -90 AND 90)),
  longitude DOUBLE PRECISION CHECK (longitude IS NULL OR (longitude BETWEEN -180 AND 180)),
  location_name TEXT,
  shared_at TIMESTAMPTZ DEFAULT NOW(),
  CHECK ((latitude IS NULL AND longitude IS NULL) OR (latitude IS NOT NULL AND longitude IS NOT NULL))
);

CREATE INDEX idx_card_shares_card_id ON public.card_shares(card_id);

-- ============================================
-- CONTACTS
-- ============================================

CREATE TABLE public.contacts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  source TEXT NOT NULL DEFAULT 'manual' CHECK (source IN ('manual', 'scan', 'exchange', 'import')),

  first_name TEXT,
  last_name TEXT,
  email TEXT,
  phone TEXT,
  company TEXT,
  job_title TEXT,
  website TEXT,
  avatar_url TEXT,

  source_card_id UUID REFERENCES public.cards(id) ON DELETE SET NULL,
  scanned_image_url TEXT,

  met_at_latitude DOUBLE PRECISION CHECK (met_at_latitude IS NULL OR (met_at_latitude BETWEEN -90 AND 90)),
  met_at_longitude DOUBLE PRECISION CHECK (met_at_longitude IS NULL OR (met_at_longitude BETWEEN -180 AND 180)),
  met_at_location_name TEXT,
  met_at TIMESTAMPTZ,

  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),

  CHECK (source != 'exchange' OR source_card_id IS NOT NULL),
  CHECK ((met_at_latitude IS NULL AND met_at_longitude IS NULL) OR (met_at_latitude IS NOT NULL AND met_at_longitude IS NOT NULL))
);

CREATE INDEX idx_contacts_user_id ON public.contacts(user_id);
CREATE UNIQUE INDEX idx_contacts_unique_email
  ON public.contacts(user_id, email) WHERE email IS NOT NULL;

-- ============================================
-- CONTACT NOTES
-- ============================================

CREATE TABLE public.contact_notes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  contact_id UUID NOT NULL REFERENCES public.contacts(id) ON DELETE CASCADE,
  content TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- CONTACT SOCIAL LINKS
-- ============================================

CREATE TABLE public.contact_social_links (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  contact_id UUID NOT NULL REFERENCES public.contacts(id) ON DELETE CASCADE,
  platform TEXT NOT NULL,
  url TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- AI NOTETAKER
-- ============================================

CREATE TABLE public.recordings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  audio_url TEXT NOT NULL,
  duration_seconds INTEGER CHECK (duration_seconds IS NULL OR duration_seconds > 0),
  file_size_bytes BIGINT,
  status TEXT NOT NULL DEFAULT 'recording' CHECK (status IN ('recording', 'processing', 'completed', 'failed')),
  error_message TEXT,
  processing_started_at TIMESTAMPTZ,
  linked_contact_id UUID REFERENCES public.contacts(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE public.recording_summaries (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  recording_id UUID UNIQUE NOT NULL REFERENCES public.recordings(id) ON DELETE CASCADE,
  transcript TEXT,
  summary TEXT,
  people_mentioned JSONB DEFAULT '[]'::jsonb,
  key_insights JSONB DEFAULT '[]'::jsonb,
  action_items JSONB DEFAULT '[]'::jsonb,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- SUBSCRIPTIONS
-- ============================================

CREATE TABLE public.subscriptions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID UNIQUE NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  plan TEXT NOT NULL DEFAULT 'free' CHECK (plan IN ('free', 'premium_monthly', 'premium_annual')),
  status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'canceled', 'expired', 'trialing')),
  provider TEXT CHECK (provider IN ('stripe', 'google_play', 'app_store')),
  provider_subscription_id TEXT,
  trial_ends_at TIMESTAMPTZ,
  current_period_start TIMESTAMPTZ,
  current_period_end TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),

  CHECK (plan = 'free' OR provider IS NOT NULL),
  CHECK (plan = 'free' OR status != 'active' OR current_period_end IS NOT NULL)
);

-- Helper view for subscription status
CREATE VIEW public.user_subscription_status AS
SELECT
  p.id AS user_id,
  COALESCE(s.plan, 'free') AS plan,
  COALESCE(s.status, 'active') AS status,
  CASE
    WHEN s.plan IN ('premium_monthly', 'premium_annual')
      AND s.status IN ('active', 'trialing')
    THEN TRUE
    ELSE FALSE
  END AS is_premium,
  s.current_period_end,
  s.provider
FROM public.profiles p
LEFT JOIN public.subscriptions s ON s.user_id = p.id;

-- ============================================
-- NFC DEVICES
-- ============================================

CREATE TABLE public.nfc_devices (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  card_id UUID NOT NULL REFERENCES public.cards(id) ON DELETE CASCADE,
  device_name TEXT,
  nfc_tag_id TEXT UNIQUE NOT NULL,
  paired_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- DEVICE TOKENS (Push Notifications)
-- ============================================

CREATE TABLE public.device_tokens (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  token TEXT NOT NULL,
  platform TEXT NOT NULL CHECK (platform IN ('android', 'ios', 'web')),
  device_name TEXT,
  last_used_at TIMESTAMPTZ DEFAULT NOW(),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE UNIQUE INDEX idx_device_tokens_token ON public.device_tokens(token);
CREATE INDEX idx_device_tokens_user_id ON public.device_tokens(user_id);

-- ============================================
-- ENRICHMENT DISMISSALS
-- ============================================

CREATE TABLE public.enrichment_dismissals (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  prompt_type TEXT NOT NULL,
  dismissed_at TIMESTAMPTZ DEFAULT NOW(),
  cooldown_until TIMESTAMPTZ NOT NULL,
  permanently_dismissed BOOLEAN DEFAULT FALSE
);

CREATE INDEX idx_enrichment_dismissals_user ON public.enrichment_dismissals(user_id, prompt_type);
CREATE UNIQUE INDEX idx_enrichment_one_active
  ON public.enrichment_dismissals(user_id, prompt_type) WHERE permanently_dismissed = FALSE;

-- ============================================
-- EMAIL SIGNATURES
-- ============================================

CREATE TABLE public.email_signatures (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  card_id UUID UNIQUE NOT NULL REFERENCES public.cards(id) ON DELETE CASCADE,
  html_content TEXT NOT NULL,
  template_name TEXT NOT NULL DEFAULT 'default',
  generated_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- AUTOMATIC updated_at TRIGGER
-- ============================================

CREATE OR REPLACE FUNCTION public.set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_profiles_updated_at BEFORE UPDATE ON public.profiles
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();
CREATE TRIGGER trg_cards_updated_at BEFORE UPDATE ON public.cards
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();
CREATE TRIGGER trg_contacts_updated_at BEFORE UPDATE ON public.contacts
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();
CREATE TRIGGER trg_contact_notes_updated_at BEFORE UPDATE ON public.contact_notes
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();
CREATE TRIGGER trg_subscriptions_updated_at BEFORE UPDATE ON public.subscriptions
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

-- ============================================
-- PUBLIC CARD VIEW
-- ============================================

CREATE VIEW public.public_card_view AS
SELECT
  c.id, c.slug, c.card_name,
  c.first_name, c.last_name, c.prefix, c.suffix, c.pronoun, c.preferred_name,
  c.job_title, c.department, c.company, c.company_website, c.headline,
  c.profile_image_url, c.logo_url, c.cover_image_url, c.image_layout,
  c.card_color, c.qr_code_url, c.qr_logo_enabled, c.remove_branding
FROM public.cards c
WHERE c.is_active = TRUE;

-- ============================================
-- ROW LEVEL SECURITY
-- ============================================

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.cards ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.card_contact_fields ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.card_social_links ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.card_accreditations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.card_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.card_shares ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.contacts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.contact_notes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.contact_social_links ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.recordings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.recording_summaries ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.subscriptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.nfc_devices ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.device_tokens ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.enrichment_dismissals ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.email_signatures ENABLE ROW LEVEL SECURITY;

-- Profiles
CREATE POLICY "Users can view own profile"
  ON public.profiles FOR SELECT USING (auth.uid() = id);
CREATE POLICY "Users can update own profile"
  ON public.profiles FOR UPDATE USING (auth.uid() = id);
CREATE POLICY "Users can insert own profile"
  ON public.profiles FOR INSERT WITH CHECK (auth.uid() = id);

-- Cards
CREATE POLICY "Users can manage own cards"
  ON public.cards FOR ALL USING (auth.uid() = user_id);

-- Card child tables
CREATE POLICY "Users can manage own card contact fields"
  ON public.card_contact_fields FOR ALL
  USING (EXISTS (SELECT 1 FROM public.cards WHERE cards.id = card_id AND cards.user_id = auth.uid()));

CREATE POLICY "Users can manage own card social links"
  ON public.card_social_links FOR ALL
  USING (EXISTS (SELECT 1 FROM public.cards WHERE cards.id = card_id AND cards.user_id = auth.uid()));

CREATE POLICY "Users can manage own card accreditations"
  ON public.card_accreditations FOR ALL
  USING (EXISTS (SELECT 1 FROM public.cards WHERE cards.id = card_id AND cards.user_id = auth.uid()));

-- Card events
CREATE POLICY "Anyone can insert card events"
  ON public.card_events FOR INSERT WITH CHECK (true);
CREATE POLICY "Users can view own card events"
  ON public.card_events FOR SELECT
  USING (EXISTS (SELECT 1 FROM public.cards WHERE cards.id = card_id AND cards.user_id = auth.uid()));

-- Card shares
CREATE POLICY "Users can manage own card shares"
  ON public.card_shares FOR ALL
  USING (EXISTS (SELECT 1 FROM public.cards WHERE cards.id = card_id AND cards.user_id = auth.uid()));
CREATE POLICY "Anyone can insert card shares"
  ON public.card_shares FOR INSERT WITH CHECK (true);

-- Contacts
CREATE POLICY "Users can manage own contacts"
  ON public.contacts FOR ALL USING (auth.uid() = user_id);

CREATE POLICY "Users can manage own contact notes"
  ON public.contact_notes FOR ALL
  USING (EXISTS (SELECT 1 FROM public.contacts WHERE contacts.id = contact_id AND contacts.user_id = auth.uid()));

CREATE POLICY "Users can manage own contact social links"
  ON public.contact_social_links FOR ALL
  USING (EXISTS (SELECT 1 FROM public.contacts WHERE contacts.id = contact_id AND contacts.user_id = auth.uid()));

-- Recordings
CREATE POLICY "Users can manage own recordings"
  ON public.recordings FOR ALL USING (auth.uid() = user_id);

CREATE POLICY "Users can view own recording summaries"
  ON public.recording_summaries FOR SELECT
  USING (EXISTS (SELECT 1 FROM public.recordings WHERE recordings.id = recording_id AND recordings.user_id = auth.uid()));

-- Subscriptions
CREATE POLICY "Users can view own subscription"
  ON public.subscriptions FOR SELECT USING (auth.uid() = user_id);

-- NFC devices
CREATE POLICY "Users can manage own NFC devices"
  ON public.nfc_devices FOR ALL USING (auth.uid() = user_id);

-- Device tokens
CREATE POLICY "Users can manage own device tokens"
  ON public.device_tokens FOR ALL USING (auth.uid() = user_id);

-- Enrichment dismissals
CREATE POLICY "Users can manage own enrichment dismissals"
  ON public.enrichment_dismissals FOR ALL USING (auth.uid() = user_id);

-- Email signatures
CREATE POLICY "Users can manage own email signatures"
  ON public.email_signatures FOR ALL
  USING (EXISTS (SELECT 1 FROM public.cards WHERE cards.id = card_id AND cards.user_id = auth.uid()));
