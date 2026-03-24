import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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
    final user = _supabase.auth.currentUser;
    final email = user?.email ?? '';
    final provider = user?.appMetadata['provider'] as String?;
    final firstName = _profile?['first_name'] ?? '';
    final lastName = _profile?['last_name'] ?? '';

    return Scaffold(
      appBar: AppBar(title: const Text('Manage Account')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Profile header
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(children: [
                      CircleAvatar(
                        radius: 32,
                        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                        child: Text(
                          firstName.isNotEmpty ? firstName[0].toUpperCase() : '?',
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onPrimaryContainer),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('$firstName $lastName'.trim(),
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                          Text(email, style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant)),
                          if (provider != null)
                            Chip(label: Text('via ${provider.toUpperCase()}'), labelStyle: const TextStyle(fontSize: 10),
                                padding: EdgeInsets.zero, materialTapTargetSize: MaterialTapTargetSize.shrinkWrap),
                        ],
                      )),
                    ]),
                  ),
                ),
                const SizedBox(height: 16),

                Card(child: Column(children: [
                  ListTile(
                    leading: const Icon(Icons.person_outline),
                    title: const Text('Edit profile'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: _editProfile,
                  ),
                ])),
                const SizedBox(height: 16),

                Card(child: Column(children: [
                  ListTile(
                    leading: const Icon(Icons.email_outlined),
                    title: const Text('Change email'),
                    subtitle: Text(email),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: _changeEmail,
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.lock_outline),
                    title: const Text('Change password'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: _changePassword,
                  ),
                ])),
                const SizedBox(height: 16),

                Card(child: ListTile(
                  leading: Icon(Icons.logout, color: Theme.of(context).colorScheme.error),
                  title: Text('Sign out', style: TextStyle(color: Theme.of(context).colorScheme.error)),
                  onTap: _signOut,
                )),
                const SizedBox(height: 16),

                Card(child: ListTile(
                  leading: Icon(Icons.delete_outline, color: Theme.of(context).colorScheme.error),
                  title: Text('Delete account', style: TextStyle(color: Theme.of(context).colorScheme.error)),
                  subtitle: const Text('Permanently delete all data'),
                  onTap: _deleteAccount,
                )),
              ],
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
          FilledButton(onPressed: () async {
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
          }, child: const Text('Save')),
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
          FilledButton(onPressed: () async {
            if (emailCtrl.text.trim().isEmpty) return;
            try {
              await _authService.changeEmail(newEmail: emailCtrl.text.trim());
              if (mounted) { Navigator.pop(ctx); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Confirmation email sent!'))); }
            } catch (e) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'))); }
          }, child: const Text('Send confirmation')),
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
          FilledButton(onPressed: () async {
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
          }, child: const Text('Update password')),
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
