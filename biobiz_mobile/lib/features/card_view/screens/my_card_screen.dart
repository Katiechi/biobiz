import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:biobiz_mobile/app/theme.dart';
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
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.menu, color: colorScheme.onSurface),
          onPressed: () => context.push('/menu'),
        ),
        title: Text(
          'My Card',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w700,
            fontSize: 20,
            color: colorScheme.onSurface,
          ),
        ),
        actions: [
          if (_activeCard != null)
            IconButton(
              icon: Icon(Icons.analytics_outlined, color: colorScheme.onSurfaceVariant),
              onPressed: () {
                context.push('/card/analytics', extra: _activeCard!['id']);
              },
            ),
          IconButton(
            icon: Icon(Icons.edit_outlined, color: colorScheme.onSurfaceVariant),
            onPressed: _openEditor,
          ),
        ],
      ),
      floatingActionButton: _activeCard != null
          ? GoldFab(
              icon: Icons.qr_code_2,
              onPressed: () {
                final cardId = _activeCard?['id'];
                if (cardId != null) {
                  context.push('/card/share', extra: cardId);
                }
              },
            )
          : null,
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: colorScheme.primary,
              ),
            )
          : _activeCard == null
              ? _buildEmptyState()
              : _buildCardView(),
    );
  }

  Widget _buildEmptyState() {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Large icon in a surfaceContainer circle
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.badge_outlined,
                size: 56,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: 28),
            Text(
              'No card yet',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Create your first digital business card',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 32),
            HeritageGradientButton(
              onPressed: _openEditor,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.add, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Create Card',
                    style: GoogleFonts.plusJakartaSans(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
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

  Widget _buildCardView() {
    final cardData = Map<String, dynamic>.from(_activeCard!);
    cardData['contact_fields'] = _contactFields;
    cardData['social_links'] = _socialLinks;

    final totalInteractions = (_analytics['views'] ?? 0) +
        (_analytics['shares'] ?? 0) +
        (_analytics['saves'] ?? 0);

    final colorScheme = Theme.of(context).colorScheme;

    return RefreshIndicator(
      onRefresh: _loadActiveCard,
      color: colorScheme.primary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          children: [
            // Analytics summary bar — tonal depth, no borders
            if (totalInteractions > 0)
              Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: GestureDetector(
                  onTap: () => context.push('/card/analytics',
                      extra: _activeCard!['id']),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainer,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildMiniStat('VIEWS', _analytics['views'] ?? 0),
                        ),
                        Expanded(
                          child: _buildMiniStat('SHARES', _analytics['shares'] ?? 0),
                        ),
                        Expanded(
                          child: _buildMiniStat('SAVES', _analytics['saves'] ?? 0),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            const SizedBox(height: 4),
            // Card renderer
            GestureDetector(
              onTap: _openEditor,
              child: CardRenderer(cardData: cardData),
            ),
            const SizedBox(height: 28),

            // Action buttons — stacked layout matching reference
            Column(
              children: [
                // Share button with heritage gradient
                HeritageGradientButton(
                  onPressed: () {
                    final cardId = _activeCard?['id'];
                    if (cardId != null) {
                      context.push('/card/share', extra: cardId);
                    }
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.share, color: Colors.white, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Share Card',
                        style: GoogleFonts.plusJakartaSans(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                // Edit button — tonal surface, no border
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: OutlinedButton.icon(
                    onPressed: _openEditor,
                    style: OutlinedButton.styleFrom(
                      backgroundColor: colorScheme.surfaceContainerHigh,
                      side: BorderSide.none,
                    ),
                    icon: Icon(Icons.edit, color: colorScheme.primary, size: 20),
                    label: Text(
                      'Edit Details',
                      style: GoogleFonts.plusJakartaSans(
                        color: colorScheme.primary,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
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
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        // Label — uppercase, small, tracked (labelSmall style)
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        // Value — headline style
        Text(
          value.toString(),
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: colorScheme.primary,
          ),
        ),
      ],
    );
  }
}
