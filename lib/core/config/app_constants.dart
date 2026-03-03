// lib/core/config/app_constants.dart

class AppConstants {
  // App Info
  static const String appName = 'Islam Focus';
  static const String appVersion = '1.0.0';

  // Breathing Exercise
  static const int breathingDurationSeconds = 30;
  static const int reInterventionMinutes = 5;

  // Dhikr
  static const int defaultDhikrTarget = 33;

  // Storage Keys
  static const String lastBreathingTimestamp = 'last_breathing_timestamp';
  static const String isLoggedIn = 'is_logged_in';
  static const String userId = 'user_id';
  static const String cachedTheme = 'cached_theme';

  // Routes
  static const String loginRoute = '/login';
  static const String signupRoute = '/signup';
  static const String homeRoute = '/home';
  static const String breathingRoute = '/breathing';
  static const String statsRoute = '/stats';
  static const String goalsRoute = '/goals';
  static const String adminRoute = '/admin';
}
