// lib/main.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:islam_focus_flutter/core/config/supabase_config.dart';
import 'package:islam_focus_flutter/core/theme/theme_provider.dart';
import 'package:islam_focus_flutter/features/auth/screens/auth_gate.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set status bar style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  // Initialize Supabase
  await Supabase.initialize(
    url: SupabaseConfig.supabaseUrl,
    anonKey: SupabaseConfig.supabaseAnonKey,
  );

  runApp(
    const ProviderScope(
      child: IslamFocusApp(),
    ),
  );
}

class IslamFocusApp extends ConsumerWidget {
  const IslamFocusApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appTheme = ref.watch(themeProvider);

    return MaterialApp(
      title: 'Islam Focus',
      debugShowCheckedModeBanner: false,
      theme: appTheme.toThemeData(),
      home: const AuthGate(),
    );
  }
}
