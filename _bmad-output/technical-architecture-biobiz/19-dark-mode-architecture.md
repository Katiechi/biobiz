# 19. Dark Mode Architecture

The UX spec specifies dark mode support for the app shell, with card rendering always respecting the user's chosen card color regardless of app theme.

## 19.1 Design Principle

**Two independent color domains:**
1. **App shell** — follows system theme (light/dark) using Material 3 color schemes
2. **Card renderer** — always uses the card's own color scheme, independent of app theme

This means a user in dark mode sees dark navigation bars, dark backgrounds, and dark surfaces — but their card preview renders with the card's own colors (e.g., a white card on a dark background).

## 19.2 Theme Implementation

```dart
// app/theme.dart
class AppTheme {
  static ThemeData light() => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.brandPrimary,
      brightness: Brightness.light,
    ),
    // ... component overrides
  );

  static ThemeData dark() => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.brandPrimary,
      brightness: Brightness.dark,
    ),
    // ... component overrides
  );
}

// app/app.dart
MaterialApp.router(
  theme: AppTheme.light(),
  darkTheme: AppTheme.dark(),
  themeMode: ThemeMode.system, // follows OS setting
  // ...
)
```

## 19.3 Color Scheme Mapping (Light → Dark)

| Semantic Role | Light Mode | Dark Mode |
|---|---|---|
| Surface | White (#FFFFFF) | Dark gray (#1C1C1E) |
| Surface Variant | Light gray (#F5F5F5) | Medium gray (#2C2C2E) |
| On Surface | Near-black (#1C1C1C) | Near-white (#E5E5E5) |
| Primary | Brand color | Brand color (slightly lighter) |
| On Primary | White | Dark |
| Outline | Medium gray (#C4C4C4) | Dark gray (#48484A) |
| Error | Red (#B3261E) | Light red (#F2B8B5) |

## 19.4 Card Renderer Independence

```dart
// core/widgets/card_renderer.dart
class CardRenderer extends StatelessWidget {
  final CardModel card;

  @override
  Widget build(BuildContext context) {
    // IMPORTANT: Card renderer does NOT use Theme.of(context) for its own colors.
    // It creates an isolated color context from the card's own color.
    final cardBgColor = Color(int.parse(card.cardColor.replaceFirst('#', '0xFF')));
    final textColor = _contrastingTextColor(cardBgColor);

    return Container(
      color: cardBgColor,
      child: DefaultTextStyle(
        style: TextStyle(color: textColor),
        child: _buildCardContent(),
      ),
    );
  }

  Color _contrastingTextColor(Color bg) {
    // WCAG luminance calculation
    final luminance = bg.computeLuminance();
    return luminance > 0.5 ? Colors.black : Colors.white;
  }
}
```

## 19.5 Component-Specific Dark Mode Behavior

| Component | Dark Mode Behavior |
|---|---|
| Navigation bar | Dark surface, light icons/labels |
| Card editor | Dark surface backgrounds, light text. Card preview within editor uses card's own colors |
| QR display | White QR on dark background (QR codes must be dark-on-light for scanning) |
| Social links grid | Dark tile backgrounds, brand-colored icons (unchanged) |
| Enrichment banner | Surface variant color, adapts to theme |
| Scanner overlay | Semi-transparent dark overlay (unchanged — already dark) |
| Contact list | Dark surface, light text |
| Snackbars | Inverted — light surface on dark theme |

## 19.6 Web Card Viewer

The web card viewer (`/card/:slug`) does NOT support dark mode in V1. The card always renders on a neutral light background to ensure consistent brand presentation for recipients.

Future consideration: respect `prefers-color-scheme` media query for the page chrome (header, footer, save button), while keeping the card itself in its own color context.

## 19.7 Persisted Images & Dark Mode

- Profile photos, logos, and cover images are displayed as-is in both modes (no filter)
- QR code PNG is always rendered as dark modules on white background (scanning requirement)
- Home screen widget: follows system theme for widget chrome, QR remains dark-on-white

---
