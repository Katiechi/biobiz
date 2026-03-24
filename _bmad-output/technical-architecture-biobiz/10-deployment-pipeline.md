# 10. Deployment Pipeline

```
GitHub
  │
  ├── biobiz_mobile (Flutter repo)
  │   ├── Push to main
  │   │   └── Codemagic: Run tests + lint (flutter analyze, flutter test)
  │   ├── Push to release/*
  │   │   └── Codemagic: Build + sign
  │   │       ├── Android → Google Play (internal track)
  │   │       └── iOS → TestFlight
  │   └── Git tag (v*.*.*)
  │       └── Codemagic: Build + submit to stores
  │           ├── Android → Google Play (production)
  │           └── iOS → App Store
  │
  ├── biobiz_web (Next.js repo)
  │   └── Push to main
  │       ├── Vercel: Auto-deploy web app
  │       └── GitHub Actions: Run tests + lint
  │
  └── biobiz_supabase (DB migrations repo)
      └── Push to main
          └── Supabase CLI: Run pending migrations
```

---
