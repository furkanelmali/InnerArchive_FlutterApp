import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/supabase_client.dart';
import '../../profile/providers/profile_provider.dart';

enum AuthStatus {
  unknown,
  unauthenticated,
  verificationRequired,
  profileSetupRequired,
  authenticated,
}

class AppAuthState {
  final AuthStatus status;
  final String? error;
  final bool isLoading;
  final String? emailToVerify;

  const AppAuthState({
    this.status = AuthStatus.unknown,
    this.error,
    this.isLoading = false,
    this.emailToVerify,
  });

  AppAuthState copyWith({
    AuthStatus? status,
    String? error,
    bool? isLoading,
    String? emailToVerify,
  }) {
    return AppAuthState(
      status: status ?? this.status,
      error: error,
      isLoading: isLoading ?? this.isLoading,
      emailToVerify: emailToVerify ?? this.emailToVerify,
    );
  }
}

class AuthNotifier extends Notifier<AppAuthState> {
  final _authService = AuthService();
  StreamSubscription<AuthState>? _authSubscription;

  @override
  AppAuthState build() {
    ref.onDispose(() {
      _authSubscription?.cancel();
    });
    _init();
    return const AppAuthState();
  }

  void _init() {
    _authSubscription = SupabaseClientProvider.client.auth.onAuthStateChange.listen((data) {
      final session = data.session;
      if (session == null) {
        state = state.copyWith(status: AuthStatus.unauthenticated);
      } else {
        _checkProfile(session.user);
      }
    });

    final session = _authService.currentSession;
    if (session != null) {
      _checkProfile(session.user);
    } else {
      state = state.copyWith(status: AuthStatus.unauthenticated);
    }
  }

  Future<void> _checkProfile(User user) async {
    try {
      final profile = await ref.read(profileProvider.future);
      if (profile != null) {
        state = state.copyWith(status: AuthStatus.authenticated, error: null);
      } else {
         final metadata = user.userMetadata;
         if (metadata != null && metadata.isNotEmpty) {
             await _attemptAutoCreateProfile(user);
         } else {
             state = state.copyWith(status: AuthStatus.profileSetupRequired, error: null);
         }
      }
    } catch (_) {
      state = state.copyWith(status: AuthStatus.profileSetupRequired, error: null);
    }
  }

  Future<void> _attemptAutoCreateProfile(User user) async {
    try {
      final metadata = user.userMetadata ?? {};
      final fullName = metadata['full_name'] as String? ?? metadata['name'] as String?;
      final avatarUrl = metadata['avatar_url'] as String? ?? metadata['picture'] as String?;
      var username = fullName?.replaceAll(' ', '').toLowerCase() ?? user.email?.split('@')[0];
      
      if (username == null) {
         state = state.copyWith(status: AuthStatus.profileSetupRequired);
         return;
      }
      
      username = '$username${DateTime.now().microsecond}';

      await SupabaseClientProvider.client.from('profiles').insert({
        'id': user.id,
        'username': username,
        'display_name': fullName,
        'avatar_url': avatarUrl,
        'updated_at': DateTime.now().toIso8601String(),
      });
      
      ref.invalidate(profileProvider);
      state = state.copyWith(status: AuthStatus.authenticated);

    } catch (e) {
      state = state.copyWith(status: AuthStatus.profileSetupRequired);
    }
  }

  Future<void> signIn(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _authService.signInWithEmailAndPassword(email: email, password: password);
    } on AuthException catch (e) {
      state = state.copyWith(error: e.message, isLoading: false);
    } catch (_) {
      state = state.copyWith(error: 'An unexpected error occurred', isLoading: false);
    }
  }

  Future<void> signUp(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _authService.signUpWithEmailAndPassword(email: email, password: password);
      state = state.copyWith(
          status: AuthStatus.verificationRequired, 
          isLoading: false, 
          emailToVerify: email
      );
    } on AuthException catch (e) {
      state = state.copyWith(error: e.message, isLoading: false);
    } catch (_) {
      state = state.copyWith(error: 'An unexpected error occurred', isLoading: false);
    }
  }

  Future<void> signInWithGoogle() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _authService.signInWithGoogle();
    } catch (e) {
      state = state.copyWith(error: 'Google Sign-In failed: $e', isLoading: false);
    }
  }

  Future<void> signInWithApple() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _authService.signInWithApple();
    } catch (e) {
      state = state.copyWith(error: 'Apple Sign-In failed: $e', isLoading: false);
    }
  }

  Future<void> signOut() async {
    await _authService.signOut();
    state = const AppAuthState(status: AuthStatus.unauthenticated);
  }

  Future<void> verifyOtp(String email, String otp) async {
      state = state.copyWith(isLoading: true, error: null);
      try {
          await SupabaseClientProvider.client.auth.verifyOTP(
              token: otp, 
              type: OtpType.signup, 
              email: email
          );
      } on AuthException catch (e) {
          state = state.copyWith(error: e.message, isLoading: false);
      } catch (_) {
          state = state.copyWith(error: 'Verification failed', isLoading: false);
      }
  }
  
  Future<void> completeSetup({
    required String username,
    required String fullName,
    DateTime? birthDate,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final user = _authService.currentUser;
      if (user == null) throw 'No authenticated user';

      await SupabaseClientProvider.client.from('profiles').insert({
        'id': user.id,
        'username': username,
        'display_name': fullName,
        'updated_at': DateTime.now().toIso8601String(),
      });

      ref.invalidate(profileProvider);
      state = state.copyWith(status: AuthStatus.authenticated, isLoading: false);
    } catch (e) {
      state = state.copyWith(error: 'Failed to create profile: $e', isLoading: false);
    }
  }
}

final authProvider = NotifierProvider<AuthNotifier, AppAuthState>(AuthNotifier.new);
