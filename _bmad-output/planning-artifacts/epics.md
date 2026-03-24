---
stepsCompleted: [1, 2, 3, 4]
inputDocuments:
  - _bmad-output/prd-biobiz-blinq-clone/index.md
  - _bmad-output/prd-biobiz-blinq-clone/1-product-overview.md
  - _bmad-output/prd-biobiz-blinq-clone/2-feature-modules.md
  - _bmad-output/prd-biobiz-blinq-clone/3-authentication-account.md
  - _bmad-output/prd-biobiz-blinq-clone/4-non-functional-requirements.md
  - _bmad-output/prd-biobiz-blinq-clone/5-mvp-phasing-recommendation.md
  - _bmad-output/prd-biobiz-blinq-clone/6-key-screens-reference.md
  - _bmad-output/prd-biobiz-blinq-clone/7-success-metrics.md
  - _bmad-output/prd-biobiz-blinq-clone/8-error-states-edge-cases.md
  - _bmad-output/technical-architecture-biobiz/index.md
  - _bmad-output/technical-architecture-biobiz/1-architecture-overview.md
  - _bmad-output/technical-architecture-biobiz/2-tech-stack.md
  - _bmad-output/technical-architecture-biobiz/9-security-considerations.md
  - _bmad-output/technical-architecture-biobiz/10-deployment-pipeline.md
  - _bmad-output/planning-artifacts/ux-design-specification.md
---

# BioBiz - Epic Breakdown

## Overview

This document provides the complete epic and story breakdown for BioBiz, decomposing the requirements from the PRD, UX Design, and Architecture into implementable stories.

## Requirements Inventory

### Functional Requirements

**Onboarding (7 requirements)**
FR-ONB-01: Progress indicator showing current step out of total steps
FR-ONB-02: Back navigation on every step
FR-ONB-03: Auto-detect company logo from provided website URL (scrape favicon/og:image)
FR-ONB-04: Support email + OAuth (Google, Microsoft, Apple) authentication
FR-ONB-05: 6-digit OTP verification with 60-second resend cooldown
FR-ONB-06: Card preview generated after all info collected, before account creation
FR-ONB-07: Privacy Policy & Terms of Service agreement on name entry step

**Card Editor (38 requirements)**
FR-EDT-01: Preset color palette with 7+ color options
FR-EDT-02: Custom color picker (premium-gated)
FR-EDT-03: Color applies to card background/accent theme
FR-EDT-04: Upload/change company logo
FR-EDT-05: Upload/change profile picture (circular crop)
FR-EDT-06: Optional cover photo
FR-EDT-07: Multiple image layout options (logo position, profile pic size/position)
FR-EDT-08: "Preview card" button always visible at bottom
FR-EDT-09: Core name fields (first, last) always visible
FR-EDT-10: Additional name fields added via chip/tag buttons (middle, prefix, suffix, pronoun, preferred, maiden)
FR-EDT-11: Job title, department, company fields
FR-EDT-12: Headline text area for personal tagline
FR-EDT-13: Accreditation field with "Add" button for multiple entries
FR-EDT-14: Add multiple contact fields of any type
FR-EDT-15: Drag-and-drop reordering of contact fields
FR-EDT-16: Optional label for each contact field
FR-EDT-17: Phone extension support
FR-EDT-18: Delete individual contact fields
FR-EDT-19: Support 22+ social/contact link types
FR-EDT-20: Grid selection UI with icons for each platform
FR-EDT-21: Each social link opens input for username/URL
FR-EDT-22: Social links appear on card with recognizable platform icons
FR-EDT-23: Auto-generate unique QR code per card
FR-EDT-24: Embed company logo in QR code center (premium)
FR-EDT-25: Option to remove platform branding from shared card (premium)
FR-EDT-26: Name each card for easy identification
FR-EDT-27: Cancel discards unsaved changes
FR-EDT-28: Save persists all card changes
FR-EDT-29: Support multiple cards per account (tier-limited)
FR-EDT-30: Card URLs are permanent — if a card is deleted, the URL shows a "card no longer available" tombstone page
FR-EDT-31: QR codes encode permanent redirect URLs, not direct card data
FR-EDT-32: "Active card" concept — one card designated as default for QR widget and share button
FR-EDT-33: Card limit reached UX — show upgrade prompt before user enters creation flow, not after
FR-EDT-34: Cancel with unsaved changes shows confirmation dialog
FR-EDT-35: Enforce max character lengths on all text fields per defined limits
FR-EDT-36: Enforce max contact field counts (10 per type, 30 total)
FR-EDT-37: Validate URL format on Link and Website fields
FR-EDT-38: Phone numbers stored in E.164 format with country code auto-detection

**Card Viewing (4 requirements)**
FR-VEW-01: Responsive card rendering matching editor configuration
FR-VEW-02: Clickable contact fields (tap email opens mail client, tap phone opens dialer, tap website opens browser)
FR-VEW-03: Social links rendered with platform icons and clickable
FR-VEW-04: Card shareable via unique URL (web landing page)

**Card Sharing (21 requirements)**
FR-SHR-01: Full-screen QR display for in-person sharing
FR-SHR-02: Offline sharing mode (device-to-device without internet)
FR-SHR-03: Copy shareable link to clipboard
FR-SHR-04: Share via SMS (pre-populated message with link)
FR-SHR-05: Share via email (pre-populated email with card link)
FR-SHR-06: Direct share to WhatsApp
FR-SHR-07: Direct share to LinkedIn messaging
FR-SHR-08: OS native share sheet integration
FR-SHR-09: Post card to LinkedIn feed
FR-SHR-10: Post card to Facebook feed
FR-SHR-11: Save QR code as image to device photos
FR-SHR-12: Share QR code image
FR-SHR-13: Add card to Google Wallet / Apple Wallet
FR-SHR-14: Share button prominently displayed on main card view
FR-SHR-15: Optional location permission for geo-tagging
FR-SHR-16: Record location and timestamp when card is shared
FR-SHR-17: Display meeting location and date in contact history
FR-SHR-18: Reverse geocode coordinates to readable place names
FR-SHR-19: Android home screen widget showing QR code
FR-SHR-20: iOS home screen widget showing QR code
FR-SHR-21: Widget links to active card's QR code

**Contact Scanning (7 requirements)**
FR-SCN-01: Camera-based contact scanning with viewfinder frame
FR-SCN-02: Smart capture mode using AI/OCR to extract contact details
FR-SCN-03: Paper card mode optimized for traditional business card layout
FR-SCN-04: QR code scanning mode
FR-SCN-05: "Enter manually" option as fallback
FR-SCN-06: Photo library import (select existing photo to scan)
FR-SCN-07: Flashlight toggle for low-light scanning

**AI Notetaker (11 requirements)**
FR-AIN-01: Audio recording for meetings/conversations
FR-AIN-02: AI transcription of recorded audio
FR-AIN-03: AI-generated summary including: who was met, key insights, action items/next steps
FR-AIN-04: Consent confirmation before recording starts
FR-AIN-05: Recordings linked to contact entries
FR-AIN-06: Recording duration limit (free: limited, premium: up to 12 hours)
FR-AIN-07: Unlimited AI summaries for premium users
FR-AIN-08: Recordings encrypted at rest, stored in a region-compliant cloud bucket; default retention period of 90 days
FR-AIN-09: GDPR right-to-deletion for recordings
FR-AIN-10: All recordings permanently deleted when the owning account is deleted
FR-AIN-11: Recording access restricted to the account owner only

**Contacts Management (9 requirements)**
FR-CON-01: Searchable contact list
FR-CON-02: Push notifications for new contact additions
FR-CON-03: Contacts auto-populated when mutual card exchange occurs
FR-CON-04: Manual contact creation
FR-CON-05: Contact export functionality
FR-CON-06: Empty state with guidance and share CTA
FR-CON-07: Contact detail view with all shared information
FR-CON-08: Notes field per contact
FR-CON-09: Meeting location/date history per contact

**Navigation & App Structure (5 requirements)**
FR-NAV-01: Bottom tab navigation with 4 primary tabs
FR-NAV-02: Side menu (hamburger) with settings, discover, and support sections
FR-NAV-03: Notification bell icon in header (My Card view)
FR-NAV-04: Edit button (pencil icon) in header for quick card editing
FR-NAV-05: Premium upsell banner in side menu

**Premium / Monetization (12 requirements)**
FR-MON-01: Free tier with 2 cards and basic features
FR-MON-02: Premium tier with enhanced features
FR-MON-03: Monthly and annual subscription options
FR-MON-04: 7-day free trial for premium
FR-MON-05: Localized pricing per region
FR-MON-06: In-app purchase flow (Google Play / App Store billing)
FR-MON-07: Premium feature gates with upgrade prompts (show "Premium" badge + lock icon)
FR-MON-08: Annual plan discount messaging ("Save X%")
FR-MON-09: Failed payment grace period (7 days) with up to 3 automatic retries before downgrade
FR-MON-10: On downgrade, excess cards archived to read-only; user prompted to choose active cards
FR-MON-11: Premium-only features revert on downgrade
FR-MON-12: One free trial per account, enforced server-side

