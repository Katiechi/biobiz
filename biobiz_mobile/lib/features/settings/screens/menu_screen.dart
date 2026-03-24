import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/guest_mode_service.dart';

class MenuScreen extends StatelessWidget {
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final email = user?.email ?? 'Guest';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Menu'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        children: [
          // User info header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                  child: Text(
                    email.isNotEmpty ? email[0].toUpperCase() : '?',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(email, style: Theme.of(context).textTheme.bodyMedium),
                      Text('BioBiz',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text('DISCOVER',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          ),
          _buildMenuItem(context, Icons.analytics_outlined, 'Card analytics',
              onTap: () async {
            final cards = await Supabase.instance.client
                .from('cards')
                .select('id')
                .eq('user_id', user?.id ?? '')
                .eq('is_active', true)
                .limit(1);
            if (cards.isNotEmpty && context.mounted) {
              context.push('/card/analytics', extra: cards.first['id']);
            }
          }),
          _buildMenuItem(context, Icons.email_outlined, 'Email signature',
              onTap: () => context.push('/settings/email-signature')),
          _buildMenuItem(context, Icons.widgets_outlined, 'BioBiz Widget'),
          _buildMenuItem(context, Icons.nfc, 'NFC accessory'),
          _buildMenuItem(context, Icons.image_outlined, 'Virtual background'),
          _buildMenuItem(context, Icons.assignment_outlined, 'Lead capture'),
          _buildMenuItem(context, Icons.integration_instructions_outlined,
              'CRM integration'),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text('SETTINGS',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          ),
          _buildMenuItem(context, Icons.manage_accounts_outlined,
              'Manage account',
              onTap: () => context.push('/settings/account')),
          _buildMenuItem(context, Icons.notifications_outlined, 'Notifications',
              onTap: () => context.push('/settings/notifications')),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text('SUPPORT',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          ),
          _buildMenuItem(context, Icons.help_outline, 'Help'),
          _buildMenuItem(
              context, Icons.feedback_outlined, 'Have feedback? Let us know'),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text('HELP US GROW',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          ),
          _buildMenuItem(context, Icons.star_outline, 'Leave a review'),
          _buildMenuItem(context, Icons.person_add_outlined, 'Invite friends'),

          const Divider(height: 32),

          // Sign out
          ListTile(
            leading:
                Icon(Icons.logout, color: Theme.of(context).colorScheme.error),
            title: Text('Sign out',
                style:
                    TextStyle(color: Theme.of(context).colorScheme.error)),
            onTap: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Sign out?'),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Cancel')),
                    FilledButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('Sign out')),
                  ],
                ),
              );
              if (confirmed == true && context.mounted) {
                await AuthService().signOut();
                await GuestModeService().clearGuestData();
                if (context.mounted) context.go('/');
              }
            },
          ),
          const SizedBox(height: 24),

          // App version
          Center(
            child: Text('BioBiz v1.0.0',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant)),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildMenuItem(BuildContext context, IconData icon, String title,
      {VoidCallback? onTap}) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      trailing: const Icon(Icons.chevron_right, size: 20),
      onTap: onTap ??
          () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('$title - Coming soon!')),
            );
          },
    );
  }
}
