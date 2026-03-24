-- ============================================
-- Public read access for card scanning
-- ============================================
-- When user A scans user B's card, user A needs to read
-- user B's card and contact fields. The existing RLS policies
-- only allow owners to read their own data.

-- Drop existing policies if they exist, then recreate
DROP POLICY IF EXISTS "Anyone can view active cards" ON public.cards;
DROP POLICY IF EXISTS "Anyone can view contact fields of active cards" ON public.card_contact_fields;
DROP POLICY IF EXISTS "Anyone can view social links of active cards" ON public.card_social_links;
DROP POLICY IF EXISTS "Anyone can insert contacts" ON public.contacts;

-- Allow any authenticated user to SELECT active cards (needed for QR scan lookup)
CREATE POLICY "Anyone can view active cards"
  ON public.cards FOR SELECT
  USING (is_active = TRUE);

-- Allow any authenticated user to SELECT contact fields of active cards
CREATE POLICY "Anyone can view contact fields of active cards"
  ON public.card_contact_fields FOR SELECT
  USING (EXISTS (
    SELECT 1 FROM public.cards
    WHERE cards.id = card_id AND cards.is_active = TRUE
  ));

-- Allow any authenticated user to SELECT social links of active cards
CREATE POLICY "Anyone can view social links of active cards"
  ON public.card_social_links FOR SELECT
  USING (EXISTS (
    SELECT 1 FROM public.cards
    WHERE cards.id = card_id AND cards.is_active = TRUE
  ));

-- Allow any authenticated user to insert contacts for themselves
-- (needed for auto-exchange: saving scanner's card to scanned person's contacts)
CREATE POLICY "Anyone can insert contacts"
  ON public.contacts FOR INSERT
  WITH CHECK (auth.uid() = user_id);
