import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/constants/color_presets.dart';
import '../../../core/constants/social_platforms.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/services/card_service.dart';
import '../../card_view/widgets/card_renderer.dart';

/// Story 3.1-3.7: Full card editor with all sections
class CardEditorScreen extends ConsumerStatefulWidget {
  final String? cardId; // null for new card

  const CardEditorScreen({super.key, this.cardId});

  @override
  ConsumerState<CardEditorScreen> createState() => _CardEditorScreenState();
}

class _CardEditorScreenState extends ConsumerState<CardEditorScreen> {
  final _supabase = Supabase.instance.client;
  final _imagePicker = ImagePicker();

  // Form controllers
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _middleNameController = TextEditingController();
  final _prefixController = TextEditingController();
  final _suffixController = TextEditingController();
  final _pronounController = TextEditingController();
  final _preferredNameController = TextEditingController();
  final _jobTitleController = TextEditingController();
  final _departmentController = TextEditingController();
  final _companyController = TextEditingController();
  final _websiteController = TextEditingController();
  final _headlineController = TextEditingController();
  final _cardNameController = TextEditingController();

  // State
  bool _isLoading = true;
  bool _isSaving = false;
  bool _hasUnsavedChanges = false;
  String _selectedColor = '#000000';
  String? _profileImageUrl;
  String? _logoUrl;
  String? _coverImageUrl;
  List<Map<String, dynamic>> _contactFields = [];
  List<Map<String, dynamic>> _socialLinks = [];
  List<Map<String, dynamic>> _accreditations = [];

