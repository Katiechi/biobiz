# 5. Key Technical Flows

## 5.1 Onboarding Flow (3-Step Progressive)

The UX spec mandates a 3-step progressive onboarding that delivers a shareable card in under 90 seconds, deferring all enrichment to post-signup contextual prompts (see Section 21). This replaces the original 9-step linear wizard.

### Core Onboarding (3 Steps)

```
STEP 1: Name Entry
  → First name (required) + Last name (optional)
  → Stored in local state + Hive (crash recovery)
  → No account required yet

STEP 2: Account Creation (Email or OAuth)
  → PATH A — OAuth (Google/Microsoft/Apple):
    → Supabase Auth OAuth flow
    → Pre-fill from OAuth profile:
      - Google: name, email, profile photo (scope: profile, email)
      - Microsoft: name, email, profile photo (scope: User.Read)
      - Apple: name, email (no photo — Apple doesn't provide)
    → Skip Step 1 name entry if OAuth provides name
    → OAuth pre-fill overwrites Hive-cached name only if name fields are empty
  → PATH B — Email:
    → Email address entry → Supabase Auth signup
    → OTP verification (6-digit code, 5-min expiry)
    → Phone number collected but optional

STEP 3: Card Generation with Smart Defaults
  → Auto-generate card immediately after account creation:
    - Card color: random from preset palette (or extracted from logo — see Section 16)
    - Slug: generated from first_name-last_name-{4-hex}
    - Contact fields: email auto-added from auth
    - Phone: auto-added if provided
    - Profile photo: from OAuth if available, otherwise placeholder silhouette
    - Company logo: background detection from email domain (non-blocking, see Section 16)
  → Show card preview: "Your card is ready!"
  → User can tap [Edit] to go to editor, or [Continue] to land on My Card + QR

ACCOUNT CREATION (internal, during Step 2-3):
  → Step A: Supabase Auth signup (email/OAuth)
  → Step B: Insert profile row (auth.users trigger OR app-side)
  → Step C: Create first card with smart defaults
  → Step D: Upload OAuth profile photo to Supabase Storage (if available)
  → Step E: Generate QR code client-side from card URL
  → ERROR HANDLING:
    - If A succeeds but B/C fails: retry on next app launch (check onboarding_completed flag)
    - If D fails: card created without photo, enrichment prompt shown later
    - If E fails: QR generated lazily on first share attempt
    - App resumes from last successful step using Hive-persisted onboarding state
  → Clear Hive onboarding cache, set profile.onboarding_completed = true

DEFERRED TO POST-SIGNUP (via Enrichment Engine — see Section 21):
  - Profile photo (if not from OAuth)
  - Company name + website
  - Job title
  - Social links
  - Card color customization
  - Location permission
  - Notification permission
```

### Onboarding Step Count Comparison

| Path | Steps | Time Target |
|------|-------|-------------|
| OAuth (Google/Microsoft) | 2 (name auto-filled + OAuth + card preview) | < 45 seconds |
| OAuth (Apple) | 2-3 (name may need entry + OAuth + card preview) | < 60 seconds |
| Email | 3 (name + email/OTP + card preview) | < 90 seconds |

## 5.2 Card Sharing via QR

```
1. User taps "Share" → opens share sheet
2. QR code displayed (generated client-side from card URL)
3. Recipient scans QR → opens /card/:slug in browser
4. Card page rendered via SSR (Next.js) using public_card_view:
   → If slug not found → 404 "Card not found" page
   → If card owner deleted account (CASCADE) → 410 "Card no longer available" page
   → If card is_active = false → not in public_card_view, returns 404
5. Recipient can:
   → "Save to contacts" (generates .vcf vCard 4.0 download — see Section 12)
   → "Exchange cards" (if they have BioBiz, mutual exchange)
6. Share event recorded:
   → INSERT into card_events { card_id, event_type: "share", metadata: { method: "qr" } }
   → INSERT into card_shares { cardId, method: "qr", lat, lng }
   → Reverse geocode location (non-blocking, updates location_name async)
7. If mutual exchange:
   → Verify both user profiles exist before creating contacts
   → Both users get contact entries + push notification
   → Deduplicated by (user_id, source_card_id) — skip if exchange already recorded
```

## 5.3 AI Notetaker Flow

