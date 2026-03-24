# 2. Feature Modules

## 2.1 Onboarding Flow

A step-by-step wizard that creates a user's first card during signup.

| Step | Screen | Fields | Notes |
|------|--------|--------|-------|
| 1 | Landing page | "Create free card" / "Sign in" | Background video/image of networking event |
| 2 | Name entry | First name (required), Last name | Progress indicator (5 steps) |
| 3 | Contact info | Work email, Phone number | |
| 4 | Professional details | Company name, Job title, Company website | Auto-detect logo from website URL |
| 5 | Company logo | Logo preview, Auto-detect from website, Select from photo library, Remove photo | Fetches favicon/logo from provided website |
| 6 | Profile picture | Select from photo library, Use camera, "Not now" skip option | |
| 7 | Account creation | Personal email, Continue with Google, Continue with Microsoft, Continue with Apple | |
| 8 | Email verification | 6-digit OTP code, Resend timer (60s), "Continue with password" fallback | |
| 9 | Card preview | Full card preview with "Edit design" and "Continue" | |

**Requirements:**
- FR-ONB-01: Progress indicator showing current step out of total steps
- FR-ONB-02: Back navigation on every step
- FR-ONB-03: Auto-detect company logo from provided website URL (scrape favicon/og:image)
- FR-ONB-04: Support email + OAuth (Google, Microsoft, Apple) authentication
- FR-ONB-05: 6-digit OTP verification with 60-second resend cooldown
- FR-ONB-06: Card preview generated after all info collected, before account creation
- FR-ONB-07: Privacy Policy & Terms of Service agreement on name entry step

---

## 2.2 Card Editor

Full card customization with live preview capability.

### 2.2.1 Card Color

- Color picker with preset swatches (black, red, orange, yellow, gold, green, + custom color wheel)
- Custom color selection (premium feature)

**Requirements:**
- FR-EDT-01: Preset color palette with 7+ color options
- FR-EDT-02: Custom color picker (premium-gated)
- FR-EDT-03: Color applies to card background/accent theme

### 2.2.2 Images & Layout

- Company logo (editable, with edit icon overlay)
- Profile picture (circular crop, with edit icon overlay)
- Cover photo (optional, addable via "+ Cover photo")
- "Change image layout" option for different arrangements

**Requirements:**
- FR-EDT-04: Upload/change company logo
- FR-EDT-05: Upload/change profile picture (circular crop)
- FR-EDT-06: Optional cover photo
- FR-EDT-07: Multiple image layout options (logo position, profile pic size/position)
- FR-EDT-08: "Preview card" button always visible at bottom

### 2.2.3 Personal Details

| Field | Type | Required |
|-------|------|----------|
| First name | Text (max 50 chars) | Yes |
| Last name | Text (max 50 chars) | No |
| Middle name | Text (addable chip) | No |
| Prefix | Text (addable chip) | No |
| Suffix | Text (addable chip) | No |
| Pronoun | Text (addable chip) | No |
| Preferred name | Text (addable chip) | No |
| Maiden name | Text (addable chip) | No |
| Job title | Text (max 100 chars) | No |
| Department | Text | No |
| Company | Text (max 100 chars) | No |
| Headline | Textarea (max 200 chars) | No |
| Accreditation | Text + "Add" button (max 20 entries) | No (repeatable) |

**Requirements:**
- FR-EDT-09: Core name fields (first, last) always visible
- FR-EDT-10: Additional name fields added via chip/tag buttons (middle, prefix, suffix, pronoun, preferred, maiden)
- FR-EDT-11: Job title, department, company fields
- FR-EDT-12: Headline text area for personal tagline
- FR-EDT-13: Accreditation field with "Add" button for multiple entries

### 2.2.4 Contact Information

- Reorderable list of contact fields (drag to reorder via long-press)
- Each field has: icon, value, optional label, extension (for phone), delete (X) button
- "Hold each field below to re-order it" instruction

**Supported contact field types:**

| Type | Icon | Fields |
|------|------|--------|
| Email | Envelope | Email address, Label (optional) |
| Phone | Phone | Phone number, Extension, Label (optional) |
| Link | Chain link | URL |
| Address | Pin | Address |
| Company Website | Browser | URL |

**Requirements:**
- FR-EDT-14: Add multiple contact fields of any type
- FR-EDT-15: Drag-and-drop reordering of contact fields
- FR-EDT-16: Optional label for each contact field
- FR-EDT-17: Phone extension support
- FR-EDT-18: Delete individual contact fields

### 2.2.5 Social Links

