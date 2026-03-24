# 4. API Design

## 4.1 Core Endpoints

```
AUTH (Supabase Auth handles these):
  POST   /auth/signup              # Email + password
  POST   /auth/signin              # Email + password / OAuth
  POST   /auth/otp                 # Send OTP
  POST   /auth/verify-otp          # Verify OTP
  POST   /auth/oauth/:provider     # Google, Microsoft, Apple

CARDS:
  GET    /api/cards                 # List user's cards
  POST   /api/cards                # Create new card
  GET    /api/cards/:id            # Get card by ID
  PUT    /api/cards/:id            # Update card
  DELETE /api/cards/:id            # Delete card
  PUT    /api/cards/:id/activate   # Set as active card
  GET    /api/cards/:id/qr         # Generate/get QR code

  # Card sub-resources
  GET    /api/cards/:id/contact-fields
  POST   /api/cards/:id/contact-fields
  PUT    /api/cards/:id/contact-fields/:fieldId
  DELETE /api/cards/:id/contact-fields/:fieldId
  PUT    /api/cards/:id/contact-fields/reorder   # Batch reorder

  GET    /api/cards/:id/social-links
  POST   /api/cards/:id/social-links
  PUT    /api/cards/:id/social-links/:linkId
  DELETE /api/cards/:id/social-links/:linkId
  PUT    /api/cards/:id/social-links/reorder    # Batch reorder

  GET    /api/cards/:id/accreditations
  POST   /api/cards/:id/accreditations
  PUT    /api/cards/:id/accreditations/:accId
  DELETE /api/cards/:id/accreditations/:accId
  PUT    /api/cards/:id/accreditations/reorder  # Batch reorder

PUBLIC CARD VIEWER:
  GET    /card/:slug               # SSR card page (Next.js page, not API)
  GET    /api/public/cards/:slug   # Card data for public viewing
  POST   /api/public/cards/:slug/view   # Track card view

SHARING:
  POST   /api/shares               # Record a card share (with optional location)
  POST   /api/shares/email         # Send card via email (server-side)
  POST   /api/shares/sms           # Send card via SMS (Twilio/similar)
  GET    /api/shares/stats/:cardId # Share analytics

CONTACTS:
  GET    /api/contacts             # List contacts (with search)
  POST   /api/contacts             # Create contact (manual)
  GET    /api/contacts/:id         # Get contact detail
  PUT    /api/contacts/:id         # Update contact
  DELETE /api/contacts/:id         # Delete contact
  POST   /api/contacts/scan        # Upload scanned image for OCR
  POST   /api/contacts/exchange    # Record mutual card exchange

  # Contact notes
  GET    /api/contacts/:id/notes
  POST   /api/contacts/:id/notes
  PUT    /api/contacts/:id/notes/:noteId
  DELETE /api/contacts/:id/notes/:noteId

AI NOTETAKER:
  POST   /api/recordings           # Create recording entry + get upload URL
  PUT    /api/recordings/:id       # Update status (stop recording)
  POST   /api/recordings/:id/process  # Trigger transcription + AI summary
  GET    /api/recordings/:id       # Get recording with summary
  GET    /api/recordings           # List recordings

PROFILE & SETTINGS:
  GET    /api/profile              # Get user profile
  PUT    /api/profile              # Update profile
  DELETE /api/profile              # Delete account

SUBSCRIPTION:
  GET    /api/subscription         # Get current subscription status
  POST   /api/subscription/checkout  # Create checkout session
  POST   /api/subscription/webhook   # Stripe/RevenueCat webhook

UTILITIES:
  POST   /api/utils/detect-logo    # Scrape logo from website URL
  POST   /api/utils/geocode        # Reverse geocode coordinates to place name

NFC:
  POST   /api/nfc/pair             # Pair NFC device to card
  DELETE /api/nfc/:id              # Unpair NFC device
  GET    /api/nfc                  # List paired devices

PUSH NOTIFICATIONS:
  POST   /api/device-tokens        # Register/update device token
  DELETE /api/device-tokens/:id    # Remove device token (logout/uninstall)

EMAIL SIGNATURES:
  GET    /api/cards/:id/email-signature          # Get generated email signature HTML
  POST   /api/cards/:id/email-signature/generate # (Re)generate signature from card data
  GET    /api/cards/:id/email-signature/preview  # Preview signature in browser

PUBLIC (Web Card Viewer):
  POST   /api/public/cards/:slug/exchange-back  # Web-based mutual exchange (no app required)

ENRICHMENT:
  GET    /api/enrichment/prompts    # Get active enrichment prompts for user
  POST   /api/enrichment/dismiss    # Dismiss an enrichment prompt (with cooldown)
```

## 4.2 Key API Patterns

```typescript
// All API responses follow this shape (TypeScript for Next.js API):
type ApiResponse<T> = {
  data: T | null;
  error: { code: string; message: string } | null;
};

// Pagination (page must be >= 1, pageSize clamped to 1..100):
type PaginatedResponse<T> = ApiResponse<{
  items: T[];
  total: number;
  page: number;
  pageSize: number;
}>;

// Card creation enforces tier limits:
// Free: max 2 cards, Premium: max 5 cards
// Returns 403 with error code 'CARD_LIMIT_REACHED' + { current, max } counts
```

## 4.2.1 Standard Error Codes

