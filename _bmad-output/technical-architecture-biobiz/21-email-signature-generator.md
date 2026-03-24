# 21. Email Signature Generator

The UX spec identifies email signature generation as a Phase 4 feature. This section defines the technical architecture for generating, previewing, and distributing HTML email signatures from card data.

## 21.1 Overview

Users can generate an HTML email signature from their card data, then copy it into their email client (Gmail, Outlook, Apple Mail). The signature includes their name, title, contact info, social links, and a link to their BioBiz card.

## 21.2 Architecture

```
┌────────────────────┐     ┌──────────────────────┐
│ Flutter App         │     │ Next.js API           │
│                    │     │                      │
│ "Get Email         │────▶│ POST /api/cards/:id/ │
│  Signature"        │     │   email-signature/   │
│  button            │     │   generate           │
│                    │◀────│                      │
│ Preview +          │     │ Returns: HTML string │
│ Copy to clipboard  │     └──────────────────────┘
└────────────────────┘
```

## 21.3 Signature Templates

**Default template (V1):** Clean, professional, table-based HTML for maximum email client compatibility.

```html
<!-- Simplified structure — actual template uses inline styles throughout -->
<table cellpadding="0" cellspacing="0" style="font-family: Arial, sans-serif;">
  <tr>
    <td style="padding-right: 12px; vertical-align: top;">
      <!-- Profile photo (optional, 80x80) -->
      <img src="{profile_image_url}" width="80" height="80"
           style="border-radius: 50%;" alt="{name}" />
    </td>
    <td style="vertical-align: top;">
      <strong style="font-size: 16px; color: #1a1a1a;">{first_name} {last_name}</strong>
      <br />
      <span style="font-size: 13px; color: #666;">{job_title} | {company}</span>
      <br /><br />
      <!-- Contact fields -->
      <span style="font-size: 12px; color: #333;">
        {email} | {phone}
      </span>
      <br />
      <!-- Social links as icons or text links -->
      <a href="{linkedin_url}" style="color: #0A66C2;">LinkedIn</a>
      <br /><br />
      <!-- BioBiz card link -->
      <a href="https://biobiz.app/card/{slug}"
         style="font-size: 12px; color: {card_color};">
        View my digital card
      </a>
    </td>
  </tr>
</table>
```

**Template rules:**
- All CSS must be inline (no `<style>` blocks — Gmail strips them)
- Tables for layout (flexbox/grid not supported in most email clients)
- Images referenced by URL, not base64 (most clients block inline data URIs)
- No JavaScript
- Maximum width: 600px
- Tested against: Gmail (web + mobile), Outlook (desktop + web), Apple Mail, Yahoo Mail

## 21.4 Generation Pipeline

```
POST /api/cards/:id/email-signature/generate

1. Fetch card data (with contact_fields, social_links) via service role
2. Select template (V1: only 'default')
3. Render HTML string with card data interpolated:
   → Profile image: Supabase Storage public URL (or omit if no photo)
   → Social links: render top 3 by sort_order as text links
   → Contact fields: email (first), phone (first)
   → Card link: https://biobiz.app/card/{slug}
4. Store in email_signatures table (upsert by card_id)
5. Return: { html: "...", preview_url: "/api/cards/:id/email-signature/preview" }

Cache: signature re-generated only when card data changes.
Check: compare card.updated_at vs email_signatures.generated_at
```

## 21.5 Preview & Copy Flow

```
Flutter client:
  1. User taps "Email Signature" in card menu
  2. POST /api/cards/:id/email-signature/generate
  3. Response HTML displayed in WebView preview
  4. "Copy to Clipboard" button:
     → Copies HTML to clipboard (Clipboard.setData with HTML MIME type)
     → On Android: uses ClipData with text/html MIME type
     → On iOS: uses UIPasteboard with HTML type
     → Fallback: copy plain-text version for clients that don't support HTML paste
  5. Instructions shown: "Paste this into your email client's signature settings"

Web preview:
  GET /api/cards/:id/email-signature/preview
  → Returns HTML page rendering the signature (for visual preview in browser)
  → Useful for sharing preview link or testing across email clients
```

## 21.6 Email Client Compatibility

| Client | HTML Paste Support | Notes |
|--------|-------------------|-------|
| Gmail (web) | Yes — paste into signature settings | Works directly |
| Gmail (mobile) | No — mobile app doesn't support HTML signatures | Guide user to web version |
| Outlook (desktop) | Yes — paste into signature editor | Works directly |
| Outlook (web) | Yes | Works directly |
| Apple Mail | Yes — paste into signature preferences | Works directly |
| Yahoo Mail | Limited | May strip some styling |

## 21.7 Data Model

See Section 3.2 for the `email_signatures` table definition. Key fields:
- `card_id` (unique FK) — one signature per card
- `html_content` — the rendered HTML string
- `template_name` — for future template variants
- `generated_at` — for cache invalidation

---
