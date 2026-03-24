import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Story 2.1: Name entry step with Privacy Policy & ToS agreement
class OnboardingNameScreen extends StatefulWidget {
  const OnboardingNameScreen({super.key});

  @override
  State<OnboardingNameScreen> createState() => _OnboardingNameScreenState();
}

class _OnboardingNameScreenState extends State<OnboardingNameScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  bool _acceptedTerms = false;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    super.dispose();
  }

  void _next() {
    if (!_formKey.currentState!.validate()) return;
    if (!_acceptedTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please accept the Privacy Policy & Terms of Service')),
      );
      return;
    }

    context.push('/onboarding/contact-info', extra: {
      'firstName': _firstNameController.text.trim(),
      'lastName': _lastNameController.text.trim(),
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
        title: const Text('Your Name'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Progress indicator (step 1 of ~5)
                LinearProgressIndicator(
                  value: 0.2,
                  backgroundColor:
                      Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(4),
                ),
                const SizedBox(height: 8),
                Text('Step 1 of 5',
                    style: Theme.of(context).textTheme.bodySmall,
                    textAlign: TextAlign.center),
                const SizedBox(height: 32),

                Text(
                  'What\'s your name?',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'This will appear on your digital business card',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 24),

                // First name
                TextFormField(
                  controller: _firstNameController,
                  textInputAction: TextInputAction.next,
                  textCapitalization: TextCapitalization.words,
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: 'First name *',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Enter your first name';
                    }
                    if (value.trim().length > 50) {
                      return 'Max 50 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Last name
                TextFormField(
                  controller: _lastNameController,
                  textInputAction: TextInputAction.done,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Last name',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (value) {
                    if (value != null && value.trim().length > 50) {
                      return 'Max 50 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // Privacy Policy & ToS checkbox
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Checkbox(
                      value: _acceptedTerms,
                      onChanged: (v) =>
                          setState(() => _acceptedTerms = v ?? false),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () =>
                            setState(() => _acceptedTerms = !_acceptedTerms),
                        child: Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Text.rich(
                            TextSpan(
                              text: 'I agree to the ',
                              children: [
                                TextSpan(
                                  text: 'Privacy Policy',
                                  style: TextStyle(
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                                const TextSpan(text: ' and '),
                                TextSpan(
                                  text: 'Terms of Service',
                                  style: TextStyle(
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ],
                            ),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const Spacer(),

                // Next button
                FilledButton(
                  onPressed: _next,
                  child: const Text('Next'),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
