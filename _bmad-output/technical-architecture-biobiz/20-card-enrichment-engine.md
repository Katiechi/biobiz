# 20. Card Enrichment Engine

The UX spec replaces front-loaded data collection with a progressive enrichment system. This section defines the rules engine that determines when, what, and how to prompt users to enhance their cards.

## 20.1 Architecture Overview

```
┌───────────────────────┐
│ Enrichment Engine     │
│ (Riverpod provider)   │
│                       │
│ Inputs:               │
│  → Card data model    │
│  → Dismissal history  │
│  → User activity      │
│                       │
│ Output:               │
│  → Active prompt      │
│  (or null)            │
└───────────┬───────────┘
            │
            ▼
┌───────────────────────┐
│ EnrichmentBanner      │
│ (UI widget)           │
│                       │
│ "Add your photo to    │
│  make your card       │
│  stand out"           │
│                       │
│ [Add Photo] [Not now] │
└───────────────────────┘
```

## 20.2 Prompt Rules

Each prompt has conditions, priority, copy, and action. The engine evaluates rules in priority order and shows the highest-priority prompt that passes all conditions.

| Priority | Prompt Type | Condition | Banner Copy | Action |
|----------|------------|-----------|-------------|--------|
| 1 | `add_photo` | `card.profile_image_url IS NULL` | "Add your photo to make your card stand out" | Opens image picker |
| 2 | `add_company` | `card.company IS NULL` | "Add your company to look more professional" | Opens editor → company section |
| 3 | `add_job_title` | `card.job_title IS NULL` | "What's your role? Add your job title" | Opens editor → personal details |
| 4 | `add_social_links` | `card has 0 social_links` | "Connect your LinkedIn and other profiles" | Opens editor → social links |
| 5 | `customize_color` | `card.custom_color = false AND card created > 3 days ago` | "Personalize your card color" | Opens color picker |

## 20.3 Dismissal & Cooldown Logic

```
When user taps "Not now" / dismisses banner:
  1. INSERT into enrichment_dismissals:
     { user_id, prompt_type, dismissed_at: NOW(), cooldown_until: NOW() + 7 days }
  2. Banner hidden immediately
  3. After cooldown_until: prompt becomes eligible again
  4. If dismissed 3 times for same prompt_type:
     → Set permanently_dismissed = true
     → Never show again (unless user manually triggers from settings)

When user completes the prompted action:
  → No dismissal record needed — condition no longer met, prompt disappears naturally
```

## 20.4 Evaluation Logic (Riverpod)

```dart
@riverpod
EnrichmentPrompt? activeEnrichmentPrompt(Ref ref) {
  final card = ref.watch(activeCardProvider);
  final dismissals = ref.watch(enrichmentDismissalsProvider);

  if (card == null) return null;

  final now = DateTime.now();

  // Ordered by priority
  final rules = [
    EnrichmentRule(
      type: 'add_photo',
      condition: card.profileImageUrl == null,
      copy: 'Add your photo to make your card stand out',
      action: EnrichmentAction.openImagePicker,
    ),
    EnrichmentRule(
      type: 'add_company',
      condition: card.company == null || card.company!.isEmpty,
      copy: 'Add your company to look more professional',
      action: EnrichmentAction.openEditorSection('company'),
    ),
    EnrichmentRule(
      type: 'add_job_title',
      condition: card.jobTitle == null || card.jobTitle!.isEmpty,
      copy: "What's your role? Add your job title",
      action: EnrichmentAction.openEditorSection('personal'),
    ),
    EnrichmentRule(
      type: 'add_social_links',
      condition: card.socialLinks.isEmpty,
      copy: 'Connect your LinkedIn and other profiles',
      action: EnrichmentAction.openEditorSection('social'),
    ),
    EnrichmentRule(
      type: 'customize_color',
      condition: !card.customColor &&
          card.createdAt.isBefore(now.subtract(Duration(days: 3))),
      copy: 'Personalize your card color',
      action: EnrichmentAction.openColorPicker,
    ),
  ];

  for (final rule in rules) {
    if (!rule.condition) continue;

    final dismissal = dismissals.firstWhereOrNull(
      (d) => d.promptType == rule.type,
    );

    // Skip if permanently dismissed
    if (dismissal?.permanentlyDismissed == true) continue;

    // Skip if within cooldown
    if (dismissal != null && dismissal.cooldownUntil.isAfter(now)) continue;

    return EnrichmentPrompt(
      type: rule.type,
      copy: rule.copy,
      action: rule.action,
    );
  }

  return null; // Card is fully enriched or all prompts dismissed
}
```

## 20.5 UI Behavior

- Banner appears below the card preview on the My Card screen
- Non-blocking — does not prevent any user actions
- Subtle animation: slide-in from bottom on first render
- Dismiss button: "Not now" as TextButton
- Action button: primary verb as FilledButton.tonal ("Add Photo", "Add Company", etc.)
- Only ONE prompt shown at a time (highest priority)
- Banner respects `reduceMotion` system setting (no animation)

## 20.6 Timing Rules

| Event | Behavior |
|-------|----------|
| First app open after onboarding | Show first applicable prompt after 5 seconds (let user explore) |
| App resume from background | Show prompt immediately if applicable |
| After completing an enrichment action | Show next prompt after 3 seconds (celebrate current completion first) |
| After dismissing a prompt | Don't show next prompt until next app session |

---
