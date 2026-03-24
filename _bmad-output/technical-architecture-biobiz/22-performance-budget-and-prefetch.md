# 22. Performance Budget & Prefetch Strategy

The UX spec defines a critical performance target: **time-to-share under 1 second** (app launch to scannable QR visible). This section defines the performance budget, prefetch strategy, and architectural decisions that make this target achievable.

## 22.1 Performance Budget

| Metric | Target | Measurement Point |
|--------|--------|-------------------|
| **Time to share (warm)** | < 1 second | App resume from background → QR visible |
| **Time to share (cold)** | < 2 seconds | App cold start → QR visible |
| **Card page SSR load** | < 1 second | QR scan → card fully rendered in browser |
| **QR code render** | < 500ms | QR generation from URL string |
| **Image upload** | Progress shown within 200ms | User sees upload indicator immediately |
| **Card editor save** | < 300ms perceived | Optimistic UI update, sync in background |
| **Contact list render** | < 500ms for 100 contacts | Initial list render with cached data |

## 22.2 Time-to-Share Architecture

The < 1 second target requires that the My Card screen with QR code loads entirely from local cache, with zero network dependency.

### Data Prefetch Strategy

```
On app cold start:
  1. Load card data from Hive cache (< 50ms)
  2. Render QR from cached card URL using qr_flutter (< 100ms)
  3. Load cached profile/logo images via cached_network_image (< 100ms)
  4. Display My Card screen immediately from cache
  5. Background: fetch fresh data from Supabase, diff against cache, update if changed

On app resume from background:
  1. Card data already in memory (Riverpod state persisted) — instant render
  2. QR already rendered — no regeneration needed
  3. If backgrounded < 5 minutes: no network fetch
  4. If backgrounded > 5 minutes: background refresh

Result: QR visible in < 1 second from either cold or warm start
```

### Cache Architecture

```
Hive boxes (persistent local cache):
  ├── card_cache        → Active card data (CardModel serialized)
  ├── contacts_cache    → Contact list (paginated, first 50 cached)
  ├── profile_cache     → User profile data
  └── widget_cache      → Data for home screen widget

cached_network_image:
  → Profile photos, logos, cover images cached on disk
  → Cache duration: 7 days (stale-while-revalidate pattern)
  → Max cache size: 100MB

QR code:
  → Pre-rendered as PNG, stored in app directory
  → Regenerated only when card slug changes (rare — slugs are immutable)
  → Widget also stores its own copy (shared app group directory)
```

## 22.3 Web Card Viewer Performance

The card page at `/card/:slug` must load in < 1 second on a 3G connection. This is critical because recipients scan QR codes on their phones, often at events with poor connectivity.

### SSR Optimization

```
Next.js App Router with server components:

1. Static generation with ISR:
   → Card pages generated at build time for popular cards
   → Revalidated every 60 seconds (or on card update via webhook)
   → generateStaticParams() pre-generates top 1000 cards by view count

2. Edge rendering:
   → Vercel Edge Runtime for card page route
   → Card data fetched from Supabase (closest region)
   → HTML streamed to client

3. Critical CSS:
   → Card page CSS inlined in <head> (< 5KB)
   → No external stylesheet blocking render

4. Image optimization:
   → Profile photos served via Supabase CDN with transformation:
     ?width=200&height=200&resize=cover (pre-sized for card display)
   → Logos: ?width=80&height=80
   → Cover images: ?width=600&height=200
   → WebP format with JPEG fallback
   → <img loading="eager"> for above-fold images (profile, logo)

5. Font loading:
   → System fonts only (no web font loading delay)
   → Matches UX spec: "Use system fonts via Material 3's default type scale"
```

### Response Headers

```
Card page (HTML):
  Cache-Control: public, s-maxage=60, stale-while-revalidate=300
  → CDN caches for 60s, serves stale for 5 min while revalidating

Card data API (/api/public/cards/:slug):
  Cache-Control: public, s-maxage=30, stale-while-revalidate=120

vCard download (/api/public/cards/:slug/vcard):
  Cache-Control: public, max-age=300
  → Invalidated on card update

OG image:
  Cache-Control: public, max-age=3600
  → Regenerated hourly or on card update
```

## 22.4 Flutter App Performance Guidelines

### Startup Optimization

```
1. Minimize main() work:
   → Initialize Supabase client
   → Initialize Hive
   → Load cached card data
   → Defer: Firebase init, notification setup, analytics

2. Splash screen:
   → Native splash (flutter_native_splash) — OS renders while Dart VM starts
   → No custom animated splash — contradicts "instant QR" goal

3. Deferred loading:
   → Scanner (camera) initialized only when Scan tab opened
   → AI Notetaker (record) initialized only when Notes tab opened
   → NFC initialized only if device supports it

4. Image optimization:
   → Profile photos resized to max 800x800 on upload (image_cropper)
   → Logos resized to max 400x400
   → Cover images resized to max 1200x400
   → All compressed to < 500KB before upload
```

### Runtime Performance

```
Key frame budget targets (60fps = 16.6ms per frame):
  → Card renderer: < 8ms build + paint
  → QR display: < 4ms (pre-rendered image, not drawn each frame)
  → Contact list item: < 2ms build
  → Editor section expand/collapse: use AnimatedContainer, not full rebuild

Riverpod optimization:
  → Use select() to watch specific fields, not entire models
  → Card renderer watches only visual fields (color, images, name)
  → Contact list uses AsyncNotifier with pagination
```

## 22.5 Performance Monitoring

| Metric | Tool | Alert Threshold |
|--------|------|----------------|
| App cold start | Sentry (sentry_flutter) performance monitoring | > 3 seconds |
| Card page SSR | Vercel Analytics + Sentry | > 2 seconds (p95) |
| QR render time | Custom Riverpod timing | > 1 second |
| Image upload duration | Sentry spans | > 10 seconds |
| API response time | Vercel Analytics | > 500ms (p95) |

---