**Authentication & Account (9 requirements)**
FR-AUT-01: Email + password registration
FR-AUT-02: OAuth: Google, Microsoft, Apple sign-in
FR-AUT-03: OTP email verification (6-digit code)
FR-AUT-04: Password fallback option
FR-AUT-05: Session management (stay signed in)
FR-AUT-06: Account management (change email, password, delete account)
FR-AUT-07: Account linking — when OAuth email matches existing password account, prompt merge
FR-AUT-08: OTP expiry window of 10 minutes; max 5 resend attempts per session; lockout requires email-based recovery
FR-AUT-09: Post-account-deletion behavior — shared card URLs display tombstone page; contact data purged within 30 days

**Content Moderation (3 requirements)**
FR-SEC-01: Input sanitization for all user-generated text fields rendered on public card URLs
FR-SEC-02: Abuse reporting mechanism for shared card links
FR-SEC-03: Phishing/malware URL scanning for user-provided links

**Discover / Additional Features (8 requirements)**
FR-DSC-01: NFC tag pairing and tap-to-share
FR-DSC-02: Email signature generator (HTML format)
FR-DSC-03: Virtual background generator with branding
FR-DSC-04: Lead capture forms/landing pages
FR-DSC-05: CRM integration (Salesforce, HubSpot, etc.)
FR-DSC-06: Team/organization management with admin controls
FR-DSC-07: Smartwatch companion app
FR-DSC-08: Invite friends / referral system

### NonFunctional Requirements

NFR-PERF-01: Card rendering < 1 second
NFR-PERF-02: QR generation < 500ms
NFR-AVAIL-01: 99.9% uptime for card viewing (cards must always be accessible)
NFR-PRIV-01: GDPR/data protection compliant, location data opt-in only
NFR-SCALE-01: Support 100K+ users, card views scale independently
NFR-OFFLINE-01: QR code display works offline, card data cached locally
NFR-A11Y-01: WCAG 2.1 AA for card viewer, screen reader support
NFR-L10N-01: Multi-currency pricing, multi-language support
NFR-LINK-01: Deep linking — card URLs open in app if installed, web fallback otherwise
NFR-SEC-01: HTTPS everywhere; all PII encrypted at rest
NFR-SEC-02: OAuth 2.0 / OIDC compliance for all third-party auth providers
NFR-SEC-03: Rate limiting on OTP and all auth endpoints (max 10 OTP requests per hour per IP)
NFR-SEC-04: Brute-force protection — progressive delay and account lockout after repeated failed login attempts
NFR-SEC-05: Input sanitization and XSS prevention on all user-generated content on web card viewer
NFR-SEC-06: Image upload validation: JPEG, PNG, WebP only; max 5 MB; server-side file type verification
NFR-SEC-07: Phishing/malware URL scanning on user-provided links before rendering on public card pages

### Additional Requirements

**From Architecture:**
- Multi-repo architecture: Flutter mobile app + Next.js web/API + Supabase shared backend
- Supabase as primary backend: PostgreSQL database, Auth, Storage, Realtime subscriptions
- Flutter 3.x with Riverpod state management, go_router navigation, Material 3 UI
- Next.js 15 (App Router) for web card viewer (SSR) and API routes
- Deployment pipeline: Codemagic for mobile CI/CD, Vercel for web, Supabase CLI for migrations
- Row-Level Security (RLS) on all Supabase tables
- JWT authentication with short expiry + refresh tokens
- Rate limiting via Vercel Edge Middleware
- Input validation: Zod schemas (API), Dart validators (Flutter), DB-level CHECK constraints
- SSRF protection on logo detection endpoint (block private IP ranges)
- Webhook security: Stripe/RevenueCat signature verification, event deduplication
- Account deletion: CASCADE deletes all user data, storage cleanup via background job
- Background jobs via Trigger.dev or Inngest for async tasks (email, AI processing, logo scraping)
- RevenueCat (mobile) + Stripe (web) for payment processing
- Sentry for error tracking (mobile + web)
- AI services: Deepgram (transcription), Claude API (summarization), Google Cloud Vision (OCR fallback)

**From UX Design:**
- Progressive onboarding: deliver usable card in 2-3 steps (name + email + account), enrich post-signup
- Time-to-share target: under 1 second from app launch to scannable QR
- Touch-first design: all core interactions designed for one-handed, thumb-reachable use
- Material 3 foundation with adaptive styling for cross-platform native feel
- Progressive disclosure: simple defaults with advanced options discoverable but not overwhelming
- Smart defaults: auto-detect logos, pre-fill from OAuth profile data, suggest color themes
- Skeleton screens and optimistic UI for loading states
- Contextual enrichment prompts ("Add your photo to make your card stand out") at natural moments
- Card completion encouragement without forced tutorials or feature dumps
- Calm, professional, reliable visual tone — no flashy animations
- Error states: inline messages (not modals), auto-retry for network issues, "Saved offline — will sync" banners
- Empty states with clear CTAs and guidance
- Web card viewer: fast SSR load, polished design, one-tap save, prominent "Share my card back" CTA

### FR Coverage Map

