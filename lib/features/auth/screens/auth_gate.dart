// lib/features/auth/screens/auth_gate.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:islam_focus_flutter/features/auth/providers/auth_provider.dart';
import 'package:islam_focus_flutter/features/auth/screens/login_screen.dart';
import 'package:islam_focus_flutter/features/home/screens/home_screen.dart';
import 'package:islam_focus_flutter/features/onboarding/screens/onboarding_screen.dart';

/// Checks: Onboarding done? → Authenticated? → Route accordingly
class AuthGate extends ConsumerStatefulWidget {
  const AuthGate({super.key});

  @override
  ConsumerState<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends ConsumerState<AuthGate> {
  bool _isLoading = true;
  bool _onboardingComplete = false;

  @override
  void initState() {
    super.initState();
    _checkOnboarding();
  }

  Future<void> _checkOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _onboardingComplete = prefs.getBool('onboarding_complete') ?? false;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFFDF8F4),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Step 1: Show onboarding if not completed
    if (!_onboardingComplete) {
      return const OnboardingScreen();
    }

    // Step 2: Check auth
    final authState = ref.watch(authProvider);
    if (authState.isAuthenticated) {
      return const HomeScreen();
    }
    return const LoginScreen();
  }
}
