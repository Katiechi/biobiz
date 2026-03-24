import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Scanner screen with QR Code, My QR, Smart, and Manual modes
class ScanScreen extends ConsumerStatefulWidget {
  const ScanScreen({super.key});

  @override
  ConsumerState<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends ConsumerState<ScanScreen> {
  final _supabase = Supabase.instance.client;
  int _selectedMode = 0; // 0=Scan QR, 1=My QR, 2=Manual
  MobileScannerController? _scannerController;
  bool _hasScanned = false;
  Map<String, dynamic>? _scannedCard;
  bool _isSaving = false;

  // My card data for QR display
  String? _myCardUrl;
  String? _myName;
  bool _isLoadingMyCard = true;

  @override
  void initState() {
    super.initState();
    _scannerController = MobileScannerController();
    _loadMyCard();
  }

  @override
  void dispose() {
    _scannerController?.dispose();
    super.dispose();
  }

  Future<void> _loadMyCard() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;
      final card = await _supabase
          .from('cards')
          .select()
          .eq('user_id', user.id)
          .eq('is_active', true)
          .maybeSingle();
      if (card != null && mounted) {
        setState(() {
          _myCardUrl = 'https://biobiz.app/card/${card['slug']}';
          _myName =
              '${card['first_name'] ?? ''} ${card['last_name'] ?? ''}'.trim();
        });
      }
    } catch (_) {}
    if (mounted) setState(() => _isLoadingMyCard = false);
  }

  void _onQrDetected(BarcodeCapture capture) {
    if (_hasScanned) return;
    final barcode = capture.barcodes.firstOrNull;
    if (barcode == null || barcode.rawValue == null) return;

    setState(() => _hasScanned = true);
    _scannerController?.stop();

    _handleScannedValue(barcode.rawValue!);
  }

  Future<void> _handleScannedValue(String value) async {
    final biobizPattern = RegExp(r'biobiz\.app/card/(.+)');
    final match = biobizPattern.firstMatch(value);

    if (match != null) {
      final slug = match.group(1)!;
      await _saveContactFromSlug(slug);
    } else if (value.startsWith('http')) {
      if (mounted) _showResultDialog('Link Scanned', value);
    } else {
      if (mounted) _showResultDialog('Scanned', value);
    }
  }

  /// Save social links from a card to a contact's contact_social_links
  Future<void> _saveSocialLinksToContact(
      String contactId, List<dynamic>? cardSocialLinks) async {
    if (cardSocialLinks == null || cardSocialLinks.isEmpty) return;
    try {
      // Clear existing social links for this contact
      await _supabase
          .from('contact_social_links')
          .delete()
          .eq('contact_id', contactId);
      // Insert new ones
      final toInsert = cardSocialLinks
          .whereType<Map>()
          .map((link) => {
                'contact_id': contactId,
                'platform': link['platform'],
                'url': link['url'],
              })
          .toList();
      if (toInsert.isNotEmpty) {
        await _supabase.from('contact_social_links').insert(toInsert);
      }
    } catch (_) {}
  }

  /// Extract the first email or phone from card_contact_fields list
  String? _extractField(List<dynamic>? fields, String type) {
    if (fields == null) return null;
    for (final f in fields) {
      if (f is Map && f['field_type'] == type) return f['value'] as String?;
    }
    return null;
  }

  /// Extract website URL from contact fields (type 'link' or 'website')
  String? _extractWebsite(List<dynamic>? fields) {
    if (fields == null) return null;
    for (final f in fields) {
      if (f is Map &&
          (f['field_type'] == 'link' || f['field_type'] == 'website')) {
        return f['value'] as String?;
      }
    }
    return null;
  }

  Future<void> _saveContactFromSlug(String slug) async {
    setState(() => _isSaving = true);
    try {
      // Look up their card WITH contact fields and social links
      final card = await _supabase
          .from('cards')
          .select('*, card_contact_fields(*), card_social_links(*)')
          .eq('slug', slug)
          .eq('is_active', true)
          .maybeSingle();

      if (card == null) {
        if (mounted) _showResultDialog('Not Found', 'This card could not be found.');
        return;
      }

      final user = _supabase.auth.currentUser;
      if (user == null) return;

      // Don't save yourself as a contact
      if (card['user_id'] == user.id) {
        if (mounted) {
          _showResultDialog('That\'s you!', 'You scanned your own card.');
        }
        return;
      }

      // Extract email and phone from card_contact_fields
      final theirFields = card['card_contact_fields'] as List<dynamic>?;
      final theirEmail = _extractField(theirFields, 'email');
      final theirPhone = _extractField(theirFields, 'phone');
      final theirWebsite = _extractWebsite(theirFields) ?? card['company_website'];

      // Check if we already have this contact (by source_card_id)
      final existingContact = await _supabase
          .from('contacts')
          .select('id')
          .eq('user_id', user.id)
          .eq('source_card_id', card['id'])
          .maybeSingle();

      final contactData = {
        'first_name': card['first_name'] ?? '',
        'last_name': card['last_name'],
        'email': theirEmail,
        'phone': theirPhone,
        'company': card['company'],
        'job_title': card['job_title'],
        'website': theirWebsite,
        'avatar_url': card['profile_image_url'],
        'source_card_id': card['id'],
      };

      String savedContactId;
      if (existingContact != null) {
        // Update existing contact with latest info
        await _supabase
            .from('contacts')
            .update(contactData)
            .eq('id', existingContact['id']);
        savedContactId = existingContact['id'] as String;
      } else {
        // Save as new contact
        final result = await _supabase.from('contacts').insert({
          'user_id': user.id,
          'source': 'scan',
          ...contactData,
        }).select('id').single();
        savedContactId = result['id'] as String;
      }

      // Save their social links to the contact
      final theirSocialLinks = card['card_social_links'] as List<dynamic>?;
      await _saveSocialLinksToContact(savedContactId, theirSocialLinks);

      // Auto-exchange: save YOUR card as THEIR contact
      final myCard = await _supabase
          .from('cards')
          .select('*, card_contact_fields(*), card_social_links(*)')
          .eq('user_id', user.id)
          .eq('is_active', true)
          .maybeSingle();

      if (myCard != null) {
        final myFields = myCard['card_contact_fields'] as List<dynamic>?;
        final myEmail = _extractField(myFields, 'email');
        final myPhone = _extractField(myFields, 'phone');
        final myWebsite = _extractWebsite(myFields) ?? myCard['company_website'];

        // Auto-exchange via RPC (bypasses RLS to insert into other user's contacts)
        try {
          final exchangeResult = await _supabase.rpc('auto_exchange_contact', params: {
            'target_user_id': card['user_id'],
            'source_card_id': myCard['id'],
            'contact_first_name': myCard['first_name'] ?? '',
            'contact_last_name': myCard['last_name'],
            'contact_email': myEmail,
            'contact_phone': myPhone,
            'contact_company': myCard['company'],
            'contact_job_title': myCard['job_title'],
            'contact_website': myWebsite,
            'contact_avatar_url': myCard['profile_image_url'],
          });

          final exchangeContactId = exchangeResult as String?;
          if (exchangeContactId != null) {
            final mySocialLinks = myCard['card_social_links'] as List<dynamic>?;
            await _saveSocialLinksToContact(exchangeContactId, mySocialLinks);
          }
        } catch (e) {
          debugPrint('Auto-exchange failed: $e');
        }
      }

      // Track scan event (exchange event type for card scans)
      await _supabase.from('card_events').insert({
        'card_id': card['id'],
        'event_type': 'exchange',
      }).catchError((_) {});

      if (mounted) {
        // Store the enriched card data with extracted fields for the success screen
        card['_email'] = theirEmail;
        card['_phone'] = theirPhone;
        setState(() => _scannedCard = card);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
        _resetScanner();
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showResultDialog(String title, String content) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _resetScanner();
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _resetScanner() {
    setState(() {
      _hasScanned = false;
      _scannedCard = null;
    });
    _scannerController?.start();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan')),
      body: Column(
        children: [
          // Mode tabs
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _buildModeTab('Scan QR', 0),
                const SizedBox(width: 8),
                _buildModeTab('My QR', 1),
                const SizedBox(width: 8),
                _buildModeTab('Manual', 2),
              ],
            ),
          ),
          Expanded(
            child: switch (_selectedMode) {
              0 => _hasScanned && _scannedCard != null
                  ? _buildScanSuccess()
                  : _buildQrScanner(),
              1 => _buildMyQr(),
              _ => _buildManualForm(),
            },
          ),
        ],
      ),
    );
  }

  Widget _buildModeTab(String label, int index) {
    final isSelected = _selectedMode == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() => _selectedMode = index);
          if (index == 0 && !_hasScanned) {
            _scannerController?.start();
          } else if (index != 0) {
            _scannerController?.stop();
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected
                  ? Theme.of(context).colorScheme.onPrimary
                  : Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQrScanner() {
    return Stack(
      children: [
        MobileScanner(
          controller: _scannerController,
          onDetect: _onQrDetected,
        ),
        Center(
          child: Container(
            width: 250,
            height: 250,
            decoration: BoxDecoration(
              border: Border.all(
                color: Theme.of(context).colorScheme.primary,
                width: 3,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
        if (_isSaving)
          Container(
            color: Colors.black54,
            child: const Center(child: CircularProgressIndicator()),
          ),
        Positioned(
          bottom: 48,
          left: 24,
          right: 24,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'Point your camera at a QR code',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white, fontSize: 14),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildScanSuccess() {
    final card = _scannedCard!;
    final name =
        '${card['first_name'] ?? ''} ${card['last_name'] ?? ''}'.trim();
    final company = card['company'] ?? '';
    final jobTitle = card['job_title'] ?? '';
    final email = card['_email'] as String? ?? '';
    final phone = card['_phone'] as String? ?? '';
    final avatarUrl = card['profile_image_url'] as String?;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Success icon
          Icon(
            Icons.check_circle,
            size: 64,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 16),
          Text(
            'Contact Exchanged!',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'You and $name have exchanged cards',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),

          // Scanned contact card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundColor:
                        Theme.of(context).colorScheme.primaryContainer,
                    backgroundImage:
                        avatarUrl != null ? NetworkImage(avatarUrl) : null,
                    child: avatarUrl == null
                        ? Text(
                            name.isNotEmpty ? name[0].toUpperCase() : '?',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onPrimaryContainer,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(height: 12),
                  Text(name,
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  if (jobTitle.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(jobTitle,
                        style: Theme.of(context).textTheme.bodyMedium),
                  ],
                  if (company.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(company,
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant)),
                  ],
                  if (email.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.email_outlined,
                            size: 16,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant),
                        const SizedBox(width: 6),
                        Text(email,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant)),
                      ],
                    ),
                  ],
                  if (phone.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.phone_outlined,
                            size: 16,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant),
                        const SizedBox(width: 6),
                        Text(phone,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant)),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Show my QR for them to scan
          if (_myCardUrl != null) ...[
            Text(
              'Now let them scan your code:',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: QrImageView(
                data: _myCardUrl!,
                version: QrVersions.auto,
                size: 160,
                backgroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _myName ?? '',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
          const SizedBox(height: 24),

          // Actions
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
                child: FilledButton(
                  onPressed: _resetScanner,
                  child: const Text('Scan Another'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMyQr() {
    if (_isLoadingMyCard) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_myCardUrl == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.qr_code,
                  size: 64,
                  color: Theme.of(context).colorScheme.onSurfaceVariant),
              const SizedBox(height: 16),
              Text('No card yet',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Text('Create a card first to get your QR code',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color:
                          Theme.of(context).colorScheme.onSurfaceVariant)),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => context.go('/card'),
                child: const Text('Create Card'),
              ),
            ],
          ),
        ),
      );
    }

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Your QR Code',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Let others scan this to get your card',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  QrImageView(
                    data: _myCardUrl!,
                    version: QrVersions.auto,
                    size: 220,
                    backgroundColor: Colors.white,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _myName ?? '',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            OutlinedButton.icon(
              onPressed: () => context.push('/card/share'),
              icon: const Icon(Icons.share),
              label: const Text('More sharing options'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildManualForm() {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final phoneController = TextEditingController();
    final companyController = TextEditingController();
    final titleController = TextEditingController();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Add contact manually',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: nameController,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Name *',
              prefixIcon: Icon(Icons.person_outline),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Email',
              prefixIcon: Icon(Icons.email_outlined),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: phoneController,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'Phone',
              prefixIcon: Icon(Icons.phone_outlined),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: companyController,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Company',
              prefixIcon: Icon(Icons.business_outlined),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: titleController,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Job title',
              prefixIcon: Icon(Icons.work_outline),
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () async {
              if (nameController.text.trim().isEmpty) return;

              try {
                final user = _supabase.auth.currentUser;
                if (user == null) return;

                final nameParts = nameController.text.trim().split(' ');
                await _supabase.from('contacts').insert({
                  'user_id': user.id,
                  'source': 'manual',
                  'first_name': nameParts.first,
                  'last_name': nameParts.length > 1
                      ? nameParts.sublist(1).join(' ')
                      : null,
                  'email': emailController.text.trim().isEmpty
                      ? null
                      : emailController.text.trim(),
                  'phone': phoneController.text.trim().isEmpty
                      ? null
                      : phoneController.text.trim(),
                  'company': companyController.text.trim().isEmpty
                      ? null
                      : companyController.text.trim(),
                  'job_title': titleController.text.trim().isEmpty
                      ? null
                      : titleController.text.trim(),
                });

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Contact saved!')),
                  );
                  nameController.clear();
                  emailController.clear();
                  phoneController.clear();
                  companyController.clear();
                  titleController.clear();
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: ${e.toString()}')),
                  );
                }
              }
            },
            icon: const Icon(Icons.save),
            label: const Text('Save Contact'),
          ),
        ],
      ),
    );
  }
}