FR-AUT-01: Epic 1 - Email + password registration
FR-AUT-02: Epic 1 - OAuth sign-in (Google, Microsoft, Apple)
FR-AUT-03: Epic 1 - OTP email verification
FR-AUT-04: Epic 1 - Password fallback option
FR-AUT-05: Epic 1 - Session management
FR-AUT-06: Epic 1 - Account management (change email, password, delete)
FR-AUT-07: Epic 1 - Account linking (OAuth + password merge)
FR-AUT-08: Epic 1 - OTP expiry and lockout rules
FR-AUT-09: Epic 1 - Post-account-deletion behavior
FR-ONB-01: Epic 2 - Progress indicator
FR-ONB-02: Epic 2 - Back navigation on every step
FR-ONB-03: Epic 2 - Auto-detect company logo from website URL
FR-ONB-04: Epic 2 - Email + OAuth authentication during onboarding
FR-ONB-05: Epic 2 - OTP verification with resend cooldown
FR-ONB-06: Epic 2 - Card preview before account creation
FR-ONB-07: Epic 2 - Privacy Policy & ToS agreement
FR-EDT-01: Epic 3 - Preset color palette
FR-EDT-02: Epic 3 - Custom color picker (premium)
FR-EDT-03: Epic 3 - Color applies to card theme
FR-EDT-04: Epic 3 - Upload/change company logo
FR-EDT-05: Epic 3 - Upload/change profile picture
FR-EDT-06: Epic 3 - Optional cover photo
FR-EDT-07: Epic 3 - Multiple image layout options
FR-EDT-08: Epic 3 - Preview card button always visible
FR-EDT-09: Epic 3 - Core name fields always visible
FR-EDT-10: Epic 3 - Additional name fields via chips
FR-EDT-11: Epic 3 - Job title, department, company fields
FR-EDT-12: Epic 3 - Headline text area
FR-EDT-13: Epic 3 - Accreditation field with Add button
FR-EDT-14: Epic 3 - Add multiple contact fields
FR-EDT-15: Epic 3 - Drag-and-drop reordering
FR-EDT-16: Epic 3 - Optional label per contact field
FR-EDT-17: Epic 3 - Phone extension support
FR-EDT-18: Epic 3 - Delete individual contact fields
FR-EDT-19: Epic 3 - 22+ social/contact link types
FR-EDT-20: Epic 3 - Grid selection UI with icons
FR-EDT-21: Epic 3 - Social link input for username/URL
FR-EDT-22: Epic 3 - Social links with platform icons on card
FR-EDT-23: Epic 3 - Auto-generate unique QR code per card
FR-EDT-24: Epic 3 - Logo in QR code center (premium)
FR-EDT-25: Epic 3 - Remove platform branding (premium)
FR-EDT-26: Epic 3 - Name each card
FR-EDT-27: Epic 3 - Cancel discards unsaved changes
FR-EDT-28: Epic 3 - Save persists all card changes
FR-EDT-29: Epic 3 - Multiple cards per account (tier-limited)
FR-EDT-30: Epic 3 - Permanent card URLs with tombstone page
FR-EDT-31: Epic 3 - QR codes encode permanent redirect URLs
FR-EDT-32: Epic 3 - Active card concept
FR-EDT-33: Epic 3 - Card limit reached upgrade prompt
FR-EDT-34: Epic 3 - Cancel with unsaved changes confirmation
FR-EDT-35: Epic 3 - Max character length enforcement
FR-EDT-36: Epic 3 - Max contact field count enforcement
FR-EDT-37: Epic 3 - URL format validation
FR-EDT-38: Epic 3 - E.164 phone format with country code detection
FR-VEW-01: Epic 4 - Responsive card rendering
FR-VEW-02: Epic 4 - Clickable contact fields
FR-VEW-03: Epic 4 - Social links rendered with platform icons
FR-VEW-04: Epic 4 - Card shareable via unique URL (web)
FR-NAV-01: Epic 4 - Bottom tab navigation (4 tabs)
FR-NAV-02: Epic 4 - Side menu (hamburger)
FR-NAV-03: Epic 4 - Notification bell icon
FR-NAV-04: Epic 4 - Edit button in header
FR-NAV-05: Epic 4 - Premium upsell banner in side menu
FR-SHR-01: Epic 5 - Full-screen QR display
FR-SHR-02: Epic 5 - Offline sharing mode
FR-SHR-03: Epic 5 - Copy shareable link
FR-SHR-04: Epic 5 - Share via SMS
FR-SHR-05: Epic 5 - Share via email
FR-SHR-06: Epic 5 - Share to WhatsApp
FR-SHR-07: Epic 5 - Share to LinkedIn messaging
FR-SHR-08: Epic 5 - OS native share sheet
FR-SHR-09: Epic 5 - Post to LinkedIn feed
FR-SHR-10: Epic 5 - Post to Facebook feed
FR-SHR-11: Epic 5 - Save QR code as image
FR-SHR-12: Epic 5 - Share QR code image
FR-SHR-13: Epic 5 - Add card to Google/Apple Wallet
FR-SHR-14: Epic 5 - Share button on main card view
FR-SCN-01: Epic 6 - Camera-based contact scanning
FR-SCN-02: Epic 6 - Smart capture mode (AI/OCR)
FR-SCN-03: Epic 6 - Paper card mode (OCR-optimized)
FR-SCN-04: Epic 6 - QR code scanning mode
FR-SCN-05: Epic 6 - Enter manually fallback
FR-SCN-06: Epic 6 - Photo library import
FR-SCN-07: Epic 6 - Flashlight toggle
FR-CON-01: Epic 7 - Searchable contact list
FR-CON-02: Epic 7 - Push notifications for new contacts
FR-CON-03: Epic 7 - Auto-populated contacts on mutual exchange
FR-CON-04: Epic 7 - Manual contact creation
FR-CON-05: Epic 7 - Contact export
FR-CON-06: Epic 7 - Empty state with share CTA
FR-CON-07: Epic 7 - Contact detail view
FR-CON-08: Epic 7 - Notes field per contact
FR-CON-09: Epic 7 - Meeting location/date history
FR-SHR-15: Epic 7 - Optional location permission for geo-tagging
FR-SHR-16: Epic 7 - Record location and timestamp on share
FR-SHR-17: Epic 7 - Display meeting location/date in contact history
FR-SHR-18: Epic 7 - Reverse geocode to readable place names
FR-MON-01: Epic 8 - Free tier with 2 cards
FR-MON-02: Epic 8 - Premium tier with enhanced features
FR-MON-03: Epic 8 - Monthly and annual subscription options
FR-MON-04: Epic 8 - 7-day free trial
FR-MON-05: Epic 8 - Localized pricing per region
FR-MON-06: Epic 8 - In-app purchase flow
FR-MON-07: Epic 8 - Premium feature gates with upgrade prompts
FR-MON-08: Epic 8 - Annual plan discount messaging
FR-MON-09: Epic 8 - Failed payment grace period
FR-MON-10: Epic 8 - Downgrade: excess cards archived
FR-MON-11: Epic 8 - Premium features revert on downgrade
FR-MON-12: Epic 8 - One free trial per account (server-side)
FR-AIN-01: Epic 9 - Audio recording
FR-AIN-02: Epic 9 - AI transcription
FR-AIN-03: Epic 9 - AI-generated summary
FR-AIN-04: Epic 9 - Consent confirmation before recording
FR-AIN-05: Epic 9 - Recordings linked to contacts
FR-AIN-06: Epic 9 - Recording duration limits (free vs premium)
FR-AIN-07: Epic 9 - Unlimited AI summaries (premium)
FR-AIN-08: Epic 9 - Recordings encrypted at rest, 90-day retention
FR-AIN-09: Epic 9 - GDPR right-to-deletion for recordings
FR-AIN-10: Epic 9 - Recordings deleted on account deletion
FR-AIN-11: Epic 9 - Recording access restricted to owner only
FR-SHR-19: Epic 10 - Android home screen QR widget
FR-SHR-20: Epic 10 - iOS home screen QR widget
FR-SHR-21: Epic 10 - Widget links to active card QR
FR-DSC-01: Epic 10 - NFC tag pairing and tap-to-share
FR-DSC-02: Epic 10 - Email signature generator
FR-DSC-03: Epic 10 - Virtual background generator
FR-DSC-04: Epic 10 - Lead capture forms/landing pages
FR-DSC-05: Epic 10 - CRM integration
FR-DSC-06: Epic 10 - Team/organization management
FR-DSC-07: Epic 10 - Smartwatch companion app
FR-DSC-08: Epic 10 - Invite friends / referral system
FR-SEC-01: Epic 10 - Input sanitization on public card URLs
FR-SEC-02: Epic 10 - Abuse reporting mechanism
FR-SEC-03: Epic 10 - Phishing/malware URL scanning

## Epic List

### Epic 1: Project Foundation & User Authentication
Users can register, sign in, manage their account, and have a secure, authenticated session. This is the foundation all other functionality builds upon.
**FRs covered:** FR-AUT-01, FR-AUT-02, FR-AUT-03, FR-AUT-04, FR-AUT-05, FR-AUT-06, FR-AUT-07, FR-AUT-08, FR-AUT-09

### Epic 2: Onboarding & First Card Creation
New users can go through the onboarding wizard, enter their details, and have their first digital business card created with smart defaults — ready to share.
**FRs covered:** FR-ONB-01, FR-ONB-02, FR-ONB-03, FR-ONB-04, FR-ONB-05, FR-ONB-06, FR-ONB-07

### Epic 3: Card Editor & Customization
Users can fully customize their digital business card — colors, images, personal details, contact fields, social links, QR code options, and manage multiple cards.
**FRs covered:** FR-EDT-01 through FR-EDT-38

### Epic 4: Card Viewing, Navigation & Web Landing Page
Users and recipients can view a polished, responsive digital business card in-app and via a public web URL with clickable contact fields and social links. Full app navigation with bottom tabs, side menu, and header actions.
**FRs covered:** FR-VEW-01, FR-VEW-02, FR-VEW-03, FR-VEW-04, FR-NAV-01, FR-NAV-02, FR-NAV-03, FR-NAV-04, FR-NAV-05

### Epic 5: Card Sharing & QR Distribution
Users can share their card through multiple channels — QR code display, copy link, SMS, email, WhatsApp, LinkedIn, native share sheet, social posts, wallet integration, and save/share QR images.
**FRs covered:** FR-SHR-01, FR-SHR-02, FR-SHR-03, FR-SHR-04, FR-SHR-05, FR-SHR-06, FR-SHR-07, FR-SHR-08, FR-SHR-09, FR-SHR-10, FR-SHR-11, FR-SHR-12, FR-SHR-13, FR-SHR-14

### Epic 6: Contact Scanning & Import
Users can capture contact information from paper cards, QR codes, and photos using AI/OCR, or enter contacts manually.
**FRs covered:** FR-SCN-01, FR-SCN-02, FR-SCN-03, FR-SCN-04, FR-SCN-05, FR-SCN-06, FR-SCN-07

### Epic 7: Contacts Management & Location Tagging
Users can manage their networking contacts — search, view details, add notes, see meeting history with location/date, receive push notifications for new contacts, and export contacts.
**FRs covered:** FR-CON-01, FR-CON-02, FR-CON-03, FR-CON-04, FR-CON-05, FR-CON-06, FR-CON-07, FR-CON-08, FR-CON-09, FR-SHR-15, FR-SHR-16, FR-SHR-17, FR-SHR-18

### Epic 8: Premium Subscriptions & Monetization
Users can subscribe to premium plans, unlock advanced features, manage their subscription, and experience proper upgrade/downgrade flows.
**FRs covered:** FR-MON-01, FR-MON-02, FR-MON-03, FR-MON-04, FR-MON-05, FR-MON-06, FR-MON-07, FR-MON-08, FR-MON-09, FR-MON-10, FR-MON-11, FR-MON-12

### Epic 9: AI Notetaker & Meeting Summaries
Users can record meetings, get AI-powered transcriptions and summaries, link recordings to contacts, and manage recording privacy/retention.
**FRs covered:** FR-AIN-01, FR-AIN-02, FR-AIN-03, FR-AIN-04, FR-AIN-05, FR-AIN-06, FR-AIN-07, FR-AIN-08, FR-AIN-09, FR-AIN-10, FR-AIN-11

### Epic 10: Advanced Features & Platform Extensions
Users can access advanced platform capabilities — home screen QR widgets, NFC tap-to-share, email signature generator, content moderation, and additional discover features.
**FRs covered:** FR-SHR-19, FR-SHR-20, FR-SHR-21, FR-DSC-01, FR-DSC-02, FR-DSC-03, FR-DSC-04, FR-DSC-05, FR-DSC-06, FR-DSC-07, FR-DSC-08, FR-SEC-01, FR-SEC-02, FR-SEC-03

---

## Epic 1: Project Foundation & User Authentication

Users can register, sign in, manage their account, and have a secure, authenticated session. This is the foundation all other functionality builds upon.

