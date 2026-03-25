import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../features/onboarding/screens/landing_screen.dart';
import '../features/onboarding/screens/quick_start_screen.dart';
import '../features/onboarding/screens/email_start_screen.dart' show OnboardingEmailStartScreen;
import '../features/onboarding/screens/name_screen.dart';
import '../features/onboarding/screens/contact_info_screen.dart';
import '../features/onboarding/screens/professional_details_screen.dart';
import '../features/onboarding/screens/logo_screen.dart';
import '../features/onboarding/screens/profile_picture_screen.dart';
import '../features/onboarding/screens/instant_preview_screen.dart';
import '../features/onboarding/screens/card_preview_screen.dart';
import '../features/onboarding/screens/create_account_screen.dart';
import '../features/onboarding/screens/save_guest_card_screen.dart';
import '../features/onboarding/screens/set_password_screen.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/register_screen.dart';
import '../features/auth/screens/otp_verification_screen.dart';
import '../core/services/guest_mode_service.dart';
import '../features/card_view/screens/my_card_screen.dart';
import '../features/scanner/screens/scan_screen.dart';
import '../features/ai_notetaker/screens/notetaker_screen.dart';
import '../features/contacts/screens/contacts_list_screen.dart';
import '../features/contacts/screens/save_card_screen.dart';
import '../features/card_editor/screens/card_editor_screen.dart';
import '../features/sharing/screens/share_card_screen.dart';
import '../features/settings/screens/menu_screen.dart';
import '../features/settings/screens/manage_account_screen.dart';
import '../features/settings/screens/notifications_screen.dart';
import '../features/settings/screens/email_signature_screen.dart';
import '../features/card_view/screens/card_analytics_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

