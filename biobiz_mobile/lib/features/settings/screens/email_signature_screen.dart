import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
    return Scaffold(
      appBar: AppBar(title: const Text('Email Signature')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _card == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.badge_outlined, size: 64, color: Theme.of(context).colorScheme.primary),
                      const SizedBox(height: 16),
                      const Text('Create a card first to generate a signature'),
                    ],
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Text('Template', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _buildTemplateChip('Modern', 'modern'),
                        const SizedBox(width: 8),
                        _buildTemplateChip('Professional', 'professional'),
                        const SizedBox(width: 8),
                        _buildTemplateChip('Minimal', 'minimal'),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Text('Preview', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
                      ),
                      child: _buildPreview(),
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: () {
                        if (_signatureHtml != null) {
                          Clipboard.setData(ClipboardData(text: _signatureHtml!));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('HTML copied to clipboard!')),
                          );
                        }
                      },
                      icon: const Icon(Icons.copy),
                      label: const Text('Copy HTML'),
                    ),
                  ],
                ),
    );
  }

  Widget _buildTemplateChip(String label, String value) {
    return FilterChip(
      label: Text(label),
      selected: _selectedTemplate == value,
      onSelected: (_) {
        setState(() {
          _selectedTemplate = value;
          if (_card != null) _signatureHtml = _generateSignature(_card!, value);
        });
      },
    );
  }

  Widget _buildPreview() {
    if (_card == null) return const SizedBox.shrink();
    final name = '${_card!['first_name'] ?? ''} ${_card!['last_name'] ?? ''}'.trim();
    final title = _card!['job_title'] ?? '';
    final company = _card!['company'] ?? '';
    final color = _parseColor(_card!['card_color'] ?? '#00C9A7');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: color)),
        if (title.isNotEmpty) Text(title, style: const TextStyle(fontSize: 13, color: Colors.grey)),
        if (company.isNotEmpty) Text(company, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)),
          child: const Text('View Digital Card', style: TextStyle(color: Colors.white, fontSize: 12)),
        ),
      ],
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
