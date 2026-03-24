# 16. Progressive Onboarding & Smart Defaults

This section details the technical architecture for the 3-step progressive onboarding flow and the smart defaults system that generates a professional-looking card from minimal input.

## 16.1 OAuth Scope & Pre-fill Strategy

OAuth providers return different profile data. The app requests minimal scopes and maps available data to card fields.

| Provider | Scopes Requested | Data Available | Pre-fill Fields |
|----------|-----------------|----------------|-----------------|
| **Google** | `profile`, `email` | name, email, profile photo URL, locale | first_name, last_name, email, profile_image_url |
| **Microsoft** | `User.Read` | name, email, profile photo (binary), job title, company | first_name, last_name, email, profile_image_url, job_title, company |
| **Apple** | `name`, `email` | name (first sign-in only), email (may be relay) | first_name, last_name, email |

### OAuth Photo Handling

```
Google:
  → Photo URL from `user.picture` (typically 96px)
  → Request higher resolution: append `=s400` to URL for 400px
  → Download and upload to Supabase Storage: cards/{card_id}/profile.jpg
  → If download fails: skip, show enrichment prompt later

Microsoft:
  → Photo is binary via Graph API: GET /me/photo/$value
  → Requires separate API call after auth
  → Upload binary directly to Supabase Storage
  → If Graph API returns 404 (no photo): skip

Apple:
  → No photo available from Apple Sign-In
  → Always triggers "Add your photo" enrichment prompt
```

### Pre-fill Priority Rules

```
1. OAuth profile data takes priority over manual entry (user can override in editor)
2. Name from OAuth overwrites Hive-cached name ONLY if Hive name fields are empty
3. Email from OAuth is always used (it's the auth identity)
4. Apple relay emails (xxx@privaterelay.appleid.com) are stored but hidden from card display
   → User prompted to add a display email via enrichment
5. Microsoft provides job_title and company — these are pre-filled on the card
   → Google and Apple do not — these become enrichment prompts
```

## 16.2 Smart Card Color Selection

When no custom color is chosen, the system selects an appropriate card color automatically.

### Color Extraction from Logo

```
1. If company logo is detected (from email domain or website):
   → Extract dominant color using server-side color extraction
   → POST /api/utils/extract-color { image_url: "logo.png" }
   → Uses: sharp (Node.js) → resize to 1px → get average color
   → Or: colorthief (npm) for dominant palette extraction
   → Returns: { dominant: "#2B5797", palette: ["#2B5797", "#F25022", ...] }

2. Color selection logic:
   → Check dominant color contrast ratio against white text (WCAG AA: 4.5:1)
   → If passes: use dominant color as card_color
   → If fails: darken by 20% and re-check
   → If still fails: use nearest preset color with sufficient contrast

3. If no logo available:
   → Random selection from preset palette:
     ['#1A1A1A', '#B91C1C', '#C2410C', '#CA8A04', '#A16207', '#15803D', '#1D4ED8']
   → Deterministic based on user_id hash (same user always gets same "random" color)
```

### Smart Defaults Card Generation

```
Given: { first_name, last_name?, email, phone?, profile_image_url?, job_title?, company? }

Generated card:
  slug: slugify(first_name + '-' + last_name + '-' + random4hex())
  card_name: "My Card"
  card_color: extracted from logo || deterministic preset
  contact_fields: [
    { field_type: 'email', value: email, label: 'Work', sort_order: 0 },
    { field_type: 'phone', value: phone, label: 'Mobile', sort_order: 1 }  // if phone provided
  ]
  social_links: []  // deferred to enrichment
  accreditations: []  // deferred to enrichment
  image_layout: 'default'
  qr_code_url: generated client-side (qr_flutter) from card URL
  is_active: true

The card is immediately shareable with just a name and email.
```

## 16.3 Company Logo Auto-Detection

```
Triggered: after account creation, non-blocking background task

1. Extract domain from email: user@acme.com → acme.com
2. Attempt logo detection (ordered by reliability):
   a. Clearbit Logo API: https://logo.clearbit.com/acme.com (free, fast)
   b. If Clearbit returns 404: scrape website
      → GET https://acme.com
      → Parse: og:image meta tag, apple-touch-icon, favicon (in priority order)
      → Validate: image is square-ish (aspect ratio 0.8-1.2), min 64px
   c. If all fail: no logo, enrichment prompt "Add your company logo"

3. If logo found:
   → Upload to Supabase Storage: cards/{card_id}/logo.{ext}
   → Update card.logo_url
   → Trigger color extraction (Section 16.2)
   → Update card.card_color if no custom color set

4. Timeout: 10s total for logo detection pipeline
   → On timeout: silently skip, user can add manually
```

---