  @override
  void initState() {
    super.initState();
    _cardNameController.text = 'My Card';
    if (widget.cardId != null) {
      _loadCard();
    } else {
      _isLoading = false;
    }

    // Track unsaved changes
    for (final c in [
      _firstNameController, _lastNameController, _jobTitleController,
      _companyController, _cardNameController,
    ]) {
      c.addListener(() => setState(() => _hasUnsavedChanges = true));
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _middleNameController.dispose();
    _prefixController.dispose();
    _suffixController.dispose();
    _pronounController.dispose();
    _preferredNameController.dispose();
    _jobTitleController.dispose();
    _departmentController.dispose();
    _companyController.dispose();
    _websiteController.dispose();
    _headlineController.dispose();
    _cardNameController.dispose();
    super.dispose();
  }

  Future<void> _loadCard() async {
    try {
      final card = await _supabase.from('cards').select().eq('id', widget.cardId!).single();

      // Load contact fields
      final fields = await _supabase
          .from('card_contact_fields')
          .select()
          .eq('card_id', widget.cardId!)
          .order('sort_order');

      // Load social links
      final links = await _supabase
          .from('card_social_links')
          .select()
          .eq('card_id', widget.cardId!)
          .order('sort_order');

      setState(() {
        _firstNameController.text = card['first_name'] ?? '';
        _lastNameController.text = card['last_name'] ?? '';
        _middleNameController.text = card['middle_name'] ?? '';
        _prefixController.text = card['prefix'] ?? '';
        _suffixController.text = card['suffix'] ?? '';
        _pronounController.text = card['pronoun'] ?? '';
        _preferredNameController.text = card['preferred_name'] ?? '';
        _jobTitleController.text = card['job_title'] ?? '';
        _departmentController.text = card['department'] ?? '';
        _companyController.text = card['company'] ?? '';
        _websiteController.text = card['company_website'] ?? '';
        _headlineController.text = card['headline'] ?? '';
        _cardNameController.text = card['card_name'] ?? 'My Card';
        _selectedColor = card['card_color'] ?? '#000000';
        _profileImageUrl = card['profile_image_url'];
        _logoUrl = card['logo_url'];
        _coverImageUrl = card['cover_image_url'];
        _contactFields = List<Map<String, dynamic>>.from(fields);
        _socialLinks = List<Map<String, dynamic>>.from(links);
      });
    } catch (e) {
      debugPrint('Error loading card: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      final cardData = {
        'user_id': user.id,
        'card_name': _cardNameController.text,
        'first_name': _firstNameController.text,
        'last_name': _lastNameController.text,
        'middle_name': _middleNameController.text.isEmpty ? null : _middleNameController.text,
        'prefix': _prefixController.text.isEmpty ? null : _prefixController.text,
        'suffix': _suffixController.text.isEmpty ? null : _suffixController.text,
        'pronoun': _pronounController.text.isEmpty ? null : _pronounController.text,
        'preferred_name': _preferredNameController.text.isEmpty ? null : _preferredNameController.text,
        'job_title': _jobTitleController.text.isEmpty ? null : _jobTitleController.text,
        'department': _departmentController.text.isEmpty ? null : _departmentController.text,
        'company': _companyController.text.isEmpty ? null : _companyController.text,
        'company_website': _websiteController.text.isEmpty ? null : _websiteController.text,
        'headline': _headlineController.text.isEmpty ? null : _headlineController.text,
        'card_color': _selectedColor,
        'profile_image_url': _profileImageUrl,
        'logo_url': _logoUrl,
        'cover_image_url': _coverImageUrl,
        'updated_at': DateTime.now().toIso8601String(),
      };

      String savedCardId;

      if (widget.cardId != null) {
        // Update existing card
        debugPrint('Updating card: ${widget.cardId}');
        await _supabase.from('cards').update(cardData).eq('id', widget.cardId!);
        savedCardId = widget.cardId!;
        debugPrint('Card updated successfully');
      } else {
        // Create new card
        final name = _firstNameController.text.trim().isEmpty
            ? 'card'
            : _firstNameController.text.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
        final uniqueId = DateTime.now().millisecondsSinceEpoch.toRadixString(36).substring(0, 6);
        final slug = '$name-$uniqueId';

        final newCardData = Map<String, dynamic>.from(cardData);
        newCardData['slug'] = slug;
        newCardData['is_active'] = true;

        debugPrint('Creating new card with slug: $slug');

        // Deactivate any existing cards first (free tier = 1 active card)
        await _supabase
            .from('cards')
            .update({'is_active': false})
            .eq('user_id', user.id)
            .eq('is_active', true);

        final result = await _supabase.from('cards').insert(newCardData).select().single();
        savedCardId = result['id'] as String;
        debugPrint('Card created: $savedCardId');
      }

      // Save contact fields and social links
      final cardSvc = CardService();
      await cardSvc.saveContactFields(savedCardId, _contactFields);
      await cardSvc.saveSocialLinks(savedCardId, _socialLinks);

      if (mounted) {
        setState(() => _hasUnsavedChanges = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Card saved!')),
        );
        context.pop();
      }
    } catch (e, stack) {
      debugPrint('Save error: $e');
      debugPrint('Stack: $stack');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving: ${e.toString()}'),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _onCancel() {
    if (_hasUnsavedChanges) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Discard changes?'),
          content: const Text('You have unsaved changes. Are you sure you want to discard them?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Keep editing')),
            FilledButton(
              onPressed: () {
                Navigator.pop(ctx);
                context.pop();
              },
              child: const Text('Discard'),
            ),
          ],
        ),
      );
    } else {
      context.pop();
    }
  }

  void _showPreview() {
    final previewData = {
      'first_name': _firstNameController.text,
      'last_name': _lastNameController.text,
      'middle_name': _middleNameController.text,
      'prefix': _prefixController.text,
      'suffix': _suffixController.text,
      'pronoun': _pronounController.text,
      'preferred_name': _preferredNameController.text,
      'job_title': _jobTitleController.text,
      'department': _departmentController.text,
      'company': _companyController.text,
      'company_website': _websiteController.text,
      'headline': _headlineController.text,
      'card_color': _selectedColor,
      'profile_image_url': _profileImageUrl,
      'logo_url': _logoUrl,
      'cover_image_url': _coverImageUrl,
      'contact_fields': _contactFields,
      'social_links': _socialLinks,
    };

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.black54,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        builder: (ctx, scrollController) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle bar
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Card Preview', style: Theme.of(context).textTheme.titleLarge),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: CardRenderer(cardData: previewData, isPreview: true),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: TextButton(onPressed: _onCancel, child: const Text('Cancel')),
        title: Text(widget.cardId != null ? 'Edit Card' : 'New Card'),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _save,
            child: _isSaving
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Save'),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildColorSection(),
                const SizedBox(height: 12),
                _buildImagesSection(),
                const SizedBox(height: 12),
                _buildPersonalDetailsSection(),
                const SizedBox(height: 12),
                _buildContactFieldsSection(),
                const SizedBox(height: 12),
                _buildSocialLinksSection(),
                const SizedBox(height: 12),
                _buildQrCodeSection(),
                const SizedBox(height: 80), // Space for preview button
              ],
            ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: FilledButton.icon(
          onPressed: _showPreview,
          icon: const Icon(Icons.visibility),
          label: const Text('Preview card'),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // Story 3.1: Card Color Section
  // ─────────────────────────────────────────────
  Widget _buildColorSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.palette_outlined, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text('Card Color', style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: List.generate(cardColorPresets.length, (index) {
                final color = cardColorPresets[index];
                final hexColor = '#${color.value.toRadixString(16).substring(2).toUpperCase()}';
                final isSelected = _selectedColor == hexColor;
                return GestureDetector(
                  onTap: () => setState(() {
                    _selectedColor = hexColor;
                    _hasUnsavedChanges = true;
                  }),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey.shade300,
                        width: isSelected ? 3 : 1,
                      ),
                    ),
                    child: isSelected
                        ? Icon(Icons.check, color: color.computeLuminance() > 0.5 ? Colors.black : Colors.white)
                        : null,
                  ),
                );
              }),
            ),
            const SizedBox(height: 12),
            // Custom color
            OutlinedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Custom color picker coming soon!')),
                );
              },
              icon: const Icon(Icons.colorize, size: 18),
              label: const Text('Custom color'),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // Story 3.2: Images Section
  // ─────────────────────────────────────────────
  Widget _buildImagesSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.image_outlined, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text('Images & Layout', style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildImagePicker('Logo', _logoUrl, Icons.business, () => _pickImage('logo')),
                _buildImagePicker('Photo', _profileImageUrl, Icons.person, () => _pickImage('profile')),
                _buildImagePicker('Cover', _coverImageUrl, Icons.photo, () => _pickImage('cover')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePicker(String label, String? imageUrl, IconData fallbackIcon, VoidCallback onTap) {
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Theme.of(context).colorScheme.outline),
            ),
            child: imageUrl != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(imageUrl, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Icon(fallbackIcon, size: 32)),
                  )
                : Icon(fallbackIcon, size: 32, color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }

  Future<void> _pickImage(String type) async {
    try {
      final image = await _imagePicker.pickImage(source: ImageSource.gallery, maxWidth: 512, maxHeight: 512, imageQuality: 85);
      if (image == null) return;

      final user = _supabase.auth.currentUser;
      if (user == null) return;

      // Show upload progress
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Uploading image...'), duration: Duration(seconds: 1)),
        );
      }

      final storage = StorageService();
      String? url;

      switch (type) {
        case 'logo':
          url = await storage.uploadLogo(image, user.id);
        case 'profile':
          url = await storage.uploadProfileImage(image, user.id);
        case 'cover':
          url = await storage.uploadCoverImage(image, user.id);
      }

      if (url != null && mounted) {
        setState(() {
          _hasUnsavedChanges = true;
          switch (type) {
            case 'logo':
              _logoUrl = url;
            case 'profile':
              _profileImageUrl = url;
            case 'cover':
              _coverImageUrl = url;
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Image uploaded!')),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Upload failed. Check storage bucket permissions.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
    }
  }

  // ─────────────────────────────────────────────
  // Story 3.3: Personal Details Section
  // ─────────────────────────────────────────────
  Widget _buildPersonalDetailsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.person_outline, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text('Personal Details', style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 16),
            // Card name
            TextField(
              controller: _cardNameController,
              decoration: const InputDecoration(labelText: 'Card name', hintText: 'My Card'),
            ),
            const SizedBox(height: 12),
            // Name fields
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _firstNameController,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(labelText: 'First name *'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _lastNameController,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(labelText: 'Last name'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Additional name chips
            Wrap(
              spacing: 8,
              children: [
                _buildNameChip('Middle', _middleNameController),
                _buildNameChip('Prefix', _prefixController),
                _buildNameChip('Suffix', _suffixController),
                _buildNameChip('Pronoun', _pronounController),
                _buildNameChip('Preferred', _preferredNameController),
              ],
            ),
            const SizedBox(height: 12),
            // Professional
            TextField(
              controller: _jobTitleController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Job title'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _departmentController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Department'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _companyController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Company'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _websiteController,
              keyboardType: TextInputType.url,
              decoration: const InputDecoration(labelText: 'Company website', hintText: 'https://'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _headlineController,
              maxLength: 200,
              maxLines: 2,
              decoration: const InputDecoration(labelText: 'Headline', hintText: 'Your personal tagline'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNameChip(String label, TextEditingController controller) {
    final hasValue = controller.text.isNotEmpty;
    return ActionChip(
      label: Text(hasValue ? '$label: ${controller.text}' : '+ $label'),
      onPressed: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          builder: (ctx) => Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
              left: 16,
              right: 16,
              top: 16,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: controller,
                  autofocus: true,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(labelText: label),
                  onChanged: (_) => setState(() => _hasUnsavedChanges = true),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Done'),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  // ─────────────────────────────────────────────
  // Story 3.4: Contact Fields Section
  // ─────────────────────────────────────────────
  Widget _buildContactFieldsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.contact_phone_outlined, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: 8),
                    Text('Contact Information', style: Theme.of(context).textTheme.titleMedium),
                  ],
                ),
                TextButton.icon(
                  onPressed: _addContactField,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add'),
                ),
              ],
            ),
            if (_contactFields.isEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Add email, phone, address, and more',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ] else ...[
              const SizedBox(height: 8),
              ReorderableListView(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                onReorder: (oldIndex, newIndex) {
                  setState(() {
                    if (newIndex > oldIndex) newIndex--;
                    final item = _contactFields.removeAt(oldIndex);
                    _contactFields.insert(newIndex, item);
                    _hasUnsavedChanges = true;
                  });
                },
                children: _contactFields.map((field) {
                  return ListTile(
                    key: ValueKey(field['id']),
                    leading: const Icon(Icons.drag_handle),
                    title: Text(field['value'] ?? ''),
                    subtitle: Text(field['field_type'] ?? ''),
                    trailing: IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: () {
                        setState(() {
                          _contactFields.remove(field);
                          _hasUnsavedChanges = true;
                        });
                      },
                    ),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _addContactField() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(title: const Text('Email'), onTap: () { Navigator.pop(ctx); _editContactField('email'); }),
            ListTile(title: const Text('Phone'), onTap: () { Navigator.pop(ctx); _editContactField('phone'); }),
            ListTile(title: const Text('Link'), onTap: () { Navigator.pop(ctx); _editContactField('link'); }),
            ListTile(title: const Text('Address'), onTap: () { Navigator.pop(ctx); _editContactField('address'); }),
            ListTile(title: const Text('Company Website'), onTap: () { Navigator.pop(ctx); _editContactField('company_website'); }),
          ],
        ),
      ),
    );
  }

  void _editContactField(String type) {
    final controller = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
          left: 16, right: 16, top: 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              autofocus: true,
              keyboardType: type == 'phone' ? TextInputType.phone : TextInputType.text,
              decoration: InputDecoration(labelText: type[0].toUpperCase() + type.substring(1)),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () {
                if (controller.text.isNotEmpty) {
                  setState(() {
                    _contactFields.add({
                      'id': DateTime.now().millisecondsSinceEpoch.toString(),
                      'field_type': type,
                      'value': controller.text,
                      'sort_order': _contactFields.length,
                    });
                    _hasUnsavedChanges = true;
                  });
                }
                Navigator.pop(ctx);
              },
              child: const Text('Add'),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // Story 3.5: Social Links Section
  // ─────────────────────────────────────────────
  Widget _buildSocialLinksSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.link, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text('Social Links', style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 8),
            if (_socialLinks.isNotEmpty) ...[
              ..._socialLinks.map((link) => ListTile(
                    leading: const Icon(Icons.link),
                    title: Text(link['platform'] ?? ''),
                    subtitle: Text(link['url'] ?? ''),
                    trailing: IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: () {
                        setState(() {
                          _socialLinks.remove(link);
                          _hasUnsavedChanges = true;
                        });
                      },
                    ),
                  )),
              const Divider(),
            ],
            // Platform grid
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: socialPlatforms.map((platform) {
                final hasLink = _socialLinks.any((l) => l['platform'] == platform.id);
                return FilterChip(
                  label: Text(platform.name),
                  selected: hasLink,
                  onSelected: (selected) {
                    if (selected) {
                      _addSocialLink(platform);
                    } else {
                      setState(() {
                        _socialLinks.removeWhere((l) => l['platform'] == platform.id);
                        _hasUnsavedChanges = true;
                      });
                    }
                  },
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  void _addSocialLink(SocialPlatform platform) {
    final controller = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
          left: 16, right: 16, top: 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(platform.name, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              autofocus: true,
              keyboardType: platform.id == 'phone' || platform.id == 'whatsapp'
                  ? TextInputType.phone
                  : TextInputType.url,
              decoration: InputDecoration(
                labelText: platform.name,
                hintText: platform.placeholder,
                prefixText: platform.baseUrl.isNotEmpty ? platform.baseUrl : null,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () {
                if (controller.text.isNotEmpty) {
                  setState(() {
                    _socialLinks.add({
                      'platform': platform.id,
                      'url': platform.baseUrl + controller.text,
                    });
                    _hasUnsavedChanges = true;
                  });
                }
                Navigator.pop(ctx);
              },
              child: const Text('Add'),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // Story 3.6: QR Code Section
  // ─────────────────────────────────────────────
  Widget _buildQrCodeSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.qr_code, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text('QR Code', style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 16),
            Center(
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: const Center(
                  child: Icon(Icons.qr_code_2, size: 80),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
