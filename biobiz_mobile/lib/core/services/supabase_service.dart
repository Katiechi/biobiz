import 'package:supabase_flutter/supabase_flutter.dart';

/// Singleton wrapper for Supabase client
class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  SupabaseClient get client => Supabase.instance.client;
  GoTrueClient get auth => client.auth;
  User? get currentUser => auth.currentUser;
  Session? get currentSession => auth.currentSession;
  bool get isLoggedIn => currentUser != null;

  /// Get the current user's ID
  String? get userId => currentUser?.id;

  /// Check if user has completed onboarding
  Future<bool> hasCompletedOnboarding() async {
    if (!isLoggedIn) return false;
    final profile = await client
        .from('profiles')
        .select('onboarding_completed')
        .eq('id', userId!)
        .maybeSingle();
    return profile?['onboarding_completed'] == true;
  }
}
