import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import '../../../core/services/auth_service.dart';

final authServiceProvider = Provider<AuthService>((ref) => AuthService());

enum AuthStatus {
  unknown,
  authenticated,
  unauthenticated,
  verificationRequired,
  profileSetupRequired
}

class AuthState {
  final AuthStatus status;
  final User? user;
  final String? emailToVerify;
  final String? error;
  final bool isLoading;

  const AuthState({
    this.status = AuthStatus.unknown,
    this.user,
    this.emailToVerify,
    this.error,
    this.isLoading = false,
  });

  AuthState copyWith({
    AuthStatus? status,
    User? Function()? user,
    String? Function()? emailToVerify,
    String? Function()? error,
    bool? isLoading,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user != null ? user() : this.user,
      emailToVerify: emailToVerify != null ? emailToVerify() : this.emailToVerify,
      error: error != null ? error() : this.error,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(
  AuthNotifier.new,
);

class AuthNotifier extends Notifier<AuthState> {
  late final AuthService _authService;
  StreamSubscription? _sub;

  @override
  AuthState build() {
    _authService = ref.read(authServiceProvider);
    
    _sub?.cancel();
    _sub = _authService.authStateChanges.listen(_onAuthStateChange);

    ref.onDispose(() => _sub?.cancel());

    return const AuthState(status: AuthStatus.unknown);
  }

  Future<void> _onAuthStateChange(supabase.AuthState data) async {
    final session = data.session;
    if (session != null) {
      // User is signed in, check profile
      final profile = await _authService.getProfile(session.user.id);
      if (profile != null) {
        state = state.copyWith(
          status: AuthStatus.authenticated,
          user: () => session.user,
          error: () => null,
        );
      } else {
        state = state.copyWith(
          status: AuthStatus.profileSetupRequired,
          user: () => session.user,
          error: () => null,
        );
      }
    } else {
      // If we are waiting for verification, don't auto-switch to unauthenticated
      if (state.status != AuthStatus.verificationRequired) {
        state = state.copyWith(
          status: AuthStatus.unauthenticated,
          user: () => null,
        );
      }
    }
  }

  Future<void> signUp({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, error: () => null);
    try {
      await _authService.signUp(email: email, password: password);
      // If success, we expect an email to be sent.
      state = state.copyWith(
        status: AuthStatus.verificationRequired,
        emailToVerify: () => email,
      );
    } catch (e) {
      state = state.copyWith(error: () => e.toString());
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> verifyOtp(String token) async {
    state = state.copyWith(isLoading: true, error: () => null);
    try {
      final email = state.emailToVerify;
      if (email == null) throw 'No email to verify';
      
      await _authService.verifyEmailOtp(email: email, token: token);
      // Success will trigger _onAuthStateChange via stream
    } catch (e) {
      state = state.copyWith(error: () => e.toString());
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> completeSetup({
    required String username,
    required String fullName,
    required DateTime? birthDate,
  }) async {
    state = state.copyWith(isLoading: true, error: () => null);
    try {
      final user = state.user;
      if (user == null) throw 'No user found';

      await _authService.createProfile(
        userId: user.id,
        username: username,
        fullName: fullName,
        birthDate: birthDate,
      );
      
      // Force refresh status
      state = state.copyWith(status: AuthStatus.authenticated);
    } catch (e) {
      state = state.copyWith(error: () => e.toString());
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, error: () => null);
    try {
      await _authService.signIn(email: email, password: password);
    } on AuthException catch (e) {
      if (e.message.toLowerCase().contains('email not confirmed')) {
        // Resend OTP and redirect to verification
        try {
          await _authService.resendOtp(email);
        } catch (_) {}
        state = state.copyWith(
          status: AuthStatus.verificationRequired,
          emailToVerify: () => email,
          error: () => null,
        );
      } else {
        state = state.copyWith(error: () => e.message);
      }
    } catch (e) {
      state = state.copyWith(error: () => e.toString());
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> signOut() async {
    await _authService.signOut();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }
}
