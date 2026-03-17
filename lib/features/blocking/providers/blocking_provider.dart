import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class InstalledApp {
  final String packageName;
  final String appName;
  final bool isSystemApp;

  InstalledApp({
    required this.packageName,
    required this.appName,
    this.isSystemApp = false,
  });

  factory InstalledApp.fromJson(Map<String, dynamic> json) {
    return InstalledApp(
      packageName: json['packageName'] ?? '',
      appName: json['appName'] ?? '',
      isSystemApp: json['isSystemApp'] ?? false,
    );
  }
}

class InterventionSettings {
  final String mode;
  final String dhikrText;
  final int breathingDurationSeconds;
  final String fillColor;
  final String frequency;
  final bool reInterventionEnabled;
  final int reInterventionMinutes;

  const InterventionSettings({
    this.mode = 'standard_dhikr',
    this.dhikrText = 'SubhanAllah',
    this.breathingDurationSeconds = 24,
    this.fillColor = '#1DB954',
    this.frequency = 'always',
    this.reInterventionEnabled = true,
    this.reInterventionMinutes = 5,
  });

  InterventionSettings copyWith({
    String? mode,
    String? dhikrText,
    int? breathingDurationSeconds,
    String? fillColor,
    String? frequency,
    bool? reInterventionEnabled,
    int? reInterventionMinutes,
  }) {
    return InterventionSettings(
      mode: mode ?? this.mode,
      dhikrText: dhikrText ?? this.dhikrText,
      breathingDurationSeconds: breathingDurationSeconds ?? this.breathingDurationSeconds,
      fillColor: fillColor ?? this.fillColor,
      frequency: frequency ?? this.frequency,
      reInterventionEnabled: reInterventionEnabled ?? this.reInterventionEnabled,
      reInterventionMinutes: reInterventionMinutes ?? this.reInterventionMinutes,
    );
  }

  Map<String, dynamic> toJson() => {
        'mode': mode,
        'dhikrText': dhikrText,
        'breathingDurationSeconds': breathingDurationSeconds,
        'fillColor': fillColor,
        'frequency': frequency,
        'reInterventionEnabled': reInterventionEnabled,
        'reInterventionMinutes': reInterventionMinutes,
      };

  factory InterventionSettings.fromJson(Map<String, dynamic> json) {
    return InterventionSettings(
      mode: json['mode'] ?? 'standard_dhikr',
      dhikrText: json['dhikrText'] ?? 'SubhanAllah',
      breathingDurationSeconds: json['breathingDurationSeconds'] ?? 24,
      fillColor: json['fillColor'] ?? '#1DB954',
      frequency: json['frequency'] ?? 'always',
      reInterventionEnabled: json['reInterventionEnabled'] ?? true,
      reInterventionMinutes: json['reInterventionMinutes'] ?? 5,
    );
  }
}

class BlockingState {
  final List<InstalledApp> installedApps;
  final Set<String> blockedPackages;
  final InterventionSettings interventionSettings;
  final bool isLoadingApps;
  final bool accessibilityEnabled;
  final bool usagePermissionEnabled;

  const BlockingState({
    this.installedApps = const [],
    this.blockedPackages = const {},
    this.interventionSettings = const InterventionSettings(),
    this.isLoadingApps = false,
    this.accessibilityEnabled = false,
    this.usagePermissionEnabled = false,
  });

  BlockingState copyWith({
    List<InstalledApp>? installedApps,
    Set<String>? blockedPackages,
    InterventionSettings? interventionSettings,
    bool? isLoadingApps,
    bool? accessibilityEnabled,
    bool? usagePermissionEnabled,
  }) {
    return BlockingState(
      installedApps: installedApps ?? this.installedApps,
      blockedPackages: blockedPackages ?? this.blockedPackages,
      interventionSettings: interventionSettings ?? this.interventionSettings,
      isLoadingApps: isLoadingApps ?? this.isLoadingApps,
      accessibilityEnabled: accessibilityEnabled ?? this.accessibilityEnabled,
      usagePermissionEnabled: usagePermissionEnabled ?? this.usagePermissionEnabled,
    );
  }
}

class BlockingNotifier extends StateNotifier<BlockingState> {
  static const _channel = MethodChannel('com.islamfocus.app/blocking');
  static const _prefsKeyBlocked = 'blocked_packages';
  static const _prefsKeySettings = 'intervention_settings';

  BlockingNotifier() : super(const BlockingState()) {
    _loadSavedData();
    _loadInstalledApps();
    _checkPermissions();
  }

  Future<void> _loadSavedData() async {
    final prefs = await SharedPreferences.getInstance();
    final blockedList = prefs.getStringList(_prefsKeyBlocked) ?? [];
    final blocked = blockedList.toSet();

    final settingsJson = prefs.getString(_prefsKeySettings);
    InterventionSettings settings = const InterventionSettings();
    if (settingsJson != null) {
      try {
        settings = InterventionSettings.fromJson(jsonDecode(settingsJson));
      } catch (_) {}
    }

    state = state.copyWith(
      blockedPackages: blocked,
      interventionSettings: settings,
    );

    // Sync to native
    _syncToNative(blocked, settings);
  }

