// lib/features/auth/providers/auth_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Auth state model
class AuthState {
  final User? user;
  final bool isLoading;
  final String? error;
  final String? successMessage;

  const AuthState({
    this.user,
    this.isLoading = false,
    this.error,
    this.successMessage,
  });

  AuthState copyWith({
    User? user,
    bool? isLoading,
    String? error,
    String? successMessage,
  }) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      successMessage: successMessage,
    );
  }

  bool get isAuthenticated => user != null;
}

/// Auth notifier handles all auth operations
class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState()) {
    _checkCurrentUser();
  }

  final _supabase = Supabase.instance.client;

  void _checkCurrentUser() {
    final user = _supabase.auth.currentUser;
    if (user != null) {
      state = AuthState(user: user);
    }

    // Listen to auth state changes
    _supabase.auth.onAuthStateChange.listen((data) {
      final event = data.event;
      if (event == AuthChangeEvent.signedIn) {
        state = AuthState(user: data.session?.user);
      } else if (event == AuthChangeEvent.signedOut) {
        state = const AuthState();
      }
    });
  }

  // ============================
  // SIGN UP with email & password
  // ============================
  Future<bool> signUp({
    required String email,
    required String password,
    required String fullName,
  }) async {
    state = state.copyWith(isLoading: true, error: null, successMessage: null);
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {'full_name': fullName},
      );

      if (response.user != null) {
        // Create profile in profiles table
        try {
          await _supabase.from('profiles').upsert({
            'id': response.user!.id,
            'full_name': fullName,
            'email': email,
            'created_at': DateTime.now().toIso8601String(),
          });
        } catch (_) {
          // Profile creation might fail if RLS blocks it before email confirm
          // That's ok, we'll create it on first login
        }

        // Check if email confirmation is required
        if (response.session == null) {
          // Email confirmation required
          state = state.copyWith(
            isLoading: false,
            successMessage: 'Account created! Please check your email to verify your account.',
          );
          return true;
        } else {
          // Auto signed in (email confirmation disabled)
          state = AuthState(user: response.user);
          return true;
        }
      }
      state = state.copyWith(isLoading: false, error: 'Something went wrong');
      return false;
    } on AuthException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Something went wrong: $e');
      return false;
    }
  }

  // ============================
  // SIGN IN with email & password
  // ============================
  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, error: null, successMessage: null);
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user != null) {
        // Ensure profile exists
        try {
          final profile = await _supabase
              .from('profiles')
              .select()
              .eq('id', response.user!.id)
              .maybeSingle();

          if (profile == null) {
            await _supabase.from('profiles').upsert({
              'id': response.user!.id,
              'full_name': response.user!.userMetadata?['full_name'] ?? 'User',
              'email': email,
              'created_at': DateTime.now().toIso8601String(),
            });
          }
        } catch (_) {}

        state = AuthState(user: response.user);
        return true;
      }
      state = state.copyWith(isLoading: false, error: 'Login failed');
      return false;
    } on AuthException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Something went wrong: $e');
      return false;
    }
  }

  // ============================
  // SIGN IN with Google
  // ============================
  Future<bool> signInWithGoogle() async {
    state = state.copyWith(isLoading: true, error: null, successMessage: null);
    try {
      final success = await _supabase.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'io.supabase.islamfocus://login-callback/',
      );

      if (!success) {
        state = state.copyWith(isLoading: false, error: 'Google sign-in was cancelled');
        return false;
      }

      // The auth state listener will handle the rest
      state = state.copyWith(isLoading: false);
      return true;
    } on AuthException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Google sign-in failed: $e');
      return false;
    }
  }

  // ============================
  // FORGOT PASSWORD
  // ============================
  Future<bool> resetPassword({required String email}) async {
    state = state.copyWith(isLoading: true, error: null, successMessage: null);
    try {
      await _supabase.auth.resetPasswordForEmail(
        email,
        redirectTo: 'io.supabase.islamfocus://reset-callback/',
      );
      state = state.copyWith(
        isLoading: false,
        successMessage: 'Password reset link sent! Check your email.',
      );
      return true;
    } on AuthException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Failed to send reset email: $e');
      return false;
    }
  }

  // ============================
  // SIGN OUT
  // ============================
  Future<void> signOut() async {
    await _supabase.auth.signOut();
    state = const AuthState();
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }

  /// Clear success message
  void clearSuccess() {
    state = state.copyWith(successMessage: null);
  }
}

/// Providers
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>(
  (ref) => AuthNotifier(),
);