```typescript
// Structured error codes returned across all endpoints:
const ERROR_CODES = {
  // Auth
  UNAUTHORIZED: 'UNAUTHORIZED',             // 401 — missing or invalid JWT
  FORBIDDEN: 'FORBIDDEN',                   // 403 — valid auth but insufficient permissions

  // Tier limits
  CARD_LIMIT_REACHED: 'CARD_LIMIT_REACHED', // 403 — free/premium card limit hit
  PREMIUM_REQUIRED: 'PREMIUM_REQUIRED',     // 403 — feature requires premium

  // Validation
  VALIDATION_ERROR: 'VALIDATION_ERROR',     // 422 — Zod schema validation failed
  INVALID_SLUG: 'INVALID_SLUG',             // 422 — slug format invalid
  SLUG_TAKEN: 'SLUG_TAKEN',                 // 409 — slug already exists
  DUPLICATE_CONTACT: 'DUPLICATE_CONTACT',   // 409 — contact with same email exists, returns existing ID for merge

  // Resources
  NOT_FOUND: 'NOT_FOUND',                   // 404
  GONE: 'GONE',                             // 410 — deleted card/profile

  // Processing
  PROCESSING_FAILED: 'PROCESSING_FAILED',   // 500 — AI/OCR processing error
  ALREADY_PROCESSING: 'ALREADY_PROCESSING', // 409 — idempotency guard on /process

  // Rate limiting
  RATE_LIMITED: 'RATE_LIMITED',              // 429
} as const;
```

## 4.2.2 Rate Limiting

```
Rate limits enforced via Vercel Edge Middleware (next.config.js headers + custom middleware):

Public endpoints (unauthenticated):
  GET  /card/:slug              — 60 req/min per IP
  GET  /api/public/cards/:slug  — 60 req/min per IP
  POST /api/public/cards/:slug/view — 10 req/min per IP (prevents inflated view counts)

Authenticated endpoints:
  POST /api/cards               — 10 req/min per user
  POST /api/recordings          — 5 req/min per user
  POST /api/recordings/:id/process — 3 req/min per user (expensive AI calls)
  POST /api/shares/email        — 10 req/min per user
  POST /api/shares/sms          — 10 req/min per user
  POST /api/contacts/scan       — 10 req/min per user

Utility endpoints (abuse vectors):
  POST /api/utils/detect-logo   — 5 req/min per user (server-side web scraping)
  POST /api/utils/geocode       — 20 req/min per user

Default for all other authenticated endpoints: 60 req/min per user
Response: 429 with Retry-After header
```

## 4.2.3 Idempotency & Validation

```
Idempotency:
  POST /api/recordings/:id/process — Skip if status is already 'processing' or 'completed'.
    Return existing summary if 'completed'. Return 409 ALREADY_PROCESSING if 'processing'.
  POST /api/subscription/webhook — Deduplicate by provider event ID stored in webhook_events table.
  POST /api/contacts/exchange — Deduplicate by (user_id, source_card_id) pair.

Input validation (Zod on all API routes):
  - Card color: regex /^#[0-9a-fA-F]{6}$/
  - Phone numbers: E.164 format validation before SMS send
  - URLs: must be valid URL with http/https scheme
  - Pagination: page >= 1, pageSize 1..100, non-integer returns 422
  - File uploads: MIME type validated via magic bytes, not just extension
  - Coordinates: lat -90..90, lng -180..180
```

```dart
// Dart equivalent models (via freezed):
@freezed
class ApiResponse<T> with _$ApiResponse<T> {
  const factory ApiResponse({
    T? data,
    ApiError? error,
  }) = _ApiResponse;
}

@freezed
class ApiError with _$ApiError {
  const factory ApiError({
    required String code,
    required String message,
  }) = _ApiError;

  factory ApiError.fromJson(Map<String, dynamic> json) =>
      _$ApiErrorFromJson(json);
}
```

## 4.3 Flutter ↔ Supabase Direct Access

The Flutter app talks to Supabase directly for most operations via `supabase_flutter`. The `dio` HTTP client is used **only** for calls to the Next.js API (server-side operations the client cannot do directly).

**Via `supabase_flutter` (direct, RLS-protected):**
- Auth (signup, login, OAuth, OTP, session management)
- All CRUD operations (cards, contacts, notes, social links, etc.)
- File storage (upload/download profile images, logos, audio)
- Realtime subscriptions (new contact notifications, card update sync)

**Via `dio` → Next.js API (server-side only):**
- `POST /api/recordings/:id/process` — AI transcription + summarization (requires API keys)
- `POST /api/utils/detect-logo` — server-side web scraping (SSRF-protected)
- `POST /api/shares/email` — email sending via Resend
- `POST /api/shares/sms` — SMS sending
- `POST /api/subscription/checkout` — create payment session

**Token management:** The `dio` interceptor reads the current access token from `supabase_flutter`'s session (single source), never caches its own copy. On 401 response, it triggers `supabase.auth.refreshSession()` then retries once.

```dart
// Flutter Supabase usage pattern:
final supabase = Supabase.instance.client;

// Auth
await supabase.auth.signInWithOtp(email: 'user@email.com');
await supabase.auth.signInWithOAuth(OAuthProvider.google);

// CRUD (uses RLS — no API needed)
final cards = await supabase.from('cards').select().eq('user_id', userId);
await supabase.from('cards').insert(cardData);
await supabase.from('cards').update(updates).eq('id', cardId);

// Storage
await supabase.storage.from('cards').upload('$cardId/logo.png', file);

// Realtime (with reconnection)
supabase.from('contacts').stream(primaryKey: ['id']).eq('user_id', userId).listen(
  (data) { /* New contact notification */ },
  onError: (err) { /* Exponential backoff reconnect + catch-up query */ },
);

// dio for server-side operations only
final apiClient = ref.read(apiClientProvider);  // Riverpod-managed dio instance
final result = await apiClient.post('/api/recordings/$id/process');
```

---
