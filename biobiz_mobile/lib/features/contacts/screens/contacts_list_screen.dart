import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:biobiz_mobile/app/theme.dart';
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

  // Rotating gradient palette for avatar circles
  static const _avatarGradients = [
    LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [AppTheme.primary, AppTheme.primaryContainer],
    ),
    LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF424242), Color(0xFF212121)],
    ),
    LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [AppTheme.secondary, AppTheme.secondaryContainer],
    ),
    LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [AppTheme.primaryContainer, Color(0xFFB71C1C)],
    ),
  ];

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
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Contacts')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Search bar
                if (_contacts.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search your network...',
                        prefixIcon: Icon(
                          Icons.search,
                          color: cs.onSurfaceVariant.withValues(alpha: 0.6),
                        ),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  _searchController.clear();
                                  _filterContacts();
                                },
                              )
                            : null,
                        filled: true,
                        fillColor: cs.surfaceContainerHighest,
                        border: UnderlineInputBorder(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(12),
                          ),
                          borderSide: BorderSide(
                            color: cs.outlineVariant.withValues(alpha: 0.2),
                            width: 2,
                          ),
                        ),
                        enabledBorder: UnderlineInputBorder(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(12),
                          ),
                          borderSide: BorderSide(
                            color: cs.outlineVariant.withValues(alpha: 0.2),
                            width: 2,
                          ),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(12),
                          ),
                          borderSide: BorderSide(color: cs.primary, width: 2),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                        hintStyle: GoogleFonts.inter(
                          color: cs.onSurfaceVariant.withValues(alpha: 0.5),
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),

                // Section header: "Directory" with count badge
                if (_contacts.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Directory',
                          style: tt.headlineMedium,
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: cs.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(100),
                          ),
                          child: Text(
                            '${_filteredContacts.length} SAVED',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.8,
                              color: cs.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Contacts list
                Expanded(
                  child: _filteredContacts.isEmpty
                      ? _buildEmptyState()
                      : RefreshIndicator(
                          onRefresh: _loadContacts,
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 4,
                            ),
                            itemCount: _filteredContacts.length,
                            itemBuilder: (context, index) {
                              final contact = _filteredContacts[index];
                              return _buildContactTile(contact, index);
                            },
                          ),
                        ),
                ),
              ],
            ),
      floatingActionButton: GoldFab(
        onPressed: _addManualContact,
        icon: Icons.person_add,
        tooltip: 'Add contact',
      ),
    );
  }

  Widget _buildEmptyState() {
    final cs = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline,
              size: 96,
              color: cs.onSurfaceVariant.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 24),
            Text(
              'No contacts yet',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'When you share your card and someone shares\ntheir details back, they\'ll appear here.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: cs.onSurfaceVariant,
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

  Widget _buildContactTile(Map<String, dynamic> contact, int index) {
    final cs = Theme.of(context).colorScheme;
    final firstName = contact['first_name'] ?? '';
    final lastName = contact['last_name'] ?? '';
    final name = '$firstName $lastName'.trim();
    final company = contact['company'] ?? '';
    final jobTitle = contact['job_title'] ?? '';
    final email = contact['email'] ?? '';
    final source = contact['source'] ?? 'manual';

    final initials = _getInitials(firstName, lastName);
    final gradient = _avatarGradients[index % _avatarGradients.length];

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ContactDetailScreen(contact: contact),
              ),
            ).then((_) => _loadContacts());
          },
          splashColor: cs.primary.withValues(alpha: 0.05),
          highlightColor: cs.surfaceContainerLow,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Gradient avatar
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: gradient,
                  ),
                  child: Center(
                    child: Text(
                      initials,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Name and subtitle
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name.isNotEmpty ? name : 'Unknown',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: cs.onSurface,
                        ),
                      ),
                      if (jobTitle.isNotEmpty || company.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          [jobTitle, company]
                              .where((s) => s.isNotEmpty)
                              .join(' \u2022 '),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Source icon + email indicator
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _buildSourceBadge(source),
                    if (email.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Icon(
                        Icons.email_outlined,
                        size: 14,
                        color: cs.onSurfaceVariant.withValues(alpha: 0.4),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getInitials(String firstName, String lastName) {
    final f = firstName.isNotEmpty ? firstName[0].toUpperCase() : '';
    final l = lastName.isNotEmpty ? lastName[0].toUpperCase() : '';
    if (f.isEmpty && l.isEmpty) return '?';
    return '$f$l';
  }

  Widget _buildSourceBadge(String source) {
    final cs = Theme.of(context).colorScheme;
    IconData icon;
    switch (source) {
      case 'scan':
        icon = Icons.qr_code_scanner;
      case 'exchange':
        icon = Icons.swap_horiz;
      default:
        icon = Icons.person;
    }

    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        icon,
        size: 16,
        color: cs.secondary,
      ),
    );
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
