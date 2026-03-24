import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';

/// OAuth provider types
enum OAuthProviderType { google }

/// Extension to convert to Supabase OAuthProvider
extension OAuthProviderExtension on OAuthProviderType {
  OAuthProvider get supabaseProvider {
    switch (this) {
      case OAuthProviderType.google:
        return OAuthProvider.google;
    }
  }

  String get displayName {
    switch (this) {
      case OAuthProviderType.google:
        return 'Google';
    }
  }
}

/// User data extracted from OAuth provider
class OAuthUserData {
  final String email;
  final String? firstName;
  final String? lastName;
  final String? fullName;
  final String? avatarUrl;
  final String? provider;
  final String? company; // Extracted from email domain
  
  const OAuthUserData({
    required this.email,
    this.firstName,
    this.lastName,
    this.fullName,
    this.avatarUrl,
    this.provider,
    this.company,
  });
  
  /// Extract first and last name from full name
  factory OAuthUserData.fromUserMetadata(Map<String, dynamic> metadata, {String? provider}) {
    String? email = metadata['email'] as String?;
    String? fullName = metadata['full_name'] as String? ?? metadata['name'] as String?;
    String? firstName = metadata['first_name'] as String?;
    String? lastName = metadata['last_name'] as String?;
    String? avatarUrl = metadata['avatar_url'] as String? ?? metadata['picture'] as String?;
    
    // If we have full_name but not first/last, try to split
    if (fullName != null && fullName.isNotEmpty) {
      if (firstName == null || firstName.isEmpty) {
        final parts = fullName.split(' ');
        firstName = parts.first;
        if (parts.length > 1 && (lastName == null || lastName.isEmpty)) {
          lastName = parts.sublist(1).join(' ');
        }
      }
    }
    
    // Extract company from email domain
    String? company;
    if (email != null && email.contains('@')) {
      final domain = email.split('@').last.toLowerCase();
      final personalDomains = [
        'gmail.com', 'yahoo.com', 'hotmail.com', 'outlook.com',
        'aol.com', 'icloud.com', 'me.com', 'qq.com', '163.com',
        'protonmail.com', 'zoho.com', 'yandex.com', 'mail.com',
        'live.com', 'msn.com', 'ymail.com', 'hey.com'
      ];
      if (!personalDomains.contains(domain)) {
        // Extract company name from domain
        company = domain.split('.').first;
        company = company[0].toUpperCase() + company.substring(1);
      }
    }
    
    return OAuthUserData(
      email: email ?? '',
      firstName: firstName,
      lastName: lastName,
      fullName: fullName,
      avatarUrl: avatarUrl,
      provider: provider,
      company: company,
    );
  }
  
  Map<String, String> toCardData() {
    return {
      'email': email,
      'firstName': firstName ?? '',
      'lastName': lastName ?? '',
      'company': company ?? '',
      'profilePicUrl': avatarUrl ?? '',
    };
  }
}

/// Handles all authentication logic: email/password, OAuth, OTP
class AuthService {
  final _supabase = SupabaseService();
  
  User? get currentUser => _supabase.currentUser;
  bool get isLoggedIn => _supabase.isLoggedIn;
  
  /// Stream of auth state changes (sign in, sign out, token refresh)
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;
  
  /// Track if the current session was initiated via OAuth
  bool _wasOAuthSignIn = false;
  bool get wasOAuthSignIn => _wasOAuthSignIn;
  
  /// Store OAuth user data temporarily for onboarding
  OAuthUserData? _pendingOAuthData;
  OAuthUserData? get pendingOAuthData => _pendingOAuthData;
  
  /// Clear pending OAuth data
  void clearPendingOAuthData() {
    _pendingOAuthData = null;
  }
  
  // ─────────────────────────────────────────────
  // Email + Password Registration
  // ─────────────────────────────────────────────
  
  /// Register with email and password
  /// Sends OTP verification email automatically
  Future<AuthResponse> registerWithEmail({
    required String email,
    required String password,
    required String firstName,
    String? lastName,
  }) async {
    _wasOAuthSignIn = false;
    return await _supabase.auth.signUp(
      email: email,
      password: password,
      data: {
        'first_name': firstName,
        'last_name': lastName,
      },
    );
  }
  
  // ─────────────────────────────────────────────
  // Email OTP Verification
  // ─────────────────────────────────────────────

  /// Verify email with OTP code — tries signup type first, then email type
  Future<AuthResponse> verifyEmailOtp({
    required String email,
    required String token,
  }) async {
    try {
      return await _supabase.auth.verifyOTP(
        email: email,
        token: token,
        type: OtpType.signup,
      );
    } catch (e) {
      // If signup type fails, try email type
      return await _supabase.auth.verifyOTP(
        email: email,
        token: token,
        type: OtpType.email,
      );
    }
  }

