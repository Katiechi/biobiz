import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../app/theme.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/guest_mode_service.dart';

class ManageAccountScreen extends StatefulWidget {
  const ManageAccountScreen({super.key});

  @override
  State<ManageAccountScreen> createState() => _ManageAccountScreenState();
}

class _ManageAccountScreenState extends State<ManageAccountScreen> {
  final _authService = AuthService();
  final _supabase = Supabase.instance.client;
  Map<String, dynamic>? _profile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;
      final profile = await _supabase.from('profiles').select().eq('id', user.id).maybeSingle();
      if (mounted) setState(() => _profile = profile);
    } catch (e) {
      debugPrint('Error loading profile: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final user = _supabase.auth.currentUser;
    final email = user?.email ?? '';
    final provider = user?.appMetadata['provider'] as String?;
    final firstName = _profile?['first_name'] ?? '';
    final lastName = _profile?['last_name'] ?? '';
    final fullName = '$firstName $lastName'.trim();

    return Scaffold(
      appBar: AppBar(title: const Text('Manage Account')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              children: [
                // ── Profile Header Card (Asymmetrical Layout) ──
                Container(
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Stack(
                    children: [
                      // Heritage decorative accent
                      Positioned(
                        top: -40,
                        right: -40,
                        child: Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            gradient: AppTheme.heritageGradient,
                            shape: BoxShape.circle,
                          ),
                          foregroundDecoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.9),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(24),
                        child: Row(
                          children: [
                            // Profile avatar with rotation + verification badge
                            Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Transform.rotate(
                                  angle: -0.035,
                                  child: Container(
                                    width: 80,
                                    height: 80,
                                    decoration: BoxDecoration(
                                      color: cs.primaryContainer,
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.1),
                                          blurRadius: 8,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: Center(
                                      child: Text(
                                        firstName.isNotEmpty ? firstName[0].toUpperCase() : '?',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 32,
                                          fontWeight: FontWeight.w800,
                                          color: cs.onPrimaryContainer,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  bottom: -4,
                                  right: -4,
                                  child: Container(
                                    width: 24,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      gradient: AppTheme.heritageGradient,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: cs.surface, width: 2),
                                    ),
                                    child: const Icon(Icons.verified, size: 14, color: Colors.white),
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
                                    fullName.isNotEmpty ? fullName : 'Your Name',
                                    style: tt.headlineMedium,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    email,
                                    style: tt.bodyMedium?.copyWith(
                                      color: cs.onSurfaceVariant,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  if (provider != null) ...[
                                    const SizedBox(height: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: cs.surfaceContainerHigh,
                                        borderRadius: BorderRadius.circular(100),
                                      ),
                                      child: Text(
                                        'via ${provider.toUpperCase()}',
                                        style: tt.labelSmall?.copyWith(
                                          letterSpacing: 1.2,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // ── Profile Section ──
                _buildSectionHeader('Profile'),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    color: cs.surfaceContainer,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _editProfile,
                      borderRadius: BorderRadius.circular(16),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: cs.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(Icons.person_outline, color: cs.primary),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Edit Profile', style: tt.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
                                  Text('Update your personal information', style: tt.bodySmall),
                                ],
                              ),
                            ),
                            Icon(Icons.chevron_right, color: cs.outlineVariant),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // ── Security & Identity Section ──
                _buildSectionHeader('Security & Identity'),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    color: cs.surfaceContainer,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      // Change Email
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: _changeEmail,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: cs.surfaceContainerHighest,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(Icons.alternate_email, color: cs.primary),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Email Address', style: tt.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
                                      Text(email, style: tt.bodySmall),
                                    ],
                                  ),
                                ),
                                Icon(Icons.chevron_right, color: cs.outlineVariant),
                              ],
                            ),
                          ),
                        ),
                      ),
                      // Ghost divider
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Divider(height: 1, color: cs.outlineVariant.withValues(alpha: 0.15)),
                      ),
                      // Change Password
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: _changePassword,
                          borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: cs.surfaceContainerHighest,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(Icons.lock_open_outlined, color: cs.primary),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Security Password', style: tt.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
                                      Text('Change your account password', style: tt.bodySmall),
                                    ],
                                  ),
                                ),
                                Icon(Icons.chevron_right, color: cs.outlineVariant),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // ── Danger Zone ──
                Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 12),
                  child: Text(
                    'DANGER ZONE',
                    style: tt.labelSmall?.copyWith(
                      color: cs.error,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: cs.errorContainer.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: cs.error.withValues(alpha: 0.05)),
                  ),
                  child: Column(
                    children: [
                      // Sign Out
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: _signOut,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: cs.errorContainer.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(Icons.logout, color: cs.error),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Sign Out', style: tt.bodyLarge?.copyWith(
                                        fontWeight: FontWeight.w600, color: cs.error)),
                                      Text('Terminate current session', style: tt.bodySmall?.copyWith(
                                        color: cs.error.withValues(alpha: 0.7))),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      // Ghost divider
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Divider(height: 1, color: cs.error.withValues(alpha: 0.1)),
                      ),
                      // Delete Account
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: _deleteAccount,
                          borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: cs.errorContainer.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(Icons.delete_forever, color: cs.error),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Delete Account', style: tt.bodyLarge?.copyWith(
                                        fontWeight: FontWeight.w600, color: cs.error)),
                                      Text('Permanently remove all data and cards', style: tt.bodySmall?.copyWith(
                                        color: cs.error.withValues(alpha: 0.7))),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // ── Branding Footer ──
                Center(
                  child: Opacity(
                    opacity: 0.4,
                    child: Text(
                      'BIOBIZ DIGITAL ATELIER',
                      style: tt.labelSmall?.copyWith(letterSpacing: 2.0),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  void _editProfile() {
    final firstNameCtrl = TextEditingController(text: _profile?['first_name'] ?? '');
    final lastNameCtrl = TextEditingController(text: _profile?['last_name'] ?? '');
    final phoneCtrl = TextEditingController(text: _profile?['phone'] ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 16, right: 16, top: 24),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text('Edit Profile', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          TextField(controller: firstNameCtrl, textCapitalization: TextCapitalization.words, decoration: const InputDecoration(labelText: 'First name')),
          const SizedBox(height: 12),
          TextField(controller: lastNameCtrl, textCapitalization: TextCapitalization.words, decoration: const InputDecoration(labelText: 'Last name')),
          const SizedBox(height: 12),
          TextField(controller: phoneCtrl, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Phone')),
          const SizedBox(height: 24),
          HeritageGradientButton(
            onPressed: () async {
              try {
                final user = _supabase.auth.currentUser;
                if (user == null) return;
                await _supabase.from('profiles').update({
                  'first_name': firstNameCtrl.text.trim(),
                  'last_name': lastNameCtrl.text.trim(),
                  'phone': phoneCtrl.text.trim().isEmpty ? null : phoneCtrl.text.trim(),
                }).eq('id', user.id);
                if (mounted) { Navigator.pop(ctx); _loadProfile(); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated!'))); }
              } catch (e) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'))); }
            },
            child: Text('Save', style: GoogleFonts.plusJakartaSans(
              color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
          ),
          const SizedBox(height: 24),
        ]),
      ),
    );
  }

  void _changeEmail() {
    final emailCtrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 16, right: 16, top: 24),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text('Change Email', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text('A confirmation link will be sent to your new email.', style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 16),
          TextField(controller: emailCtrl, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'New email address')),
          const SizedBox(height: 24),
          HeritageGradientButton(
            onPressed: () async {
              if (emailCtrl.text.trim().isEmpty) return;
              try {
                await _authService.changeEmail(newEmail: emailCtrl.text.trim());
                if (mounted) { Navigator.pop(ctx); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Confirmation email sent!'))); }
              } catch (e) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'))); }
            },
            child: Text('Send confirmation', style: GoogleFonts.plusJakartaSans(
              color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
          ),
          const SizedBox(height: 24),
        ]),
      ),
    );
  }

  void _changePassword() {
    final passwordCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 16, right: 16, top: 24),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text('Change Password', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          TextField(controller: passwordCtrl, obscureText: true, decoration: const InputDecoration(labelText: 'New password')),
          const SizedBox(height: 12),
          TextField(controller: confirmCtrl, obscureText: true, decoration: const InputDecoration(labelText: 'Confirm password')),
          const SizedBox(height: 24),
          HeritageGradientButton(
            onPressed: () async {
              if (passwordCtrl.text != confirmCtrl.text) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Passwords do not match')));
                return;
              }
              if (passwordCtrl.text.length < 6) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password must be at least 6 characters')));
                return;
              }
              try {
                await _authService.changePassword(newPassword: passwordCtrl.text);
                if (mounted) { Navigator.pop(ctx); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password updated!'))); }
              } catch (e) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'))); }
            },
            child: Text('Update password', style: GoogleFonts.plusJakartaSans(
              color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
          ),
          const SizedBox(height: 24),
        ]),
      ),
    );
  }

  Future<void> _signOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign out?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Sign out')),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await _authService.signOut();
      await GuestModeService().clearGuestData();
      if (mounted) context.go('/');
    }
  }

  Future<void> _deleteAccount() async {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete account?'),
        content: const Text('This will permanently delete your account, all cards, contacts, and recordings. This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _authService.signOut();
              await GuestModeService().clearGuestData();
              if (mounted) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Account deletion requested'))); context.go('/'); }
            },
            style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
            child: const Text('Delete permanently'),
          ),
        ],
      ),
    );
  }
}
