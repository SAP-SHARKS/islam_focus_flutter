import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_accessibility_service/flutter_accessibility_service.dart';
import 'package:islam_focus_flutter/core/config/supabase_config.dart';
import 'package:islam_focus_flutter/core/theme/theme_provider.dart';
import 'package:islam_focus_flutter/features/auth/screens/auth_gate.dart';
import 'package:islam_focus_flutter/features/quran/quran_service.dart';
import 'dart:convert';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  await Supabase.initialize(
    url: SupabaseConfig.supabaseUrl,
    anonKey: SupabaseConfig.supabaseAnonKey,
  );

  try {
    FlutterAccessibilityService.accessStream.listen((event) {});
  } catch (e) {}

  // Setup Quran MethodChannel for native InterventionActivity
  const quranChannel = MethodChannel('com.islamfocus.app/quran');
  quranChannel.setMethodCallHandler((call) async {
    switch (call.method) {
      case 'getNextAyat':
        final ayat = await QuranService.getNextAyat();
        if (ayat != null) {
          return jsonEncode(ayat.toJson());
        }
        return null;
      case 'moveToNext':
        await QuranService.moveToNext();
        return null;
      case 'getCurrentPosition':
        final pos = await QuranService.getCurrentPosition();
        return jsonEncode(pos);
      default:
        return null;
    }
  });

  // Preload first surah in background
  QuranService.loadSurah(1);

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
      home: AuthGate(),
    );
  }
}