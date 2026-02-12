import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_client.dart';

class AuthService {
  SupabaseClient get _client => SupabaseClientProvider.client;

  Stream<AuthState> get onAuthStateChanges => _client.auth.onAuthStateChange;
  User? get currentUser => _client.auth.currentUser;
  Session? get currentSession => _client.auth.currentSession;

  Future<AuthResponse> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    return _client.auth.signInWithPassword(email: email, password: password);
  }

  Future<AuthResponse> signUpWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    return _client.auth.signUp(email: email, password: password);
  }

  Future<void> signInWithGoogle() async {
    // Web/Mobile seamless flow via browser.
    // Handles deep linking via callback URL.
    await _client.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: kIsWeb ? null : 'com.innerarchive.app://login-callback/',
    );
  }

  Future<void> signInWithApple() async {
    await _client.auth.signInWithOAuth(
      OAuthProvider.apple,
      redirectTo: kIsWeb ? null : 'com.innerarchive.app://login-callback/',
    );
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }
}
