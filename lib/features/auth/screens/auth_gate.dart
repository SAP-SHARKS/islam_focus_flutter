import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:islam_focus_flutter/features/auth/providers/permission_provider.dart';
import 'package:islam_focus_flutter/features/auth/screens/permissions_screen.dart';
import 'package:islam_focus_flutter/features/blocking/screens/blocked_apps_screen.dart';
import 'package:islam_focus_flutter/features/home/screens/home_screen.dart';
import 'package:islam_focus_flutter/features/onboarding/screens/onboarding_screen.dart';

class AuthGate extends ConsumerStatefulWidget {
  AuthGate({super.key});

  @override
  ConsumerState<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends ConsumerState<AuthGate> {
  bool _isLoading = true;
  bool _onboardingComplete = false;
  bool _appBlockingSetupComplete = false;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _onboardingComplete = prefs.getBool('onboarding_complete') ?? false;
      _appBlockingSetupComplete = prefs.getBool('app_blocking_setup_complete') ?? false;
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

    if (!_onboardingComplete) {
      return OnboardingScreen();
    }

    final permissionState = ref.watch(permissionProvider);
    if (!permissionState.allGranted) {
      return const PermissionsScreen();
    }

    if (!_appBlockingSetupComplete) {
      return const FirstTimeBlockedAppsScreen();
    }

    return const HomeScreen();
  }
}