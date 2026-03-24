import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Story 2.2: Contact info (email, phone) + Professional details (company, title, website)
class OnboardingContactInfoScreen extends StatefulWidget {
  final Map<String, String> previousData;

  const OnboardingContactInfoScreen({super.key, required this.previousData});

  @override
  State<OnboardingContactInfoScreen> createState() =>
      _OnboardingContactInfoScreenState();
}

class _OnboardingContactInfoScreenState
    extends State<OnboardingContactInfoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _next() {
    if (!_formKey.currentState!.validate()) return;

    context.push('/onboarding/professional', extra: {
      ...widget.previousData,
      'email': _emailController.text.trim(),
      'phone': _phoneController.text.trim(),
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
        title: const Text('Contact Info'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Progress (step 2)
                LinearProgressIndicator(
                  value: 0.4,
                  backgroundColor:
                      Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(4),
                ),
                const SizedBox(height: 8),
                Text('Step 2 of 5',
                    style: Theme.of(context).textTheme.bodySmall,
                    textAlign: TextAlign.center),
                const SizedBox(height: 32),

                Text(
                  'How can people reach you?',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 24),

                // Email
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Work email',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return null; // optional
                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                        .hasMatch(value)) {
                      return 'Enter a valid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Phone
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.done,
                  decoration: const InputDecoration(
                    labelText: 'Phone number',
                    prefixIcon: Icon(Icons.phone_outlined),
                    hintText: '+1 234 567 8900',
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
      ),
    );
  }
}
