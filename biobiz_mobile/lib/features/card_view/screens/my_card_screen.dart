import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../widgets/card_renderer.dart';

/// Story 4.1: Main card view screen with analytics summary
class MyCardScreen extends ConsumerStatefulWidget {
  const MyCardScreen({super.key});

  @override
  ConsumerState<MyCardScreen> createState() => _MyCardScreenState();
}

class _MyCardScreenState extends ConsumerState<MyCardScreen> {
  final _supabase = Supabase.instance.client;
  Map<String, dynamic>? _activeCard;
  List<dynamic> _contactFields = [];
  List<dynamic> _socialLinks = [];
  Map<String, int> _analytics = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadActiveCard();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadActiveCard();
  }

  Future<void> _loadActiveCard() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        setState(() => _isLoading = false);
        return;
      }

      final cards = await _supabase
          .from('cards')
          .select()
          .eq('user_id', user.id)
          .eq('is_active', true)
          .order('updated_at', ascending: false)
          .limit(1);
      final card = cards.isNotEmpty ? cards.first : null;

      if (card != null) {
        final fields = await _supabase
            .from('card_contact_fields')
            .select()
            .eq('card_id', card['id'])
            .order('sort_order');

        final links = await _supabase
            .from('card_social_links')
            .select()
            .eq('card_id', card['id'])
            .order('sort_order');

        // Load analytics
        final events = await _supabase
            .from('card_events')
            .select('event_type')
            .eq('card_id', card['id']);

        final analytics = <String, int>{
          'views': 0, 'shares': 0, 'saves': 0,
        };
        for (final e in events) {
          final type = e['event_type'] as String;
          switch (type) {
            case 'view': analytics['views'] = (analytics['views'] ?? 0) + 1;
            case 'share': analytics['shares'] = (analytics['shares'] ?? 0) + 1;
            case 'save_contact': analytics['saves'] = (analytics['saves'] ?? 0) + 1;
          }
        }

        if (mounted) {
          setState(() {
            _activeCard = card;
            _contactFields = fields;
            _socialLinks = links;
            _analytics = analytics;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _activeCard = null;
            _contactFields = [];
            _socialLinks = [];
            _analytics = {};
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading card: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _openEditor() {
    final cardId = _activeCard?['id'] as String?;
    context.push('/card/edit', extra: cardId).then((_) => _loadActiveCard());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => context.push('/menu'),
        ),
        title: const Text('My Card'),
        actions: [
          if (_activeCard != null)
            IconButton(
              icon: const Icon(Icons.analytics_outlined),
              onPressed: () {
                context.push('/card/analytics', extra: _activeCard!['id']);
              },
            ),
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: _openEditor,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _activeCard == null
              ? _buildEmptyState()
              : _buildCardView(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.badge_outlined, size: 80,
                color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 24),
            Text('No card yet',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Create your first digital business card',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant)),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _openEditor,
              icon: const Icon(Icons.add),
              label: const Text('Create card'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardView() {
    final cardData = Map<String, dynamic>.from(_activeCard!);
    cardData['contact_fields'] = _contactFields;
    cardData['social_links'] = _socialLinks;

    final totalInteractions = (_analytics['views'] ?? 0) +
        (_analytics['shares'] ?? 0) +
        (_analytics['saves'] ?? 0);

    return RefreshIndicator(
      onRefresh: _loadActiveCard,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Analytics summary bar
            if (totalInteractions > 0)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: InkWell(
                  onTap: () => context.push('/card/analytics',
                      extra: _activeCard!['id']),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildMiniStat('Views', _analytics['views'] ?? 0),
                      _buildStatDivider(),
                      _buildMiniStat('Shares', _analytics['shares'] ?? 0),
                      _buildStatDivider(),
                      _buildMiniStat('Saves', _analytics['saves'] ?? 0),
                    ],
                  ),
                ),
              ),

            GestureDetector(
              onTap: _openEditor,
              child: CardRenderer(cardData: cardData),
            ),
            const SizedBox(height: 24),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () {
                      final cardId = _activeCard?['id'];
                      if (cardId != null) {
                        context.push('/card/share', extra: cardId);
                      }
                    },
                    icon: const Icon(Icons.share),
                    label: const Text('Share'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _openEditor,
                    icon: const Icon(Icons.edit),
                    label: const Text('Edit'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniStat(String label, int value) {
    return Column(
      children: [
        Text(value.toString(),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onPrimaryContainer)),
        Text(label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onPrimaryContainer)),
      ],
    );
  }

  Widget _buildStatDivider() {
    return Container(
      width: 1, height: 28,
      color: Theme.of(context).colorScheme.onPrimaryContainer.withValues(alpha: 0.3),
    );
  }
}
