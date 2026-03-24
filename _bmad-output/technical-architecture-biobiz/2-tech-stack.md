# 2. Tech Stack

## 2.1 Mobile App (Flutter)

| Layer | Technology | Rationale |
|-------|-----------|-----------|
| Framework | **Flutter 3.x (Dart)** | Cross-platform (Android + iOS) with pixel-perfect rendering, excellent for UI-heavy card editor |
| Navigation | **go_router** | Declarative routing with deep linking, redirect guards, nested navigation |
| State Management | **flutter_riverpod** | Reactive, testable, compile-safe state management with code generation |
| UI Components | **Material 3 + custom widgets** | Material Design 3 with custom card rendering widgets |
| Camera/Scanner | **camera** + **mobile_scanner** | Camera feed for scanning, QR/barcode detection |
| OCR | **google_mlkit_text_recognition** | On-device text recognition for business card scanning |
| NFC | **nfc_manager** | NFC tag reading/writing for tap-to-share |
| Local Storage | **flutter_secure_storage** + **hive** | Secure credential storage + fast local key-value cache |
| Push Notifications | **firebase_messaging** + **flutter_local_notifications** | FCM/APNs push notifications |
| Widgets | **home_widget** | Android + iOS home screen QR code widget |
| Audio Recording | **record** | Meeting recording for AI Notetaker |
| Image Handling | **image_picker** + **image_cropper** | Photo selection, circular cropping, resizing |
| QR Generation | **qr_flutter** | Client-side QR code rendering with logo embedding |
| Maps/Location | **geolocator** + **geocoding** | Geo-tagging card shares + reverse geocoding |
| HTTP Client | **dio** | HTTP client for Next.js API calls only (AI processing, logo detection, email sending, webhooks). Auth token injected via interceptor that reads from `supabase_flutter` session |
| Supabase SDK | **supabase_flutter** | Official Supabase client — auth, database CRUD, storage, realtime. Primary data access layer; all RLS-protected operations go through this SDK directly |
| Freezed Models | **freezed** + **json_serializable** | Immutable data classes with JSON serialization |

## 2.2 Web (Card Viewer + Landing Pages)

| Layer | Technology | Rationale |
|-------|-----------|-----------|
| Framework | **Next.js 15 (App Router)** | SSR for card pages (SEO + fast loading), API routes for backend |
| Styling | **Tailwind CSS** | Rapid UI development, consistent with mobile design tokens |
| Card Rendering | **React** server components | Fast initial card load for recipients |
| QR Generation | **qrcode** (npm) | Server-side QR generation for OG images |
| Analytics | **Plausible** or **PostHog** | Privacy-friendly card view tracking |

## 2.3 Backend / API

| Layer | Technology | Rationale |
|-------|-----------|-----------|
| API | **Next.js API Routes** | Co-located with web card viewer, handles server-side logic |
| Database | **Supabase (PostgreSQL)** | Managed Postgres with built-in auth, storage, realtime |
| Auth | **Supabase Auth** | Email/password, OAuth (Google, Microsoft, Apple), OTP — Flutter uses `supabase_flutter` SDK directly |
| File Storage | **Supabase Storage** | Profile photos, logos, cover photos, QR images |
| Realtime | **Supabase Realtime** | Live contact notifications, card update sync — Flutter subscribes directly |
| Background Jobs | **Trigger.dev** or **Inngest** | Async tasks: email sending, AI processing, logo scraping |
| Email | **Resend** | Transactional emails (OTP, card sharing, notifications) |
| Payments | **RevenueCat** (mobile) + **Stripe** (web) | In-app purchases + web subscription management |

## 2.4 AI Services

| Service | Technology | Rationale |
|---------|-----------|-----------|
| Audio Transcription | **Deepgram** | Fast, accurate, affordable speech-to-text |
| AI Summarization | **Claude API (Anthropic)** | Meeting summary generation, insight extraction |
| OCR (server-side) | **Google Cloud Vision** or **Tesseract** | Fallback OCR for complex card scans |
| Logo Detection | **Clearbit Logo API** or custom scraper | Auto-detect company logo from website URL |

## 2.5 Infrastructure

| Layer | Technology | Rationale |
|-------|-----------|-----------|
| Hosting | **Vercel** | Next.js-native hosting, edge functions, CDN |
| Database | **Supabase Cloud** | Managed Postgres, auto-backups, connection pooling |
| CDN | **Vercel Edge Network** + **Supabase CDN** | Fast card page loads globally |
| Monitoring | **Sentry** (via `sentry_flutter`) | Error tracking for mobile + web |
| CI/CD | **GitHub Actions** + **Fastlane** + **Codemagic** | Automated builds, tests, app store submissions |

## 2.6 Project Structure

The Flutter app and Next.js web/API are separate projects sharing the same Supabase backend.

### Flutter Mobile App

