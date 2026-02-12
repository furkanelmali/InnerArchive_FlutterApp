import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_client.dart';

class AuthService {
  SupabaseClient get _client => SupabaseClientProvider.client;

  User? get currentUser => _client.auth.currentUser;
  bool get isAuthenticated => currentUser != null;

  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  Future<AuthResponse> signUp({
    required String email,
    required String password,
  }) async {
    return _client.auth.signUp(email: email, password: password);
  }

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return _client.auth.signInWithPassword(email: email, password: password);
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  Future<AuthResponse> verifyEmailOtp({
    required String email,
    required String token,
  }) async {
    return _client.auth.verifyOTP(
      token: token,
      type: OtpType.signup,
      email: email,
    );
  }

  Future<void> createProfile({
    required String userId,
    required String username,
    required String fullName,
    required DateTime? birthDate,
  }) async {
    await _client.from('profiles').insert({
      'id': userId,
      'username': username,
      'full_name': fullName,
      'birth_date': birthDate?.toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  Future<Map<String, dynamic>?> getProfile(String userId) async {
    try {
      final response = await _client
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();
      return response;
    } catch (_) {
      return null;
    }
  }

  Future<void> resendOtp(String email) async {
    await _client.auth.resend(type: OtpType.signup, email: email);
  }

  Future<void> resetPassword(String email) async {
    await _client.auth.resetPasswordForEmail(email);
  }
}
