import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Story 2.2 + 2.3: Professional details (company, title, website)
class OnboardingProfessionalScreen extends StatefulWidget {
  final Map<String, String> previousData;

  const OnboardingProfessionalScreen({super.key, required this.previousData});

  @override
  State<OnboardingProfessionalScreen> createState() =>
      _OnboardingProfessionalScreenState();
}

class _OnboardingProfessionalScreenState
    extends State<OnboardingProfessionalScreen> {
  final _companyController = TextEditingController();
  final _titleController = TextEditingController();
  final _websiteController = TextEditingController();

  @override
  void dispose() {
    _companyController.dispose();
    _titleController.dispose();
    _websiteController.dispose();
    super.dispose();
  }

  void _next() {
    context.push('/onboarding/logo', extra: {
      ...widget.previousData,
      'company': _companyController.text.trim(),
      'jobTitle': _titleController.text.trim(),
      'website': _websiteController.text.trim(),
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: const Text('Professional Details'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Progress (step 3)
              LinearProgressIndicator(
                value: 0.6,
                backgroundColor:
                    Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(4),
              ),
              const SizedBox(height: 8),
              Text('Step 3 of 5',
                  style: Theme.of(context).textTheme.bodySmall,
                  textAlign: TextAlign.center),
              const SizedBox(height: 32),

              Text(
                'Where do you work?',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Add your professional info (all fields optional)',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 24),

              // Company name
              TextFormField(
                controller: _companyController,
                textInputAction: TextInputAction.next,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Company name',
                  prefixIcon: Icon(Icons.business_outlined),
                ),
              ),
              const SizedBox(height: 16),

              // Job title
              TextFormField(
                controller: _titleController,
                textInputAction: TextInputAction.next,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Job title',
                  prefixIcon: Icon(Icons.work_outline),
                ),
              ),
              const SizedBox(height: 16),

              // Company website (for logo detection)
              TextFormField(
                controller: _websiteController,
                keyboardType: TextInputType.url,
                textInputAction: TextInputAction.done,
                decoration: const InputDecoration(
                  labelText: 'Company website',
                  prefixIcon: Icon(Icons.language),
                  hintText: 'https://yourcompany.com',
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'We\'ll try to auto-detect your company logo',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),

              const Spacer(),

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
