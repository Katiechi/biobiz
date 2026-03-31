import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../app/theme.dart';

class EmailSignatureScreen extends StatefulWidget {
  const EmailSignatureScreen({super.key});

  @override
  State<EmailSignatureScreen> createState() => _EmailSignatureScreenState();
}

class _EmailSignatureScreenState extends State<EmailSignatureScreen> {
  final _supabase = Supabase.instance.client;
  Map<String, dynamic>? _card;
  String? _signatureHtml;
  String _selectedTemplate = 'modern';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCard();
  }

  Future<void> _loadCard() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      final cards = await _supabase
          .from('cards')
          .select()
          .eq('user_id', user.id)
          .eq('is_active', true)
          .limit(1);

      if (cards.isNotEmpty && mounted) {
        setState(() {
          _card = cards.first;
          _signatureHtml = _generateSignature(cards.first, _selectedTemplate);
        });
      }
    } catch (e) {
      debugPrint('Error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _generateSignature(Map<String, dynamic> card, String template) {
    final name = '${card['first_name'] ?? ''} ${card['last_name'] ?? ''}'.trim();
    final title = card['job_title'] ?? '';
    final company = card['company'] ?? '';
    final website = card['company_website'] ?? '';
    final slug = card['slug'] ?? '';
    final cardUrl = 'https://biobiz.app/card/$slug';
    final color = card['card_color'] ?? '#00C9A7';

    switch (template) {
      case 'minimal':
        return '<table cellpadding="0" cellspacing="0" style="font-family:Arial,sans-serif;font-size:13px;color:#333;">'
            '<tr><td><strong>$name</strong><br/>'
            '${title.isNotEmpty ? '$title<br/>' : ''}${company.isNotEmpty ? '$company<br/>' : ''}'
            '<a href="$cardUrl" style="color:$color;">View my digital card</a>'
            '</td></tr></table>';
      case 'professional':
        return '<table cellpadding="0" cellspacing="0" style="font-family:Arial,sans-serif;font-size:13px;color:#333;">'
            '<tr><td style="border-left:3px solid $color;padding-left:12px;">'
            '<strong style="font-size:15px;">$name</strong><br/>'
            '${title.isNotEmpty ? '<span style="color:#666;">$title</span><br/>' : ''}'
            '${company.isNotEmpty ? '<strong>$company</strong><br/>' : ''}'
            '${website.isNotEmpty ? '<a href="$website" style="color:$color;">$website</a><br/>' : ''}'
            '<br/><a href="$cardUrl" style="display:inline-block;padding:6px 16px;background-color:$color;color:white;text-decoration:none;border-radius:4px;font-size:12px;">View Digital Card</a>'
            '</td></tr></table>';
      default:
        return '<table cellpadding="0" cellspacing="0" style="font-family:Arial,sans-serif;font-size:13px;color:#333;">'
            '<tr><td style="padding-right:16px;border-right:2px solid $color;">'
            '<strong style="font-size:16px;color:$color;">$name</strong><br/>'
            '${title.isNotEmpty ? '$title<br/>' : ''}${company.isNotEmpty ? company : ''}'
            '</td><td style="padding-left:16px;">'
            '${website.isNotEmpty ? '<a href="$website" style="color:$color;text-decoration:none;">Website</a><br/>' : ''}'
            '<a href="$cardUrl" style="color:$color;text-decoration:none;">Digital Card</a>'
            '</td></tr></table>';
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Email Signature')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _card == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.badge_outlined, size: 64, color: cs.primary),
                      const SizedBox(height: 16),
                      const Text('Create a card first to generate a signature'),
                    ],
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                  children: [
                    // ── Page Header ──
                    Text('Email Signature', style: tt.displaySmall),
                    const SizedBox(height: 4),
                    Text(
                      'Customize your editorial-grade digital identity.',
                      style: tt.bodySmall?.copyWith(letterSpacing: 0.3),
                    ),
                    const SizedBox(height: 32),

                    // ── Template Selection ──
                    _buildSectionHeader('Choose Template'),
                    const SizedBox(height: 12),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildTemplateChip('Modern', 'modern'),
                          const SizedBox(width: 10),
                          _buildTemplateChip('Professional', 'professional'),
                          const SizedBox(width: 10),
                          _buildTemplateChip('Minimal', 'minimal'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // ── Live Preview ──
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: cs.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'LIVE PREVIEW',
                                style: tt.labelSmall?.copyWith(
                                  color: cs.onSurfaceVariant,
                                  letterSpacing: 1.5,
                                ),
                              ),
                              // Browser dots
                              Row(
                                children: [
                                  _buildDot(cs.error.withValues(alpha: 0.2)),
                                  const SizedBox(width: 6),
                                  _buildDot(cs.secondary.withValues(alpha: 0.2)),
                                  const SizedBox(width: 6),
                                  _buildDot(cs.primary.withValues(alpha: 0.2)),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // Signature preview card
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: cs.surfaceContainerLowest,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.06),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Stack(
                              children: [
                                // Heritage accent decoration
                                Positioned(
                                  top: -20,
                                  right: -20,
                                  child: Container(
                                    width: 80,
                                    height: 80,
                                    decoration: BoxDecoration(
                                      gradient: AppTheme.heritageGradient,
                                      borderRadius: const BorderRadius.only(
                                        bottomLeft: Radius.circular(80),
                                      ),
                                    ),
                                    foregroundDecoration: BoxDecoration(
                                      color: cs.surfaceContainerLowest.withValues(alpha: 0.95),
                                      borderRadius: const BorderRadius.only(
                                        bottomLeft: Radius.circular(80),
                                      ),
                                    ),
                                  ),
                                ),
                                _buildPreview(),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // ── Action Buttons ──
                    HeritageGradientButton(
                      onPressed: () {
                        if (_signatureHtml != null) {
                          Clipboard.setData(ClipboardData(text: _signatureHtml!));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('HTML copied to clipboard!')),
                          );
                        }
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.content_copy, color: Colors.white, size: 20),
                          const SizedBox(width: 10),
                          Text('Copy HTML Code', style: GoogleFonts.plusJakartaSans(
                            color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title.toUpperCase(),
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
        color: Theme.of(context).colorScheme.onSurfaceVariant,
        letterSpacing: 1.5,
      ),
    );
  }

  Widget _buildDot(Color color) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildTemplateChip(String label, String value) {
    final cs = Theme.of(context).colorScheme;
    final isSelected = _selectedTemplate == value;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTemplate = value;
          if (_card != null) _signatureHtml = _generateSignature(_card!, value);
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? cs.primaryContainer : cs.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(100),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? cs.onPrimaryContainer : cs.onSurface,
            letterSpacing: 0.3,
          ),
        ),
      ),
    );
  }

  Widget _buildPreview() {
    if (_card == null) return const SizedBox.shrink();
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final name = '${_card!['first_name'] ?? ''} ${_card!['last_name'] ?? ''}'.trim();
    final title = _card!['job_title'] ?? '';
    final company = _card!['company'] ?? '';
    final website = _card!['company_website'] ?? '';
    final slug = _card!['slug'] ?? '';
    final cardUrl = 'https://biobiz.app/card/$slug';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          name,
          style: tt.headlineMedium?.copyWith(color: cs.primary),
        ),
        if (title.isNotEmpty || company.isNotEmpty)
          Text(
            [title, company].where((s) => s.isNotEmpty).join(' \u2022 '),
            style: tt.labelSmall?.copyWith(
              color: cs.secondary,
              letterSpacing: 1.0,
            ),
          ),
        const SizedBox(height: 16),
        // Contact details with left border
        Container(
          padding: const EdgeInsets.only(left: 12),
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(
                color: cs.outlineVariant.withValues(alpha: 0.3),
                width: 2,
              ),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (website.isNotEmpty)
                _buildPreviewContactRow(Icons.public, website),
              _buildPreviewContactRow(Icons.link, cardUrl),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Icon(Icons.share, size: 20, color: cs.onSurfaceVariant),
            const SizedBox(width: 16),
            Icon(Icons.link, size: 20, color: cs.onSurfaceVariant),
            const SizedBox(width: 16),
            Icon(Icons.qr_code, size: 20, color: cs.onSurfaceVariant),
          ],
        ),
      ],
    );
  }

  Widget _buildPreviewContactRow(IconData icon, String text) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Icon(icon, size: 14, color: cs.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: cs.onSurfaceVariant,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Color _parseColor(String hex) {
    try {
      return Color(int.parse(hex.replaceFirst('#', '0xFF')));
    } catch (_) {
      return const Color(0xFF00C9A7);
    }
  }
}
