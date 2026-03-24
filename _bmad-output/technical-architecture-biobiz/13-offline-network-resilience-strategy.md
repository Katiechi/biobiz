# 13. Offline & Network Resilience Strategy

BioBiz is used at networking events (conferences, trade shows) where connectivity is often poor.

## 13.1 Offline-Capable Features

| Feature | Offline Behavior |
|---------|-----------------|
| **View own card** | Card data cached in Hive on last successful load. Images cached via `cached_network_image` |
| **Show QR code** | QR generated client-side from cached card URL — always available offline |
| **View contacts list** | Contact list cached in Hive, searchable offline |
| **View contact detail** | Cached in Hive |
| **Edit card** | Edits saved to Hive pending queue, synced when connectivity returns |
| **Add contact manually** | Saved to Hive pending queue, inserted on reconnect |
| **Scan business card (OCR)** | On-device ML Kit works offline. Server-side fallback skipped |
| **Record audio** | Recording saved locally. Upload queued for when online |

## 13.2 Online-Only Features

| Feature | Offline Behavior |
|---------|-----------------|
| **Share via email/SMS** | Greyed out with "Requires internet" tooltip |
| **AI Notetaker processing** | Upload queued; processing starts when online |
| **Card exchange** | QR share works (generates URL), but exchange requires connectivity |
| **Logo detection** | Skipped; user can add logo manually later |

## 13.3 Sync Strategy

```
1. On connectivity change (connectivity_plus):
   → If online: process Hive pending queue (FIFO)
   → Each queued operation retried up to 3 times with exponential backoff
   → On permanent failure: surface error to user with retry button

2. Realtime reconnection:
   → supabase_flutter handles WebSocket reconnection automatically
   → On reconnect: catch-up query for contacts/cards updated since last_synced_at
   → last_synced_at stored in Hive per data type

3. Conflict resolution (field-level granularity):
   → Each offline edit stores a per-field change log in Hive:
     { card_id, field_name, old_value, new_value, edited_at }
   → On sync, compare field-by-field against server state:
     - If field was NOT changed on server since last_synced_at → apply local edit
     - If field WAS changed on server AND locally → conflict detected
   → Conflict resolution strategy:
     - Auto-merge non-conflicting fields (e.g., user edited job_title offline,
       someone else's exchange updated a different field — no conflict)
     - For conflicting fields: present user with side-by-side comparison:
       "Server: [value] vs Your edit: [value]" → user picks per field
     - Bulk actions: "Keep all mine" / "Keep all server" for convenience
   → Card child tables (contact_fields, social_links, accreditations):
     - Additions: always merge (append)
     - Deletions: if item still exists on server, delete; if already deleted, no-op
     - Reorder changes: last-write-wins (field-level merge not practical for sort_order)
   → This replaces the previous whole-record last-write-wins approach to prevent
     data loss when users edit cards offline at events
```

---
