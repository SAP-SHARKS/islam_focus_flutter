// lib/core/config/supabase_config.dart
// ============================================
// REPLACE THESE WITH YOUR SUPABASE CREDENTIALS
// ============================================

class SupabaseConfig {
  // Go to: Supabase Dashboard → Settings → API
  static const String supabaseUrl = 'https://zgupeerauxqcyeshpokj.supabase.co';
  static const String supabaseAnonKey =
      'sb_publishable_lE5MLejav9CMO3p3nAOJiA_0GgHUKR-';

  // Table names (keep consistent with Supabase)
  static const String profilesTable = 'profiles';
  static const String appThemesTable = 'app_themes';
  static const String dhikrLogsTable = 'dhikr_logs';
  static const String blockedAppsTable = 'blocked_apps';
  static const String breathingSessionsTable = 'breathing_sessions';
  static const String goalsTable = 'goals';
}