class AppRouter {
  static final GoRouter router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
    redirect: (context, state) {
      try {
        final session = Supabase.instance.client.auth.currentSession;
        final isLoggedIn = session != null;
        final isGuest = GuestModeService().isGuest;
        final loc = state.matchedLocation;
        final uri = state.uri;
        final fullUri = uri.toString();

        debugPrint('ROUTER: loc=$loc fullUri=$fullUri');

        // Handle deep links: io.supabase.biobiz://card/SLUG
        // GoRouter may receive this as location "/" with the full URI containing the slug
        // Or the path might come through as just "/SLUG" with host "card"
        final deepLinkPatterns = [
          RegExp(r'io\.supabase\.biobiz://card/([^/?#]+)'),
          RegExp(r'biobiz\.app/card/([^/?#]+)'),
        ];
        for (final pattern in deepLinkPatterns) {
          final match = pattern.firstMatch(fullUri);
          if (match != null) {
            final slug = match.group(1)!;
            debugPrint('ROUTER: Deep link card slug=$slug');
            return '/card/view/$slug';
          }
        }

        // Also catch if GoRouter parsed the deep link as a bare path like /okeino-mn4ifh
        // from io.supabase.biobiz://card/okeino-mn4ifh (host=card, path=/okeino-mn4ifh)
        if (loc.startsWith('/') && !loc.contains('/card/') && !loc.startsWith('/onboarding') &&
            !loc.startsWith('/login') && !loc.startsWith('/register') && !loc.startsWith('/scan') &&
            !loc.startsWith('/contacts') && !loc.startsWith('/notetaker') && !loc.startsWith('/menu') &&
            !loc.startsWith('/settings') && !loc.startsWith('/premium') && !loc.startsWith('/verify') &&
            loc != '/' && loc != '/card') {
          // This might be a deep link slug that GoRouter couldn't match
          final possibleSlug = loc.substring(1); // strip leading /
          if (possibleSlug.isNotEmpty && !possibleSlug.contains('/')) {
            debugPrint('ROUTER: Possible deep link slug from unmatched path: $possibleSlug');
            return '/card/view/$possibleSlug';
          }
        }

        // These routes are always accessible regardless of auth state
        final publicRoutes = [
          '/',
          '/login',
          '/register',
          '/verify-otp',
          '/onboarding/quick-start',
          '/onboarding/email-start',
          '/onboarding/set-password',
          '/onboarding/name',
          '/onboarding/contact-info',
          '/onboarding/professional',
          '/onboarding/logo',
          '/onboarding/profile-pic',
          '/onboarding/card-preview',
          '/onboarding/create-account',
          '/onboarding/save-guest-card',
          '/onboarding/instant-preview',
        ];

        debugPrint('ROUTER REDIRECT: loc=$loc isLoggedIn=$isLoggedIn isGuest=$isGuest');

        // Only redirect if user is on the landing page
        // All other navigation is intentional and should not be overridden
        if (loc == '/') {
          if (isLoggedIn) {
            debugPrint('ROUTER: Redirecting logged-in user from / to /card');
            return '/card';
          }
          if (isGuest) return '/onboarding/card-preview';
        }

        // Allow shared card deep links without auth
        if (loc.startsWith('/card/view/')) {
          return null;
        }

        // If not logged in, not a guest, and trying to access a protected route
        if (!isLoggedIn && !isGuest && !publicRoutes.contains(loc)) {
          return '/';
        }
      } catch (_) {
        // If Supabase isn't initialized, allow navigation
      }
      return null;
    },
    routes: [
      // Landing / Onboarding
      GoRoute(
        path: '/',
        builder: (context, state) => const LandingScreen(),
      ),
      GoRoute(
        path: '/onboarding/quick-start',
        builder: (context, state) => const OnboardingQuickStartScreen(),
      ),
      GoRoute(
        path: '/onboarding/email-start',
        builder: (context, state) => const OnboardingEmailStartScreen(),
      ),
      GoRoute(
        path: '/onboarding/save-guest-card',
        builder: (context, state) => const SaveGuestCardScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/verify-otp',
        builder: (context, state) {
          final extra = state.extra;
          final String email;
          if (extra is String) {
            email = extra;
          } else if (extra is Map) {
            email = extra['email'] as String? ?? '';
          } else {
            email = '';
          }
          return OtpVerificationScreen(email: email);
        },
      ),
      GoRoute(
        path: '/onboarding/set-password',
        builder: (context, state) {
          final raw = state.extra as Map<String, dynamic>;
          final data = raw.map((k, v) => MapEntry(k, v?.toString() ?? ''));
          return OnboardingSetPasswordScreen(cardData: data);
        },
      ),
      // Onboarding Flow
      GoRoute(
        path: '/onboarding/name',
        builder: (context, state) => const OnboardingNameScreen(),
      ),
      GoRoute(
        path: '/onboarding/contact-info',
        builder: (context, state) {
          final data = state.extra as Map<String, String>;
          return OnboardingContactInfoScreen(previousData: data);
        },
      ),
      GoRoute(
        path: '/onboarding/professional',
        builder: (context, state) {
          final data = state.extra as Map<String, String>;
          return OnboardingProfessionalScreen(previousData: data);
        },
      ),
      GoRoute(
        path: '/onboarding/logo',
        builder: (context, state) {
          final data = state.extra as Map<String, String>;
          return OnboardingLogoScreen(previousData: data);
        },
      ),
      GoRoute(
        path: '/onboarding/profile-pic',
        builder: (context, state) {
          final raw = state.extra as Map<String, dynamic>;
          final data = raw.map((k, v) => MapEntry(k, v?.toString() ?? ''));
          return OnboardingProfilePicScreen(previousData: data);
        },
      ),
      GoRoute(
        path: '/onboarding/card-preview',
        builder: (context, state) {
          final raw = state.extra as Map<String, dynamic>?;
          final data = raw?.map((k, v) => MapEntry(k, v?.toString() ?? '')) ??
              GuestModeService().convertToCardData();
          return OnboardingCardPreviewScreen(cardData: data);
        },
      ),
      GoRoute(
        path: '/onboarding/instant-preview',
        builder: (context, state) {
          final raw = state.extra as Map<String, dynamic>;
          final data = raw.map((k, v) => MapEntry(k, v?.toString() ?? ''));
          return OnboardingInstantPreviewScreen(cardData: data);
        },
      ),
      GoRoute(
        path: '/onboarding/create-account',
        builder: (context, state) {
          final raw = state.extra as Map<String, dynamic>;
          final data = raw.map((k, v) => MapEntry(k, v?.toString() ?? ''));
          return OnboardingCreateAccountScreen(cardData: data);
        },
      ),

      // Main App Shell (Bottom Navigation)
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: '/card',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: MyCardScreen(),
            ),
          ),
          GoRoute(
            path: '/scan',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: ScanScreen(),
            ),
          ),
          GoRoute(
            path: '/notetaker',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: NotetakerScreen(),
            ),
          ),
          GoRoute(
            path: '/contacts',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: ContactsListScreen(),
            ),
          ),
        ],
      ),

      // Full-screen routes
      GoRoute(
        path: '/card/edit',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final cardId = state.extra as String?;
          return CardEditorScreen(cardId: cardId);
        },
      ),
      GoRoute(
        path: '/card/share',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const ShareCardScreen(),
      ),
      // Deep link: open a shared card by slug
      GoRoute(
        path: '/card/view/:slug',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final slug = state.pathParameters['slug'] ?? '';
          return SaveCardScreen(slug: slug);
        },
      ),
      GoRoute(
        path: '/menu',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const MenuScreen(),
      ),
      GoRoute(
        path: '/settings/account',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const ManageAccountScreen(),
      ),
      GoRoute(
        path: '/settings/notifications',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const NotificationsScreen(),
      ),
      GoRoute(
        path: '/settings/email-signature',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const EmailSignatureScreen(),
      ),
      GoRoute(
        path: '/card/analytics',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final cardId = state.extra as String;
          return CardAnalyticsScreen(cardId: cardId);
        },
      ),
    ],
  );
}

/// Main app shell with bottom navigation bar
class MainShell extends StatelessWidget {
  final Widget child;

  const MainShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _getSelectedIndex(context),
        onDestinationSelected: (index) => _onDestinationSelected(context, index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.badge_outlined),
            selectedIcon: Icon(Icons.badge),
            label: 'My Card',
          ),
          NavigationDestination(
            icon: Icon(Icons.qr_code_scanner_outlined),
            selectedIcon: Icon(Icons.qr_code_scanner),
            label: 'Scan',
          ),
          NavigationDestination(
            icon: Icon(Icons.mic_none_outlined),
            selectedIcon: Icon(Icons.mic),
            label: 'AI Notetaker',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people),
            label: 'Contacts',
          ),
        ],
      ),
    );
  }

  int _getSelectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    switch (location) {
      case '/card':
        return 0;
      case '/scan':
        return 1;
      case '/notetaker':
        return 2;
      case '/contacts':
        return 3;
      default:
        return 0;
    }
  }

  void _onDestinationSelected(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go('/card');
      case 1:
        context.go('/scan');
      case 2:
        context.go('/notetaker');
      case 3:
        context.go('/contacts');
    }
  }
}
