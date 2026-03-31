import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../app/theme.dart';
import '../../card_view/widgets/card_renderer.dart';

/// Screen shown when a user opens a shared card link (deep link).
/// Fetches the card by slug, displays it, and offers to save as contact.
class SaveCardScreen extends StatefulWidget {
  final String slug;

  const SaveCardScreen({super.key, required this.slug});

  @override
  State<SaveCardScreen> createState() => _SaveCardScreenState();
}

class _SaveCardScreenState extends State<SaveCardScreen> {
  final _supabase = Supabase.instance.client;
  Map<String, dynamic>? _card;
  List<dynamic> _contactFields = [];
  List<dynamic> _socialLinks = [];
  bool _isLoading = true;
  bool _isSaving = false;
  bool _saved = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCard();
  }

  Future<void> _loadCard() async {
    try {
      final card = await _supabase
          .from('cards')
          .select('*, card_contact_fields(*), card_social_links(*)')
          .eq('slug', widget.slug)
          .eq('is_active', true)
          .maybeSingle();

      if (card == null) {
        setState(() {
          _error = 'Card not found';
          _isLoading = false;
        });
        return;
      }

      setState(() {
        _card = card;
        _contactFields = card['card_contact_fields'] as List<dynamic>? ?? [];
        _socialLinks = card['card_social_links'] as List<dynamic>? ?? [];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load card';
        _isLoading = false;
      });
    }
  }

  String? _extractField(List<dynamic> fields, String type) {
    for (final f in fields) {
      if (f is Map && f['field_type'] == type) return f['value'] as String?;
    }
    return null;
  }

  String? _extractWebsite(List<dynamic> fields) {
    for (final f in fields) {
      if (f is Map &&
          (f['field_type'] == 'link' || f['field_type'] == 'website')) {
        return f['value'] as String?;
      }
    }
    return null;
  }

  Future<void> _saveContact() async {
    if (_card == null) return;
    final user = _supabase.auth.currentUser;
    if (user == null) {
      // Not logged in — go to login, then come back
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to save contacts')),
      );
      context.go('/login');
      return;
    }

    // Don't save yourself
    if (_card!['user_id'] == user.id) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("That's your own card!")),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final email = _extractField(_contactFields, 'email');
      final phone = _extractField(_contactFields, 'phone');
      final website = _extractWebsite(_contactFields) ?? _card!['company_website'];

      // Check if already saved
      final existing = await _supabase
          .from('contacts')
          .select('id')
          .eq('user_id', user.id)
          .eq('source_card_id', _card!['id'])
          .maybeSingle();

      final contactData = {
        'first_name': _card!['first_name'] ?? '',
        'last_name': _card!['last_name'],
        'email': email,
        'phone': phone,
        'company': _card!['company'],
        'job_title': _card!['job_title'],
        'website': website,
        'avatar_url': _card!['profile_image_url'],
        'source_card_id': _card!['id'],
      };

      String savedId;
      if (existing != null) {
        await _supabase
            .from('contacts')
            .update(contactData)
            .eq('id', existing['id']);
        savedId = existing['id'] as String;
      } else {
        final result = await _supabase.from('contacts').insert({
          'user_id': user.id,
          'source': 'scan',
          ...contactData,
        }).select('id').single();
        savedId = result['id'] as String;
      }

      // Save social links
      if (_socialLinks.isNotEmpty) {
        await _supabase
            .from('contact_social_links')
            .delete()
            .eq('contact_id', savedId);
        final toInsert = _socialLinks
            .whereType<Map>()
            .map((link) => {
                  'contact_id': savedId,
                  'platform': link['platform'],
                  'url': link['url'],
                })
            .toList();
        if (toInsert.isNotEmpty) {
          await _supabase.from('contact_social_links').insert(toInsert);
        }
      }

      // Track event
      await _supabase.from('card_events').insert({
        'card_id': _card!['id'],
        'event_type': 'save_contact',
      }).catchError((_) {});

      setState(() => _saved = true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shared Card'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              context.go('/card');
            }
          },
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildError()
              : _buildCard(),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.error_outline,
                  size: 64, color: Theme.of(context).colorScheme.error),
            ),
            const SizedBox(height: 16),
            Text(_error!, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 24),
            HeritageGradientButton(
              onPressed: () => context.go('/card'),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.home, color: Colors.white),
                  const SizedBox(width: 8),
                  Text(
                    'Go Home',
                    style: GoogleFonts.plusJakartaSans(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard() {
    final cardData = Map<String, dynamic>.from(_card!);
    cardData['contact_fields'] = _contactFields;
    cardData['social_links'] = _socialLinks;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Render the full card
          CardRenderer(cardData: cardData),
          const SizedBox(height: 24),

          // Save / Saved button
          if (_saved) ...[
            Icon(Icons.check_circle,
                size: 48, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 8),
            Text('Contact Saved!',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => context.go('/contacts'),
                    child: const Text('View Contacts'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: HeritageGradientButton(
                    onPressed: () => context.go('/card'),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.home, color: Colors.white),
                        const SizedBox(width: 8),
                        Text(
                          'Go Home',
                          style: GoogleFonts.plusJakartaSans(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ] else ...[
            HeritageGradientButton(
              onPressed: _isSaving ? null : _saveContact,
              child: _isSaving
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.person_add, color: Colors.white),
                        const SizedBox(width: 8),
                        Text(
                          _isSaving ? 'Saving...' : 'Save to My Contacts',
                          style: GoogleFonts.plusJakartaSans(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ],
      ),
    );
  }
}
