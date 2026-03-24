# 5. MVP Phasing Recommendation

## Phase 1 — Core Card (Weeks 1-4)
- User registration & authentication (email + OAuth)
- Card creation (personal details, contact info, social links)
- Card editor (color, images, layout)
- Card preview & web landing page
- QR code generation
- Basic sharing (copy link, QR display)

> **Scope note:** This phase assumes a team of [X] engineers (validate with stakeholders). If timeline pressure hits, the recommended **cut line** is: reduce OAuth to 1 provider (Google), defer image layout options to Phase 2.

## Phase 2 — Sharing & Scanning (Weeks 5-8)
- Multi-channel sharing (SMS, email, WhatsApp, LinkedIn, native share)
- Contact scanning (QR code, OCR/paper card, manual entry)
- Contacts list with search
- Location tagging on card shares
- Push notifications for new contacts

## Phase 3 — Premium & AI (Weeks 9-12)
- Premium tier with subscription billing
- Multiple cards per account
- Custom colors, logo in QR, branding removal
- AI Notetaker (recording, transcription, summaries)
- Google Wallet / Apple Wallet integration

## Phase 4 — Advanced (Weeks 13+)
- Home screen widgets (Android + iOS)
- NFC pairing. *Deferred to detailed design: NFC technical implementation details.*
- Email signature generator
- Virtual backgrounds
- Lead capture
- CRM integrations. *Deferred to detailed design: external API contracts and rate limits.*
- Team/organization management. *Deferred to detailed design: team/organization management scope.*
- Smartwatch companion app

> **Deferred items (separate docs):** Competitor differentiation strategy (strategy doc), offline device-to-device sharing mechanism (architecture doc).

---
