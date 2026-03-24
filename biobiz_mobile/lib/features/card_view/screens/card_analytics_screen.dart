import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
                padding: const EdgeInsets.all(16),
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
                  Card(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.trending_up, color: Theme.of(context).colorScheme.primary),
                          const SizedBox(width: 8),
                          Text(
                            'Total: ${(_analytics['views'] ?? 0) + (_analytics['shares'] ?? 0) + (_analytics['saves'] ?? 0) + (_analytics['exchanges'] ?? 0)}',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.onPrimaryContainer),
                          ),
                        ],
                      ),
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
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, size: 28, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 8),
            Text(value.toString(), style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
            Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
          ],
        ),
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