### Story 1.1: Project Scaffolding & Supabase Setup

As a developer,
I want the Flutter mobile app, Next.js web app, and Supabase backend initialized with the correct project structure and dependencies,
So that I have a working foundation to build features upon.

**Acceptance Criteria:**

**Given** no existing project repositories
**When** the developer initializes the projects
**Then** a Flutter project is created with the folder structure defined in the Architecture (features/, core/, app/ directories)
**And** a Next.js 15 project is created with App Router, Tailwind CSS, and the folder structure from the Architecture
**And** a Supabase project is configured with PostgreSQL database
**And** the Flutter project includes all core dependencies from the Architecture (supabase_flutter, flutter_riverpod, go_router, freezed, dio, etc.)
**And** the Next.js project includes Supabase client, Zod, and Tailwind CSS dependencies
**And** Material 3 theming is configured in the Flutter app with light/dark color schemes
**And** go_router is set up with placeholder routes for the 4 main tabs (My Card, Scan, AI Notetaker, Contacts)
**And** Riverpod is initialized as the state management solution
**And** Sentry error tracking is integrated in both Flutter and Next.js projects
**And** the Supabase client singleton is configured in both Flutter and Next.js

### Story 1.2: User Registration with Email & Password

As a new user,
I want to register with my email and password,
So that I can create an account and access the platform.

**Acceptance Criteria:**

**Given** the user is on the registration screen
**When** they enter a valid email address and password and submit
**Then** a new user account is created in Supabase Auth
**And** the `users` table is populated with the new user record (id, email, auth_provider='email', subscription_tier='free', created_at)
**And** a verification email with a 6-digit OTP is sent to the provided email
**And** the user is redirected to the OTP verification screen

**Given** the user enters an email that is already registered
**When** they submit the registration form
**Then** an error message is displayed: "An account with this email already exists"

**Given** the user enters an invalid email format or a password that doesn't meet requirements
**When** they submit the registration form
**Then** inline validation errors are displayed on the relevant fields

**Given** the registration endpoint
**When** excessive registration attempts are made from the same IP
**Then** rate limiting is enforced per NFR-SEC-03

### Story 1.3: Email OTP Verification

As a registered user,
I want to verify my email with a 6-digit OTP code,
So that my account is secured and verified.

**Acceptance Criteria:**

**Given** the user has just registered and is on the OTP verification screen
**When** they enter the correct 6-digit OTP code
**Then** their email is marked as verified in Supabase Auth
**And** they are redirected to the main app screen

**Given** the user enters an incorrect OTP code
**When** they submit
**Then** an error message is displayed: "Invalid code — please try again"

**Given** the OTP code was sent more than 10 minutes ago
**When** the user enters the code
**Then** an error is displayed: "Code expired — tap to resend"

**Given** the user taps "Resend code"
**When** the resend cooldown (60 seconds) has not elapsed
**Then** the resend button is disabled and shows a countdown timer

**Given** the user has resent the OTP 5 times in the current session
**When** they attempt to resend again
**Then** the resend is blocked with message: "Too many attempts. Try again in 30 minutes or use password sign-in."
**And** lockout requires email-based recovery per FR-AUT-08

### Story 1.4: User Login with Email & Password

As a returning user,
I want to sign in with my email and password,
So that I can access my account.

**Acceptance Criteria:**

**Given** the user is on the sign-in screen
**When** they enter valid email and password credentials
**Then** they are authenticated via Supabase Auth
**And** a JWT access token and refresh token are stored securely (flutter_secure_storage)
**And** they are redirected to the My Card tab

**Given** the user enters incorrect credentials
**When** they submit
**Then** an error message is displayed: "Invalid email or password"

**Given** the user has failed login multiple times consecutively
**When** they continue to fail
**Then** progressive delay is applied between attempts per NFR-SEC-04
**And** after excessive failures, the account is temporarily locked with a recovery path

**Given** the user taps "Continue with password" (password fallback)
**When** they are on the OTP screen
**Then** they are redirected to the password login screen per FR-AUT-04

### Story 1.5: OAuth Sign-In (Google, Microsoft, Apple)

As a user,
I want to sign in with Google, Microsoft, or Apple,
So that I can use my existing accounts for quick access.

**Acceptance Criteria:**

**Given** the user is on the sign-in or registration screen
**When** they tap "Continue with Google"
**Then** the Google OAuth 2.0 flow is initiated via Supabase Auth
**And** on successful authentication, a user record is created (if new) or retrieved (if existing) with auth_provider='google'
**And** profile data from Google (name, email, profile photo) is stored for later use during onboarding

**Given** the user taps "Continue with Microsoft"
**When** the OAuth flow completes successfully
**Then** a user record is created/retrieved with auth_provider='microsoft'
**And** profile data from Microsoft is stored

**Given** the user taps "Continue with Apple"
**When** the OAuth flow completes successfully
**Then** a user record is created/retrieved with auth_provider='apple'
**And** Apple's privacy requirements are respected (handle private relay email)

**Given** the OAuth provider is temporarily unavailable
**When** the user attempts OAuth sign-in
**Then** an error is displayed: "Sign in with [provider] is temporarily unavailable. Try another method."
**And** fallback to email/password is offered

**Given** all OAuth providers
**When** authentication completes
**Then** OAuth 2.0 / OIDC compliance is maintained per NFR-SEC-02

### Story 1.6: Session Management & Token Refresh

As a signed-in user,
I want my session to persist across app restarts,
So that I don't have to sign in every time I open the app.

**Acceptance Criteria:**

**Given** the user has successfully signed in
**When** they close and reopen the app
**Then** the session is automatically restored from the stored refresh token
**And** the user lands on the My Card tab without needing to sign in again

**Given** the access token has expired
**When** the app makes an API request
**Then** the token is automatically refreshed using the refresh token via Supabase Auth
**And** the request proceeds transparently

**Given** the refresh token has also expired or been revoked
**When** the app attempts to restore the session
**Then** the user is redirected to the sign-in screen with message: "Session expired — please sign in again"

**Given** the user is signed in on the Flutter app
**When** the dio HTTP client makes a request to the Next.js API
**Then** the JWT auth token is automatically injected via the dio interceptor reading from the supabase_flutter session

### Story 1.7: Account Linking (OAuth + Password Merge)

As a user who signed up with email,
I want to link my OAuth account when the emails match,
So that I have a unified account with multiple sign-in methods.

**Acceptance Criteria:**

**Given** a user registered with email/password exists
**When** they (or someone) attempt OAuth sign-in with the same email address
**Then** a prompt is displayed: "An account with this email already exists. Would you like to link your [provider] account?"
**And** if the user confirms, the OAuth identity is linked to the existing account
**And** the user can now sign in with either method

**Given** a user confirms account linking
**When** the linking is processed
**Then** the auth_provider field is updated to reflect multiple providers
**And** all existing data (cards, contacts, etc.) remains intact

**Given** a user declines account linking
**When** they dismiss the prompt
**Then** the OAuth sign-in is cancelled and they return to the sign-in screen

### Story 1.8: Account Management (Change Email, Password, Delete)

As a user,
I want to change my email, update my password, and delete my account,
So that I have full control over my account.

**Acceptance Criteria:**

**Given** the user navigates to the Manage Account screen
**When** they tap "Change email" and enter a new valid email
**Then** a verification OTP is sent to the new email
**And** on verification, the account email is updated in Supabase Auth and the users table

**Given** the user taps "Change password"
**When** they enter their current password and a new valid password
**Then** the password is updated in Supabase Auth

**Given** the user taps "Delete account"
**When** they confirm via a confirmation dialog
**Then** any active subscriptions are cancelled with the payment provider (RevenueCat/Stripe)
**And** all user data is CASCADE deleted (cards, contacts, recordings, shares, social links, contact fields)
**And** storage files (profile photos, logos, cover photos, recordings) are cleaned up via a background job
**And** shared card URLs for this user display a "card no longer available" tombstone page per FR-AUT-09
**And** contact data is fully purged within 30 days per FR-AUT-09

**Given** the user deletes their account
**When** they attempt to sign in again with the same email
**Then** they are treated as a new user and can register fresh

---

## Epic 2: Onboarding & First Card Creation

New users can go through the onboarding wizard, enter their details, and have their first digital business card created with smart defaults — ready to share.

### Story 2.1: Onboarding Wizard Scaffold & Name Entry

As a new user,
I want to see a welcoming landing page and enter my name as the first step of onboarding,
So that I can begin creating my digital business card.

**Acceptance Criteria:**

**Given** the user opens the app for the first time (not signed in)
**When** the app loads
**Then** a landing page is displayed with a background image/video of a networking event
**And** "Create free card" and "Sign in" buttons are prominently displayed

**Given** the user taps "Create free card"
**When** the onboarding wizard begins
**Then** a progress indicator shows current step out of total steps per FR-ONB-01
**And** the first step displays First name (required) and Last name fields

**Given** the user is on any onboarding step after the first
**When** they tap the back button
**Then** they navigate to the previous step with their entered data preserved per FR-ONB-02

