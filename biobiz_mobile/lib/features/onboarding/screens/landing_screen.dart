import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:biobiz_mobile/app/theme.dart';
import '../../../core/services/guest_mode_service.dart';

/// New Landing Screen with OAuth-first approach
/// Implements: Flip the funnel, Guest Mode entry point
/// Design: Atelier "Digital Curator" aesthetic
class LandingScreen extends ConsumerStatefulWidget {
  const LandingScreen({super.key});

  @override
  ConsumerState<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends ConsumerState<LandingScreen> {
  @override
  void initState() {
    super.initState();
    _checkForExistingGuestData();
  }

  /// Check if there's existing guest card data to resume
  void _checkForExistingGuestData() {
    final guestService = GuestModeService();
    if (guestService.hasGuestCardData) {
      // Show option to resume guest card
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showResumeGuestDialog();
      });
    }
  }

  void _showResumeGuestDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Resume your card?'),
        content: const Text('You have an unsaved card. Would you like to continue working on it?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              GuestModeService().clearGuestData();
            },
            child: const Text('Start fresh'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              final cardData = GuestModeService().convertToCardData();
              context.push('/onboarding/card-preview', extra: cardData);
            },
            child: const Text('Resume'),
          ),
        ],
      ),
    );
  }

  void _continueWithEmail() {
    context.push('/onboarding/email-start');
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: Stack(
        children: [
          // ─── Decorative Background Blur Circles ───────────
          Positioned(
            top: -MediaQuery.of(context).size.height * 0.1,
            right: -MediaQuery.of(context).size.width * 0.1,
            child: Container(
              width: MediaQuery.of(context).size.width * 0.6,
              height: MediaQuery.of(context).size.height * 0.4,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colorScheme.surfaceContainerHigh.withValues(alpha: 0.4),
              ),
            ),
          ),
          Positioned(
            bottom: -MediaQuery.of(context).size.height * 0.1,
            left: -MediaQuery.of(context).size.width * 0.1,
            child: Container(
              width: MediaQuery.of(context).size.width * 0.6,
              height: MediaQuery.of(context).size.height * 0.4,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colorScheme.secondaryContainer.withValues(alpha: 0.15),
              ),
            ),
          ),

          // ─── ATELIER Watermark ────────────────────────────
          Positioned(
            bottom: 48,
            left: 0,
            right: 0,
            child: IgnorePointer(
              child: Center(
                child: Text(
                  'ATELIER',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 72,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 16,
                    color: colorScheme.primary.withValues(alpha: 0.06),
                  ),
                ),
              ),
            ),
          ),

          // ─── Main Content ─────────────────────────────────
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 48),

                      // ─── Logo ───────────────────────────────
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerLowest,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.15),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(60),
                          child: Image.asset(
                            'assets/images/biobiz_logo.png',
                            height: 120,
                            width: 120,
                            errorBuilder: (_, __, ___) => Icon(
                              Icons.badge_rounded,
                              size: 72,
                              color: colorScheme.primary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // ─── Identity Section ───────────────────
                      Text(
                        'BioBiz',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 48,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -1.5,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Your digital business card',
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: colorScheme.onSurfaceVariant,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 48),

                      // ─── Primary CTA: Heritage Gradient ─────
                      HeritageGradientButton(
                        onPressed: _continueWithEmail,
                        height: 60,
                        borderRadius: 12,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.mail_outlined,
                              color: Colors.white,
                              size: 22,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Continue with Email',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 48),

                      // ─── Sign In Link ───────────────────────
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Already have an account?',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(width: 4),
                          GestureDetector(
                            onTap: () => context.go('/login'),
                            child: Text(
                              'Sign in',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: colorScheme.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 48),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}


