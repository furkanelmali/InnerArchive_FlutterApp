import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/auth_service.dart';

final authServiceProvider = Provider<AuthService>((ref) => AuthService());

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthState {
  final AuthStatus status;
  final User? user;
  final String? error;
  final bool isLoading;

  const AuthState({
    this.status = AuthStatus.unknown,
    this.user,
    this.error,
    this.isLoading = false,
  });

  AuthState copyWith({
    AuthStatus? status,
    User? Function()? user,
    String? Function()? error,
    bool? isLoading,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user != null ? user() : this.user,
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
    final user = _authService.currentUser;

    _sub?.cancel();
    _sub = _authService.authStateChanges.listen((event) {
      final session = event.session;
      if (session != null) {
        state = state.copyWith(
          status: AuthStatus.authenticated,
          user: () => session.user,
          error: () => null,
        );
      } else {
        state = state.copyWith(
          status: AuthStatus.unauthenticated,
          user: () => null,
        );
      }
    });

    ref.onDispose(() => _sub?.cancel());

    return AuthState(
      status: user != null
          ? AuthStatus.authenticated
          : AuthStatus.unauthenticated,
      user: user,
    );
  }

  Future<void> signUp({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, error: () => null);
    try {
      await _authService.signUp(email: email, password: password);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: () => e.toString());
    }
  }

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, error: () => null);
    try {
      await _authService.signIn(email: email, password: password);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: () => e.toString());
    }
  }

  Future<void> signOut() async {
    await _authService.signOut();
  }
}
