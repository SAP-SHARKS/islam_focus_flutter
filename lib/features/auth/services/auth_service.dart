import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<AuthResponse> signInWithGoogle() async {
    try {
      // 1. Initialize Google Sign-In
      // IMPORTANT: Replace 'YOUR_WEB_CLIENT_ID' with the one from Google Cloud Console
      final GoogleSignIn googleSignIn = GoogleSignIn(
        serverClientId: 'YOUR_WEB_CLIENT_ID.apps.googleusercontent.com',
      );

      // 2. Trigger the sign-in flow
      final googleUser = await googleSignIn.signIn();
      
      if (googleUser == null) {
        throw 'Sign in was cancelled by the user.';
      }

      final googleAuth = await googleUser.authentication;
      final accessToken = googleAuth.accessToken;
      final idToken = googleAuth.idToken;

      if (idToken == null) {
        throw 'No ID Token found.';
      }

      // 3. Authenticate with Supabase
      return await _supabase.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );
    } catch (e) {
      throw 'Error during Google Sign-In: $e';
    }
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }
}