**Given** the user is on the name entry step
**When** the step loads
**Then** a Privacy Policy & Terms of Service agreement checkbox/link is displayed per FR-ONB-07
**And** the user must accept before proceeding

**Given** the user enters a first name and taps next
**When** validation passes (first name provided, max 50 chars)
**Then** they proceed to the next onboarding step

### Story 2.2: Contact Information & Professional Details Entry

As a new user,
I want to enter my work email, phone, company, job title, and website during onboarding,
So that my card has professional contact information.

**Acceptance Criteria:**

**Given** the user completed the name entry step
**When** they arrive at the contact info step
**Then** fields for work email and phone number are displayed
**And** the progress indicator updates to reflect the current step

**Given** the user completes contact info and proceeds
**When** they arrive at the professional details step
**Then** fields for company name, job title, and company website are displayed

**Given** the user enters a company website URL
**When** they proceed to the next step
**Then** the URL is stored for logo auto-detection in the next step

**Given** any onboarding step
**When** the user navigates back
**Then** all previously entered data is preserved and editable

### Story 2.3: Company Logo Auto-Detection & Profile Picture

As a new user,
I want my company logo to be auto-detected from my website and to optionally add a profile picture,
So that my card looks professional with minimal effort.

**Acceptance Criteria:**

**Given** the user provided a company website URL in the previous step
**When** the logo step loads
**Then** the system calls the Next.js API `/api/utils/detect-logo` endpoint to scrape favicon/og:image from the website per FR-ONB-03
**And** if a logo is found, it is displayed as a preview with options to keep, change from photo library, or remove

**Given** the logo auto-detection fails or no website was provided
**When** the logo step loads
**Then** options to select from photo library or skip are displayed

**Given** the user proceeds to the profile picture step
**When** the step loads
**Then** options are displayed: "Select from photo library", "Use camera", and "Not now" skip option

**Given** the user selects a profile picture
**When** they choose an image
**Then** a circular crop tool is presented
**And** the cropped image is stored locally for card creation

**Given** image upload validation
**When** the user selects an image
**Then** only JPEG, PNG, WebP formats are accepted, max 5 MB per NFR-SEC-06

### Story 2.4: Account Creation During Onboarding

As a new user,
I want to create my account using email or OAuth during onboarding,
So that my card data is saved and I can access it later.

**Acceptance Criteria:**

**Given** the user has completed all info collection steps
**When** they reach the account creation step
**Then** options are displayed: personal email field, "Continue with Google", "Continue with Microsoft", "Continue with Apple" per FR-ONB-04

**Given** the user enters a personal email
**When** they submit
**Then** a 6-digit OTP is sent to their email per FR-ONB-05
**And** the OTP verification screen is displayed with a 60-second resend cooldown

**Given** the user chooses OAuth
**When** they complete the OAuth flow
**Then** the account is created and linked to their onboarding data
**And** profile data from OAuth (name, photo) is used to supplement any missing onboarding fields

**Given** the user enters the correct OTP
**When** verification succeeds
**Then** the account is created in Supabase Auth
**And** the user record is populated in the users table
**And** all onboarding data is associated with the new account

### Story 2.5: Card Preview & First Card Generation

As a new user,
I want to see a preview of my generated card with smart defaults before entering the app,
So that I can verify my card looks good and start sharing immediately.

**Acceptance Criteria:**

**Given** the user has completed account creation
**When** the card preview step loads
**Then** a full card preview is generated using all collected onboarding data per FR-ONB-06
**And** smart defaults are applied: default color theme, standard layout, auto-generated QR code
**And** "Edit design" and "Continue" buttons are displayed

**Given** the card preview is displayed
**When** the user taps "Continue"
**Then** the card is saved to the database (cards table with user_id, name="My Card", is_active=true)
**And** all contact fields, social links, and images are persisted
**And** a unique card URL/slug is generated
**And** a QR code encoding the permanent redirect URL is generated per FR-EDT-31
**And** the user is redirected to the My Card tab in the main app

**Given** the card preview is displayed
**When** the user taps "Edit design"
**Then** they are taken to the card editor (Epic 3) with their onboarding data pre-populated

**Given** a new user completes onboarding
**When** their first card is created
**Then** the card is set as the active card per FR-EDT-32
**And** the card count is 1 out of 2 (free tier limit)

---

## Epic 3: Card Editor & Customization

Users can fully customize their digital business card — colors, images, personal details, contact fields, social links, QR code options, and manage multiple cards.

### Story 3.1: Card Editor Screen & Color Customization

As a user,
I want to open the card editor and change my card's color theme,
So that my card reflects my personal or brand style.

**Acceptance Criteria:**

**Given** the user navigates to edit their card
**When** the card editor screen loads
**Then** the editor displays all card sections: color, images, personal details, contact info, social links, QR code
**And** a "Preview card" button is always visible at the bottom per FR-EDT-08
**And** Cancel and Save buttons are in the header

**Given** the user is in the color section
**When** they view the color options
**Then** a preset color palette with 7+ color options is displayed (black, red, orange, yellow, gold, green, etc.) per FR-EDT-01
**And** the selected color applies to the card background/accent theme per FR-EDT-03

**Given** the user taps the custom color picker
**When** they are on the free tier
**Then** a premium gate is shown with upgrade prompt per FR-EDT-02

**Given** the user selects a preset color
**When** they tap a color swatch
**Then** the card preview updates immediately to reflect the new color

### Story 3.2: Image Management (Logo, Profile Picture, Cover Photo)

As a user,
I want to upload and manage my company logo, profile picture, and cover photo,
So that my card has a professional visual identity.

**Acceptance Criteria:**

**Given** the user is in the images section of the editor
**When** they tap the company logo area
**Then** options to upload/change the logo are presented with an edit icon overlay per FR-EDT-04

**Given** the user taps the profile picture area
**When** they select an image
**Then** a circular crop tool is presented per FR-EDT-05
**And** the cropped image is uploaded to Supabase Storage

**Given** the user wants a cover photo
**When** they tap "+ Cover photo"
**Then** they can select and upload an optional cover photo per FR-EDT-06

**Given** any image upload
**When** the user selects a file
**Then** only JPEG, PNG, WebP are accepted, max 5 MB, with server-side MIME validation per NFR-SEC-06
**And** oversized files show "Image must be under 5 MB"
**And** unsupported formats show "Supported formats: JPEG, PNG, WebP"

**Given** the user taps "Change image layout"
**When** layout options are displayed
**Then** multiple arrangement options for logo position and profile pic size/position are available per FR-EDT-07

### Story 3.3: Personal Details Editing

As a user,
I want to edit my name, job title, company, headline, and accreditations,
So that my card accurately represents my professional identity.

**Acceptance Criteria:**

**Given** the user is in the personal details section
**When** the section loads
**Then** core name fields (first name, last name) are always visible per FR-EDT-09
**And** job title, department, and company fields are displayed per FR-EDT-11

**Given** the user wants additional name fields
**When** they tap chip/tag buttons
**Then** fields for middle name, prefix, suffix, pronoun, preferred name, and maiden name can be added per FR-EDT-10

**Given** the user edits the headline field
**When** they type
**Then** a text area with max 200 characters is available for a personal tagline per FR-EDT-12
**And** a character counter is displayed

**Given** the user wants to add accreditations
**When** they tap the "Add" button in the accreditation section
**Then** they can add up to 20 accreditation entries, max 100 characters each per FR-EDT-13

**Given** any text field
**When** the user types
**Then** max character lengths are enforced per FR-EDT-35 (first/last name: 50, headline: 200, job title: 100, company: 100)

### Story 3.4: Contact Fields Management

As a user,
I want to add, edit, reorder, and delete contact fields on my card,
So that people can reach me through my preferred channels.

**Acceptance Criteria:**

**Given** the user is in the contact information section
**When** they tap "Add field"
**Then** they can choose from: Email, Phone, Link, Address, Company Website per FR-EDT-14

**Given** the user has multiple contact fields
**When** they long-press and drag a field
**Then** the field can be reordered via drag-and-drop per FR-EDT-15

**Given** a contact field is displayed
**When** the user views it
**Then** each field shows: icon, value, optional label, and delete (X) button per FR-EDT-16, FR-EDT-18
**And** phone fields additionally show an extension input per FR-EDT-17

**Given** the user adds a phone number
**When** they enter the number
**Then** the phone number is stored in E.164 format with country code auto-detection per FR-EDT-38