Grid of supported social platforms (3 columns):

| Row | Platform 1 | Platform 2 | Platform 3 |
|-----|-----------|-----------|-----------|
| 1 | Phone | Email | Link |
| 2 | Address | Company Website | LinkedIn |
| 3 | Instagram | Calendly | X (Twitter) |
| 4 | Facebook | Threads | Snapchat |
| 5 | TikTok | YouTube | GitHub |
| 6 | Yelp | Venmo | PayPal |
| 7 | CashApp | Discord | Signal |
| 8 | Skype | Telegram | Twitch |
| 9 | WhatsApp | | |

**Requirements:**
- FR-EDT-19: Support 22+ social/contact link types
- FR-EDT-20: Grid selection UI with icons for each platform
- FR-EDT-21: Each social link opens input for username/URL
- FR-EDT-22: Social links appear on card with recognizable platform icons

### 2.2.6 QR Code Section

- Auto-generated QR code for the card
- "Add logo in QR code" toggle (premium)
- "Remove BioBiz branding" toggle (premium)

**Requirements:**
- FR-EDT-23: Auto-generate unique QR code per card
- FR-EDT-24: Embed company logo in QR code center (premium)
- FR-EDT-25: Option to remove platform branding from shared card (premium)
- FR-EDT-30: Card URLs are permanent — if a card is deleted, the URL shows a "card no longer available" tombstone page
- FR-EDT-31: QR codes encode permanent redirect URLs, not direct card data

### 2.2.7 Card Management

- Card name/label at top (editable via pencil icon, e.g., "My Card")
- Cancel / Save buttons in header
- Support for multiple cards (Free: 2, Premium: 5)

**Requirements:**
- FR-EDT-26: Name each card for easy identification
- FR-EDT-27: Cancel discards unsaved changes
- FR-EDT-28: Save persists all card changes
- FR-EDT-29: Support multiple cards per account (tier-limited)
- FR-EDT-32: "Active card" concept — one card designated as default for QR widget and share button
- FR-EDT-33: Card limit reached UX — show upgrade prompt before user enters creation flow, not after
- FR-EDT-34: Cancel with unsaved changes shows confirmation dialog

### 2.2.8 Input Validation & Field Limits

