import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';

class PermissionState {
  final bool isAccessibilityGranted;
  final bool isUsageStatsGranted;
  final bool isLoading;

  const PermissionState({
    this.isAccessibilityGranted = false,
    this.isUsageStatsGranted = false,
    this.isLoading = true,
  });

  PermissionState copyWith({
    bool? isAccessibilityGranted,
    bool? isUsageStatsGranted,
    bool? isLoading,
  }) {
    return PermissionState(
      isAccessibilityGranted: isAccessibilityGranted ?? this.isAccessibilityGranted,
      isUsageStatsGranted: isUsageStatsGranted ?? this.isUsageStatsGranted,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  bool get allGranted => isAccessibilityGranted && isUsageStatsGranted;
}

class PermissionNotifier extends StateNotifier<PermissionState> {
  PermissionNotifier() : super(const PermissionState()) {
    checkPermissions();
  }

  static const _channel = MethodChannel('com.example.islamfocus/usage_stats');

  Future<void> checkPermissions() async {
    state = state.copyWith(isLoading: true);

    bool isAccessibilityEnabled = false;
    bool isUsageGranted = false;

    try {
      final result = await _channel.invokeMethod<bool>('isAccessibilityServiceEnabled');
      isAccessibilityEnabled = result ?? false;
    } catch (e) {
      // Try checking with blocking channel as fallback
      try {
        const blockingChannel = MethodChannel('com.islamfocus.app/blocking');
        final result = await blockingChannel.invokeMethod<bool>('isAccessibilityEnabled');
        isAccessibilityEnabled = result ?? false;
      } catch (_) {
        isAccessibilityEnabled = false;
      }
    }

    try {
      final result = await _channel.invokeMethod<bool>('isUsageStatsGranted');
      isUsageGranted = result ?? false;
    } catch (e) {
      isUsageGranted = false;
    }

    state = state.copyWith(
      isAccessibilityGranted: isAccessibilityEnabled,
      isUsageStatsGranted: isUsageGranted,
      isLoading: false,
    );
  }

  Future<void> requestAccessibility() async {
    try {
      await _channel.invokeMethod('requestAccessibility');
    } catch (e) {
      // ignore
    }
  }

  Future<void> requestUsageStats() async {
    try {
      await _channel.invokeMethod('requestUsageStats');
    } catch (e) {
      // ignore
    }
  }
}

final permissionProvider = StateNotifierProvider<PermissionNotifier, PermissionState>((ref) {
  return PermissionNotifier();
});
