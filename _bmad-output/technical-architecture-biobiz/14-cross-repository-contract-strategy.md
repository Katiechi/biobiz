# 14. Cross-Repository Contract Strategy

The multi-repo setup (Flutter, Next.js, Supabase) requires explicit contracts to prevent type drift.

## 14.1 Shared Type Definitions

```
biobiz_supabase/ (source of truth)
├── migrations/           # SQL schema = canonical data contract
├── types/
│   ├── database.ts       # Auto-generated via `supabase gen types typescript`
│   └── database.dart     # Auto-generated via custom script from database.ts
└── api-contracts/
    └── openapi.yaml      # API contract for Next.js endpoints consumed by Flutter
```

## 14.2 Contract Enforcement

| Mechanism | Scope | When |
|-----------|-------|------|
| `supabase gen types typescript` | DB → TypeScript types | CI on every migration merge |
| Custom codegen script | TypeScript types → Dart freezed models | CI on type changes |
| OpenAPI spec for Next.js API | API request/response shapes | Manual, validated in CI via `openapi-typescript` |
| CI integration test | Smoke test: Flutter → Supabase → Next.js | On PR to any repo |

## 14.3 Migration Safety

```
1. Schema change in biobiz_supabase → PR triggers:
   → Generate updated TypeScript types
   → Generate updated Dart models
   → Run integration tests against all three repos
2. Breaking changes require coordinated deployment:
   → Add new column (nullable) → deploy web → deploy mobile → backfill → make non-nullable
```

---
