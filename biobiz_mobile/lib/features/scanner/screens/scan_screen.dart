import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:biobiz_mobile/app/theme.dart';

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
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Scan')),
      body: Column(
        children: [
          // Segmented tab selector
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  _buildModeTab('Scan QR', 0),
                  const SizedBox(width: 4),
                  _buildModeTab('My QR', 1),
                  const SizedBox(width: 4),
                  _buildModeTab('Manual', 2),
                ],
              ),
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
      floatingActionButton: GoldFab(
        onPressed: () {
          // Quick share: switch to My QR tab
          setState(() => _selectedMode = 1);
          _scannerController?.stop();
        },
        icon: Icons.qr_code_2,
        tooltip: 'Show my QR',
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildModeTab(String label, int index) {
    final isSelected = _selectedMode == index;
    final cs = Theme.of(context).colorScheme;
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
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? cs.surfaceContainerLowest : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: isSelected ? cs.primary : cs.onSurfaceVariant,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQrScanner() {
    return Stack(
      children: [
        // Camera view in a rounded container
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(32),
            child: SizedBox(
              width: double.infinity,
              height: double.infinity,
              child: MobileScanner(
                controller: _scannerController,
                onDetect: _onQrDetected,
              ),
            ),
          ),
        ),
        // Dark overlay
        Positioned.fill(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(32),
              child: Container(
                color: Colors.black.withValues(alpha: 0.35),
              ),
            ),
          ),
        ),
        // Scanning frame with corner brackets
        Center(
          child: SizedBox(
            width: 250,
            height: 250,
            child: CustomPaint(
              painter: _CornerBracketPainter(
                color: Colors.white,
                strokeWidth: 4,
                cornerLength: 40,
                cornerRadius: 12,
              ),
            ),
          ),
        ),
        // Scanning line animation
        Center(
          child: SizedBox(
            width: 250,
            height: 250,
            child: _ScanLineAnimation(),
          ),
        ),
        // Loading overlay
        if (_isSaving)
          Container(
            color: Colors.black54,
            child: const Center(child: CircularProgressIndicator()),
          ),
        // Camera controls (flash, flip)
        Positioned(
          top: 24,
          right: 40,
          child: Column(
            children: [
              _buildCameraControlButton(
                icon: Icons.flashlight_on,
                onTap: () => _scannerController?.toggleTorch(),
              ),
              const SizedBox(height: 12),
              _buildCameraControlButton(
                icon: Icons.flip_camera_ios,
                onTap: () => _scannerController?.switchCamera(),
              ),
            ],
          ),
        ),
        // Instruction pill
        Positioned(
          bottom: 48,
          left: 0,
          right: 0,
          child: Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(100),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.12),
                    ),
                  ),
                  child: Text(
                    'Align QR code within the frame',
                    style: GoogleFonts.inter(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCameraControlButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.4),
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.1),
          ),
        ),
        child: Icon(icon, color: Colors.white, size: 22),
      ),
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
    final cs = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Success icon
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.check_circle,
              size: 48,
              color: cs.primary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Contact Exchanged!',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'You and $name have exchanged cards',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: cs.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),

          // Scanned contact card
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: cs.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundColor: cs.primaryContainer,
                  backgroundImage:
                      avatarUrl != null ? NetworkImage(avatarUrl) : null,
                  child: avatarUrl == null
                      ? Text(
                          name.isNotEmpty ? name[0].toUpperCase() : '?',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: cs.onPrimaryContainer,
                          ),
                        )
                      : null,
                ),
                const SizedBox(height: 12),
                Text(
                  name,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface,
                  ),
                ),
                if (jobTitle.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(jobTitle,
                      style: Theme.of(context).textTheme.bodyMedium),
                ],
                if (company.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(company,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: cs.onSurfaceVariant,
                      )),
                ],
                if (email.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.email_outlined,
                          size: 16, color: cs.onSurfaceVariant),
                      const SizedBox(width: 6),
                      Text(email,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: cs.onSurfaceVariant,
                          )),
                    ],
                  ),
                ],
                if (phone.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.phone_outlined,
                          size: 16, color: cs.onSurfaceVariant),
                      const SizedBox(width: 6),
                      Text(phone,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: cs.onSurfaceVariant,
                          )),
                    ],
                  ),
                ],
              ],
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
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 12,
                    offset: const Offset(0, 2),
                  ),
                ],
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
              style: GoogleFonts.inter(
                fontSize: 12,
                color: cs.onSurfaceVariant,
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
    final cs = Theme.of(context).colorScheme;

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
              Icon(Icons.qr_code, size: 64, color: cs.onSurfaceVariant),
              const SizedBox(height: 16),
              Text('No card yet',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Text('Create a card first to get your QR code',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: cs.onSurfaceVariant,
                  )),
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
              style: GoogleFonts.plusJakartaSans(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Let others scan this to get your card',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: cs.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 32),
            // QR card with premium shadow
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: cs.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
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
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: cs.onSurface,
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

// ─── Corner bracket painter for QR scan frame ────────────────────
class _CornerBracketPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double cornerLength;
  final double cornerRadius;

  _CornerBracketPainter({
    required this.color,
    required this.strokeWidth,
    required this.cornerLength,
    required this.cornerRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final w = size.width;
    final h = size.height;
    final r = cornerRadius;
    final l = cornerLength;

    // Top-left corner
    final tlPath = Path()
      ..moveTo(0, l)
      ..lineTo(0, r)
      ..arcToPoint(Offset(r, 0), radius: Radius.circular(r))
      ..lineTo(l, 0);
    canvas.drawPath(tlPath, paint);

    // Top-right corner
    final trPath = Path()
      ..moveTo(w - l, 0)
      ..lineTo(w - r, 0)
      ..arcToPoint(Offset(w, r), radius: Radius.circular(r))
      ..lineTo(w, l);
    canvas.drawPath(trPath, paint);

    // Bottom-left corner
    final blPath = Path()
      ..moveTo(0, h - l)
      ..lineTo(0, h - r)
      ..arcToPoint(Offset(r, h), radius: Radius.circular(r))
      ..lineTo(l, h);
    canvas.drawPath(blPath, paint);

    // Bottom-right corner
    final brPath = Path()
      ..moveTo(w - l, h)
      ..lineTo(w - r, h)
      ..arcToPoint(Offset(w, h - r), radius: Radius.circular(r))
      ..lineTo(w, h - l);
    canvas.drawPath(brPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─── Scanning line animation widget ──────────────────────────────
class _ScanLineAnimation extends StatefulWidget {
  @override
  State<_ScanLineAnimation> createState() => _ScanLineAnimationState();
}

class _ScanLineAnimationState extends State<_ScanLineAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        // Smooth sine-wave oscillation
        final progress = sin(_controller.value * pi);
        final opacity = (_controller.value < 0.1 || _controller.value > 0.9)
            ? (_controller.value < 0.1
                ? _controller.value / 0.1
                : (1.0 - _controller.value) / 0.1)
            : 1.0;

        return Stack(
          children: [
            Positioned(
              top: progress * 240,
              left: 0,
              right: 0,
              child: Opacity(
                opacity: opacity,
                child: Container(
                  height: 2,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        AppTheme.primary.withValues(alpha: 0.8),
                        Colors.transparent,
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primary.withValues(alpha: 0.5),
                        blurRadius: 15,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
