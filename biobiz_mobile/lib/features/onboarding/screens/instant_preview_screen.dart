import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../../core/services/guest_mode_service.dart';
import '../../../core/services/website_scraper_service.dart';

import 'package:biobiz_mobile/app/theme.dart';

/// Instant Card Preview after OAuth sign-in
/// Shows preview immediately, allows refinement later
class OnboardingInstantPreviewScreen extends ConsumerStatefulWidget {
  final Map<String, String> cardData;

  const OnboardingInstantPreviewScreen({
    super.key,
    required this.cardData,
  });

  @override
  ConsumerState<OnboardingInstantPreviewScreen> createState() => _OnboardingInstantPreviewScreenState();
}

class _OnboardingInstantPreviewScreenState extends ConsumerState<OnboardingInstantPreviewScreen> {
  bool _isSaving = false;
  bool _isScraping = false;
  late Map<String, String> _cardData;

  @override
  void initState() {
    super.initState();
    _cardData = Map.from(widget.cardData);
    _autoEnhanceFromDomain();
  }

  Future<void> _autoEnhanceFromDomain() async {
    final website = _cardData['website'];
    final email = _cardData['email'];

    String? domain;
    if (website != null && website.isNotEmpty) {
      domain = website;
    } else if (email != null && email.isNotEmpty) {
      final scraper = WebsiteScraperService();
      domain = scraper.extractDomainFromEmail(email);
    }

    if (domain != null) {
      setState(() => _isScraping = true);

      try {
        final scraper = WebsiteScraperService();
        final metadata = await scraper.scrapeWebsite(domain);

        if (mounted) {
          setState(() {
            if ((_cardData['company']?.isEmpty ?? true) && metadata.companyName != null) {
              _cardData['company'] = metadata.companyName!;
            }
            if ((_cardData['logoUrl']?.isEmpty ?? true) && metadata.logoUrl != null) {
              _cardData['logoUrl'] = metadata.logoUrl!;
            }
            _isScraping = false;
          });
        }
      } catch (e) {
        if (mounted) setState(() => _isScraping = false);
      }
    }
  }

