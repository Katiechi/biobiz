import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../app/theme.dart';

class CardAnalyticsScreen extends StatefulWidget {
  final String cardId;
  const CardAnalyticsScreen({super.key, required this.cardId});

  @override
  State<CardAnalyticsScreen> createState() => _CardAnalyticsScreenState();
}

class _CardAnalyticsScreenState extends State<CardAnalyticsScreen> {
  final _supabase = Supabase.instance.client;
  Map<String, int> _analytics = {};
  List<Map<String, dynamic>> _recentShares = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    try {
      final events = await _supabase
          .from('card_events')
          .select('event_type')
          .eq('card_id', widget.cardId);

      final analytics = <String, int>{'views': 0, 'shares': 0, 'saves': 0, 'exchanges': 0};
      for (final e in events) {
        final type = e['event_type'] as String;
        switch (type) {
          case 'view': analytics['views'] = (analytics['views'] ?? 0) + 1;
          case 'share': analytics['shares'] = (analytics['shares'] ?? 0) + 1;
          case 'save_contact': analytics['saves'] = (analytics['saves'] ?? 0) + 1;
          case 'exchange': analytics['exchanges'] = (analytics['exchanges'] ?? 0) + 1;
        }
      }

      final shares = await _supabase
          .from('card_shares')
          .select()
          .eq('card_id', widget.cardId)
          .order('shared_at', ascending: false)
          .limit(20);

      if (mounted) {
        setState(() {
          _analytics = analytics;
          _recentShares = List<Map<String, dynamic>>.from(shares);
        });
      }
    } catch (e) {
      debugPrint('Error loading analytics: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Card Analytics')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadAnalytics,
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  Row(
                    children: [
                      Expanded(child: _buildStatCard('Views', _analytics['views'] ?? 0, Icons.visibility_outlined)),
                      const SizedBox(width: 12),
                      Expanded(child: _buildStatCard('Shares', _analytics['shares'] ?? 0, Icons.share_outlined)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _buildStatCard('Saves', _analytics['saves'] ?? 0, Icons.bookmark_outline)),
                      const SizedBox(width: 12),
                      Expanded(child: _buildStatCard('Exchanges', _analytics['exchanges'] ?? 0, Icons.swap_horiz)),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Container(
                    clipBehavior: Clip.hardEdge,
                    decoration: BoxDecoration(
                      gradient: AppTheme.heritageGradient,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primary.withValues(alpha: 0.2),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        // Decorative blur circle
                        Positioned(
                          right: -32,
                          top: -32,
                          child: Container(
                            width: 128,
                            height: 128,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'TOTAL ENGAGEMENT',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 1.5,
                                      color: Colors.white.withValues(alpha: 0.8),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.trending_up, color: Colors.white, size: 14),
                                        const SizedBox(width: 4),
                                        Text('Active', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  '${(_analytics['views'] ?? 0) + (_analytics['shares'] ?? 0) + (_analytics['saves'] ?? 0) + (_analytics['exchanges'] ?? 0)}',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 48,
                                    color: Colors.white,
                                    letterSpacing: -2,
                                  ),
                                ),
                              ),
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  'Total interactions with your card',
                                  style: GoogleFonts.inter(fontSize: 13, color: Colors.white.withValues(alpha: 0.7), fontWeight: FontWeight.w500),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_recentShares.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    Text('Recent Shares', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 12),
                    ..._recentShares.map((share) {
                      final method = share['share_method'] ?? 'unknown';
                      final location = share['location_name'];
                      final sharedAt = DateTime.tryParse(share['shared_at'] ?? '');
                      return ListTile(
                        leading: Icon(_methodIcon(method), color: Theme.of(context).colorScheme.primary),
                        title: Text('Shared via $method'),
                        subtitle: Text([
                          if (location != null) location,
                          if (sharedAt != null) _formatDate(sharedAt),
                        ].join(' - ')),
                      );
                    }),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildStatCard(String label, int value, IconData icon) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 20, color: colorScheme.primary),
              ),
              const SizedBox(width: 12),
              Text(
                label.toUpperCase(),
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.0,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            value.toString(),
            style: GoogleFonts.plusJakartaSans(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  IconData _methodIcon(String method) {
    switch (method) {
      case 'link': return Icons.link;
      case 'qr': return Icons.qr_code;
      case 'sms': return Icons.message;
      case 'email': return Icons.email;
      case 'whatsapp': return Icons.chat;
      case 'linkedin': return Icons.work;
      default: return Icons.share;
    }
  }

  String _formatDate(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${date.day}/${date.month}/${date.year}';
  }
}
