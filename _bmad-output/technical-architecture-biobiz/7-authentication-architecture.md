# 7. Authentication Architecture

```
┌──────────────────────────────────┐
│         Supabase Auth            │
│                                  │
│  ┌────────────┐ ┌─────────────┐ │
│  │ Email/Pass │ │ OAuth 2.0   │ │
│  │ + OTP      │ │ Google      │ │
│  │            │ │ Microsoft   │ │
│  │            │ │ Apple       │ │
│  └────────────┘ └─────────────┘ │
│                                  │
│  Returns: JWT (access + refresh) │
└──────────────┬───────────────────┘
               │
               ▼
    Flutter: supabase_flutter manages session
             (stored in flutter_secure_storage)
    Web: Stored in httpOnly cookie
               │
               ▼
    Flutter → Supabase direct (RLS enforced)
    Flutter → Next.js API (Bearer JWT in header via dio interceptor)
               │
               ▼
    Supabase RLS validates auth.uid()
    against row ownership
```

**Session Lifecycle (Flutter):**

| Event | Behavior |
|-------|----------|
| App launch | `supabase_flutter` auto-restores session from `flutter_secure_storage` |
| Token near expiry | `supabase_flutter` auto-refreshes (built-in) |
| App backgrounded >1 hour | On resume, check session validity; if refresh token expired, redirect to login with preserved navigation state |
| dio 401 response | Interceptor calls `supabase.auth.refreshSession()`, retries request once. If refresh fails, emit auth error event → redirect to login |
| Account deletion | Cancel any active provider subscription (Stripe/RevenueCat) **before** CASCADE delete. Confirm with user via dialog |

**Token flow for Next.js API calls:**
The `dio` interceptor reads `supabase.auth.currentSession?.accessToken` on every request. It never stores or caches a separate copy. This ensures dio always uses the same token that `supabase_flutter` manages.

---
