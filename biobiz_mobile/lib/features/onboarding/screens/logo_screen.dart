import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

/// Story 2.3: Company logo auto-detection from website URL
class OnboardingLogoScreen extends StatefulWidget {
  final Map<String, String> previousData;

  const OnboardingLogoScreen({super.key, required this.previousData});

  @override
  State<OnboardingLogoScreen> createState() => _OnboardingLogoScreenState();
}

class _OnboardingLogoScreenState extends State<OnboardingLogoScreen> {
  final ImagePicker _picker = ImagePicker();
  bool _isDetecting = false;
  XFile? _selectedImage;
  bool _skipped = false;

  @override
  void initState() {
    super.initState();
    final website = widget.previousData['website'];
    if (website != null && website.isNotEmpty) {
      _detectLogo(website);
    }
  }

  Future<void> _detectLogo(String website) async {
    setState(() => _isDetecting = true);

    // Simulate logo detection delay (will be replaced with actual API call)
    await Future.delayed(const Duration(seconds: 2));

    // TODO: Call POST /api/utils/detect-logo on Next.js API
    // For now, skip auto-detection and let user pick manually
    if (mounted) {
      setState(() => _isDetecting = false);
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

  void _next() {
    context.push('/onboarding/profile-pic', extra: {
      ...widget.previousData,
      'logoUrl': _selectedImage?.path,
    });
  }

  @override
  Widget build(BuildContext context) {
    final website = widget.previousData['website'];

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: const Text('Company Logo'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Progress (step 4)
              LinearProgressIndicator(
                value: 0.7,
                backgroundColor:
                    Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(4),
              ),
              const SizedBox(height: 8),
              Text('Step 4 of 5',
                  style: Theme.of(context).textTheme.bodySmall,
                  textAlign: TextAlign.center),
              const SizedBox(height: 32),

              Text(
                'Your company logo',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                website != null && website.isNotEmpty
                    ? 'Detecting logo from $website...'
                    : 'Add your company logo',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 32),

              // Logo preview area
              Center(
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color:
                        Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outline,
                      width: 1,
                    ),
                  ),
                  child: _isDetecting
                      ? const Center(child: CircularProgressIndicator())
                      : _selectedImage != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Image.network(
                                _selectedImage!.path,
                                fit: BoxFit.contain,
                                errorBuilder: (_, __, ___) =>
                                    const Icon(Icons.image, size: 48),
                              ),
                            )
                          : Icon(
                              Icons.business,
                              size: 48,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                ),
              ),
              const SizedBox(height: 24),

              if (!_isDetecting) ...[
                OutlinedButton.icon(
                  onPressed: _pickFromCamera,
                  icon: const Icon(Icons.camera_alt_outlined),
                  label: const Text('Take photo'),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _pickFromGallery,
                  icon: const Icon(Icons.photo_library_outlined),
                  label: const Text('Choose from gallery'),
                ),
              ],

              const Spacer(),

              // Skip button
              TextButton(
                onPressed: () {
                  _skipped = true;
                  _next();
                },
                child: const Text('Skip for now'),
              ),
              const SizedBox(height: 8),

              FilledButton(
                onPressed: _next,
                child: const Text('Next'),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
