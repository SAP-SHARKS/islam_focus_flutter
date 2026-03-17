import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:app_links/app_links.dart';
import 'dart:async';

/// Auth state model
class AuthState {
  final User? user;
  final bool isLoading;
  final String? error;
  final String? successMessage;
  final bool isPasswordRecovery;

  const AuthState({
    this.user,
    this.isLoading = false,
    this.error,
    this.successMessage,
    this.isPasswordRecovery = false,
  });

  AuthState copyWith({
    User? user,
    bool? isLoading,
    String? error,
    String? successMessage,
    bool? isPasswordRecovery,
  }) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      successMessage: successMessage,
      isPasswordRecovery: isPasswordRecovery ?? this.isPasswordRecovery,
    );
  }

  bool get isAuthenticated => user != null;
}

/// Auth notifier handles all auth operations
class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState()) {
    _init();
  }

  final _supabase = Supabase.instance.client;
  final _appLinks = AppLinks();
  StreamSubscription<Uri>? _linkSubscription;
  final _redirectUrl = 'com.example.islamfocus://login-callback';

  void _init() {
    // Set current user if already logged in
    final user = _supabase.auth.currentUser;
    if (user != null) {
      state = AuthState(user: user);
    }

    // Listen to auth state changes from Supabase
    _supabase.auth.onAuthStateChange.listen((data) {
      final event = data.event;
      final session = data.session;

      if (event == AuthChangeEvent.signedIn || event == AuthChangeEvent.initialSession) {
        if (session != null) {
          _ensureProfileExists(session.user);
          state = state.copyWith(user: session.user, isPasswordRecovery: false);
        }
      } else if (event == AuthChangeEvent.signedOut) {
        state = const AuthState();
      } else if (event == AuthChangeEvent.passwordRecovery) {
        state = state.copyWith(isPasswordRecovery: true);
      }
    });

    // Deep links (for password recovery & magic link only)
    _initDeepLinkListener();
  }

  Future<void> _ensureProfileExists(User user) async {
    try {
      final profile = await _supabase
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (profile == null) {
        await _supabase.from('profiles').upsert({
          'id': user.id,
          'full_name': user.userMetadata?['full_name'] ?? 'User',
          'email': user.email,
          'created_at': DateTime.now().toIso8601String(),
        });
      }
    } catch (_) {}
  }

  // ============================
  // DEEP LINK HANDLING
  // ============================
  void _initDeepLinkListener() {
    // Cold start
    _appLinks.getInitialLink().then((uri) {
      if (uri != null) _handleDeepLink(uri);
    }).catchError((_) {});

    // Warm start
    _linkSubscription = _appLinks.uriLinkStream.listen(_handleDeepLink);
  }

  Future<void> _handleDeepLink(Uri uri) async {
    final uriString = uri.toString();
    final fragment = uri.fragment;

    if (!uriString.contains('login-callback') && !fragment.contains('access_token')) {
      return;
    }

    try {
      final isRecovery = uriString.contains('type=recovery') || fragment.contains('type=recovery');

      if (isRecovery) {
        await _supabase.auth.getSessionFromUrl(uri);
        state = state.copyWith(isPasswordRecovery: true);
      } else {
        // Magic link or any other link — just get the session
        await _supabase.auth.getSessionFromUrl(uri);
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    super.dispose();
  }

  // ============================
  // SIGN UP — no email verification
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

      if (response.user != null && response.session != null) {
        // Profile create
        try {
          await _supabase.from('profiles').upsert({
            'id': response.user!.id,
            'full_name': fullName,
            'email': email,
            'created_at': DateTime.now().toIso8601String(),
          });
        } catch (_) {}

        // User is auto-logged in, Supabase auth listener will update state
        return true;
      }

      // If session is null, something is wrong (maybe email confirm is still on)
      state = state.copyWith(
        isLoading: false,
        error: 'Signup failed. Please try again.',
      );
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
        // Supabase auth listener will update state
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
      final googleSignIn = GoogleSignIn(
        serverClientId: '538385479650-q2to6t1d35s74gdcesfi0qps6err95vm.apps.googleusercontent.com',
      );
      final googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        state = state.copyWith(isLoading: false, error: 'Sign in cancelled');
        return false;
      }

      final googleAuth = await googleUser.authentication;
      final idToken = googleAuth.idToken;

      if (idToken == null) {
        throw 'No ID Token found.';
      }

      final response = await _supabase.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: googleAuth.accessToken,
      );

      if (response.user != null) {
        return true;
      }

      state = state.copyWith(isLoading: false, error: 'Google authentication failed');
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
        redirectTo: _redirectUrl,
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
  // UPDATE PASSWORD
  // ============================
  Future<bool> updatePassword({required String newPassword}) async {
    state = state.copyWith(isLoading: true, error: null, successMessage: null);
    try {
      await _supabase.auth.updateUser(
        UserAttributes(password: newPassword),
      );
      state = state.copyWith(
        isLoading: false,
        successMessage: 'Password updated successfully!',
        isPasswordRecovery: false,
      );
      return true;
    } on AuthException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Failed to update password: $e');
      return false;
    }
  }

  // ============================
  // MAGIC LINK
  // ============================
  Future<bool> signInWithMagicLink({required String email}) async {
    state = state.copyWith(isLoading: true, error: null, successMessage: null);
    try {
      await _supabase.auth.signInWithOtp(
        email: email,
        emailRedirectTo: _redirectUrl,
        shouldCreateUser: false,
      );
      state = state.copyWith(
        isLoading: false,
        successMessage: 'Magic link sent! Check your email to log in.',
      );
      return true;
    } on AuthException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Failed to send magic link: $e');
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

  void clearError() {
    state = state.copyWith(error: null);
  }

  void clearSuccess() {
    state = state.copyWith(successMessage: null);
  }
}

/// Providers
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>(
  (ref) => AuthNotifier(),
);
