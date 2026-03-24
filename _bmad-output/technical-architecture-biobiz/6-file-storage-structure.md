# 6. File Storage Structure

```
Supabase Storage Buckets:

profiles/
  └── {user_id}/
      └── avatar.{ext}

cards/
  └── {card_id}/
      ├── logo.{ext}
      ├── profile.{ext}
      ├── cover.{ext}
      └── qr.png

scans/
  └── {user_id}/
      └── {scan_id}.{ext}

recordings/
  └── {user_id}/
      └── {recording_id}.{ext}
```

**Storage Policies & Limits:**

| Bucket | Access | Max File Size | Allowed MIME Types |
|--------|--------|---------------|-------------------|
| `profiles/` | Owner read/write, public read | 5 MB | image/jpeg, image/png, image/webp |
| `cards/` | Owner read/write, public read | 5 MB (images), auto (QR) | image/jpeg, image/png, image/webp, image/svg+xml |
| `scans/` | Owner only | 10 MB | image/jpeg, image/png |
| `recordings/` | Owner only | 100 MB | audio/wav, audio/mp4, audio/mpeg, audio/webm |

**Upload validation:** MIME type verified via magic bytes on the server, not file extension alone. Mismatched extension/content is rejected.

**Retention policy:**
- `recordings/` — Audio files auto-deleted 90 days after `recording_summaries` is created (transcript preserved). Users notified 7 days before deletion.
- `scans/` — Scan images auto-deleted 30 days after contact creation.
- Per-user storage quota: 500 MB (free), 2 GB (premium). Enforced at upload time.

---