  Future<void> _loadInstalledApps() async {
    state = state.copyWith(isLoadingApps: true);
    try {
      final result = await _channel.invokeMethod('getInstalledApps');
      if (result != null) {
        final List<dynamic> appList = result;
        final apps = appList
            .map((e) => InstalledApp.fromJson(Map<String, dynamic>.from(e)))
            .where((app) => !app.isSystemApp)
            .toList();
        apps.sort((a, b) => a.appName.toLowerCase().compareTo(b.appName.toLowerCase()));
        state = state.copyWith(installedApps: apps, isLoadingApps: false);
      } else {
        state = state.copyWith(installedApps: _fallbackApps(), isLoadingApps: false);
      }
    } on MissingPluginException {
      state = state.copyWith(installedApps: _fallbackApps(), isLoadingApps: false);
    } catch (e) {
      state = state.copyWith(installedApps: _fallbackApps(), isLoadingApps: false);
    }
  }

  List<InstalledApp> _fallbackApps() {
    return [
      InstalledApp(packageName: 'com.instagram.android', appName: 'Instagram'),
      InstalledApp(packageName: 'com.facebook.katana', appName: 'Facebook'),
      InstalledApp(packageName: 'com.zhiliaoapp.musically', appName: 'TikTok'),
      InstalledApp(packageName: 'com.twitter.android', appName: 'X (Twitter)'),
      InstalledApp(packageName: 'com.snapchat.android', appName: 'Snapchat'),
      InstalledApp(packageName: 'com.google.android.youtube', appName: 'YouTube'),
      InstalledApp(packageName: 'com.whatsapp', appName: 'WhatsApp'),
      InstalledApp(packageName: 'com.reddit.frontpage', appName: 'Reddit'),
      InstalledApp(packageName: 'com.discord', appName: 'Discord'),
      InstalledApp(packageName: 'com.spotify.music', appName: 'Spotify'),
      InstalledApp(packageName: 'com.netflix.mediaclient', appName: 'Netflix'),
      InstalledApp(packageName: 'com.amazon.avod.thirdpartyclient', appName: 'Prime Video'),
      InstalledApp(packageName: 'com.supercell.clashofclans', appName: 'Clash of Clans'),
      InstalledApp(packageName: 'com.king.candycrushsaga', appName: 'Candy Crush'),
      InstalledApp(packageName: 'com.pubg.imobile', appName: 'PUBG Mobile'),
      InstalledApp(packageName: 'com.miHoYo.GenshinImpact', appName: 'Genshin Impact'),
      InstalledApp(packageName: 'com.pinterest', appName: 'Pinterest'),
      InstalledApp(packageName: 'com.linkedin.android', appName: 'LinkedIn'),
      InstalledApp(packageName: 'org.telegram.messenger', appName: 'Telegram'),
    ];
  }

  Future<void> toggleAppBlocking(String packageName) async {
    final newBlocked = Set<String>.from(state.blockedPackages);
    if (newBlocked.contains(packageName)) {
      newBlocked.remove(packageName);
    } else {
      newBlocked.add(packageName);
    }
    state = state.copyWith(blockedPackages: newBlocked);
    await _saveBlockedApps(newBlocked);
  }

  Future<void> updateSettings(InterventionSettings settings) async {
    state = state.copyWith(interventionSettings: settings);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKeySettings, jsonEncode(settings.toJson()));

    // Sync to native
    try {
      await _channel.invokeMethod('updateSettings', settings.toJson());
    } catch (_) {}
  }

  Future<void> _checkPermissions() async {
    try {
      final accessibility = await _channel.invokeMethod('isAccessibilityEnabled');
      final usage = await _channel.invokeMethod('isUsagePermissionEnabled');
      state = state.copyWith(
        accessibilityEnabled: accessibility ?? false,
        usagePermissionEnabled: usage ?? false,
      );
    } catch (_) {}
  }

  Future<void> openAccessibilitySettings() async {
    try { await _channel.invokeMethod('openAccessibilitySettings'); } catch (_) {}
  }

  Future<void> openUsageAccessSettings() async {
    try { await _channel.invokeMethod('openUsageAccessSettings'); } catch (_) {}
  }

  Future<void> refreshPermissions() async {
    await _checkPermissions();
  }

  Future<void> _saveBlockedApps(Set<String> packages) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_prefsKeyBlocked, packages.toList());

    // Sync to native side
    try {
      await _channel.invokeMethod('updateBlockedApps', {
        'packages': packages.toList(),
      });
    } catch (_) {}
  }

  Future<void> _syncToNative(Set<String> blocked, InterventionSettings settings) async {
    try {
      await _channel.invokeMethod('updateBlockedApps', {
        'packages': blocked.toList(),
      });
      await _channel.invokeMethod('updateSettings', settings.toJson());
    } catch (_) {}
  }
}

final blockingProvider = StateNotifierProvider<BlockingNotifier, BlockingState>(
  (ref) => BlockingNotifier(),
);