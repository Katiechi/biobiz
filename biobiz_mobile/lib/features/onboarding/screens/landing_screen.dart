import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/guest_mode_service.dart';

/// New Landing Screen with OAuth-first approach
/// Implements: Flip the funnel, Guest Mode entry point
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
    
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const Spacer(),
              
              // Logo
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.asset(
                  'assets/images/biobiz_logo.png',
                  height: 160,
                  errorBuilder: (_, __, ___) => Icon(
                    Icons.badge_rounded,
                    size: 80,
                    color: colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Title
              Text(
                'BioBiz',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                      letterSpacing: 1.0,
                    ),
              ),
              const SizedBox(height: 6),

              // Subtitle
              Text(
                'Your digital business card',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 40),

              // Primary action
              Text(
                'Create your card instantly',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 16),

              FilledButton(
                onPressed: _continueWithEmail,
                child: const Text('Continue with Email'),
              ),
              
              const Spacer(),
              
              // Sign in link for existing users
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Already have an account?'),
                  TextButton(
                    onPressed: () => context.go('/login'),
                    child: const Text('Sign in'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
