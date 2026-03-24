import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'contact_detail_screen.dart';

/// Story 7.1: Searchable contacts list
class ContactsListScreen extends ConsumerStatefulWidget {
  const ContactsListScreen({super.key});

  @override
  ConsumerState<ContactsListScreen> createState() => _ContactsListScreenState();
}

class _ContactsListScreenState extends ConsumerState<ContactsListScreen> {
  final _supabase = Supabase.instance.client;
  final _searchController = TextEditingController();
  List<Map<String, dynamic>> _contacts = [];
  List<Map<String, dynamic>> _filteredContacts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadContacts();
    _searchController.addListener(_filterContacts);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadContacts() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        setState(() => _isLoading = false);
        return;
      }

      final contacts = await _supabase
          .from('contacts')
          .select()
          .eq('user_id', user.id)
          .order('created_at', ascending: false);

      setState(() {
        _contacts = List<Map<String, dynamic>>.from(contacts);
        _filteredContacts = _contacts;
      });
    } catch (e) {
      debugPrint('Error loading contacts: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _filterContacts() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredContacts = _contacts.where((c) {
        final name = '${c['first_name'] ?? ''} ${c['last_name'] ?? ''}'.toLowerCase();
        final email = (c['email'] ?? '').toLowerCase();
        final company = (c['company'] ?? '').toLowerCase();
        final phone = (c['phone'] ?? '').toLowerCase();
        return name.contains(query) ||
            email.contains(query) ||
            company.contains(query) ||
            phone.contains(query);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Contacts')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Search bar
                if (_contacts.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search contacts...',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  _searchController.clear();
                                  _filterContacts();
                                },
                              )
                            : null,
                      ),
                    ),
                  ),

                // Contacts list
                Expanded(
                  child: _filteredContacts.isEmpty
                      ? _buildEmptyState()
                      : RefreshIndicator(
                          onRefresh: _loadContacts,
                          child: ListView.builder(
                            itemCount: _filteredContacts.length,
                            itemBuilder: (context, index) {
                              final contact = _filteredContacts[index];
                              return _buildContactTile(contact);
                            },
                          ),
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addManualContact,
        child: const Icon(Icons.person_add),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline,
              size: 80,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 24),
            Text(
              'No contacts yet',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'When you share your card and someone shares\ntheir details back, they\'ll appear here.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => context.push('/card/share'),
              icon: const Icon(Icons.share),
              label: const Text('Share my card'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactTile(Map<String, dynamic> contact) {
    final firstName = contact['first_name'] ?? '';
    final lastName = contact['last_name'] ?? '';
    final name = '$firstName $lastName'.trim();
    final company = contact['company'] ?? '';
    final jobTitle = contact['job_title'] ?? '';
    final email = contact['email'] ?? '';
    final source = contact['source'] ?? 'manual';

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onPrimaryContainer,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      title: Text(name.isNotEmpty ? name : 'Unknown'),
      subtitle: Text(
        [jobTitle, company].where((s) => s.isNotEmpty).join(' · '),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (email.isNotEmpty)
            Icon(Icons.email_outlined, size: 16, color: Theme.of(context).colorScheme.onSurfaceVariant),
          const SizedBox(width: 4),
          _buildSourceBadge(source),
        ],
      ),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ContactDetailScreen(contact: contact),
          ),
        ).then((_) => _loadContacts());
      },
    );
  }

  Widget _buildSourceBadge(String source) {
    IconData icon;
    switch (source) {
      case 'scan':
        icon = Icons.qr_code_scanner;
      case 'exchange':
        icon = Icons.swap_horiz;
      default:
        icon = Icons.person;
    }
    return Icon(icon, size: 14, color: Theme.of(context).colorScheme.onSurfaceVariant);
  }

  void _addManualContact() {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final phoneController = TextEditingController();
    final companyController = TextEditingController();
    final titleController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
          left: 16, right: 16, top: 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Add Contact', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Name *', prefixIcon: Icon(Icons.person_outline))),
            const SizedBox(height: 12),
            TextField(controller: emailController, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email_outlined))),
            const SizedBox(height: 12),
            TextField(controller: phoneController, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Phone', prefixIcon: Icon(Icons.phone_outlined))),
            const SizedBox(height: 12),
            TextField(controller: companyController, decoration: const InputDecoration(labelText: 'Company', prefixIcon: Icon(Icons.business_outlined))),
            const SizedBox(height: 12),
            TextField(controller: titleController, decoration: const InputDecoration(labelText: 'Job title', prefixIcon: Icon(Icons.work_outline))),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () async {
                if (nameController.text.trim().isEmpty) return;

                try {
                  final user = _supabase.auth.currentUser;
                  if (user == null) return;

                  final nameParts = nameController.text.trim().split(' ');
                  await _supabase.from('contacts').insert({
                    'user_id': user.id,
                    'source': 'manual',
                    'first_name': nameParts.first,
                    'last_name': nameParts.length > 1 ? nameParts.sublist(1).join(' ') : null,
                    'email': emailController.text.trim().isEmpty ? null : emailController.text.trim(),
                    'phone': phoneController.text.trim().isEmpty ? null : phoneController.text.trim(),
                    'company': companyController.text.trim().isEmpty ? null : companyController.text.trim(),
                    'job_title': titleController.text.trim().isEmpty ? null : titleController.text.trim(),
                  });

                  if (mounted) {
                    Navigator.pop(ctx);
                    _loadContacts();
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: ${e.toString()}')),
                  );
                }
              },
              child: const Text('Save Contact'),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
