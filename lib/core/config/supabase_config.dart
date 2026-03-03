// lib/core/config/supabase_config.dart
// ============================================
// REPLACE THESE WITH YOUR SUPABASE CREDENTIALS
// ============================================

class SupabaseConfig {
  // Go to: Supabase Dashboard → Settings → API
  static const String supabaseUrl = 'https://dnrbaszxnrcsrffjymxo.supabase.co';
  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRucmJhc3p4bnJjc3JmZmp5bXhvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzIxODgxMzQsImV4cCI6MjA4Nzc2NDEzNH0.8otQn-XcwYxsH_pmWpHqvakg_fI_eP4YkbTCIY3zuPY';

  // Table names (keep consistent with Supabase)
  static const String profilesTable = 'profiles';
  static const String appThemesTable = 'app_themes';
  static const String dhikrLogsTable = 'dhikr_logs';
  static const String blockedAppsTable = 'blocked_apps';
  static const String breathingSessionsTable = 'breathing_sessions';
  static const String goalsTable = 'goals';
}
