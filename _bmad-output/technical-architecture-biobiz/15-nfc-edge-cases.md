# 15. NFC Edge Cases

| Scenario | Handling |
|----------|---------|
| NFC tag tapped after linked card deleted | Tag URL resolves to `/card/:slug` → 404 page with "This card is no longer available" |
| NFC tag re-paired to different user | Previous pairing row deleted (UNIQUE on nfc_tag_id). Old user's NFC device list updated via realtime subscription |
| NFC tag tapped while owner account deleted | CASCADE deletes nfc_devices row. Tag URL → 410 Gone page |
| Multiple NFC tags paired to same card | Allowed (1:N). All tags resolve to same card URL |
| NFC not supported on device | `nfc_manager` capability check on app start; NFC features hidden if unsupported |

---

*This architecture is designed to get BioBiz from zero to production as fast as possible using managed services, with room to scale as the user base grows. Flutter handles the mobile experience with pixel-perfect rendering, while Next.js serves the public card pages and handles server-side operations.*