  /// Resend OTP verification code
  Future<void> resendOtp({required String email}) async {
    try {
      await _supabase.auth.resend(
        type: OtpType.signup,
        email: email,
      );
    } catch (_) {
      // Fallback: send a new magic link/OTP via signInWithOtp
      await _supabase.auth.signInWithOtp(email: email);
    }
  }
  
  // ─────────────────────────────────────────────
  // Email + Password Login
  // ─────────────────────────────────────────────
  
  /// Sign in with email and password
  Future<AuthResponse> loginWithEmail({
    required String email,
    required String password,
  }) async {
    _wasOAuthSignIn = false;
    return await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }
  
  // ─────────────────────────────────────────────
  // OAuth Sign-In (NO OTP Required)
  // ─────────────────────────────────────────────
  
  /// Sign in with OAuth provider (Google)
  /// No OTP required - directly creates/returns authenticated session
  Future<bool> signInWithOAuth(OAuthProviderType provider) async {
    _wasOAuthSignIn = true;

    final result = await _supabase.auth.signInWithOAuth(
      provider.supabaseProvider,
      redirectTo: 'io.supabase.biobiz://login-callback',
    );

    return result;
  }

  /// Convenience method for Google sign-in
  Future<bool> signInWithGoogle() => signInWithOAuth(OAuthProviderType.google);
  
  /// Process OAuth callback and extract user data
  /// Call this after OAuth redirect is handled
  Future<OAuthUserData?> processOAuthCallback() async {
    final user = currentUser;
    if (user == null) return null;
    
    // Extract provider from user's app_metadata
    final provider = user.appMetadata['provider'] as String?;
    
    final oauthData = OAuthUserData.fromUserMetadata(
      user.userMetadata ?? {},
      provider: provider,
    );
    
    _pendingOAuthData = oauthData;
    return oauthData;
  }
  
  /// Check if user was just created (new OAuth sign-up vs existing sign-in)
  Future<bool> isNewUser() async {
    final user = currentUser;
    if (user == null) return false;
    
    // Check if profile exists
    try {
      final profile = await _supabase.client
          .from('profiles')
          .select('created_at')
          .eq('id', user.id)
          .maybeSingle();
      
      if (profile == null) return true;
      
      // Check if created within last 5 minutes (likely new)
      final createdAt = DateTime.parse(profile['created_at']);
      final now = DateTime.now();
      return now.difference(createdAt).inMinutes < 5;
    } catch (e) {
      return true; // Assume new if we can't check
    }
  }
  
  /// Check if OAuth sign-in should skip onboarding
  /// Returns true if user already has cards
  Future<bool> shouldSkipOnboarding() async {
    final user = currentUser;
    if (user == null) return false;
    
    try {
      final cards = await _supabase.client
          .from('cards')
          .select('id')
          .eq('user_id', user.id)
          .limit(1);
      
      return cards.isNotEmpty;
    } catch (e) {
      return false;
    }
  }
  
  // ─────────────────────────────────────────────
  // Session Management
  // ─────────────────────────────────────────────
  
  /// Check if session is valid
  bool get hasValidSession {
    final session = _supabase.currentSession;
    if (session == null) return false;
    final expiresAt = DateTime.fromMillisecondsSinceEpoch(session.expiresAt! * 1000);
    return expiresAt.isAfter(DateTime.now());
  }
  
  /// Sign out
  Future<void> signOut() async {
    _wasOAuthSignIn = false;
    _pendingOAuthData = null;
    await _supabase.auth.signOut();
  }
  
  // ─────────────────────────────────────────────
  // Account Management
  // ─────────────────────────────────────────────
  
  /// Change email
  Future<void> changeEmail({required String newEmail}) async {
    await _supabase.auth.updateUser(
      UserAttributes(email: newEmail),
    );
  }
  
  /// Change password
  Future<void> changePassword({required String newPassword}) async {
    await _supabase.auth.updateUser(
      UserAttributes(password: newPassword),
    );
  }
  
  /// Delete account
  Future<void> deleteAccount() async {
    await _supabase.auth.signOut();
  }
  
  /// Update user profile data
  Future<void> updateProfile({
    String? firstName,
    String? lastName,
    String? avatarUrl,
  }) async {
    final data = <String, dynamic>{};
    if (firstName != null) data['first_name'] = firstName;
    if (lastName != null) data['last_name'] = lastName;
    if (avatarUrl != null) data['avatar_url'] = avatarUrl;
    
    await _supabase.auth.updateUser(
      UserAttributes(data: data),
    );
  }
}
