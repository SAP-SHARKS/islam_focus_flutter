// lib/core/theme/theme_provider.dart

import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:islam_focus_flutter/core/config/supabase_config.dart';
import 'package:islam_focus_flutter/core/config/app_constants.dart';
import 'package:islam_focus_flutter/core/theme/app_theme.dart';

/// Notifier that manages the app theme state
class ThemeNotifier extends StateNotifier<AppThemeData> {
  ThemeNotifier() : super(AppThemeData.lightCalm()) {
    _loadTheme();
  }

  /// Load theme: try from Supabase first, fallback to cache, then default
  Future<void> _loadTheme() async {
    // 1. Try loading from cache first (instant)
    await _loadCachedTheme();

    // 2. Then try fetching from Supabase (async update)
    await fetchThemeFromSupabase();
  }

  /// Load cached theme from SharedPreferences
  Future<void> _loadCachedTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedJson = prefs.getString(AppConstants.cachedTheme);
      if (cachedJson != null) {
        final data = jsonDecode(cachedJson) as Map<String, dynamic>;
        state = AppThemeData.fromJson(data);
      }
    } catch (e) {
      // Use default theme on error
    }
  }

  /// Fetch latest theme from Supabase and cache it
  Future<void> fetchThemeFromSupabase() async {
    try {
      final response = await Supabase.instance.client
          .from(SupabaseConfig.appThemesTable)
          .select()
          .eq('is_active', true)
          .single();

      final themeData = AppThemeData.fromJson(response);
      state = themeData;

      // Cache it
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        AppConstants.cachedTheme,
        jsonEncode(themeData.toJson()),
      );
    } catch (e) {
      // Keep current theme (cached or default) on error
    }
  }

  /// Update theme locally (used by admin panel)
  void updateTheme(AppThemeData newTheme) {
    state = newTheme;
  }
}

/// Global theme provider
final themeProvider = StateNotifierProvider<ThemeNotifier, AppThemeData>(
  (ref) => ThemeNotifier(),
);
