import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../app/theme.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/guest_mode_service.dart';

class MenuScreen extends StatelessWidget {
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final email = user?.email ?? 'Guest';
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Digital Atelier',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: [
          const SizedBox(height: 8),

          // ─── User Profile Header ─────────────────────────
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: colors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                // Avatar with verification badge
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Transform.rotate(
                      angle: -0.05,
                      child: Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: colors.primaryContainer,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            email.isNotEmpty ? email[0].toUpperCase() : '?',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: colors.onPrimaryContainer,
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Heritage gradient verification badge
                    Positioned(
                      bottom: -4,
                      right: -4,
                      child: Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          gradient: AppTheme.heritageGradient,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: colors.surfaceContainerLow,
                            width: 2,
                          ),
                        ),
                        child: const Icon(
                          Icons.verified,
                          size: 12,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        email.split('@').first,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                          color: colors.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        email.toUpperCase(),
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 1.5,
                          color: colors.onSurfaceVariant.withValues(alpha: 0.8),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // ─── DISCOVER Section Header ─────────────────────
          _buildSectionHeader(context, 'DISCOVER'),
          const SizedBox(height: 12),

          // Bento grid
          // Card Analytics — full width feature tile
          _buildBentoTileFull(
            context,
            icon: Icons.insights_outlined,
            title: 'Card Analytics',
            subtitle: 'Track your profile engagement.',
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
            },
          ),
          const SizedBox(height: 12),

          // Email Signature + Widget — half width tiles
          Row(
            children: [
              Expanded(
                child: _buildBentoTileHalf(
                  context,
                  icon: Icons.email_outlined,
                  title: 'Email Signature',
                  subtitle: 'Embed your digital card in every email.',
                  onTap: () => context.push('/settings/email-signature'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildBentoTileHalf(
                  context,
                  icon: Icons.widgets_outlined,
                  title: 'Widget',
                  subtitle: 'Add to your home screen.',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // NFC — full width, coming soon
          _buildComingSoonTile(
            context,
            icon: Icons.nfc,
            title: 'NFC Smart Cards',
            subtitle: 'Physical cards for the elite.',
          ),
          const SizedBox(height: 12),

          // Remaining discover items — coming soon
          _buildComingSoonTile(
            context,
            icon: Icons.image_outlined,
            title: 'Virtual Background',
            subtitle: 'Brand your video calls.',
          ),
          const SizedBox(height: 12),
          _buildComingSoonTile(
            context,
            icon: Icons.assignment_outlined,
            title: 'Lead Capture',
            subtitle: 'Collect contacts effortlessly.',
          ),
          const SizedBox(height: 12),
          _buildComingSoonTile(
            context,
            icon: Icons.integration_instructions_outlined,
            title: 'CRM Integration',
            subtitle: 'Sync with your tools.',
          ),

          const SizedBox(height: 32),

          // ─── SETTINGS Section ────────────────────────────
          _buildSectionHeader(context, 'SETTINGS'),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: colors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                _buildSettingsTile(
                  context,
                  icon: Icons.manage_accounts_outlined,
                  title: 'Manage account',
                  onTap: () => context.push('/settings/account'),
                ),
                _buildSettingsTile(
                  context,
                  icon: Icons.notifications_outlined,
                  title: 'Notifications',
                  onTap: () => context.push('/settings/notifications'),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // ─── SUPPORT Section ─────────────────────────────
          _buildSectionHeader(context, 'SUPPORT'),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: colors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                _buildSettingsTile(
                  context,
                  icon: Icons.help_outline,
                  title: 'Help',
                ),
                _buildSettingsTile(
                  context,
                  icon: Icons.feedback_outlined,
                  title: 'Feedback',
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // ─── HELP US GROW Section ────────────────────────
          _buildSectionHeader(context, 'HELP US GROW'),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: colors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                _buildSettingsTile(
                  context,
                  icon: Icons.star_outline,
                  title: 'Leave a review',
                ),
                _buildSettingsTile(
                  context,
                  icon: Icons.person_add_outlined,
                  title: 'Invite friends',
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // ─── Sign Out ────────────────────────────────────
          Material(
            color: colors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
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
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 18),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.logout, color: colors.primary, size: 20),
                    const SizedBox(width: 10),
                    Text(
                      'SIGN OUT',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.0,
                        color: colors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 32),

          // ─── Version Footer ──────────────────────────────
          Center(
            child: Column(
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: colors.primary.withValues(alpha: 0.3),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'BIOBIZ ATELIER EDITION',
                      style: theme.textTheme.labelSmall?.copyWith(
                        letterSpacing: 2.0,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: colors.primary.withValues(alpha: 0.3),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'BioBiz v1.0.0',
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: colors.onSurfaceVariant.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  // ─── Section Header ──────────────────────────────────────
  Widget _buildSectionHeader(BuildContext context, String title) {
    return Text(
      title,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.8,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }

  // ─── Bento Full-Width Tile ───────────────────────────────
  Widget _buildBentoTileFull(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
  }) {
    final colors = Theme.of(context).colorScheme;
    return Material(
      color: colors.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap ??
            () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('$title - Coming soon!')),
              );
            },
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(icon, color: colors.primary, size: 28),
                    const SizedBox(height: 12),
                    Text(
                      title,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: colors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Bento Half-Width Tile ───────────────────────────────
  Widget _buildBentoTileHalf(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
  }) {
    final colors = Theme.of(context).colorScheme;
    return Material(
      color: colors.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap ??
            () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('$title - Coming soon!')),
              );
            },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: colors.primary, size: 24),
              const SizedBox(height: 12),
              Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: colors.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: colors.onSurfaceVariant,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Coming Soon Tile ────────────────────────────────────
  Widget _buildComingSoonTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    final colors = Theme.of(context).colorScheme;
    return Opacity(
      opacity: 0.75,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: colors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(icon, color: colors.onSurfaceVariant, size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: colors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: colors.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(100),
              ),
              child: Text(
                'COMING SOON',
                style: GoogleFonts.inter(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                  color: colors.secondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Settings / Support Tile ─────────────────────────────
  Widget _buildSettingsTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    VoidCallback? onTap,
  }) {
    final colors = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap ??
          () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('$title - Coming soon!')),
            );
          },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Icon(icon, color: colors.onSurfaceVariant, size: 22),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: colors.onSurface,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right,
              size: 20,
              color: colors.onSurfaceVariant.withValues(alpha: 0.4),
            ),
          ],
        ),
      ),
    );
  }
}
