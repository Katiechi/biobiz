import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

/// Story 2.5: Card preview with smart defaults, then first card generation
class OnboardingCardPreviewScreen extends ConsumerStatefulWidget {
  final Map<String, String> cardData;

  const OnboardingCardPreviewScreen({super.key, required this.cardData});

  @override
  ConsumerState<OnboardingCardPreviewScreen> createState() =>
      _OnboardingCardPreviewScreenState();
}

class _OnboardingCardPreviewScreenState
    extends ConsumerState<OnboardingCardPreviewScreen> {
  bool _isSaving = false;

  Future<void> _createCard() async {
    setState(() => _isSaving = true);

    try {
      final supabase = Supabase.instance.client;

      // Wait a moment for session to be established after OTP verification
      User? user = supabase.auth.currentUser;
      if (user == null) {
        // Wait for auth state to propagate
        await Future.delayed(const Duration(seconds: 2));
        user = supabase.auth.currentUser;
      }

      if (user == null) {
        // Still not logged in - go to account creation
        if (mounted) {
          setState(() => _isSaving = false);
          context.push('/onboarding/create-account', extra: widget.cardData);
        }
        return;
      }

      // Generate unique slug
      final firstName =
          (widget.cardData['firstName'] ?? 'user').toLowerCase().replaceAll(
                RegExp(r'[^a-z0-9]'),
                '',
              );
      final lastName =
          (widget.cardData['lastName'] ?? '').toLowerCase().replaceAll(
                RegExp(r'[^a-z0-9]'),
                '',
              );
      final uniqueId = const Uuid().v4().substring(0, 8);
      final slug = lastName.isNotEmpty
          ? '$firstName-$lastName-$uniqueId'
          : '$firstName-$uniqueId';

      debugPrint('Creating card with slug: $slug for user: ${user.id}');

      // Create card
      final cardResponse = await supabase
          .from('cards')
          .insert({
            'user_id': user.id,
            'slug': slug,
            'card_name': 'My Card',
            'first_name': widget.cardData['firstName'] ?? '',
            'last_name': widget.cardData['lastName'],
            'job_title': widget.cardData['jobTitle'],
            'company': widget.cardData['company'],
            'company_website': widget.cardData['website'],
            'email': widget.cardData['workEmail']?.isNotEmpty == true
                ? widget.cardData['workEmail']
                : widget.cardData['email'],
            'phone': widget.cardData['phone'],
            'profile_image_url': widget.cardData['profilePicUrl'],
            'logo_url': widget.cardData['logoUrl'],
            'card_color': '#000000',
            'is_active': true,
          })
          .select()
          .single();

      debugPrint('Card created: ${cardResponse['id']}');

      // Update profile onboarding_completed
      await supabase.from('profiles').update({
        'onboarding_completed': true,
      }).eq('id', user.id);

      debugPrint('Profile updated, onboarding_completed = true');

      if (mounted) {
        // Navigate to main app
        context.go('/card');
      }
    } catch (e, stackTrace) {
      debugPrint('Card creation error: $e');
      debugPrint('Stack trace: $stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating card: ${e.toString()}'),
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Retry',
              onPressed: _createCard,
            ),
          ),
        );
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final firstName = widget.cardData['firstName'] ?? '';
    final lastName = widget.cardData['lastName'] ?? '';
    final company = widget.cardData['company'];
    final jobTitle = widget.cardData['jobTitle'];
    final email = widget.cardData['email'];
    final phone = widget.cardData['phone'];
    final workEmail = widget.cardData['workEmail'];

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: const Text('Your Card'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Looking good!',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Here\'s a preview of your card',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // Card preview
              Center(
                  child: Card(
                    elevation: 4,
                    shadowColor: Theme.of(context).colorScheme.shadow,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Container(
                      width: double.infinity,
                      constraints: const BoxConstraints(maxWidth: 340),
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Profile pic / Avatar
                          CircleAvatar(
                            radius: 40,
                            backgroundColor: Theme.of(context)
                                .colorScheme
                                .primaryContainer,
                            backgroundImage: _getProfileImage(),
                            child: _getProfileImage() == null
                                ? Text(
                                    firstName.isNotEmpty
                                        ? firstName[0].toUpperCase()
                                        : '?',
                                    style: TextStyle(
                                      fontSize: 32,
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onPrimaryContainer,
                                    ),
                                  )
                                : null,
                          ),
                          const SizedBox(height: 16),

                          // Name
                          Text(
                            '$firstName ${lastName ?? ''}'.trim(),
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),

                          // Title & Company
                          if (jobTitle != null && jobTitle.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              jobTitle,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyLarge
                                  ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                            ),
                          ],
                          if (company != null && company.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              company,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],

                          const SizedBox(height: 24),
                          const Divider(),
                          const SizedBox(height: 16),

                          // Contact fields
                          if (email != null && email.isNotEmpty)
                            _buildContactRow(
                                context, Icons.email_outlined, email),
                          if (workEmail != null && workEmail.isNotEmpty && workEmail != email)
                            _buildContactRow(
                                context, Icons.work_outline, workEmail),
                          if (phone != null && phone.isNotEmpty)
                            _buildContactRow(
                                context, Icons.phone_outlined, phone),
                        ],
                      ),
                    ),
                  ),
              ),
              const SizedBox(height: 16),

              // Edit design button
              OutlinedButton(
                onPressed: () {
                  context.push('/card/edit');
                },
                child: const Text('Edit design'),
              ),
              const SizedBox(height: 12),

              // Continue / Create button
              FilledButton(
                onPressed: _isSaving ? null : _createCard,
                child: _isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Continue'),
              ),
              const SizedBox(height: 16),

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
            ],
          ),
        ),
      ),
    );
  }

  /// Get profile image - handles both network URLs and local file paths
  ImageProvider? _getProfileImage() {
    final picUrl = widget.cardData['profilePicUrl'];
    if (picUrl == null || picUrl.isEmpty) return null;

    if (picUrl.startsWith('http') || picUrl.startsWith('blob:')) {
      // Network URL or blob URL (web)
      return NetworkImage(picUrl);
    } else {
      // Local file path
      return AssetImage(picUrl);
    }
  }

  Widget _buildContactRow(BuildContext context, IconData icon, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(value, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}
