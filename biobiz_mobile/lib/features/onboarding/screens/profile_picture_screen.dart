import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

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
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: const Text('Profile Picture'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Progress (step 5)
              LinearProgressIndicator(
                value: 0.85,
                backgroundColor:
                    Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(4),
              ),
              const SizedBox(height: 8),
              Text('Step 5 of 5',
                  style: Theme.of(context).textTheme.bodySmall,
                  textAlign: TextAlign.center),
              const SizedBox(height: 32),

              Text(
                'Add a photo',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Help people recognize you',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 32),

              // Profile picture preview
              Center(
                child: CircleAvatar(
                  radius: 60,
                  backgroundColor:
                      Theme.of(context).colorScheme.surfaceContainerHighest,
                  child: _selectedImage != null
                      ? ClipOval(
                          child: Image.network(
                            _selectedImage!.path,
                            width: 120,
                            height: 120,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Icon(
                              Icons.person,
                              size: 60,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                          ),
                        )
                      : Icon(
                          Icons.person,
                          size: 60,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                ),
              ),
              const SizedBox(height: 24),

              OutlinedButton.icon(
                onPressed: _pickFromCamera,
                icon: const Icon(Icons.camera_alt_outlined),
                label: const Text('Take a photo'),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _pickFromGallery,
                icon: const Icon(Icons.photo_library_outlined),
                label: const Text('Choose from gallery'),
              ),

              const Spacer(),

              // Not now button
              TextButton(
                onPressed: () {
                  _skipped = true;
                  _next();
                },
                child: const Text('Not now'),
              ),
              const SizedBox(height: 8),

              FilledButton(
                onPressed: _next,
                child: const Text('Preview my card'),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
