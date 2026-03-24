import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers/auth_provider.dart';

/// OTP Verification Screen — single paste-friendly input
class OtpVerificationScreen extends ConsumerStatefulWidget {
  final String email;

  const OtpVerificationScreen({super.key, required this.email});

  @override
  ConsumerState<OtpVerificationScreen> createState() =>
      _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends ConsumerState<OtpVerificationScreen> {
  final _codeController = TextEditingController();
  bool _isLoading = false;
  bool _isResending = false;
  int _resendCooldown = 0;
  Timer? _cooldownTimer;

  @override
  void initState() {
    super.initState();
    _startCooldown(60);
  }

  @override
  void dispose() {
    _codeController.dispose();
    _cooldownTimer?.cancel();
    super.dispose();
  }

  void _startCooldown(int seconds) {
    _resendCooldown = seconds;
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendCooldown <= 0) {
        timer.cancel();
      } else {
        setState(() => _resendCooldown--);
      }
    });
  }

  Future<void> _verifyOtp() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) return;

    setState(() => _isLoading = true);
    ref.read(authErrorProvider.notifier).state = null;

    try {
      await ref.read(authServiceProvider).verifyEmailOtp(
            email: widget.email,
            token: code,
          );
      if (mounted) {
        context.go('/card');
      }
    } catch (e) {
      if (mounted) {
        String errorMsg = 'Invalid code — please try again';
        if (e.toString().contains('expired')) {
          errorMsg = 'Code expired — tap Resend to get a new one';
        }
        ref.read(authErrorProvider.notifier).state = errorMsg;
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _resendCode() async {
    if (_resendCooldown > 0) return;

    setState(() => _isResending = true);
    try {
      await ref.read(authServiceProvider).resendOtp(email: widget.email);
      if (mounted) {
        _startCooldown(60);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('New code sent to your email')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to resend. Try again later.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isResending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authError = ref.watch(authErrorProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Verify Email')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),
              Icon(Icons.mark_email_read_outlined,
                  size: 64, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 24),
              Text(
                'Check your email',
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'We sent a verification code to',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                widget.email,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // Error message
              if (authError != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    authError,
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.onErrorContainer),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Single code input — paste friendly
              TextField(
                controller: _codeController,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .headlineMedium
                    ?.copyWith(letterSpacing: 8),
                decoration: const InputDecoration(
                  hintText: 'Paste code here',
                ),
                onSubmitted: (_) => _verifyOtp(),
              ),
              const SizedBox(height: 24),

              // Verify button
              FilledButton(
                onPressed: _isLoading ? null : _verifyOtp,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Verify'),
              ),
              const SizedBox(height: 24),

              // Resend
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Didn't get the code? "),
                  if (_resendCooldown > 0)
                    Text(
                      'Resend in ${_resendCooldown}s',
                      style: TextStyle(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurfaceVariant),
                    )
                  else
                    TextButton(
                      onPressed: _isResending ? null : _resendCode,
                      child: _isResending
                          ? const SizedBox(
                              height: 16,
                              width: 16,
                              child:
                                  CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Resend'),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
