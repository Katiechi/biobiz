import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../../core/services/guest_mode_service.dart';
import '../../../core/services/website_scraper_service.dart';

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
    final firstName = _cardData['firstName'] ?? '';
    final lastName = _cardData['lastName'] ?? '';
    final company = _cardData['company'];
    final jobTitle = _cardData['jobTitle'];
    final email = _cardData['email'];
    final profilePicUrl = _cardData['profilePicUrl'];

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Your card is ready!',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'We created this from your ${profilePicUrl != null && profilePicUrl.isNotEmpty ? "profile" : "info"}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                textAlign: TextAlign.center,
              ),
              if (_isScraping) ...[
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Enhancing with company info...',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 32),
              Expanded(
                child: Center(
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
                          CircleAvatar(
                            radius: 40,
                            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                            backgroundImage: profilePicUrl != null && profilePicUrl.isNotEmpty
                                ? NetworkImage(profilePicUrl)
                                : null,
                            child: profilePicUrl == null || profilePicUrl.isEmpty
                                ? Text(
                                    firstName.isNotEmpty ? firstName[0].toUpperCase() : '?',
                                    style: TextStyle(
                                      fontSize: 32,
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                                    ),
                                  )
                                : null,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            '$firstName ${lastName}'.trim(),
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                          if (jobTitle != null && jobTitle.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              jobTitle,
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
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
                          if (email != null && email.isNotEmpty)
                            _buildContactRow(context, Icons.email_outlined, email),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _isSaving ? null : _createCard,
                child: _isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Save my card'),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: _isSaving ? null : _editCard,
                child: const Text('Edit details'),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
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
