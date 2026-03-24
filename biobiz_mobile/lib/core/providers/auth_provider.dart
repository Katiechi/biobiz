import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/auth_service.dart';

/// Auth service provider
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

/// Auth state stream provider
final authStateProvider = StreamProvider<AuthState>((ref) {
  final authService = ref.read(authServiceProvider);
  return authService.authStateChanges;
});

/// Current user provider
final currentUserProvider = Provider<User?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.valueOrNull?.session?.user;
});

/// Is logged in provider
final isLoggedInProvider = Provider<bool>((ref) {
  final user = ref.watch(currentUserProvider);
  return user != null;
});

/// Loading state for auth operations
final authLoadingProvider = StateProvider<bool>((ref) => false);

/// Auth error message provider
final authErrorProvider = StateProvider<String?>((ref) => null);
