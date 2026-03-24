# 12. vCard Generation Specification

The "Save to Contacts" feature on the public card page generates a downloadable `.vcf` file.

**Format:** vCard 4.0 (RFC 6350)

| Card Field | vCard Property | Notes |
|-----------|---------------|-------|
| prefix, first_name, last_name, suffix | `N` | Structured name |
| preferred_name OR first_name + last_name | `FN` | Display name |
| pronoun | `X-PRONOUN` | Custom extension |
| job_title | `TITLE` | |
| company, department | `ORG` | Semicolon-separated |
| profile_image_url | `PHOTO;MEDIATYPE=image/jpeg` | URL reference (not inline base64, to keep file size small) |
| card_contact_fields (email) | `EMAIL;TYPE=work` | Label mapped to TYPE parameter |
| card_contact_fields (phone) | `TEL;TYPE=work` | Extension appended as `X-EXTENSION` |
| card_contact_fields (address) | `ADR` | |
| card_social_links (linkedin) | `URL;TYPE=linkedin` | |
| card_social_links (other) | `X-SOCIALPROFILE;TYPE={platform}` | Apple Contacts extension |
| company_website | `URL;TYPE=work` | |
| card URL (biobiz.com/card/:slug) | `URL;TYPE=pref` | Primary URL |

**Generation:** Server-side in Next.js API route (`/api/public/cards/:slug/vcard`), cached with `Cache-Control: public, max-age=300`. Invalidated when card is updated.

## 12.1 "One Tap Save" — Cross-Browser Fallback Strategy

The UX spec requires a one-tap "Save to Contacts" action on the web card viewer. Browser support for `.vcf` downloads varies significantly.

**Primary approach:** Serve `.vcf` as a file download via `Content-Disposition: attachment; filename="{name}.vcf"` with `Content-Type: text/vcard`.

**Cross-browser fallback chain:**

| Browser | Behavior | Fallback |
|---------|----------|----------|
| **iOS Safari** | Opens `.vcf` natively → "Add to Contacts" prompt | ✅ Native support — no fallback needed |
| **Android Chrome** | Downloads `.vcf` → user must open from downloads | Show "Open in Contacts" instruction toast after download triggers |
| **Android (other browsers)** | May not auto-associate `.vcf` | Offer `intent://` URI as alternative: `intent://import/PHONE#Intent;type=text/x-vcard;end` |
| **Desktop browsers** | Downloads file → user imports manually | Show "Downloaded! Open the file to add to your contacts" banner |
| **In-app browsers (Instagram, LinkedIn, etc.)** | Often block downloads or lack file type associations | Detect in-app browser via user-agent → show "Open in browser" button that copies URL + guides user to open in Safari/Chrome |

**Implementation:**

```typescript
// Web card viewer: Save to Contacts button handler
async function handleSaveContact(slug: string) {
  const isInAppBrowser = detectInAppBrowser(navigator.userAgent);

  if (isInAppBrowser) {
    // In-app browsers can't reliably handle vcf downloads
    await navigator.clipboard.writeText(window.location.href);
    showToast("Link copied! Open in Safari or Chrome to save contact");
    return;
  }

  // Trigger download
  const link = document.createElement('a');
  link.href = `/api/public/cards/${slug}/vcard`;
  link.download = `${slug}.vcf`;
  link.click();

  // Android-specific guidance
  if (/android/i.test(navigator.userAgent)) {
    showToast("Check your downloads and tap the file to add to contacts");
  }
}

function detectInAppBrowser(ua: string): boolean {
  return /FBAN|FBAV|Instagram|LinkedIn|Twitter|Snapchat/i.test(ua);
}
```

**Tracking:** Each "Save to Contacts" tap inserts a `card_event` with `event_type: 'save_contact'` and `metadata: { browser, method }` for analytics on which fallbacks are most used.

---
