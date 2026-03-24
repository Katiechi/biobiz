# 3. Authentication & Account

**Requirements:**
- FR-AUT-01: Email + password registration
- FR-AUT-02: OAuth: Google, Microsoft, Apple sign-in
- FR-AUT-03: OTP email verification (6-digit code)
- FR-AUT-04: Password fallback option
- FR-AUT-05: Session management (stay signed in)
- FR-AUT-06: Account management (change email, password, delete account)
- FR-AUT-07: Account linking — when OAuth email matches an existing password account, prompt user to merge accounts
- FR-AUT-08: OTP expiry window of 10 minutes; max 5 resend attempts per session; lockout requires email-based recovery
- FR-AUT-09: Post-account-deletion behavior — shared card URLs display a "card no longer available" page; contact data purged within 30 days

---

## 3.5 Data Model Overview

Core entities and their relationships. Full schema deferred to architecture/design docs.

| Entity | Key Fields | Relationships |
|--------|-----------|---------------|
| User | id, email, auth_provider, subscription_tier, created_at | Has many Cards, has many Contacts, has one Subscription |
| Card | id, user_id, name, color, is_active, created_at | Belongs to User, has many ContactFields, has many SocialLinks, has one QRCode |
| ContactField | id, card_id, type, value, label, sort_order | Belongs to Card |
| SocialLink | id, card_id, platform, url, sort_order | Belongs to Card |
| Contact | id, user_id, name, email, phone, notes, source | Belongs to User, has many CardShares |
| CardShare | id, card_id, contact_id, location_lat, location_lng, place_name, shared_at | Links Card to Contact (records when/where a share occurred) |
| Subscription | id, user_id, plan, status, trial_used, current_period_end | Belongs to User |
| Recording | id, user_id, contact_id, audio_url, transcript, summary, duration, created_at | Belongs to User, optionally linked to Contact |

**Cardinality summary:**
- User → Cards: one-to-many (max 2 free, 5 premium)
- Card → ContactFields: one-to-many (max 30)
- Card → SocialLinks: one-to-many
- User → Contacts: one-to-many
- CardShare: junction between Card and Contact with location + timestamp
- User → Recordings: one-to-many

---
