import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import 'package:biobiz_mobile/app/theme.dart';

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
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final firstName = widget.cardData['firstName'] ?? '';
    final lastName = widget.cardData['lastName'] ?? '';
    final company = widget.cardData['company'];
    final jobTitle = widget.cardData['jobTitle'];
    final email = widget.cardData['email'];
    final phone = widget.cardData['phone'];
    final workEmail = widget.cardData['workEmail'];

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Top Navigation
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => context.pop(),
                  ),
                  Text(
                    'Looking good!',
                    style: theme.textTheme.displaySmall,
                  ),
                  const SizedBox(width: 48), // Spacer for symmetry
                ],
              ),
            ),
            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    const SizedBox(height: 16),
                    // Step label
                    Text(
                      'STEP 3 OF 3',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colors.onSurfaceVariant,
                        letterSpacing: 1.6,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Here's a preview of your card",
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                        color: colors.onSurface,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 48),

                    // Business Card
                    _buildBusinessCard(
                      context,
                      firstName: firstName,
                      lastName: lastName,
                      company: company,
                      jobTitle: jobTitle,
                      email: email,
                      workEmail: workEmail,
                      phone: phone,
                    ),
                    const SizedBox(height: 16),

                    // Tap to flip hint
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.touch_app, size: 14, color: colors.onSurfaceVariant.withValues(alpha: 0.6)),
                        const SizedBox(width: 8),
                        Text(
                          'Tap to flip card',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: colors.onSurfaceVariant.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 48),

                    // Actions
                    HeritageGradientButton(
                      onPressed: _isSaving ? null : _createCard,
                      child: _isSaving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              'Continue',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: OutlinedButton(
                        onPressed: () {
                          context.push('/card/edit');
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.palette, size: 20, color: colors.primary),
                            const SizedBox(width: 8),
                            Text(
                              'Edit design',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Sign in link for existing users
                    Text.rich(
                      TextSpan(
                        text: 'Already have an account? ',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () => context.go('/login'),
                      child: Text(
                        'Sign in',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: colors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBusinessCard(
    BuildContext context, {
    required String firstName,
    required String lastName,
    String? company,
    String? jobTitle,
    String? email,
    String? workEmail,
    String? phone,
  }) {
    final colors = Theme.of(context).colorScheme;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Card accent glow
        Positioned(
          bottom: -16,
          right: -16,
          child: ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
            child: Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.gold.withValues(alpha: 0.10),
              ),
            ),
          ),
        ),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1E3A5F), Color(0xFF102A43)],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 40,
                offset: const Offset(0, 20),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: AspectRatio(
            aspectRatio: 1.586,
            child: Stack(
              children: [
                // Decorative elements
                Positioned(
                  top: -48,
                  right: -48,
                  child: Container(
                    width: 192,
                    height: 192,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.05),
                    ),
                  ),
                ),
                Positioned(
                  bottom: -32,
                  left: -32,
                  child: ImageFiltered(
                    imageFilter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
                    child: Container(
                      width: 128,
                      height: 128,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: colors.primary.withValues(alpha: 0.10),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Top row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '$firstName $lastName'.trim(),
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: -0.3,
                                    color: Colors.white,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (jobTitle != null && jobTitle.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    jobTitle.toUpperCase(),
                                    style: GoogleFonts.inter(
                                      fontSize: 10,
                                      letterSpacing: 2.0,
                                      color: Colors.white.withValues(alpha: 0.7),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.10),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: _getProfileImage() != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image(
                                      image: _getProfileImage()!,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Icon(
                                        Icons.pentagon,
                                        color: Colors.white,
                                        size: 28,
                                      ),
                                    ),
                                  )
                                : const Icon(Icons.pentagon, color: Colors.white, size: 28),
                          ),
                        ],
                      ),
                      // Bottom row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (email != null && email.isNotEmpty)
                                  _buildCardContact(Icons.mail, email),
                                if (workEmail != null && workEmail.isNotEmpty && workEmail != email)
                                  _buildCardContact(Icons.work, workEmail),
                                if (phone != null && phone.isNotEmpty)
                                  _buildCardContact(Icons.call, phone),
                              ],
                            ),
                          ),
                          // QR placeholder
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.15),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.qr_code_2,
                              size: 48,
                              color: Colors.grey.shade800,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCardContact(IconData icon, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.white.withValues(alpha: 0.6)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.white.withValues(alpha: 0.9),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
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
}
