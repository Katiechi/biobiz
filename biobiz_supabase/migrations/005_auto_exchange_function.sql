-- ============================================
-- Auto-exchange function for card scanning
-- ============================================
-- When user A scans user B's card, we need to save user A's card
-- as a contact in user B's contacts table. This requires bypassing
-- RLS since user A can't insert into user B's contacts directly.

CREATE OR REPLACE FUNCTION public.auto_exchange_contact(
  target_user_id UUID,
  source_card_id UUID,
  contact_first_name TEXT,
  contact_last_name TEXT,
  contact_email TEXT,
  contact_phone TEXT,
  contact_company TEXT,
  contact_job_title TEXT,
  contact_website TEXT,
  contact_avatar_url TEXT
) RETURNS UUID AS $$
DECLARE
  existing_id UUID;
  new_id UUID;
BEGIN
  -- Check if this contact already exists for the target user
  SELECT id INTO existing_id
  FROM public.contacts
  WHERE user_id = target_user_id
    AND contacts.source_card_id = auto_exchange_contact.source_card_id;

  IF existing_id IS NOT NULL THEN
    -- Update existing contact
    UPDATE public.contacts SET
      first_name = contact_first_name,
      last_name = contact_last_name,
      email = contact_email,
      phone = contact_phone,
      company = contact_company,
      job_title = contact_job_title,
      website = contact_website,
      avatar_url = contact_avatar_url,
      updated_at = NOW()
    WHERE id = existing_id;
    RETURN existing_id;
  ELSE
    -- Insert new contact
    INSERT INTO public.contacts (
      user_id, source, first_name, last_name, email, phone,
      company, job_title, website, avatar_url, source_card_id
    ) VALUES (
      target_user_id, 'exchange', contact_first_name, contact_last_name,
      contact_email, contact_phone, contact_company, contact_job_title,
      contact_website, contact_avatar_url, auto_exchange_contact.source_card_id
    ) RETURNING id INTO new_id;
    RETURN new_id;
  END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
