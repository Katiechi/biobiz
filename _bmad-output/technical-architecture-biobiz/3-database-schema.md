# 3. Database Schema

## 3.1 Entity Relationship Diagram

```
users (profiles)
  ├── 1:N → cards
  │         ├── 1:N → card_contact_fields
  │         ├── 1:N → card_social_links
  │         ├── 1:N → card_accreditations
  │         ├── 1:N → card_events (view/share analytics)
  │         └── 1:N → card_shares (with location)
  ├── 1:N → contacts
  │         ├── 1:N → contact_notes
  │         └── 1:N → contact_social_links
  ├── 1:N → recordings (AI Notetaker)
  │         └── 1:1 → recording_summaries
  ├── 1:1 → subscriptions
  ├── 1:N → nfc_devices
  ├── 1:N → device_tokens (push notifications)
  └── 1:N → enrichment_dismissals (prompt cooldowns)
```

## 3.2 Tables

```sql
-- ============================================
-- USERS & AUTH
-- ============================================

-- Uses Supabase Auth (auth.users) for core auth
-- This extends it with profile data

CREATE TABLE public.profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  first_name TEXT NOT NULL,
  last_name TEXT,
  email TEXT,  -- populated from auth.users on signup; may be NULL for phone-only OAuth
  phone TEXT,
  avatar_url TEXT,
  onboarding_completed BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- NOTE: Subscription tier is derived exclusively from the `subscriptions` table.
-- Do NOT store subscription state on profiles to avoid dual-source-of-truth drift.
-- Use the helper view `user_subscription_status` (defined below) for tier checks.

-- ============================================
-- CARDS
-- ============================================

CREATE TABLE public.cards (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  slug TEXT UNIQUE NOT NULL,  -- URL-friendly identifier for card link
  card_name TEXT DEFAULT 'My Card',  -- User's label for this card

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
  image_layout TEXT DEFAULT 'default',  -- layout variant name

  -- Appearance
  card_color TEXT DEFAULT '#000000'
    CHECK (card_color ~ '^#[0-9a-fA-F]{6}$'),  -- enforce valid hex color
  custom_color BOOLEAN DEFAULT FALSE,  -- premium flag

  -- QR Code
  qr_code_url TEXT,
  qr_logo_enabled BOOLEAN DEFAULT FALSE,  -- premium flag

  -- Settings
  remove_branding BOOLEAN DEFAULT FALSE,  -- premium flag
  is_active BOOLEAN DEFAULT TRUE,  -- which card is currently active
  location_tagging_enabled BOOLEAN DEFAULT FALSE,

  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Slug generation strategy:
-- Format: {first_name}-{last_name}-{4_char_random_hex} (e.g., "john-smith-a3f1")
-- On collision: regenerate random suffix up to 3 retries, then use full UUID suffix
-- Slugs are immutable after creation to prevent breaking shared QR codes/links
-- Validated: lowercase alphanumeric + hyphens only, 3-60 chars

CREATE INDEX idx_cards_user_id ON public.cards(user_id);
CREATE INDEX idx_cards_slug ON public.cards(slug);

-- ============================================
-- CARD EVENTS (analytics — replaces denormalized counters)
-- ============================================
-- view_count and share_count are NOT stored on the cards table to avoid
-- lost updates under concurrent load. Use this append-only events table instead.

CREATE TABLE public.card_events (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  card_id UUID NOT NULL REFERENCES public.cards(id) ON DELETE CASCADE,
  event_type TEXT NOT NULL CHECK (event_type IN ('view', 'share', 'save_contact', 'exchange')),
  metadata JSONB,  -- e.g., { "method": "qr", "referrer": "..." }
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_card_events_card_id ON public.card_events(card_id);
CREATE INDEX idx_card_events_type_created ON public.card_events(card_id, event_type, created_at);

-- Aggregate counts via: SELECT count(*) FROM card_events WHERE card_id = ? AND event_type = 'view'
-- For dashboard performance, consider a materialized view refreshed periodically

-- ============================================
-- CARD CONTACT FIELDS (reorderable)
-- ============================================

CREATE TABLE public.card_contact_fields (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  card_id UUID NOT NULL REFERENCES public.cards(id) ON DELETE CASCADE,
  field_type TEXT NOT NULL,  -- 'email', 'phone', 'link', 'address', 'company_website', etc.
                             -- Validated at application layer to allow adding new types without migrations
  value TEXT NOT NULL,
  label TEXT,            -- optional user label (e.g., "Work", "Personal")
  extension TEXT,        -- phone extension
  sort_order INTEGER NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE (card_id, sort_order)  -- prevent ambiguous ordering
);

CREATE INDEX idx_card_contact_fields_card_id ON public.card_contact_fields(card_id);

-- ============================================
-- CARD SOCIAL LINKS
-- ============================================

CREATE TABLE public.card_social_links (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  card_id UUID NOT NULL REFERENCES public.cards(id) ON DELETE CASCADE,
  platform TEXT NOT NULL,  -- 'linkedin', 'instagram', 'x', 'facebook', etc.
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
-- CARD SHARES (tracking + location)
-- ============================================

CREATE TABLE public.card_shares (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  card_id UUID NOT NULL REFERENCES public.cards(id) ON DELETE CASCADE,
  share_method TEXT NOT NULL,  -- 'qr', 'link', 'sms', 'email', 'whatsapp', 'linkedin', 'nfc', 'wallet'
  recipient_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,  -- if recipient is also a user
  latitude DOUBLE PRECISION CHECK (latitude IS NULL OR (latitude BETWEEN -90 AND 90)),
  longitude DOUBLE PRECISION CHECK (longitude IS NULL OR (longitude BETWEEN -180 AND 180)),
  location_name TEXT,       -- reverse geocoded place name
  shared_at TIMESTAMPTZ DEFAULT NOW(),
  -- Both lat/lng must be present or both NULL
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

  -- Contact info (from scan, exchange, or manual entry)
  first_name TEXT,
  last_name TEXT,
  email TEXT,
  phone TEXT,
  company TEXT,
  job_title TEXT,
  website TEXT,
  avatar_url TEXT,

  -- Source metadata
  source_card_id UUID REFERENCES public.cards(id) ON DELETE SET NULL,  -- if from card exchange
  scanned_image_url TEXT,  -- original scan image

  -- Meeting context
  met_at_latitude DOUBLE PRECISION CHECK (met_at_latitude IS NULL OR (met_at_latitude BETWEEN -90 AND 90)),
  met_at_longitude DOUBLE PRECISION CHECK (met_at_longitude IS NULL OR (met_at_longitude BETWEEN -180 AND 180)),
  met_at_location_name TEXT,
  met_at TIMESTAMPTZ,

  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),

  -- Exchange contacts must have a source card
  CHECK (source != 'exchange' OR source_card_id IS NOT NULL),
  -- Both lat/lng must be present or both NULL
  CHECK ((met_at_latitude IS NULL AND met_at_longitude IS NULL) OR (met_at_latitude IS NOT NULL AND met_at_longitude IS NOT NULL))
);

CREATE INDEX idx_contacts_user_id ON public.contacts(user_id);
-- Soft duplicate prevention: same user + same email should prompt merge UI
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
  audio_url TEXT NOT NULL,  -- Supabase Storage path
  duration_seconds INTEGER CHECK (duration_seconds IS NULL OR duration_seconds > 0),
  file_size_bytes BIGINT,  -- track storage usage per user
  status TEXT NOT NULL DEFAULT 'recording' CHECK (status IN ('recording', 'processing', 'completed', 'failed')),
  error_message TEXT,       -- populated when status='failed' for user-facing error display
  processing_started_at TIMESTAMPTZ,  -- set when status transitions to 'processing'
  linked_contact_id UUID REFERENCES public.contacts(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Cron job (Supabase pg_cron or background job) should run periodically:
-- UPDATE recordings SET status = 'failed', error_message = 'Processing timed out'
-- WHERE status = 'processing' AND processing_started_at < NOW() - INTERVAL '10 minutes';

CREATE TABLE public.recording_summaries (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  recording_id UUID UNIQUE NOT NULL REFERENCES public.recordings(id) ON DELETE CASCADE,  -- 1:1 enforced
  transcript TEXT,
  summary TEXT,           -- AI-generated summary
  people_mentioned JSONB DEFAULT '[]'::jsonb, -- [{name, role, context}]
  key_insights JSONB DEFAULT '[]'::jsonb,     -- [string]
  action_items JSONB DEFAULT '[]'::jsonb,     -- [{task, assignee, deadline}]
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

  -- Paid plans must have a provider
  CHECK (plan = 'free' OR provider IS NOT NULL),
  -- Active paid plans must have a period end date
  CHECK (plan = 'free' OR status != 'active' OR current_period_end IS NOT NULL)
);

-- This is the SINGLE SOURCE OF TRUTH for subscription status.
-- Helper view for easy tier checks across the app:
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

-- Cron job to expire lapsed subscriptions:
-- UPDATE subscriptions SET status = 'expired'
-- WHERE status = 'active' AND plan != 'free' AND current_period_end < NOW();

-- ============================================
-- NFC DEVICES
-- ============================================

CREATE TABLE public.nfc_devices (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  card_id UUID NOT NULL REFERENCES public.cards(id) ON DELETE CASCADE,
  device_name TEXT,
  nfc_tag_id TEXT UNIQUE NOT NULL,  -- hardware identifier
  paired_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- DEVICE TOKENS (Push Notifications)
-- ============================================
-- Stores FCM/APNs device tokens for push notification delivery.
-- A user may have multiple devices; each device has one token.

CREATE TABLE public.device_tokens (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  token TEXT NOT NULL,            -- FCM registration token
  platform TEXT NOT NULL CHECK (platform IN ('android', 'ios', 'web')),
  device_name TEXT,               -- optional human-readable device name
  last_used_at TIMESTAMPTZ DEFAULT NOW(),  -- updated on each notification send
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Each token is unique across all users (device can only belong to one user)
CREATE UNIQUE INDEX idx_device_tokens_token ON public.device_tokens(token);
CREATE INDEX idx_device_tokens_user_id ON public.device_tokens(user_id);

-- Cleanup: delete tokens not used in 90 days (stale devices)
-- Cron: DELETE FROM device_tokens WHERE last_used_at < NOW() - INTERVAL '90 days';

-- ============================================
-- ENRICHMENT DISMISSALS (Card Enrichment Prompts)
-- ============================================
-- Tracks when users dismiss enrichment banners, enabling cooldown logic.
-- The enrichment engine (Section 21) uses this to control prompt frequency.

CREATE TABLE public.enrichment_dismissals (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  prompt_type TEXT NOT NULL,      -- 'add_photo', 'add_company', 'add_social_links', 'add_job_title', 'customize_color'
  dismissed_at TIMESTAMPTZ DEFAULT NOW(),
  cooldown_until TIMESTAMPTZ NOT NULL,  -- don't show again until this time (default: dismissed_at + 7 days)
  permanently_dismissed BOOLEAN DEFAULT FALSE  -- user chose "Don't show again"
);

CREATE INDEX idx_enrichment_dismissals_user ON public.enrichment_dismissals(user_id, prompt_type);
-- Only one active dismissal per prompt type per user
CREATE UNIQUE INDEX idx_enrichment_one_active
  ON public.enrichment_dismissals(user_id, prompt_type) WHERE permanently_dismissed = FALSE;

-- ============================================
-- EMAIL SIGNATURES
-- ============================================
-- Stores generated email signature HTML for a card.
-- Re-generated when card data changes (via trigger or app-side).

CREATE TABLE public.email_signatures (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  card_id UUID UNIQUE NOT NULL REFERENCES public.cards(id) ON DELETE CASCADE,
  html_content TEXT NOT NULL,      -- rendered HTML signature
  template_name TEXT NOT NULL DEFAULT 'default',  -- signature template variant
  generated_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- AUTOMATIC updated_at TRIGGER
-- ============================================
-- Without this, updated_at columns only reflect creation time (DEFAULT only fires on INSERT)

CREATE OR REPLACE FUNCTION public.set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply to all tables with updated_at columns
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
-- PUBLIC CARD VIEW (limited columns for anonymous access)
-- ============================================
-- Prevents USING(true) on base table from leaking all columns to anonymous users

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

-- ── Profiles ──
CREATE POLICY "Users can view own profile"
  ON public.profiles FOR SELECT USING (auth.uid() = id);
CREATE POLICY "Users can update own profile"
  ON public.profiles FOR UPDATE USING (auth.uid() = id);
CREATE POLICY "Users can insert own profile"
  ON public.profiles FOR INSERT WITH CHECK (auth.uid() = id);

-- ── Cards (owner access) ──
-- No USING(true) SELECT policy — public card data is served through public_card_view
CREATE POLICY "Users can manage own cards"
  ON public.cards FOR ALL USING (auth.uid() = user_id);

-- ── Card child tables (owner via card join) ──
CREATE POLICY "Users can manage own card contact fields"
  ON public.card_contact_fields FOR ALL
  USING (EXISTS (SELECT 1 FROM public.cards WHERE cards.id = card_id AND cards.user_id = auth.uid()));

CREATE POLICY "Users can manage own card social links"
  ON public.card_social_links FOR ALL
  USING (EXISTS (SELECT 1 FROM public.cards WHERE cards.id = card_id AND cards.user_id = auth.uid()));

CREATE POLICY "Users can manage own card accreditations"
  ON public.card_accreditations FOR ALL
  USING (EXISTS (SELECT 1 FROM public.cards WHERE cards.id = card_id AND cards.user_id = auth.uid()));

-- ── Card events ──
-- Insert: anyone (for public view tracking via service role); Select: owner only
CREATE POLICY "Anyone can insert card events"
  ON public.card_events FOR INSERT WITH CHECK (true);
CREATE POLICY "Users can view own card events"
  ON public.card_events FOR SELECT
  USING (EXISTS (SELECT 1 FROM public.cards WHERE cards.id = card_id AND cards.user_id = auth.uid()));

-- ── Card shares ──
CREATE POLICY "Users can manage own card shares"
  ON public.card_shares FOR ALL
  USING (EXISTS (SELECT 1 FROM public.cards WHERE cards.id = card_id AND cards.user_id = auth.uid()));
CREATE POLICY "Anyone can insert card shares"
  ON public.card_shares FOR INSERT WITH CHECK (true);

-- ── Contacts + children ──
CREATE POLICY "Users can manage own contacts"
  ON public.contacts FOR ALL USING (auth.uid() = user_id);

CREATE POLICY "Users can manage own contact notes"
  ON public.contact_notes FOR ALL
  USING (EXISTS (SELECT 1 FROM public.contacts WHERE contacts.id = contact_id AND contacts.user_id = auth.uid()));

CREATE POLICY "Users can manage own contact social links"
  ON public.contact_social_links FOR ALL
  USING (EXISTS (SELECT 1 FROM public.contacts WHERE contacts.id = contact_id AND contacts.user_id = auth.uid()));

-- ── Recordings + summaries ──
CREATE POLICY "Users can manage own recordings"
  ON public.recordings FOR ALL USING (auth.uid() = user_id);

CREATE POLICY "Users can view own recording summaries"
  ON public.recording_summaries FOR SELECT
  USING (EXISTS (SELECT 1 FROM public.recordings WHERE recordings.id = recording_id AND recordings.user_id = auth.uid()));

-- ── Subscriptions ──
CREATE POLICY "Users can view own subscription"
  ON public.subscriptions FOR SELECT USING (auth.uid() = user_id);
-- INSERT/UPDATE handled by webhook via service role key only

-- ── NFC devices ──
CREATE POLICY "Users can manage own NFC devices"
  ON public.nfc_devices FOR ALL USING (auth.uid() = user_id);

-- ── Device tokens ──
CREATE POLICY "Users can manage own device tokens"
  ON public.device_tokens FOR ALL USING (auth.uid() = user_id);

-- ── Enrichment dismissals ──
CREATE POLICY "Users can manage own enrichment dismissals"
  ON public.enrichment_dismissals FOR ALL USING (auth.uid() = user_id);

-- ── Email signatures (owner via card join) ──
CREATE POLICY "Users can manage own email signatures"
  ON public.email_signatures FOR ALL
  USING (EXISTS (SELECT 1 FROM public.cards WHERE cards.id = card_id AND cards.user_id = auth.uid()));
```

---
