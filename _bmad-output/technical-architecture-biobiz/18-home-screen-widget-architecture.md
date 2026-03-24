# 18. Home Screen Widget Architecture

The UX spec identifies the home screen QR widget as a key accelerator for the "share without opening the app" use case. This section defines the data sync, rendering, and update architecture.

## 18.1 Overview

The widget displays the user's active card QR code on the home screen, enabling card sharing in under 1 second without opening the app.

```
┌──────────────────────────┐
│ Home Screen Widget       │
│ (home_widget package)    │
│                          │
│  ┌────────────────────┐  │
│  │   [QR Code Image]  │  │
│  │                    │  │
│  │   First Last       │  │
│  │   Job Title        │  │
│  └────────────────────┘  │
│                          │
│  Tap → opens app to      │
│  My Card screen          │
└──────────────────────────┘
```

## 18.2 Data Flow & Sync

```
Data source: Hive local cache (same as offline card data)
Render target: Native widget via home_widget package

Sync triggers (widget re-rendered when any of these occur):
  1. Card data changes (edit, create, activate different card)
  2. App goes to background (ensure latest data is shown)
  3. User explicitly refreshes (pull-to-refresh on My Card screen)
  4. Active card switch (user activates a different card)

Data passed to widget:
  → QR code image: pre-rendered PNG stored in shared app group directory
  → Card holder name: first_name + last_name (truncated to fit)
  → Job title: truncated to fit (optional, may be empty)
  → Card color: hex string for widget background accent
```

## 18.3 Implementation

### Flutter Side

```dart
// widget_service.dart
class WidgetService {
  static Future<void> updateWidget(CardModel card) async {
    // 1. Generate QR code as image
    final qrImage = await QrPainter(
      data: 'https://biobiz.app/card/${card.slug}',
      version: QrVersions.auto,
    ).toImageData(400); // 400px for crisp rendering on high-DPI

    // 2. Save QR image to shared directory
    final directory = await HomeWidget.getWidgetDirectory();
    final file = File('${directory.path}/qr_${card.id}.png');
    await file.writeAsBytes(qrImage.buffer.asUint8List());

    // 3. Pass data to native widget
    await HomeWidget.saveWidgetData<String>('qr_image_path', file.path);
    await HomeWidget.saveWidgetData<String>('name', '${card.firstName} ${card.lastName ?? ""}');
    await HomeWidget.saveWidgetData<String>('title', card.jobTitle ?? '');
    await HomeWidget.saveWidgetData<String>('card_color', card.cardColor);
    await HomeWidget.saveWidgetData<String>('card_slug', card.slug);

    // 4. Request widget update
    await HomeWidget.updateWidget(
      androidName: 'BioBizQRWidget',
      iOSName: 'BioBizQRWidget',
    );
  }
}
```

### Android Widget (Kotlin/XML)

```
android/app/src/main/
├── res/layout/biobiz_qr_widget.xml    # Widget layout
├── res/xml/biobiz_qr_widget_info.xml  # Widget metadata (min size: 3x3 cells)
└── kotlin/.../BioBizQRWidget.kt       # AppWidgetProvider
```

- Minimum size: 3x3 grid cells (roughly 180x180dp)
- Resizable up to 4x4 for larger QR display
- Tap action: opens app via deep link `biobiz://my-card`

### iOS Widget (SwiftUI/WidgetKit)

```
ios/BioBizWidget/
├── BioBizWidget.swift          # Widget definition
├── BioBizWidgetEntryView.swift # SwiftUI view
└── BioBizWidgetBundle.swift    # Widget bundle
```

- Small widget (2x2): QR code only
- Medium widget (4x2): QR code + name + title
- Uses App Group for shared data access between app and widget extension

## 18.4 Offline Behavior

- Widget always renders from local data (never fetches from network)
- QR code is a static image pre-generated from the card URL
- If no card data exists (fresh install, logged out): show "Open BioBiz to set up your card" placeholder
- Widget data survives app termination — stored in shared preferences / App Group

## 18.5 Update Frequency

| Event | Widget Update? | Method |
|-------|---------------|--------|
| Card edited | Yes | `WidgetService.updateWidget()` called after save |
| Active card switched | Yes | Triggered by card activation |
| App backgrounded | Yes | `WidgetsBindingObserver.didChangeAppLifecycleState` |
| App opened from widget | No | Just navigates to My Card screen |
| Periodic (Android) | Every 30 min | `updatePeriodMillis` in widget XML |
| Timeline (iOS) | Every 1 hour | WidgetKit timeline refresh |

---