| Field / Category | Constraint |
|------------------|-----------|
| First name | Max 50 characters |
| Last name | Max 50 characters |
| Headline | Max 200 characters |
| Job title | Max 100 characters |
| Company | Max 100 characters |
| Accreditations | Max 20 entries, 100 characters each |
| Contact fields | Max 10 per type, 30 total |
| Link / Website fields | Must pass URL validation (https:// required) |
| Phone number | E.164 format — require or auto-detect country code |

**Requirements:**
- FR-EDT-35: Enforce max character lengths on all text fields per table above
- FR-EDT-36: Enforce max contact field counts (10 per type, 30 total)
- FR-EDT-37: Validate URL format on Link and Website fields
- FR-EDT-38: Phone numbers stored in E.164 format with country code auto-detection

---

## 2.3 Card Viewing & Preview

The rendered digital business card as seen by the card owner and recipients.

**Card Layout (from screenshot 09):**
- Company logo (top center, banner area)
- Profile picture (circular, overlapping banner bottom-left)
- Full name (large, bold)
- Job title
- Company name
- Contact fields with icons (email, phone, website)
- "Edit design" button (owner view only)

**Requirements:**
- FR-VEW-01: Responsive card rendering matching editor configuration
- FR-VEW-02: Clickable contact fields (tap email opens mail client, tap phone opens dialer, tap website opens browser)
- FR-VEW-03: Social links rendered with platform icons and clickable
- FR-VEW-04: Card shareable via unique URL (web landing page)

---

## 2.4 Card Sharing

Multiple channels for sharing your digital business card.

### 2.4.1 QR Code Sharing

- Full-screen QR code display
- "Point your camera at the QR code to receive the card"
- "Share card offline" toggle

**Requirements:**
- FR-SHR-01: Full-screen QR display for in-person sharing
- FR-SHR-02: Offline sharing mode (device-to-device without internet). *Deferred to detailed design: offline device-to-device sharing mechanism.*

### 2.4.2 Sharing Channels

| Channel | Description |
|---------|------------|
| Copy link | Copy card URL to clipboard |
| Text your card | Send via SMS |
| Email your card | Send via email |
| Send via WhatsApp | Share through WhatsApp |
| Send via LinkedIn | Share through LinkedIn messaging |
| Send another way | OS share sheet |
| Post to LinkedIn | Post card as LinkedIn content |
| Post to Facebook | Post card as Facebook content |
| Save QR code to photos | Download QR as image |
| Send QR code | Share QR image |
| Add card to wallet | Google Wallet / Apple Wallet |

**Requirements:**
- FR-SHR-03: Copy shareable link to clipboard
- FR-SHR-04: Share via SMS (pre-populated message with link)
- FR-SHR-05: Share via email (pre-populated email with card link)
- FR-SHR-06: Direct share to WhatsApp
- FR-SHR-07: Direct share to LinkedIn messaging
- FR-SHR-08: OS native share sheet integration
- FR-SHR-09: Post card to LinkedIn feed
- FR-SHR-10: Post card to Facebook feed
- FR-SHR-11: Save QR code as image to device photos
- FR-SHR-12: Share QR code image
- FR-SHR-13: Add card to Google Wallet / Apple Wallet. *Deferred to detailed design: wallet pass update mechanism after card edits.*
- FR-SHR-14: Share button prominently displayed on main card view

### 2.4.3 Location Tagging

- "Want to remember where you meet people?"
- Geo-tags card shares with location + date
- Shows "Where we met" (place name + address) and "When we met" (date)

**Requirements:**
- FR-SHR-15: Optional location permission for geo-tagging
- FR-SHR-16: Record location and timestamp when card is shared
- FR-SHR-17: Display meeting location and date in contact history
- FR-SHR-18: Reverse geocode coordinates to readable place names

### 2.4.4 QR Widget

- Home screen / lock screen QR code widget (3x2 size)
- Setup instructions: tap and hold app > Widgets > drag to home screen

**Requirements:**
- FR-SHR-19: Android home screen widget showing QR code
- FR-SHR-20: iOS home screen widget showing QR code
- FR-SHR-21: Widget links to active card's QR code

---

## 2.5 Contact Scanning

Capture contact information from physical cards, QR codes, and manual entry.

### 2.5.1 Scan Modes

| Mode | Description |
|------|------------|
| Smart capture | AI-powered camera scan that extracts contact info from any source |
| Paper card | OCR-optimized scanning for traditional paper business cards |
| QR code | Scan QR codes from other digital card platforms |

**Requirements:**
- FR-SCN-01: Camera-based contact scanning with viewfinder frame
- FR-SCN-02: Smart capture mode using AI/OCR to extract contact details
- FR-SCN-03: Paper card mode optimized for traditional business card layout. *Deferred to detailed design: OCR accuracy benchmarks and non-Latin script support.*
- FR-SCN-04: QR code scanning mode
- FR-SCN-05: "Enter manually" option as fallback
- FR-SCN-06: Photo library import (select existing photo to scan)
- FR-SCN-07: Flashlight toggle for low-light scanning

---

## 2.6 AI Notetaker

Record meetings and get AI-generated summaries.

**Screen content:**
- "Record your chats, meetings, conferences and more."
- "Tap record below to get an AI summary of who you met, insights and next steps."
- Consent notice: "By starting, you confirm everybody has given consent."
- Record button (microphone icon)

**Requirements:**
- FR-AIN-01: Audio recording for meetings/conversations
- FR-AIN-02: AI transcription of recorded audio
- FR-AIN-03: AI-generated summary including: who was met, key insights, action items/next steps
- FR-AIN-04: Consent confirmation before recording starts
- FR-AIN-05: Recordings linked to contact entries
- FR-AIN-06: Recording duration limit (free: limited, premium: up to 12 hours)
- FR-AIN-07: Unlimited AI summaries for premium users
- FR-AIN-08: Recordings encrypted at rest, stored in a region-compliant cloud bucket; default retention period of 90 days (configurable by user)
- FR-AIN-09: GDPR right-to-deletion for recordings — any recorded party may request deletion of recordings containing their voice
- FR-AIN-10: All recordings permanently deleted when the owning account is deleted
- FR-AIN-11: Recording access restricted to the account owner only — no shared or team access

---

## 2.7 Contacts Management

CRM-lite contact list for managing networking connections.

**Features:**
- Search contacts
- New contact notification banner ("Get new contact notifications")
- Empty state: "No contacts yet — When you share your card and they share their details back, it will appear here."
- "Share my card" CTA in empty state
- Add contacts manually (+)
- Export contacts (share icon)

**Requirements:**
- FR-CON-01: Searchable contact list
- FR-CON-02: Push notifications for new contact additions
- FR-CON-03: Contacts auto-populated when mutual card exchange occurs
- FR-CON-04: Manual contact creation
- FR-CON-05: Contact export functionality
- FR-CON-06: Empty state with guidance and share CTA
- FR-CON-07: Contact detail view with all shared information
- FR-CON-08: Notes field per contact
- FR-CON-09: Meeting location/date history per contact

---

## 2.8 Navigation & App Structure

**Bottom Tab Bar (4 tabs):**

| Tab | Icon | Description |
|-----|------|------------|
| My Card | Card icon | View/share your active business card + QR code |
| Scan | Scan frame icon | Camera-based contact scanning |
| AI Notetaker | Notepad icon | Meeting recording & AI summaries |
| Contacts | People icon | Contact list management |

**Side Menu (hamburger):**

| Section | Items |
|---------|-------|
| Premium upsell | Banner: "Try Premium for KES0.00" with "View all features" |
| Team | "Get BioBiz for your team" |
| Discover | BioBiz Widget, Android Smartwatch app, NFC accessory, Email signature, Virtual background, Lead capture, CRM integration |
| Settings | Manage account, Notifications, Pair NFC |
| Support | Help, "Have feedback? Let us know" |
| Help us grow | "Leave a review", "Invite friends" |

**Requirements:**
- FR-NAV-01: Bottom tab navigation with 4 primary tabs
- FR-NAV-02: Side menu (hamburger) with settings, discover, and support sections
- FR-NAV-03: Notification bell icon in header (My Card view)
- FR-NAV-04: Edit button (pencil icon) in header for quick card editing
- FR-NAV-05: Premium upsell banner in side menu

---

## 2.9 Premium / Monetization

**Pricing (localized — BioBiz uses KES for Kenya):**

| Plan | Price | Notes |
|------|-------|-------|
| Free | KES 0 | 2 cards, limited features |
| Premium Monthly | KES 1,200/month | Full features |
| Premium Annual | KES 10,000/year (KES 833.33/month) | Save 30.6%, 7-day free trial |

**Free vs Premium Feature Comparison:**

| Feature | Free | Premium |
|---------|------|---------|
| Maximum number of cards | 2 | 5 |
| Custom color theme | Locked | Yes |
| Unlimited AI Notetaker (up to 12 hrs each) | Locked | Yes |
| Logo inside QR code | Locked | Yes |
| Remove platform branding | Locked | Yes |
| Email card via platform servers (hide your email) | Locked | Yes |

**Requirements:**
- FR-MON-01: Free tier with 2 cards and basic features
- FR-MON-02: Premium tier with enhanced features (see table above)
- FR-MON-03: Monthly and annual subscription options
- FR-MON-04: 7-day free trial for premium
- FR-MON-05: Localized pricing per region
- FR-MON-06: In-app purchase flow (Google Play / App Store billing)
- FR-MON-07: Premium feature gates with upgrade prompts (show "Premium" badge + lock icon)
- FR-MON-08: Annual plan discount messaging ("Save X%")
- FR-MON-09: Failed payment grace period (7 days) with up to 3 automatic retries before downgrade
- FR-MON-10: On downgrade, excess cards (beyond free tier limit) archived to read-only; user prompted to choose which cards remain active
- FR-MON-11: Premium-only features revert on downgrade (custom color reverts to default, logo removed from QR, branding restored)
- FR-MON-12: One free trial per account, enforced server-side (not bypassable via reinstall)

---

## 2.10 Additional Features (Discover Section)

Features visible in the side menu for future implementation:

| Feature | Description |
|---------|------------|
| Home screen widget | QR code widget for quick sharing |
| Smartwatch app | Android Wear / watchOS companion app |
| NFC accessory | Pair NFC tags/cards for tap-to-share |
| Email signature | Generate HTML email signature from card data |
| Virtual background | Generate branded video call backgrounds |
| Lead capture | Form/landing page for capturing leads |
| CRM integration | Sync contacts with CRM platforms |
| Team management | Multi-user admin for organizations |

**Requirements:**
- FR-DSC-01: NFC tag pairing and tap-to-share. *Deferred to detailed design: NFC technical implementation details.*
- FR-DSC-02: Email signature generator (HTML format)
- FR-DSC-03: Virtual background generator with branding
- FR-DSC-04: Lead capture forms/landing pages
- FR-DSC-05: CRM integration (Salesforce, HubSpot, etc.). *Deferred to detailed design: external API contracts and rate limits.*
- FR-DSC-06: Team/organization management with admin controls. *Deferred to detailed design: team/organization management scope.*
- FR-DSC-07: Smartwatch companion app
- FR-DSC-08: Invite friends / referral system

---
