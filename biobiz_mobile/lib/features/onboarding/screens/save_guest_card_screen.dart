import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/guest_mode_service.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/providers/auth_provider.dart';

/// Save Guest Card Screen - Prompts user to create account
/// Shown when guest tries to share or save their card
class SaveGuestCardScreen extends ConsumerStatefulWidget {
  const SaveGuestCardScreen({super.key});

  @override
  ConsumerState<SaveGuestCardScreen> createState() => _SaveGuestCardScreenState();
}

class _SaveGuestCardScreenState extends ConsumerState<SaveGuestCardScreen> {
  bool _isLoading = false;

  Future<void> _signInWithOAuth(OAuthProviderType provider) async {
    setState(() => _isLoading = true);

    try {
      final guestData = GuestModeService().getGuestCardData();
      if (guestData != null) {
        await GuestModeService().saveGuestCardData(guestData);
      }

      final success = await ref.read(authServiceProvider).signInWithOAuth(provider);

      if (success && mounted) {
        await Future.delayed(const Duration(seconds: 1));
        final oauthData = await ref.read(authServiceProvider).processOAuthCallback();

        final mergedData = Map<String, String>.from(guestData?.map((k, v) => MapEntry(k, v.toString())) ?? {});
        if (oauthData != null) {
          if (mergedData['firstName']?.isEmpty ?? true) {
            mergedData['firstName'] = oauthData.firstName ?? '';
          }
          if (mergedData['lastName']?.isEmpty ?? true) {
            mergedData['lastName'] = oauthData.lastName ?? '';
          }
          if (mergedData['email']?.isEmpty ?? true) {
            mergedData['email'] = oauthData.email;
          }
          if (mergedData['profilePicUrl']?.isEmpty ?? true) {
            mergedData['profilePicUrl'] = oauthData.avatarUrl ?? '';
          }
        }

        await GuestModeService().setIsGuest(false);

        if (mounted) {
          context.go('/onboarding/card-preview', extra: mergedData);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _continueWithEmail() {
    final guestData = GuestModeService().getGuestCardData();
    final cardData = guestData?.map((k, v) => MapEntry(k, v.toString())) ?? {};
    context.push('/onboarding/create-account', extra: cardData);
  }

  void _continueEditing() {
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Icon(
                Icons.cloud_upload_outlined,
                size: 80,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 32),
              Text(
                'Save your card',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Create a free account to save your card and share it with others. Your card data will be preserved.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                textAlign: TextAlign.center,
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'With an account you can:',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 12),
                    _buildBenefit(context, 'Share your card via QR code'),
                    _buildBenefit(context, 'Edit your card anytime'),
                    _buildBenefit(context, 'Access your card from any device'),
                    _buildBenefit(context, 'Create multiple cards'),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              _OAuthButton(
                onPressed: _isLoading ? null : () => _signInWithOAuth(OAuthProviderType.google),
                icon: Icons.g_mobiledata,
                label: 'Continue with Google',
                isLoading: _isLoading,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Expanded(child: Divider()),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'or',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                  const Expanded(child: Divider()),
                ],
              ),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: _isLoading ? null : _continueWithEmail,
                child: const Text('Continue with Email'),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: _isLoading ? null : _continueEditing,
                child: const Text('Keep editing without saving'),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBenefit(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            Icons.check_circle,
            size: 20,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}

class _OAuthButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final IconData icon;
  final String label;
  final bool isLoading;

  const _OAuthButton({
    required this.onPressed,
    required this.icon,
    required this.label,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 24),
      label: isLoading
          ? const SizedBox(
              height: 16,
              width: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Text(label),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(double.infinity, 48),
      ),
    );
  }
}