```
1. User taps "Record" (consent confirmed via consent_banner widget)
2. record package starts audio recording → saved locally
   → Max recording duration: 60 min (enforced client-side)
   → Max file size: 100MB (enforced on upload)
3. User stops recording
4. Audio uploaded to Supabase Storage:
   → POST /api/recordings → returns signed upload URL + creates recording row (status='recording')
   → Upload audio file directly to Storage
   → Update recording status to 'uploaded' (file_size_bytes recorded)
5. Background job triggered:
   → POST /api/recordings/:id/process
   → IDEMPOTENCY: If status is 'completed', return existing summary (200).
     If status is 'processing', return 409 ALREADY_PROCESSING.
   → Set status='processing', processing_started_at=NOW()
   → Deepgram: audio → transcript
     - On Deepgram failure: set status='failed', error_message='Transcription service unavailable'
   → Claude API: transcript → { summary, people, insights, action_items }
     - Validate AI output schema (Zod) before INSERT
     - On malformed output: save transcript only, set summary to null, log warning
     - On Claude API failure: save transcript, set status='completed' (partial success)
   → Save to recording_summaries table
   → Set status='completed'
6. Push notification: "Your meeting summary is ready"
   → On failure: "Recording processing failed — tap to retry"
7. User views summary in app
   → If linked_contact_id was deleted, show summary without contact link (ON DELETE SET NULL)
   → Retry button visible when status='failed'

TIMEOUT RECOVERY:
  → Cron job runs every 5 min: any recording in 'processing' for >10 min is set to 'failed'
  → User sees "Processing timed out" error with retry option
```

## 5.4 Contact Scanning (OCR)

Scan tab modes use names aligned with the UX spec:

```
1. User opens Scan tab → camera activates (camera package)
2. Smart Capture mode (default):
   → Full-frame AI-powered capture
   → google_mlkit_text_recognition extracts text on-device
   → Parse extracted text into structured fields (name, email, phone, company)
   → If no text recognized: show "No text detected — try again with better lighting" message
   → If text found but no fields parsed: show raw text with manual field assignment UI
3. Paper Card mode:
   → Landscape-oriented capture frame for physical business cards
   → Capture image → send to server for better OCR if needed
   → POST /api/contacts/scan { image: base64 }
   → Validate MIME type via magic bytes (reject non-image files)
   → Server-side Google Vision OCR → structured parsing
   → Response includes confidence score; show warning if low confidence
   → On OCR API failure: fall back to on-device ML Kit result
4. QR Code mode:
   → Square framing guide for QR scanning
   → mobile_scanner detects QR
   → If BioBiz QR → fetch card data via public_card_view → create contact
   → If vCard QR → parse vCard via vcard_parser.dart → create contact
   → If standard URL → store as website field on new contact
   → If unrecognized payload → show raw QR content with option to save as contact note
5. User reviews/edits extracted info
   → Check for duplicate (same email) via unique index — if exists, prompt merge UI
   → Insert into Supabase contacts table
```

**Mode ↔ Architecture mapping:**

| UX Mode Name | Camera Frame | Processing |
|---|---|---|
| Smart Capture | Full-frame overlay | On-device ML Kit |
| Paper Card | Landscape rectangle | Server-side Google Vision (ML Kit fallback) |
| QR Code | Square centered frame | mobile_scanner QR detection |

## 5.5 Mutual Exchange from Web Card Viewer

When a recipient views a card in the web browser, they can share their own card back — even without the BioBiz app installed. This addresses the UX spec's "two-way exchange" principle.

```
1. Recipient views card at /card/:slug (SSR)
2. Prominent CTA: "Share my card back"
3. Recipient taps CTA:
   → IF recipient has BioBiz app (detected via deep link attempt):
     → Deep link: biobiz://exchange?card_slug={slug}
     → App opens → auto-selects user's active card → confirms exchange
     → POST /api/contacts/exchange { my_card_id, their_slug }
     → Both parties get contact entries + push notifications
   → IF recipient does NOT have BioBiz app:
     → Web form: "Enter your details to share back"
     → Collects: name, email, phone (optional), company (optional)
     → POST /api/public/cards/:slug/exchange-back { name, email, phone?, company? }
     → Creates a lightweight contact entry for the card owner
     → Card owner gets push notification: "New contact from card share"
     → Recipient shown: "Contact shared! Download BioBiz for a full digital card"
4. Exchange tracking:
   → INSERT into card_events { card_id, event_type: 'exchange', metadata: { method: 'web' } }
   → Rate limited: 5 exchanges per slug per hour (prevent spam)
   → Honeypot field on web form for bot detection
5. Deduplication:
   → Check (card_owner_user_id, email) before creating contact
   → If duplicate: update existing contact with new info, don't create new
```

---
