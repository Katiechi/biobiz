import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import 'package:biobiz_mobile/app/theme.dart';

/// Story 2.3: Optional profile picture with circular crop
class OnboardingProfilePicScreen extends StatefulWidget {
  final Map<String, String> previousData;

  const OnboardingProfilePicScreen({super.key, required this.previousData});

  @override
  State<OnboardingProfilePicScreen> createState() =>
      _OnboardingProfilePicScreenState();
}

class _OnboardingProfilePicScreenState
    extends State<OnboardingProfilePicScreen> {
  final ImagePicker _picker = ImagePicker();
  XFile? _selectedImage;
  bool _skipped = false;

  Future<void> _pickFromCamera() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );
      if (image != null) {
        setState(() => _selectedImage = image);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open camera: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );
      if (image != null) {
        setState(() => _selectedImage = image);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not pick image: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _next() async {
    String? imageData;
    if (_selectedImage != null) {
      // Read as bytes and convert to data URL for web compatibility
      final bytes = await _selectedImage!.readAsBytes();
      final base64 = Uri.dataFromBytes(bytes, mimeType: 'image/jpeg').toString();
      imageData = base64;
    }

    if (mounted) {
      context.push('/onboarding/card-preview', extra: {
        ...widget.previousData,
        'profilePicUrl': imageData,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Top Navigation
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back),
                        onPressed: () => context.pop(),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'BioBiz',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: colors.primaryContainer,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 16),
                    // Progress
                    _buildProgressSection(context),
                    const SizedBox(height: 48),

                    // Editorial Header
                    Text(
                      'Add a photo',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 36,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                        color: colors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Help people recognize you',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        color: colors.onSurfaceVariant,
                      ),
                    ),

                    // Center Stage: Avatar
                    Expanded(
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Avatar with heritage gradient badge
                            Stack(
                              children: [
                                Container(
                                  width: 192,
                                  height: 192,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: colors.surfaceContainer,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.08),
                                        blurRadius: 20,
                                        offset: const Offset(0, 8),
                                      ),
                                    ],
                                  ),
                                  child: _selectedImage != null
                                      ? ClipOval(
                                          child: Image.network(
                                            _selectedImage!.path,
                                            width: 192,
                                            height: 192,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) => Icon(
                                              Icons.person,
                                              size: 84,
                                              color: colors.surfaceContainerHighest,
                                            ),
                                          ),
                                        )
                                      : Icon(
                                          Icons.person,
                                          size: 84,
                                          color: colors.surfaceContainerHighest,
                                        ),
                                ),
                                // Heritage gradient FAB badge
                                Positioned(
                                  bottom: 4,
                                  right: 4,
                                  child: Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: AppTheme.heritageGradient,
                                      border: Border.all(
                                        color: colors.surface,
                                        width: 3,
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.add_a_photo,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 48),

                            // Action Buttons
                            _buildActionButton(
                              context,
                              icon: Icons.photo_camera,
                              label: 'Take a photo',
                              onTap: _pickFromCamera,
                            ),
                            const SizedBox(height: 16),
                            _buildActionButton(
                              context,
                              icon: Icons.photo_library,
                              label: 'Choose from gallery',
                              onTap: _pickFromGallery,
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Bottom Actions
                    HeritageGradientButton(
                      onPressed: _next,
                      height: 56,
                      child: Text(
                        'Preview my card',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: TextButton(
                        onPressed: () {
                          _skipped = true;
                          _next();
                        },
                        child: Text(
                          'NOT NOW',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: colors.primary,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressSection(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'STEP 5 OF 5',
              style: theme.textTheme.labelSmall?.copyWith(
                color: colors.onSurfaceVariant,
                letterSpacing: 0.8,
              ),
            ),
            Text(
              '85%',
              style: theme.textTheme.labelSmall?.copyWith(
                color: colors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: SizedBox(
            height: 4,
            child: Container(
              decoration: BoxDecoration(
                color: colors.surfaceContainer,
                borderRadius: BorderRadius.circular(4),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: 0.85,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: AppTheme.heritageGradient,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    final colors = Theme.of(context).colorScheme;

    return Material(
      color: colors.surfaceContainerLow,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            children: [
              Icon(icon, color: colors.primary, size: 24),
              const SizedBox(width: 16),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: colors.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