**Given** the user adds a Link or Company Website field
**When** they enter a URL
**Then** URL format validation is enforced (https:// required) per FR-EDT-37

**Given** the contact field limits
**When** the user attempts to exceed them
**Then** max 10 fields per type and 30 total are enforced per FR-EDT-36

### Story 3.5: Social Links Grid & Management

As a user,
I want to add social media and platform links to my card,
So that people can connect with me across platforms.

**Acceptance Criteria:**

**Given** the user is in the social links section
**When** the section loads
**Then** a grid of 22+ supported social/contact platforms is displayed in 3 columns per FR-EDT-19, FR-EDT-20
**And** platforms include: Phone, Email, Link, Address, Company Website, LinkedIn, Instagram, Calendly, X, Facebook, Threads, Snapchat, TikTok, YouTube, GitHub, Yelp, Venmo, PayPal, CashApp, Discord, Signal, Skype, Telegram, Twitch, WhatsApp

**Given** the user taps a platform icon
**When** the input opens
**Then** a field for username/URL is displayed specific to that platform per FR-EDT-21

**Given** social links have been added
**When** the card is rendered
**Then** social links appear with recognizable platform icons per FR-EDT-22

### Story 3.6: QR Code Generation & Premium Options

As a user,
I want a unique QR code for my card with optional premium customizations,
So that I can share my card easily via QR scanning.

**Acceptance Criteria:**

**Given** the user is in the QR code section of the editor
**When** the section loads
**Then** an auto-generated unique QR code for the card is displayed per FR-EDT-23
**And** the QR code encodes a permanent redirect URL, not direct card data per FR-EDT-31

**Given** the user toggles "Add logo in QR code"
**When** they are on the free tier
**Then** a premium gate is shown per FR-EDT-24

**Given** the user toggles "Remove BioBiz branding"
**When** they are on the free tier
**Then** a premium gate is shown per FR-EDT-25

**Given** the card has a permanent URL
**When** the card is later deleted
**Then** the URL displays a "card no longer available" tombstone page per FR-EDT-30

### Story 3.7: Card Save, Cancel & Unsaved Changes

As a user,
I want to save my card changes or cancel and discard them,
So that I have control over when my edits are applied.

**Acceptance Criteria:**

**Given** the user has made changes in the editor
**When** they tap "Save"
**Then** all card changes are persisted to the database per FR-EDT-28
**And** images are uploaded to Supabase Storage
**And** the user returns to the card view

**Given** the user taps "Cancel" with unsaved changes
**When** the cancel action is triggered
**Then** a confirmation dialog is shown: "Discard unsaved changes?" per FR-EDT-34

**Given** the user confirms discard
**When** they confirm
**Then** all unsaved changes are discarded and the card reverts to the last saved state per FR-EDT-27

**Given** the user taps "Cancel" with no changes
**When** the cancel action is triggered
**Then** they return to the card view without a dialog

### Story 3.8: Multiple Cards & Card Management

As a user,
I want to create and manage multiple cards with one set as active,
So that I can have different cards for different contexts.

**Acceptance Criteria:**

**Given** the user wants to create a new card
**When** they are on the free tier with 2 cards already
**Then** an upgrade prompt is shown BEFORE entering the creation flow per FR-EDT-33

**Given** the user is on the premium tier
**When** they create cards
**Then** up to 5 cards are supported per FR-EDT-29

**Given** the user has multiple cards
**When** they view their cards
**Then** each card has an editable name/label (e.g., "My Card", "Work Card") per FR-EDT-26

**Given** the user wants to set a default card
**When** they designate a card as active
**Then** that card becomes the default for the QR widget and share button per FR-EDT-32

---

## Epic 4: Card Viewing, Navigation & Web Landing Page

Users and recipients can view a polished, responsive digital business card in-app and via a public web URL with clickable contact fields and social links. Full app navigation with bottom tabs, side menu, and header actions.

### Story 4.1: In-App Card Renderer & My Card Screen

As a user,
I want to view my digital business card in the app with all my information rendered beautifully,
So that I can see how my card looks before sharing it.

**Acceptance Criteria:**

**Given** the user is on the My Card tab
**When** the screen loads
**Then** the active card is rendered with: company logo, profile picture, full name, job title, company, contact fields with icons, and social links per FR-VEW-01
**And** the card renders in under 1 second per NFR-PERF-01

**Given** the card is displayed
**When** the user taps an email field
**Then** the device mail client opens with the email pre-populated per FR-VEW-02

**Given** the card is displayed
**When** the user taps a phone field
**Then** the device dialer opens with the number per FR-VEW-02

**Given** the card is displayed
**When** the user taps a website or social link
**Then** the browser opens to the URL per FR-VEW-02, FR-VEW-03

**Given** social links on the card
**When** rendered
**Then** each displays with the recognizable platform icon per FR-VEW-03

### Story 4.2: Bottom Tab Navigation & App Shell

As a user,
I want to navigate between the main app sections using bottom tabs,
So that I can quickly access My Card, Scan, AI Notetaker, and Contacts.

**Acceptance Criteria:**

**Given** the user is signed in
**When** the app loads
**Then** a bottom tab bar with 4 tabs is displayed: My Card (card icon), Scan (scan frame icon), AI Notetaker (notepad icon), Contacts (people icon) per FR-NAV-01

**Given** any tab
**When** the user taps it
**Then** the corresponding screen is displayed with smooth transition

**Given** the My Card tab header
**When** displayed
**Then** a notification bell icon is shown per FR-NAV-03
**And** an edit button (pencil icon) for quick card editing is shown per FR-NAV-04

### Story 4.3: Side Menu (Hamburger) & Settings Navigation

As a user,
I want to access settings, discover features, and support from a side menu,
So that I can manage my account and explore additional functionality.

**Acceptance Criteria:**

**Given** the user taps the hamburger menu icon
**When** the side menu opens
**Then** it displays sections for: Premium upsell banner, Team, Discover, Settings, Support, and Help us grow per FR-NAV-02

**Given** the Premium section
**When** displayed
**Then** a banner shows "Try Premium for [price]" with "View all features" link per FR-NAV-05

**Given** the Discover section
**When** displayed
**Then** items include: BioBiz Widget, Android Smartwatch app, NFC accessory, Email signature, Virtual background, Lead capture, CRM integration

**Given** the Settings section
**When** displayed
**Then** items include: Manage account, Notifications, Pair NFC

**Given** the Support section
**When** displayed
**Then** items include: Help, "Have feedback? Let us know"

**Given** the Help us grow section
**When** displayed
**Then** items include: "Leave a review", "Invite friends"

### Story 4.4: Web Card Viewer (Public Landing Page)

As a card recipient,
I want to view a shared card in my browser after scanning a QR code,
So that I can see the sender's contact information and save it.

**Acceptance Criteria:**

**Given** a recipient scans a BioBiz QR code or opens a card URL
**When** the web page loads
**Then** the card is rendered via Next.js SSR with the same layout as the in-app view per FR-VEW-04
**And** the page loads in under 1 second per NFR-PERF-01

**Given** the web card is displayed
**When** the recipient views it
**Then** all contact fields are clickable (email opens mailto:, phone opens tel:, websites open in new tabs)
**And** social links are rendered with platform icons and are clickable

**Given** the web card viewer
**When** rendered
**Then** a "Save to contacts" button is prominently displayed (vCard download)
**And** a "Share my card back" CTA is prominently displayed for mutual exchange
**And** the BioBiz branding is shown (removable with premium)

**Given** a deleted card's URL
**When** a recipient visits it
**Then** a "This card is no longer available" tombstone page is displayed per FR-EDT-30

**Given** the web card viewer
**When** rendering user-generated content
**Then** all text is sanitized to prevent XSS per NFR-SEC-05
**And** CSP headers are set on the page

**Given** deep linking is configured
**When** a card URL is opened on a device with the BioBiz app installed
**Then** the app opens to that card per NFR-LINK-01
**And** if the app is not installed, the web fallback is displayed

---

## Epic 5: Card Sharing & QR Distribution

Users can share their card through multiple channels — QR code display, copy link, SMS, email, WhatsApp, LinkedIn, native share sheet, social posts, wallet integration, and save/share QR images.

### Story 5.1: Full-Screen QR Code Display & Share Screen

As a user,
I want to display my QR code full-screen for in-person sharing,
So that someone can scan it quickly to receive my card.

**Acceptance Criteria:**

**Given** the user is on the My Card tab
**When** they tap the share button
**Then** a share screen opens with a full-screen QR code display per FR-SHR-01
**And** the text "Point your camera at the QR code to receive the card" is displayed
**And** the share button is prominently displayed on the main card view per FR-SHR-14

**Given** the QR code is displayed
**When** rendered
**Then** the QR is generated in under 500ms per NFR-PERF-02

**Given** the device is offline
**When** the user opens the QR display
**Then** the QR code still displays from cached data per NFR-OFFLINE-01

**Given** the "Share card offline" toggle
**When** enabled
**Then** device-to-device sharing is available without internet per FR-SHR-02

### Story 5.2: Copy Link & Basic Sharing Channels

As a user,
I want to copy my card link and share via SMS, email, and native share sheet,
So that I can distribute my card through basic channels.

**Acceptance Criteria:**

**Given** the user is on the share screen
**When** they tap "Copy link"
**Then** the card URL is copied to the clipboard with a confirmation toast per FR-SHR-03

**Given** the user taps "Text your card"
**When** the SMS app opens
**Then** a pre-populated message with the card link is ready to send per FR-SHR-04

**Given** the user taps "Email your card"
**When** the email client opens
**Then** a pre-populated email with the card link is ready to send per FR-SHR-05

**Given** the user taps "Send another way"
**When** the OS share sheet opens
**Then** the card link is available to share through any installed app per FR-SHR-08

### Story 5.3: Social Platform Sharing (WhatsApp, LinkedIn, Facebook)

As a user,
I want to share my card directly to WhatsApp, LinkedIn, and Facebook,
So that I can reach contacts on the platforms they use most.

**Acceptance Criteria:**

**Given** the user taps "Send via WhatsApp"
**When** WhatsApp is installed
**Then** a share intent opens WhatsApp with the card link per FR-SHR-06

**Given** the user taps "Send via LinkedIn"
**When** LinkedIn is available
**Then** a share intent opens LinkedIn messaging with the card link per FR-SHR-07

**Given** the user taps "Post to LinkedIn"
**When** the action is triggered
**Then** a LinkedIn post composition opens with the card link per FR-SHR-09

**Given** the user taps "Post to Facebook"
**When** the action is triggered
**Then** a Facebook post composition opens with the card link per FR-SHR-10

### Story 5.4: QR Code Image Save & Share

As a user,
I want to save my QR code as an image and share it,
So that I can include it in presentations, emails, or printed materials.

**Acceptance Criteria:**

**Given** the user taps "Save QR code to photos"
**When** the action completes
**Then** the QR code is saved as a PNG image to the device photo library per FR-SHR-11
**And** a confirmation message is shown

**Given** the user taps "Send QR code"
**When** the share sheet opens
**Then** the QR code image is available for sharing through any channel per FR-SHR-12

### Story 5.5: Google Wallet & Apple Wallet Integration

As a user,
I want to add my card to Google Wallet or Apple Wallet,
So that I can share it directly from my phone's wallet without opening the app.

**Acceptance Criteria:**

**Given** the user taps "Add card to wallet"
**When** on an Android device
**Then** a Google Wallet pass is generated and the user is prompted to add it per FR-SHR-13

**Given** the user taps "Add card to wallet"
**When** on an iOS device
**Then** an Apple Wallet pass is generated and the user is prompted to add it per FR-SHR-13

**Given** the wallet pass is added
**When** the user updates their card later
**Then** the wallet pass update mechanism handles card edits (deferred to implementation detail)

---

## Epic 6: Contact Scanning & Import

Users can capture contact information from paper cards, QR codes, and photos using AI/OCR, or enter contacts manually.

### Story 6.1: Camera Scanner & QR Code Scanning

As a user,
I want to scan QR codes with my camera to receive digital business cards,
So that I can quickly save someone's contact information.

**Acceptance Criteria:**

**Given** the user taps the Scan tab
**When** the scanner screen loads
**Then** a camera viewfinder with a scanning frame is displayed per FR-SCN-01
**And** scan mode tabs are shown: Smart capture, Paper card, QR code

**Given** the user selects QR code mode
**When** they point their camera at a QR code
**Then** the QR code is detected and decoded per FR-SCN-04
**And** if it's a BioBiz card URL, the card is displayed for saving
**And** if it's another QR code, the content is processed appropriately

**Given** the scan fails (damaged/blurry QR)
**When** detection fails
**Then** a message is shown: "Couldn't read QR code — try moving closer or improving lighting"

**Given** low-light conditions
**When** the user taps the flashlight icon
**Then** the device flashlight toggles on/off per FR-SCN-07

### Story 6.2: Smart Capture & Paper Card OCR Scanning

As a user,
I want to scan paper business cards and extract contact details using AI/OCR,
So that I can digitize physical cards without manual entry.

**Acceptance Criteria:**

**Given** the user selects "Smart capture" mode
**When** they point the camera at a business card or any contact source
**Then** AI/OCR extracts contact details (name, email, phone, company, title) per FR-SCN-02

**Given** the user selects "Paper card" mode
**When** they photograph a traditional business card
**Then** OCR-optimized scanning extracts the card layout and fields per FR-SCN-03

**Given** contact details are extracted
**When** the scan completes
**Then** a review screen displays the extracted fields for the user to verify and correct before saving

**Given** no contact information is found
**When** the scan completes
**Then** a message is shown: "No contact information found — try again or enter manually"

### Story 6.3: Photo Library Import & Manual Entry

As a user,
I want to scan contacts from existing photos or enter them manually,
So that I have alternatives when live camera scanning isn't possible.

**Acceptance Criteria:**

**Given** the user taps the photo library import option
**When** they select an existing photo
**Then** the same OCR/AI extraction is performed on the photo per FR-SCN-06
**And** extracted results are shown for review

**Given** the user taps "Enter manually"
**When** the manual entry form opens
**Then** fields for name, email, phone, company, job title, and notes are available per FR-SCN-05
**And** the contact is saved to the contacts table on submission

---

## Epic 7: Contacts Management & Location Tagging

Users can manage their networking contacts — search, view details, add notes, see meeting history with location/date, receive push notifications for new contacts, and export contacts.

### Story 7.1: Contacts List & Search

As a user,
I want to view and search my contacts list,
So that I can find and manage people I've connected with.

**Acceptance Criteria:**

**Given** the user taps the Contacts tab
**When** they have contacts
**Then** a list of all contacts is displayed with name, company, and most recent interaction per FR-CON-01

**Given** the contacts list
**When** the user types in the search bar
**Then** contacts are filtered by name, email, phone, or company in real-time per FR-CON-01

**Given** the user has no contacts
**When** the contacts screen loads
**Then** an empty state is displayed: "No contacts yet — When you share your card and they share their details back, it will appear here."
**And** a "Share my card" CTA is displayed per FR-CON-06

### Story 7.2: Contact Detail View, Notes & Meeting History

As a user,
I want to view full contact details, add notes, and see where/when we met,
So that I can maintain context about my professional relationships.

**Acceptance Criteria:**

**Given** the user taps a contact in the list
**When** the contact detail view opens
**Then** all shared information is displayed (name, email, phone, company, social links, etc.) per FR-CON-07

**Given** the contact detail view
**When** the user scrolls to the notes section
**Then** a free-text notes field is available for adding and editing notes per FR-CON-08

**Given** the contact was created from a card share with location tagging
**When** the detail view is displayed
**Then** "Where we met" (place name + address) and "When we met" (date) are shown per FR-CON-09, FR-SHR-17

### Story 7.3: Mutual Exchange & Auto-Populated Contacts

As a user,
I want contacts to be automatically created when someone shares their card back after scanning mine,
So that mutual exchanges are seamless and automatic.

**Acceptance Criteria:**

**Given** the user shared their card with someone
**When** the recipient taps "Share my card back" on the web card viewer
**Then** a contact is automatically created in the user's contacts list per FR-CON-03
**And** the contact contains the recipient's shared information

**Given** a card share occurs
**When** location permission is granted
**Then** the share is geo-tagged with the current location and timestamp per FR-SHR-15, FR-SHR-16
**And** coordinates are reverse geocoded to a readable place name per FR-SHR-18

**Given** location permission
**When** the user is first prompted
**Then** the prompt explains "Want to remember where you meet people?" per FR-SHR-15
**And** location data is opt-in only per NFR-PRIV-01

### Story 7.4: Manual Contact Creation & Export

As a user,
I want to create contacts manually and export my contacts,
So that I can manage contacts from any source and use them outside the app.

**Acceptance Criteria:**

**Given** the user taps the "+" button on the contacts screen
**When** the manual creation form opens
**Then** fields for name, email, phone, company, job title, and notes are available per FR-CON-04

**Given** the user taps the export/share icon
**When** the export action is triggered
**Then** contacts are exported in a standard format (vCard/CSV) per FR-CON-05
**And** the OS share sheet opens to distribute the export file

### Story 7.5: Push Notifications for New Contacts

As a user,
I want to receive push notifications when someone shares their card with me,
So that I know immediately when I have a new connection.

**Acceptance Criteria:**

**Given** a mutual card exchange occurs
**When** a new contact is created for the user
**Then** a push notification is sent: "New contact: [name] shared their card with you" per FR-CON-02

**Given** the notification is received
**When** the user taps it
**Then** the app opens to the new contact's detail view

**Given** notifications are configured
**When** the system sends push notifications
**Then** FCM (Android) and APNs (iOS) are used via firebase_messaging per Architecture

---

## Epic 8: Premium Subscriptions & Monetization

Users can subscribe to premium plans, unlock advanced features, manage their subscription, and experience proper upgrade/downgrade flows.

### Story 8.1: Premium Feature Gates & Upgrade Prompts

As a user,
I want to see clear indicators of premium features with easy upgrade paths,
So that I understand the value of upgrading.

**Acceptance Criteria:**

**Given** a feature is premium-only (custom color, logo in QR, remove branding, unlimited AI, extra cards)
**When** a free-tier user attempts to use it
**Then** a "Premium" badge with lock icon is displayed per FR-MON-07
**And** an upgrade prompt explains the feature and offers to start a subscription

**Given** the free tier
**When** the user is using the app
**Then** they have access to 2 cards and basic features per FR-MON-01

**Given** the premium tier
**When** the user is subscribed
**Then** they have access to 5 cards, custom colors, logo in QR, branding removal, unlimited AI Notetaker, and email via platform servers per FR-MON-02

### Story 8.2: Subscription Purchase Flow & Pricing

As a user,
I want to view pricing plans and subscribe through in-app purchases,
So that I can unlock premium features.

**Acceptance Criteria:**

**Given** the user navigates to the Premium screen
**When** the pricing is displayed
**Then** monthly and annual subscription options are shown per FR-MON-03
**And** pricing is localized per region (e.g., KES for Kenya) per FR-MON-05
**And** the annual plan shows "Save X%" discount messaging per FR-MON-08

**Given** the user taps subscribe
**When** on mobile
**Then** the in-app purchase flow is initiated via RevenueCat (Google Play / App Store billing) per FR-MON-06

**Given** the 7-day free trial
**When** the user starts a trial
**Then** full premium features are available for 7 days per FR-MON-04
**And** the trial is enforced as one per account, server-side (not bypassable via reinstall) per FR-MON-12

### Story 8.3: Subscription Management, Downgrade & Grace Period

As a premium user,
I want to manage my subscription and have a graceful experience if I downgrade,
So that I don't lose work and understand what changes.

**Acceptance Criteria:**

**Given** a payment fails
**When** the grace period begins
**Then** the user retains premium features for 7 days per FR-MON-09
**And** up to 3 automatic payment retries are attempted

**Given** the user downgrades (or payment retries fail)
**When** the downgrade is processed
**Then** excess cards beyond the free tier limit (2) are archived to read-only per FR-MON-10
**And** the user is prompted to choose which cards remain active

**Given** a downgrade occurs
**When** premium-only features are reverted
**Then** custom color reverts to default, logo is removed from QR, branding is restored per FR-MON-11

---

## Epic 9: AI Notetaker & Meeting Summaries

Users can record meetings, get AI-powered transcriptions and summaries, link recordings to contacts, and manage recording privacy/retention.

### Story 9.1: Meeting Recording & Consent

As a user,
I want to record meetings with a consent confirmation,
So that I can capture conversations ethically and review them later.

**Acceptance Criteria:**

**Given** the user taps the AI Notetaker tab
**When** the screen loads
**Then** the recording interface is displayed with: description text, consent notice, and record button per FR-AIN-01

**Given** the user taps the record button
**When** the recording is about to start
**Then** a consent confirmation is shown: "By starting, you confirm everybody has given consent" per FR-AIN-04
**And** the user must explicitly confirm before recording begins

**Given** the user is recording
**When** the recording is in progress
**Then** a timer shows elapsed duration
**And** free tier users have a limited recording duration; premium users can record up to 12 hours per FR-AIN-06

**Given** the user has no recordings
**When** the screen loads
**Then** an empty state is shown: "No recordings yet — tap record to get started"

### Story 9.2: AI Transcription & Summary Generation

As a user,
I want my recordings to be transcribed and summarized by AI,
So that I can quickly review key insights and action items from meetings.

**Acceptance Criteria:**

**Given** the user stops a recording
**When** the recording is complete
**Then** the audio is uploaded to Supabase Storage (encrypted at rest) per FR-AIN-08
**And** a background job sends the audio to Deepgram for transcription per FR-AIN-02

**Given** the transcription completes
**When** the transcript is available
**Then** the transcript is sent to Claude API for summary generation per FR-AIN-03
**And** the summary includes: who was met, key insights, and action items/next steps

**Given** premium users
**When** they generate summaries
**Then** unlimited AI summaries are available per FR-AIN-07

**Given** free tier users
**When** they use the AI Notetaker
**Then** usage limits are enforced per the free tier restrictions

### Story 9.3: Recording Management, Linking & Privacy

As a user,
I want to link recordings to contacts and manage recording privacy and retention,
So that my meeting notes are organized and my data is protected.

**Acceptance Criteria:**

**Given** a recording is completed
**When** the user views the summary
**Then** they can link the recording to one or more contact entries per FR-AIN-05

**Given** recording storage
**When** recordings are stored
**Then** they are encrypted at rest in a region-compliant cloud bucket per FR-AIN-08
**And** default retention period is 90 days (configurable by user)

**Given** a GDPR deletion request
**When** any recorded party requests deletion of recordings containing their voice
**Then** the recordings are deleted per FR-AIN-09

**Given** an account deletion
**When** the owning account is deleted
**Then** all recordings are permanently deleted per FR-AIN-10

**Given** recording access
**When** any user attempts to access a recording
**Then** access is restricted to the account owner only — no shared or team access per FR-AIN-11

---

## Epic 10: Advanced Features & Platform Extensions

Users can access advanced platform capabilities — home screen QR widgets, NFC tap-to-share, email signature generator, content moderation, and additional discover features.

### Story 10.1: Home Screen QR Code Widget (Android & iOS)

As a user,
I want a home screen widget showing my QR code,
So that I can share my card without even opening the app.

**Acceptance Criteria:**

**Given** the user sets up the widget
**When** they add a BioBiz widget to their Android home screen
**Then** a 3x2 QR code widget is displayed showing the active card's QR code per FR-SHR-19, FR-SHR-21

**Given** the user is on iOS
**When** they add a BioBiz widget
**Then** a home screen QR code widget is displayed per FR-SHR-20, FR-SHR-21

**Given** the user changes their active card
**When** the active card is updated
**Then** the widget automatically updates to show the new active card's QR code

**Given** the widget is tapped
**When** the user taps it
**Then** the BioBiz app opens to the My Card screen

### Story 10.2: NFC Tag Pairing & Tap-to-Share

As a user,
I want to pair NFC tags and share my card via tap,
So that I can share my card by simply tapping a physical NFC accessory.

**Acceptance Criteria:**

**Given** the user navigates to Settings > Pair NFC
**When** they initiate NFC pairing
**Then** the app enters NFC write mode and prompts the user to tap their NFC tag/card per FR-DSC-01

**Given** the NFC tag is successfully paired
**When** someone taps their phone on the NFC tag
**Then** the card URL is transmitted and opens in the recipient's browser

**Given** the user changes their active card after pairing
**When** the NFC tag is tapped
**Then** the permanent redirect URL ensures the current active card is shown

### Story 10.3: Email Signature Generator

As a user,
I want to generate an HTML email signature from my card data,
So that I can use my digital card information in my email communications.

**Acceptance Criteria:**

**Given** the user navigates to Discover > Email signature
**When** the generator loads
**Then** an HTML email signature is generated from the active card's data (name, title, company, contact info, social links) per FR-DSC-02

**Given** the signature is generated
**When** the user reviews it
**Then** they can copy the HTML to clipboard
**And** instructions are provided for adding it to common email clients (Gmail, Outlook, Apple Mail)

### Story 10.4: Content Moderation & Security

As a platform,
I want user-generated content to be sanitized and protected against abuse,
So that public card pages are safe for all visitors.

**Acceptance Criteria:**

**Given** user-generated text is rendered on public card URLs
**When** the web card viewer renders content
**Then** all text fields are sanitized (strip scripts, HTML injection) per FR-SEC-01

**Given** a visitor views a shared card link
**When** they suspect abuse
**Then** a report button is available on the web card viewer per FR-SEC-02

**Given** user-provided links on cards
**When** links are saved
**Then** phishing/malware URL scanning is performed per FR-SEC-03
**And** known-bad URLs are blocked and suspicious patterns are flagged

### Story 10.5: Additional Discover Features (Virtual Background, Lead Capture, Referrals)

As a user,
I want access to additional platform features for professional networking,
So that I can extend my BioBiz experience beyond basic card sharing.

**Acceptance Criteria:**

**Given** the user navigates to Discover > Virtual background
**When** the generator loads
**Then** a branded video call background is generated from their card data per FR-DSC-03

**Given** the user navigates to Discover > Lead capture
**When** the feature loads
**Then** they can create a form/landing page for capturing leads per FR-DSC-04

**Given** the user taps "Invite friends"
**When** the referral flow starts
**Then** a shareable referral link/message is generated per FR-DSC-08

### Story 10.6: CRM Integration & Team Management (Future)

As a power user or team admin,
I want to sync contacts with CRM platforms and manage team cards,
So that BioBiz integrates into my existing workflow.

**Acceptance Criteria:**

**Given** the user navigates to Discover > CRM integration
**When** they select a CRM (Salesforce, HubSpot, etc.)
**Then** an OAuth connection flow is initiated per FR-DSC-05
**And** contacts sync bidirectionally between BioBiz and the CRM

**Given** the user navigates to "Get BioBiz for your team"
**When** the team management feature loads
**Then** admin controls for managing organization cards and members are available per FR-DSC-06

### Story 10.7: Smartwatch Companion App

As a user with a smartwatch,
I want to view and share my QR code from my wrist,
So that I can share my card without reaching for my phone.

**Acceptance Criteria:**

**Given** the user has an Android Wear or watchOS smartwatch
**When** they install the BioBiz companion app
**Then** the active card's QR code is displayed on the watch face per FR-DSC-07

**Given** the companion app is running
**When** the user shows their wrist to someone
**Then** the QR code can be scanned directly from the watch
