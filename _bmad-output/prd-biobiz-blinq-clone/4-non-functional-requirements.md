# 4. Non-Functional Requirements

| Category | Requirement |
|----------|------------|
| Performance | Card rendering < 1 second, QR generation < 500ms |
| Availability | 99.9% uptime for card viewing (cards must always be accessible) |
| Privacy | GDPR/data protection compliant, location data opt-in only |
| Scalability | Support 100K+ users, card views scale independently |
| Offline | QR code display works offline, card data cached locally |
| Accessibility | WCAG 2.1 AA for card viewer, screen reader support |
| Localization | Multi-currency pricing, multi-language support |
| Deep linking | Card URLs open in app if installed, web fallback otherwise |

## 4.1 Security Requirements

| ID | Requirement |
|----|------------|
| NFR-SEC-01 | HTTPS everywhere; all PII encrypted at rest |
| NFR-SEC-02 | OAuth 2.0 / OIDC compliance for all third-party auth providers |
| NFR-SEC-03 | Rate limiting on OTP and all auth endpoints (e.g., max 10 OTP requests per hour per IP) |
| NFR-SEC-04 | Brute-force protection — progressive delay and account lockout after repeated failed login attempts |
| NFR-SEC-05 | Input sanitization and XSS prevention on all user-generated content rendered on the web card viewer |
| NFR-SEC-06 | Image upload validation: accepted formats JPEG, PNG, WebP only; max file size 5 MB; server-side file type verification (not just extension check) |
| NFR-SEC-07 | Phishing/malware URL scanning on user-provided links before rendering on public card pages |

## 4.2 Content Moderation

| ID | Requirement |
|----|------------|
| FR-SEC-01 | Input sanitization for all user-generated text fields rendered on public card URLs (strip scripts, HTML injection) |
| FR-SEC-02 | Abuse reporting mechanism for shared card links (report button on web card viewer) |
| FR-SEC-03 | Phishing/malware URL scanning for user-provided links (block known-bad URLs, flag suspicious patterns) |

---
