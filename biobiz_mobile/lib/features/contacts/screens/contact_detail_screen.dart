import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../card_view/widgets/card_renderer.dart';

/// Story 7.2: Contact detail view with notes, editing, and meeting history
class ContactDetailScreen extends StatefulWidget {
  final Map<String, dynamic> contact;

  const ContactDetailScreen({super.key, required this.contact});

  @override
  State<ContactDetailScreen> createState() => _ContactDetailScreenState();
}

class _ContactDetailScreenState extends State<ContactDetailScreen> {
  final _supabase = Supabase.instance.client;
  final _notesController = TextEditingController();
  late Map<String, dynamic> _contact;
  List<Map<String, dynamic>> _notes = [];
  List<Map<String, dynamic>> _socialLinks = [];
  // Source card data for full card display
  Map<String, dynamic>? _sourceCard;
  List<dynamic> _sourceCardContactFields = [];
  List<dynamic> _sourceCardSocialLinks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _contact = Map<String, dynamic>.from(widget.contact);
    _loadDetails();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadDetails() async {
    try {
      // Reload contact data
      final freshContact = await _supabase
          .from('contacts')
          .select()
          .eq('id', _contact['id'])
          .maybeSingle();
      if (freshContact != null) _contact = freshContact;

      final notes = await _supabase
          .from('contact_notes')
          .select()
          .eq('contact_id', _contact['id'])
          .order('created_at', ascending: false);

      final socialLinks = await _supabase
          .from('contact_social_links')
          .select()
          .eq('contact_id', _contact['id']);

      // If this contact came from a scan/exchange, load the source card
      final sourceCardId = _contact['source_card_id'] as String?;
      Map<String, dynamic>? sourceCard;
      List<dynamic> cardFields = [];
      List<dynamic> cardSocialLinks = [];

      if (sourceCardId != null) {
        try {
          sourceCard = await _supabase
              .from('cards')
              .select('*, card_contact_fields(*), card_social_links(*)')
              .eq('id', sourceCardId)
              .eq('is_active', true)
              .maybeSingle();

          if (sourceCard != null) {
            cardFields = sourceCard['card_contact_fields'] as List<dynamic>? ?? [];
            cardSocialLinks = sourceCard['card_social_links'] as List<dynamic>? ?? [];
          }
        } catch (_) {
          // Card may have been deleted or deactivated
        }
      }

      if (mounted) {
        setState(() {
          _notes = List<Map<String, dynamic>>.from(notes);
          _socialLinks = List<Map<String, dynamic>>.from(socialLinks);
          _sourceCard = sourceCard;
          _sourceCardContactFields = cardFields;
          _sourceCardSocialLinks = cardSocialLinks;
        });
      }
    } catch (e) {
      debugPrint('Error loading details: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _addNote() async {
    if (_notesController.text.trim().isEmpty) return;

    try {
      await _supabase.from('contact_notes').insert({
        'contact_id': _contact['id'],
        'content': _notesController.text.trim(),
      });
      _notesController.clear();
      _loadDetails();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _deleteNote(String noteId) async {
    try {
      await _supabase.from('contact_notes').delete().eq('id', noteId);
      _loadDetails();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = '${_contact['first_name'] ?? ''} ${_contact['last_name'] ?? ''}'.trim();
    final email = _contact['email'] as String?;
    final phone = _contact['phone'] as String?;
    final company = _contact['company'] as String?;
    final jobTitle = _contact['job_title'] as String?;
    final website = _contact['website'] as String?;
    final source = _contact['source'] as String? ?? 'manual';
    final metAt = _contact['met_at_location_name'] as String?;
    final metDate = _contact['met_at'] as String?;
    final avatarUrl = _contact['avatar_url'] as String?;

    return Scaffold(
      appBar: AppBar(
        title: Text(name.isNotEmpty ? name : 'Contact'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => _editContact(),
          ),
          PopupMenuButton(
            itemBuilder: (ctx) => [
              PopupMenuItem(
                child: const ListTile(
                  leading: Icon(Icons.share),
                  title: Text('Export vCard'),
                  contentPadding: EdgeInsets.zero,
                ),
                onTap: () => _exportVCard(),
              ),
              PopupMenuItem(
                child: ListTile(
                  leading: Icon(Icons.delete, color: Theme.of(context).colorScheme.error),
                  title: Text('Delete', style: TextStyle(color: Theme.of(context).colorScheme.error)),
                  contentPadding: EdgeInsets.zero,
                ),
                onTap: () => Future.delayed(Duration.zero, _deleteContact),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Full card display if source card exists
                  if (_sourceCard != null) ...[
                    _buildSourceCardView(),
                    const SizedBox(height: 24),
                  ] else ...[
                    // Fallback header for manual contacts
                    _buildBasicHeader(name, jobTitle, company, avatarUrl),
                    const SizedBox(height: 24),
                  ],

                  // Quick actions
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (phone != null && phone.isNotEmpty)
                        _buildQuickAction(Icons.phone, 'Call', () {
                          launchUrl(Uri.parse('tel:$phone'));
                        }),
                      if (email != null && email.isNotEmpty)
                        _buildQuickAction(Icons.email, 'Email', () {
                          launchUrl(Uri.parse('mailto:$email'));
                        }),
                      if (phone != null && phone.isNotEmpty)
                        _buildQuickAction(Icons.message, 'Text', () {
                          launchUrl(Uri.parse('sms:$phone'));
                        }),
                      if (website != null && website.isNotEmpty)
                        _buildQuickAction(Icons.language, 'Web', () {
                          final url = website.startsWith('http') ? website : 'https://$website';
                          launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
                        }),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Contact info tiles
                  if (email != null && email.isNotEmpty)
                    _buildInfoTile(Icons.email_outlined, email, 'Email', () {
                      launchUrl(Uri.parse('mailto:$email'));
                    }),
                  if (phone != null && phone.isNotEmpty)
                    _buildInfoTile(Icons.phone_outlined, phone, 'Phone', () {
                      launchUrl(Uri.parse('tel:$phone'));
                    }),
                  if (website != null && website.isNotEmpty)
                    _buildInfoTile(Icons.language, website, 'Website', () {
                      final url = website.startsWith('http') ? website : 'https://$website';
                      launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
                    }),

                  // Social links
                  if (_socialLinks.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text('Social', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    ..._socialLinks.map((link) => _buildInfoTile(
                          _getSocialIcon(link['platform']),
                          link['url'] ?? '',
                          _platformDisplayName(link['platform'] ?? ''),
                          () {
                            final url = link['url'] as String;
                            if (url.startsWith('http')) {
                              launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
                            }
                          },
                        )),
                  ],

                  // Source info
                  const SizedBox(height: 16),
                  _buildSourceInfo(source, metAt, metDate),

                  // Notes section
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Notes', style: Theme.of(context).textTheme.titleMedium),
                      Text('${_notes.length}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant)),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Add note
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _notesController,
                          decoration: const InputDecoration(
                            hintText: 'Add a note...',
                            isDense: true,
                          ),
                          maxLines: null,
                          textInputAction: TextInputAction.send,
                          onSubmitted: (_) => _addNote(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filled(
                        onPressed: _addNote,
                        icon: const Icon(Icons.send, size: 18),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Notes list
                  if (_notes.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Center(
                        child: Text(
                          'No notes yet. Add one above.',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant),
                        ),
                      ),
                    )
                  else
                    ..._notes.map((note) => Dismissible(
                          key: ValueKey(note['id']),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 16),
                            color: Theme.of(context).colorScheme.error,
                            child: const Icon(Icons.delete, color: Colors.white),
                          ),
                          onDismissed: (_) => _deleteNote(note['id']),
                          child: Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(note['content'] ?? ''),
                                  const SizedBox(height: 4),
                                  Text(
                                    _formatDate(note['created_at']),
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          color: Theme.of(context).colorScheme.onSurfaceVariant),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )),
                ],
              ),
            ),
    );
  }

  /// Renders the full source card using CardRenderer (same as My Card screen)
  Widget _buildSourceCardView() {
    final cardData = Map<String, dynamic>.from(_sourceCard!);
    cardData['contact_fields'] = _sourceCardContactFields;
    cardData['social_links'] = _sourceCardSocialLinks;

    return CardRenderer(cardData: cardData);
  }

  /// Fallback header for contacts without a source card (manual contacts)
  Widget _buildBasicHeader(String name, String? jobTitle, String? company, String? avatarUrl) {
    return Center(
      child: Column(
        children: [
          CircleAvatar(
            radius: 48,
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
            child: avatarUrl == null
                ? Text(
                    name.isNotEmpty ? name[0].toUpperCase() : '?',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  )
                : null,
          ),
          const SizedBox(height: 16),
          Text(name,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold)),
          if (jobTitle != null && jobTitle.isNotEmpty)
            Text(jobTitle, style: Theme.of(context).textTheme.bodyLarge),
          if (company != null && company.isNotEmpty)
            Text(company,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }

  Widget _buildQuickAction(IconData icon, String label, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Theme.of(context).colorScheme.primary),
            ),
            const SizedBox(height: 4),
            Text(label, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTile(IconData icon, String value, String label, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
        title: Text(value),
        subtitle: Text(label),
        trailing: IconButton(
          icon: const Icon(Icons.copy, size: 18),
          onPressed: () {
            Clipboard.setData(ClipboardData(text: value));
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('$label copied!')),
            );
          },
        ),
        onTap: onTap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
        ),
      ),
    );
  }

  Widget _buildSourceInfo(String source, String? location, String? date) {
    String sourceText;
    IconData sourceIcon;
    switch (source) {
      case 'scan': sourceText = 'Scanned'; sourceIcon = Icons.qr_code_scanner;
      case 'exchange': sourceText = 'Card exchange'; sourceIcon = Icons.swap_horiz;
      case 'import': sourceText = 'Imported'; sourceIcon = Icons.upload;
      default: sourceText = 'Added manually'; sourceIcon = Icons.person_add;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(sourceIcon, size: 16, color: Theme.of(context).colorScheme.onSurfaceVariant),
            const SizedBox(width: 8),
            Text(sourceText, style: Theme.of(context).textTheme.bodySmall),
          ]),
          if (location != null) ...[
            const SizedBox(height: 4),
            Row(children: [
              Icon(Icons.location_on, size: 16, color: Theme.of(context).colorScheme.onSurfaceVariant),
              const SizedBox(width: 8),
              Text('Met at: $location', style: Theme.of(context).textTheme.bodySmall),
            ]),
          ],
          if (date != null) ...[
            const SizedBox(height: 4),
            Row(children: [
              Icon(Icons.calendar_today, size: 16, color: Theme.of(context).colorScheme.onSurfaceVariant),
              const SizedBox(width: 8),
              Text('Met on: ${_formatDate(date)}', style: Theme.of(context).textTheme.bodySmall),
            ]),
          ],
        ],
      ),
    );
  }

  void _editContact() {
    final firstNameCtrl = TextEditingController(text: _contact['first_name'] ?? '');
    final lastNameCtrl = TextEditingController(text: _contact['last_name'] ?? '');
    final emailCtrl = TextEditingController(text: _contact['email'] ?? '');
    final phoneCtrl = TextEditingController(text: _contact['phone'] ?? '');
    final companyCtrl = TextEditingController(text: _contact['company'] ?? '');
    final titleCtrl = TextEditingController(text: _contact['job_title'] ?? '');
    final websiteCtrl = TextEditingController(text: _contact['website'] ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
          left: 16, right: 16, top: 24,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Edit Contact', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              Row(children: [
                Expanded(child: TextField(controller: firstNameCtrl, decoration: const InputDecoration(labelText: 'First name'))),
                const SizedBox(width: 12),
                Expanded(child: TextField(controller: lastNameCtrl, decoration: const InputDecoration(labelText: 'Last name'))),
              ]),
              const SizedBox(height: 12),
              TextField(controller: emailCtrl, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'Email')),
              const SizedBox(height: 12),
              TextField(controller: phoneCtrl, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Phone')),
              const SizedBox(height: 12),
              TextField(controller: companyCtrl, decoration: const InputDecoration(labelText: 'Company')),
              const SizedBox(height: 12),
              TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Job title')),
              const SizedBox(height: 12),
              TextField(controller: websiteCtrl, keyboardType: TextInputType.url, decoration: const InputDecoration(labelText: 'Website')),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () async {
                  try {
                    await _supabase.from('contacts').update({
                      'first_name': firstNameCtrl.text.trim().isEmpty ? null : firstNameCtrl.text.trim(),
                      'last_name': lastNameCtrl.text.trim().isEmpty ? null : lastNameCtrl.text.trim(),
                      'email': emailCtrl.text.trim().isEmpty ? null : emailCtrl.text.trim(),
                      'phone': phoneCtrl.text.trim().isEmpty ? null : phoneCtrl.text.trim(),
                      'company': companyCtrl.text.trim().isEmpty ? null : companyCtrl.text.trim(),
                      'job_title': titleCtrl.text.trim().isEmpty ? null : titleCtrl.text.trim(),
                      'website': websiteCtrl.text.trim().isEmpty ? null : websiteCtrl.text.trim(),
                    }).eq('id', _contact['id']);

                    if (mounted) {
                      Navigator.pop(ctx);
                      _loadDetails();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Contact updated!')),
                      );
                    }
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: ${e.toString()}')),
                    );
                  }
                },
                child: const Text('Save'),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  void _exportVCard() {
    final buffer = StringBuffer();
    buffer.writeln('BEGIN:VCARD');
    buffer.writeln('VERSION:3.0');
    final firstName = _contact['first_name'] ?? '';
    final lastName = _contact['last_name'] ?? '';
    buffer.writeln('N:$lastName;$firstName;;;');
    buffer.writeln('FN:$firstName${lastName.isNotEmpty ? " $lastName" : ""}'.trim());
    if (_contact['company'] != null) buffer.writeln('ORG:${_contact['company']}');
    if (_contact['job_title'] != null) buffer.writeln('TITLE:${_contact['job_title']}');
    if (_contact['email'] != null) buffer.writeln('EMAIL:${_contact['email']}');
    if (_contact['phone'] != null) buffer.writeln('TEL:${_contact['phone']}');
    if (_contact['website'] != null) buffer.writeln('URL:${_contact['website']}');
    for (final link in _socialLinks) {
      if (link['url'] != null) buffer.writeln('URL;TYPE=${link['platform'] ?? 'other'}:${link['url']}');
    }
    buffer.writeln('END:VCARD');

    Clipboard.setData(ClipboardData(text: buffer.toString()));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('vCard copied to clipboard!')),
    );
  }

  void _deleteContact() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete contact?'),
        content: const Text('This will permanently delete this contact and all notes.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              await _supabase.from('contacts').delete().eq('id', _contact['id']);
              if (mounted) {
                Navigator.pop(ctx);
                Navigator.pop(context);
              }
            },
            style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final diff = now.difference(date);
      if (diff.inDays == 0) return 'Today';
      if (diff.inDays == 1) return 'Yesterday';
      if (diff.inDays < 7) return '${diff.inDays}d ago';
      return '${date.day}/${date.month}/${date.year}';
    } catch (_) {
      return dateStr;
    }
  }

  IconData _getSocialIcon(String? platform) {
    switch (platform) {
      case 'linkedin': return Icons.work_outline;
      case 'instagram': return Icons.photo_camera_outlined;
      case 'x': return Icons.close;
      case 'facebook': return Icons.facebook;
      case 'whatsapp': return Icons.chat;
      case 'telegram': return Icons.send_outlined;
      case 'tiktok': return Icons.music_note;
      case 'youtube': return Icons.play_circle_outline;
      case 'github': return Icons.code;
      default: return Icons.link;
    }
  }

  String _platformDisplayName(String platform) {
    switch (platform) {
      case 'linkedin': return 'LinkedIn';
      case 'instagram': return 'Instagram';
      case 'x': return 'X (Twitter)';
      case 'facebook': return 'Facebook';
      case 'whatsapp': return 'WhatsApp';
      case 'telegram': return 'Telegram';
      case 'tiktok': return 'TikTok';
      case 'youtube': return 'YouTube';
      case 'github': return 'GitHub';
      default: return platform;
    }
  }
}