  Future<void> _createCard() async {
    setState(() => _isSaving = true);

    try {
      final supabase = Supabase.instance.client;

      User? user = supabase.auth.currentUser;
      if (user == null) {
        await Future.delayed(const Duration(seconds: 2));
        user = supabase.auth.currentUser;
      }

      if (user == null) {
        await GuestModeService().saveGuestCardData(_cardData);
        await GuestModeService().setIsGuest(true);

        if (mounted) {
          context.push('/onboarding/save-guest-card');
        }
        return;
      }

      final firstName = (_cardData['firstName'] ?? 'user').toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
      final lastName = (_cardData['lastName'] ?? '').toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
      final uniqueId = const Uuid().v4().substring(0, 8);
      final slug = lastName.isNotEmpty ? '$firstName-$lastName-$uniqueId' : '$firstName-$uniqueId';

      await supabase.from('cards').insert({
        'user_id': user.id,
        'slug': slug,
        'card_name': 'My Card',
        'first_name': _cardData['firstName'] ?? '',
        'last_name': _cardData['lastName'],
        'job_title': _cardData['jobTitle'],
        'company': _cardData['company'],
        'company_website': _cardData['website'],
        'profile_image_url': _cardData['profilePicUrl'],
        'logo_url': _cardData['logoUrl'],
        'card_color': '#000000',
        'is_active': true,
      });

      await supabase.from('profiles').update({
        'onboarding_completed': true,
      }).eq('id', user.id);

      if (mounted) {
        context.go('/card');
      }
    } catch (e, stackTrace) {
      debugPrint('Card creation error: $e');
      debugPrint('Stack trace: $stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
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

  void _editCard() {
    context.push('/card/edit');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final firstName = _cardData['firstName'] ?? '';
    final lastName = _cardData['lastName'] ?? '';
    final company = _cardData['company'];
    final jobTitle = _cardData['jobTitle'];
    final email = _cardData['email'];
    final profilePicUrl = _cardData['profilePicUrl'];

    return Scaffold(
      body: Stack(
        children: [
          // Background decorative blurs
          Positioned(
            top: MediaQuery.of(context).size.height * 0.1,
            right: -MediaQuery.of(context).size.width * 0.1,
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 100, sigmaY: 100),
              child: Container(
                width: 384,
                height: 384,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.secondaryFixed.withValues(alpha: 0.20),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: MediaQuery.of(context).size.height * 0.05,
            left: -MediaQuery.of(context).size.width * 0.05,
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
              child: Container(
                width: 256,
                height: 256,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colors.errorContainer.withValues(alpha: 0.30),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                // Top Navigation
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'BioBiz',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                          color: colors.primaryContainer,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => context.pop(),
                      ),
                    ],
                  ),
                ),
                // Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        const SizedBox(height: 32),
                        // Headline Section
                        Text(
                          'Your card is ready!',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.3,
                            color: colors.onSurface,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Preview your digital identity below',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 40),

                        // Digital Business Card
                        _buildBusinessCard(
                          context,
                          firstName: firstName,
                          lastName: lastName,
                          company: company,
                          jobTitle: jobTitle,
                          email: email,
                          profilePicUrl: profilePicUrl,
                        ),

                        // Scraping indicator
                        if (_isScraping) ...[
                          const SizedBox(height: 48),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              for (int i = 0; i < 3; i++) ...[
                                _BouncingDot(
                                  color: colors.primary,
                                  delay: Duration(milliseconds: i * 150),
                                ),
                                if (i < 2) const SizedBox(width: 6),
                              ],
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Enhancing with company info...',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              fontStyle: FontStyle.italic,
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                        ],
                        const SizedBox(height: 48),

                        // Action Buttons
                        SizedBox(
                          width: 340,
                          child: HeritageGradientButton(
                            onPressed: _isSaving ? null : _createCard,
                            height: 56,
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
                                    'Save my card',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: 340,
                          height: 56,
                          child: OutlinedButton(
                            onPressed: _isSaving ? null : _editCard,
                            child: Text(
                              'Edit details',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 48),

                        // Sign in link
                        Text.rich(
                          TextSpan(
                            text: 'Already have an account? ',
                            style: GoogleFonts.inter(
                              fontSize: 14,
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
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
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
    String? profilePicUrl,
  }) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      width: 340,
      decoration: BoxDecoration(
        color: const Color(0xFF1E3A5F),
        borderRadius: BorderRadius.circular(20),
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
            // Background texture
            Positioned(
              top: -40,
              right: -20,
              child: Container(
                width: 256,
                height: 256,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.05),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Card Header
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
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
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
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: 1.0,
                                  color: const Color(0xFF90CAF9),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.20),
                          ),
                        ),
                        child: const Icon(Icons.qr_code_2, color: Colors.white, size: 24),
                      ),
                    ],
                  ),
                  // Card Bottom
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (company != null && company.isNotEmpty) ...[
                              Text(
                                company,
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white.withValues(alpha: 0.9),
                                ),
                              ),
                              const SizedBox(height: 4),
                            ],
                            if (email != null && email.isNotEmpty)
                              Row(
                                children: [
                                  Icon(Icons.mail, size: 12, color: Colors.white.withValues(alpha: 0.6)),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      email,
                                      style: GoogleFonts.inter(
                                        fontSize: 10,
                                        color: Colors.white.withValues(alpha: 0.6),
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                      RotatedBox(
                        quarterTurns: 3,
                        child: Text(
                          'BIOBIZ ELITE',
                          style: GoogleFonts.inter(
                            fontSize: 8,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.6,
                            color: Colors.white.withValues(alpha: 0.4),
                          ),
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
    );
  }
}

/// Bouncing dot for loading animation
class _BouncingDot extends StatefulWidget {
  final Color color;
  final Duration delay;
  const _BouncingDot({required this.color, required this.delay});

  @override
  State<_BouncingDot> createState() => _BouncingDotState();
}

class _BouncingDotState extends State<_BouncingDot> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _animation = Tween(begin: 0.0, end: -8.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    Future.delayed(widget.delay, () {
      if (mounted) _controller.repeat(reverse: true);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _animation.value),
          child: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: widget.color,
            ),
          ),
        );
      },
    );
  }
}
