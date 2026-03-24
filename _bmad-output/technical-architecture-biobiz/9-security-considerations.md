# 9. Security Considerations

| Area | Approach |
|------|---------|
| **Data at rest** | Supabase encrypts all data at rest (AES-256) |
| **Data in transit** | HTTPS/TLS everywhere |
| **Authentication** | JWT with short expiry + refresh tokens, OAuth 2.0 |
| **Authorization** | Supabase RLS (row-level security) on all tables with complete per-table policies (see Section 3.2) |
| **PII handling** | Minimal data collection, encrypted storage, GDPR-ready |
| **File uploads** | MIME validated via magic bytes (not extension), per-bucket size limits (see Section 6), allowed type allowlist |
| **Rate limiting** | Per-endpoint rate limits enforced via Vercel Edge Middleware (see Section 4.2.2) |
| **Input validation** | Zod schemas on all API inputs, Dart validators in Flutter, DB-level CHECK constraints |
| **XSS prevention** | React auto-escaping + CSP headers on card pages |
| **Location data** | Opt-in only, stored with consent, deletable, coordinate range validated at DB level |
| **Recording consent** | Explicit consent UI before recording starts |
| **SSRF protection** | `/api/utils/detect-logo` validates URLs against public DNS only; blocks private IP ranges (10.x, 172.16.x, 192.168.x, 127.x, ::1), enforces 5s timeout, 5MB response size limit |
| **Webhook security** | Stripe/RevenueCat webhook signature verification required; event deduplication via `webhook_events` table; reject events with timestamps >5 min old |
| **Account deletion** | Pre-delete: cancel active provider subscriptions, confirm via dialog. CASCADE deletes all user data. Storage files cleaned up via background job |

---