```
biobiz_mobile/
├── lib/
│   ├── main.dart                    # App entry point
│   ├── app/
│   │   ├── app.dart                 # MaterialApp + theme + router setup
│   │   ├── router.dart              # go_router configuration
│   │   └── theme.dart               # Material 3 theme + color schemes
│   │
│   ├── core/
│   │   ├── constants/
│   │   │   ├── social_platforms.dart # 22+ social platform definitions
│   │   │   ├── color_presets.dart    # Card color palette
│   │   │   └── app_constants.dart    # Free/premium limits, etc.
│   │   ├── models/                   # Freezed data classes
│   │   │   ├── card_model.dart
│   │   │   ├── contact_model.dart
│   │   │   ├── profile_model.dart
│   │   │   ├── recording_model.dart
│   │   │   └── subscription_model.dart
│   │   ├── services/
│   │   │   ├── supabase_service.dart # Supabase client singleton
│   │   │   ├── api_client.dart       # dio instance for Next.js API (Riverpod-managed)
│   │   │   ├── auth_service.dart     # Auth logic (email, OAuth, OTP)
│   │   │   ├── storage_service.dart  # File upload/download
│   │   │   ├── location_service.dart # Geolocator + geocoding
│   │   │   ├── nfc_service.dart      # NFC pairing
│   │   │   └── notification_service.dart
│   │   ├── providers/                # Riverpod providers
│   │   │   ├── auth_provider.dart
│   │   │   ├── cards_provider.dart
│   │   │   ├── contacts_provider.dart
│   │   │   └── subscription_provider.dart
│   │   └── utils/
│   │       ├── validators.dart       # Input validation
│   │       ├── slug_generator.dart   # URL-friendly card slugs
│   │       └── vcard_parser.dart     # vCard import/export
│   │
│   └── features/
│       ├── onboarding/
│       │   ├── screens/
│       │   │   ├── landing_screen.dart
│       │   │   ├── name_screen.dart
│       │   │   ├── contact_info_screen.dart
│       │   │   ├── professional_details_screen.dart
│       │   │   ├── logo_screen.dart
│       │   │   ├── profile_picture_screen.dart
│       │   │   ├── create_account_screen.dart
│       │   │   ├── otp_verification_screen.dart
│       │   │   └── card_preview_screen.dart
│       │   └── widgets/
│       │       ├── progress_indicator.dart
│       │       └── onboarding_scaffold.dart
│       │
│       ├── card_editor/
│       │   ├── screens/
│       │   │   └── card_editor_screen.dart
│       │   └── widgets/
│       │       ├── color_picker_section.dart
│       │       ├── images_layout_section.dart
│       │       ├── personal_details_section.dart
│       │       ├── contact_fields_section.dart
│       │       ├── social_links_grid.dart
│       │       ├── qr_code_section.dart
│       │       └── reorderable_contact_list.dart
│       │
│       ├── card_view/
│       │   ├── screens/
│       │   │   └── my_card_screen.dart
│       │   └── widgets/
│       │       ├── card_renderer.dart   # The actual card visual
│       │       ├── card_header.dart
│       │       └── contact_field_row.dart
│       │
│       ├── sharing/
│       │   ├── screens/
│       │   │   └── share_card_screen.dart
│       │   └── widgets/
│       │       ├── qr_display.dart
│       │       ├── share_channel_list.dart
│       │       └── location_tag_prompt.dart
│       │
│       ├── scanner/
│       │   ├── screens/
│       │   │   └── scan_screen.dart
│       │   └── widgets/
│       │       ├── camera_viewfinder.dart
│       │       ├── scan_mode_tabs.dart
│       │       └── scanned_contact_review.dart
│       │
│       ├── ai_notetaker/
│       │   ├── screens/
│       │   │   ├── notetaker_screen.dart
│       │   │   └── recording_summary_screen.dart
│       │   └── widgets/
│       │       ├── record_button.dart
│       │       └── consent_banner.dart
│       │
│       ├── contacts/
│       │   ├── screens/
│       │   │   ├── contacts_list_screen.dart
│       │   │   └── contact_detail_screen.dart
│       │   └── widgets/
│       │       ├── contact_card.dart
│       │       └── contact_notes_section.dart
│       │
│       ├── premium/
│       │   ├── screens/
│       │   │   └── premium_screen.dart
│       │   └── widgets/
│       │       ├── pricing_cards.dart
│       │       └── feature_comparison.dart
│       │
│       └── settings/
│           └── screens/
│               ├── menu_screen.dart
│               └── manage_account_screen.dart
│
├── android/                          # Android native config
│   └── app/src/main/
│       └── AndroidManifest.xml       # NFC, camera, location permissions
├── ios/                              # iOS native config
│   └── Runner/Info.plist             # Permissions, deep links
├── pubspec.yaml                      # Dependencies
├── analysis_options.yaml             # Lint rules
└── build.yaml                        # build_runner config (freezed, riverpod_generator)
```

### Next.js Web App + API

```
biobiz_web/
├── app/
│   ├── card/[slug]/
│   │   └── page.tsx          # Public card viewer (SSR)
│   ├── api/
│   │   ├── cards/            # Card CRUD endpoints
│   │   ├── contacts/         # Contact endpoints
│   │   ├── shares/           # Sharing endpoints
│   │   ├── recordings/       # AI Notetaker endpoints
│   │   ├── subscription/     # Payment webhooks
│   │   └── utils/            # Logo detection, geocoding
│   └── dashboard/            # Future admin dashboard
├── components/               # Web UI components
├── lib/
│   └── supabase.ts           # Supabase server client
├── next.config.js
├── tailwind.config.ts
└── package.json
```

### Supabase (shared backend)

```
biobiz_supabase/
├── migrations/               # SQL migration files
├── seed.sql                  # Seed data
├── config.toml               # Supabase project config
└── functions/                # Supabase Edge Functions (optional)
    └── process-recording/    # AI transcription + summarization
```

---
