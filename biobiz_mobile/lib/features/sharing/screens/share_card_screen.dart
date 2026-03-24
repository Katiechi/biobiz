import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Story 5.1-5.5: Full share screen with QR and sharing channels
class ShareCardScreen extends ConsumerStatefulWidget {
  final String? cardId;

  const ShareCardScreen({super.key, this.cardId});

  @override
  ConsumerState<ShareCardScreen> createState() => _ShareCardScreenState();
}

class _ShareCardScreenState extends ConsumerState<ShareCardScreen> {
  final _supabase = Supabase.instance.client;
  Map<String, dynamic>? _card;
  String _cardUrl = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCard();
  }

  Future<void> _loadCard() async {
    try {
      final cardId = widget.cardId;
      if (cardId == null) {
        // Load active card
        final user = _supabase.auth.currentUser;
        if (user != null) {
          _card = await _supabase
              .from('cards')
              .select()
              .eq('user_id', user.id)
              .eq('is_active', true)
              .maybeSingle();
        }
      } else {
        _card = await _supabase.from('cards').select().eq('id', cardId).single();
      }

      if (_card != null) {
        _cardUrl = 'https://biobiz.app/card/${_card!['slug']}';
      }
    } catch (e) {
      debugPrint('Error loading card: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Share Card'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _card == null
              ? const Center(child: Text('No card found'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      // QR Code (Story 5.1)
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
                              data: _cardUrl,
                              version: QrVersions.auto,
                              size: 200,
                              backgroundColor: Colors.white,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Point your camera at the QR code\nto receive the card',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.grey.shade600,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Share channels
                      _buildShareOption(
                        context,
                        Icons.link,
                        'Copy link',
                        () {
                          Clipboard.setData(ClipboardData(text: _cardUrl));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Link copied!')),
                          );
                          _trackShare('link');
                        },
                      ),
                      _buildShareOption(
                        context,
                        Icons.message_outlined,
                        'Text your card',
                        () async {
                          final url = Uri.parse('sms:?body=Check out my digital business card: $_cardUrl');
                          if (await canLaunchUrl(url)) launchUrl(url);
                          _trackShare('sms');
                        },
                      ),
                      _buildShareOption(
                        context,
                        Icons.email_outlined,
                        'Email your card',
                        () async {
                          final url = Uri.parse('mailto:?subject=My Digital Business Card&body=Check out my card: $_cardUrl');
                          if (await canLaunchUrl(url)) launchUrl(url);
                          _trackShare('email');
                        },
                      ),
                      _buildShareOption(
                        context,
                        Icons.chat,
                        'Send via WhatsApp',
                        () async {
                          final url = Uri.parse('https://wa.me/?text=Check out my digital business card: $_cardUrl');
                          if (await canLaunchUrl(url)) launchUrl(url, mode: LaunchMode.externalApplication);
                          _trackShare('whatsapp');
                        },
                      ),
                      _buildShareOption(
                        context,
                        Icons.work_outline,
                        'Send via LinkedIn',
                        () async {
                          final url = Uri.parse('https://www.linkedin.com/messaging/compose?body=Check out my card: $_cardUrl');
                          if (await canLaunchUrl(url)) launchUrl(url, mode: LaunchMode.externalApplication);
                          _trackShare('linkedin');
                        },
                      ),
                      _buildShareOption(
                        context,
                        Icons.share_outlined,
                        'Send another way',
                        () {
                          Share.share('Check out my digital business card: $_cardUrl');
                          _trackShare('other');
                        },
                      ),

                      const SizedBox(height: 24),
                      const Divider(),
                      const SizedBox(height: 16),

                      // QR Image actions
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          TextButton.icon(
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: _cardUrl));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Card link copied!')),
                              );
                            },
                            icon: const Icon(Icons.copy),
                            label: const Text('Copy Link'),
                          ),
                          TextButton.icon(
                            onPressed: () {
                              Share.share('Check out my digital business card: $_cardUrl');
                            },
                            icon: const Icon(Icons.share),
                            label: const Text('Share'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildShareOption(
    BuildContext context,
    IconData icon,
    String label,
    VoidCallback onTap,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(double.infinity, 48),
        ),
      ),
    );
  }

  Future<void> _trackShare(String method) async {
    try {
      if (_card != null) {
        await _supabase.from('card_events').insert({
          'card_id': _card!['id'],
          'event_type': 'share',
          'metadata': {'method': method},
        });
      }
    } catch (_) {}
  }
}
