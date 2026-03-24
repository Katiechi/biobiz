# 17. Push Notification Infrastructure

The architecture was missing server-side push notification delivery. This section defines the Firebase Admin SDK integration, device token management, and notification dispatch pipeline.

## 17.1 Architecture Overview

```
┌────────────────────┐
│ Flutter App         │
│ (firebase_messaging)│
│                    │
│ 1. Get FCM token   │
│ 2. POST to API     │
└────────┬───────────┘
         │
         ▼
┌────────────────────┐     ┌──────────────────────┐
│ Next.js API        │     │ Firebase Admin SDK    │
│                    │────▶│ (firebase-admin npm)  │
│ /api/device-tokens │     │                      │
│ /api/notifications │     │ Send to FCM/APNs     │
└────────────────────┘     └──────────────────────┘
         │
         ▼
┌────────────────────┐
│ Supabase           │
│ device_tokens table│
│ (Section 3.2)      │
└────────────────────┘
```

## 17.2 Device Token Registration

```
Flutter client (on app startup + token refresh):
  1. firebase_messaging.getToken() → FCM registration token
  2. POST /api/device-tokens { token, platform: 'android'|'ios' }
  3. Server upserts into device_tokens table (ON CONFLICT(token) UPDATE user_id, last_used_at)

Token refresh handling:
  → firebase_messaging.onTokenRefresh.listen((newToken) { ... })
  → DELETE old token, POST new token
  → Handles device transfer between users (token reassigned)

Logout / account deletion:
  → DELETE /api/device-tokens/:id
  → Prevents notifications to logged-out devices
```

## 17.3 Server-Side Setup (Next.js)

```typescript
// lib/firebase-admin.ts
import admin from 'firebase-admin';

// Initialize once — service account key stored in env var
if (!admin.apps.length) {
  admin.initializeApp({
    credential: admin.credential.cert({
      projectId: process.env.FIREBASE_PROJECT_ID,
      clientEmail: process.env.FIREBASE_CLIENT_EMAIL,
      privateKey: process.env.FIREBASE_PRIVATE_KEY?.replace(/\\n/g, '\n'),
    }),
  });
}

export const messaging = admin.messaging();
```

## 17.4 Notification Types & Dispatch

| Event | Notification Title | Body | Data Payload |
|-------|-------------------|------|-------------|
| New contact (exchange) | "New contact: {name}" | "{name} shared their card with you" | `{ type: 'new_contact', contact_id }` |
| Recording ready | "Meeting summary ready" | "Your recording from {time} has been summarized" | `{ type: 'recording_ready', recording_id }` |
| Recording failed | "Recording processing failed" | "Tap to retry" | `{ type: 'recording_failed', recording_id }` |
| Web exchange-back | "New contact from card share" | "{name} shared their details with you" | `{ type: 'web_exchange', contact_id }` |
| Card viewed (threshold) | "Your card is getting views!" | "{count} people viewed your card today" | `{ type: 'card_views', card_id }` |

### Dispatch Logic

```typescript
// lib/notifications.ts
async function sendPushNotification(
  userId: string,
  notification: { title: string; body: string },
  data: Record<string, string>
) {
  // Fetch all device tokens for user
  const { data: tokens } = await supabase
    .from('device_tokens')
    .select('token, platform')
    .eq('user_id', userId);

  if (!tokens?.length) return; // No registered devices

  const messages = tokens.map(t => ({
    token: t.token,
    notification,
    data,
    android: {
      priority: 'high' as const,
      notification: { channelId: 'biobiz_default' },
    },
    apns: {
      payload: { aps: { badge: 1, sound: 'default' } },
    },
  }));

  const response = await messaging.sendEach(messages);

  // Clean up invalid tokens
  response.responses.forEach((resp, idx) => {
    if (resp.error?.code === 'messaging/registration-token-not-registered') {
      supabase.from('device_tokens').delete().eq('token', tokens[idx].token);
    }
  });

  // Update last_used_at for successful sends
  const successTokens = tokens.filter((_, i) => response.responses[i].success);
  if (successTokens.length) {
    await supabase.from('device_tokens')
      .update({ last_used_at: new Date().toISOString() })
      .in('token', successTokens.map(t => t.token));
  }
}
```

## 17.5 Flutter Client Notification Handling

```dart
// notification_service.dart additions
class NotificationService {
  Future<void> initialize() async {
    // Request permission (deferred — not during onboarding)
    await FirebaseMessaging.instance.requestPermission();

    // Foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Background/terminated tap handler
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    // Check for initial notification (app opened from terminated state)
    final initial = await FirebaseMessaging.instance.getInitialMessage();
    if (initial != null) _handleNotificationTap(initial);
  }

  void _handleNotificationTap(RemoteMessage message) {
    final type = message.data['type'];
    switch (type) {
      case 'new_contact':
      case 'web_exchange':
        router.go('/contacts/${message.data['contact_id']}');
      case 'recording_ready':
        router.go('/recordings/${message.data['recording_id']}');
      case 'recording_failed':
        router.go('/recordings/${message.data['recording_id']}');
      case 'card_views':
        router.go('/card/${message.data['card_id']}/analytics');
    }
  }
}
```

## 17.6 Third-Party Service Addition

| Service | Purpose | Cost |
|---------|---------|------|
| **Firebase Admin SDK** (`firebase-admin` npm) | Server-side push notification dispatch via FCM | Free (FCM has no per-message cost) |

Environment variables required:
- `FIREBASE_PROJECT_ID`
- `FIREBASE_CLIENT_EMAIL`
- `FIREBASE_PRIVATE_KEY`

---
