import 'package:flutter/material.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _cardViewed = true;
  bool _contactSaved = true;
  bool _newExchange = true;
  bool _recordingSummary = true;
  bool _weeklyDigest = false;
  bool _marketingUpdates = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        children: [
          // ── Page Header ──
          Text('Notifications', style: tt.displaySmall),
          const SizedBox(height: 4),
          Text(
            'Manage how you receive alerts and curated updates.',
            style: tt.bodyMedium?.copyWith(
              color: cs.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 32),

          // ── Activity Alerts Section ──
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: cs.primaryContainer.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(100),
            ),
            child: Text(
              'ACTIVITY ALERTS',
              style: tt.labelSmall?.copyWith(
                color: cs.primary,
                letterSpacing: 1.5,
              ),
            ),
          ).wrapAlign(Alignment.centerLeft),
          const SizedBox(height: 16),

          _buildActivityToggle(
            icon: Icons.visibility_outlined,
            title: 'Card viewed',
            subtitle: 'Notify when someone opens your card',
            value: _cardViewed,
            onChanged: (v) => setState(() => _cardViewed = v),
          ),
          const SizedBox(height: 8),
          _buildActivityToggle(
            icon: Icons.person_add_outlined,
            title: 'Contact saved',
            subtitle: 'When your info is added to a phonebook',
            value: _contactSaved,
            onChanged: (v) => setState(() => _contactSaved = v),
          ),
          const SizedBox(height: 8),
          _buildActivityToggle(
            icon: Icons.sync_alt,
            title: 'Card exchange',
            subtitle: 'Instant alerts for two-way card swaps',
            value: _newExchange,
            onChanged: (v) => setState(() => _newExchange = v),
          ),
          const SizedBox(height: 8),
          _buildActivityToggle(
            icon: Icons.mic_outlined,
            title: 'Recording summary',
            subtitle: 'AI-generated briefs from shared recordings',
            value: _recordingSummary,
            onChanged: (v) => setState(() => _recordingSummary = v),
          ),
          const SizedBox(height: 32),

          // ── Updates Section ──
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: cs.secondaryContainer.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(100),
            ),
            child: Text(
              'UPDATES',
              style: tt.labelSmall?.copyWith(
                color: cs.secondary,
                letterSpacing: 1.5,
              ),
            ),
          ).wrapAlign(Alignment.centerLeft),
          const SizedBox(height: 16),

          // Update cards in grid
          Row(
            children: [
              Expanded(child: _buildUpdateCard(
                icon: Icons.calendar_month,
                iconColor: cs.secondary,
                title: 'Weekly digest',
                subtitle: 'A curated summary of your networking performance every Monday.',
                value: _weeklyDigest,
                onChanged: (v) => setState(() => _weeklyDigest = v),
                accentColor: cs.secondaryContainer,
              )),
              const SizedBox(width: 12),
              Expanded(child: _buildUpdateCard(
                icon: Icons.new_releases_outlined,
                iconColor: cs.primary,
                title: 'Product updates',
                subtitle: 'Be the first to know about new features and design drops.',
                value: _marketingUpdates,
                onChanged: (v) => setState(() => _marketingUpdates = v),
                accentColor: cs.primary,
              )),
            ],
          ),
          const SizedBox(height: 32),

          // ── Focus Mode Card ──
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: cs.surfaceContainer,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Text('Need a break?', style: tt.titleMedium),
                const SizedBox(height: 8),
                Text(
                  'Pause all notifications for a set period to focus on your work.',
                  textAlign: TextAlign.center,
                  style: tt.bodySmall,
                ),
                const SizedBox(height: 20),
                OutlinedButton(
                  onPressed: () {
                    // Focus mode - placeholder
                  },
                  child: const Text('Enable Focus Mode'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildActivityToggle({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: cs.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(icon, color: cs.primary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: tt.titleSmall),
                const SizedBox(height: 2),
                Text(subtitle, style: tt.bodySmall),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }

  Widget _buildUpdateCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required Color accentColor,
  }) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border(
          bottom: BorderSide(color: accentColor, width: 3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: iconColor, size: 28),
              Transform.scale(
                scale: 0.85,
                child: Switch(value: value, onChanged: onChanged),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(title, style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(subtitle, style: tt.bodySmall?.copyWith(height: 1.4)),
        ],
      ),
    );
  }
}

/// Extension to wrap a widget with Align
extension _WidgetAlignExtension on Widget {
  Widget wrapAlign(Alignment alignment) {
    return Align(alignment: alignment, child: this);
  }
}
