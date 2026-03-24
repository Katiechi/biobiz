# 8. Error States & Edge Cases

Defined behavior for failure modes across major features.

## 8.1 Network Failures

| Scenario | Behavior |
|----------|---------|
| Network loss during card save | Queue save locally, retry on reconnect, show "Saved offline — will sync" banner |
| Network loss during card share | Allow QR and link copy (offline-capable); disable SMS/email/social sharing with "No connection" message |
| Network loss during image upload | Show retry button with "Upload failed — tap to retry" |
| Network loss during contact scan | Cache scanned data locally, sync when reconnected |

## 8.2 Image Upload Failures

| Scenario | Behavior |
|----------|---------|
| Corrupt or unreadable file | Show "Unable to read this image. Please try a different file." |
| Oversized file (> 5 MB) | Block upload, show "Image must be under 5 MB" with file size displayed |
| Unsupported format | Block upload, show "Supported formats: JPEG, PNG, WebP" |
| Upload timeout | Show retry option after 15 seconds |

## 8.3 QR Code Failures

| Scenario | Behavior |
|----------|---------|
| QR generation fails | Show placeholder with "Tap to retry" overlay |
| QR scan fails (damaged/blurry) | Show "Couldn't read QR code — try moving closer or improving lighting" |

## 8.4 Authentication Failures

| Scenario | Behavior |
|----------|---------|
| OAuth provider unavailable | Show "Sign in with [provider] is temporarily unavailable. Try another method." with fallback to email/password |
| OTP expired | Show "Code expired — tap to resend" |
| Max OTP resend attempts reached | Show "Too many attempts. Try again in 30 minutes or use password sign-in." |
| Session expired | Redirect to sign-in with "Session expired — please sign in again" message; preserve draft state if possible |

## 8.5 Empty & Loading States

| Screen | Empty State | Loading State |
|--------|------------|--------------|
| Card list | "Create your first card" CTA | Skeleton card placeholder |
| Contacts | "No contacts yet" with share CTA (existing FR-CON-06) | Skeleton list rows |
| AI Notetaker recordings | "No recordings yet — tap record to get started" | Spinner with "Processing recording..." |
| Contact scan result | "No contact information found — try again or enter manually" | Camera viewfinder with scanning animation |
| Card web viewer (deleted card) | "This card is no longer available" tombstone page | Skeleton card placeholder |

---

*Generated from analysis of 30 BioBiz app screenshots on 2026-03-12*
