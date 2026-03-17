import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

enum StatsPeriod { week, month, year }

class StatsData {
  final int totalDhikr;
  final int totalAyatRecitation;
  final int appsBlocked;
  final int currentStreak;
  final List<DailyDhikr> dailyDhikr;
  final List<DailyDhikr> dailyAyat;
  final bool isLoading;

  const StatsData({
    this.totalDhikr = 0,
    this.totalAyatRecitation = 0,
    this.appsBlocked = 0,
    this.currentStreak = 0,
    this.dailyDhikr = const [],
    this.dailyAyat = const [],
    this.isLoading = true,
  });

  StatsData copyWith({
    int? totalDhikr,
    int? totalAyatRecitation,
    int? appsBlocked,
    int? currentStreak,
    List<DailyDhikr>? dailyDhikr,
    List<DailyDhikr>? dailyAyat,
    bool? isLoading,
  }) {
    return StatsData(
      totalDhikr: totalDhikr ?? this.totalDhikr,
      totalAyatRecitation: totalAyatRecitation ?? this.totalAyatRecitation,
      appsBlocked: appsBlocked ?? this.appsBlocked,
      currentStreak: currentStreak ?? this.currentStreak,
      dailyDhikr: dailyDhikr ?? this.dailyDhikr,
      dailyAyat: dailyAyat ?? this.dailyAyat,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class DailyDhikr {
  final DateTime date;
  final int count;
  DailyDhikr({required this.date, required this.count});
}

class StatsNotifier extends StateNotifier<StatsData> {
  StatsNotifier() : super(const StatsData()) {
    loadStats(StatsPeriod.week);
  }

  final _supabase = Supabase.instance.client;

  Future<void> loadStats(StatsPeriod period) async {
    state = state.copyWith(isLoading: true);

    final now = DateTime.now();
    DateTime startDate;

    switch (period) {
      case StatsPeriod.week:
        startDate = now.subtract(const Duration(days: 7));
        break;
      case StatsPeriod.month:
        startDate = now.subtract(const Duration(days: 30));
        break;
      case StatsPeriod.year:
        startDate = now.subtract(const Duration(days: 365));
        break;
    }

    final prefs = await SharedPreferences.getInstance();

    final totalDhikr = prefs.getInt('total_dhikr_count') ?? 0;
    final totalAyat = prefs.getInt('total_ayat_recitation') ?? 0;
    final currentStreak = prefs.getInt('current_streak') ?? 0;
    final blockedList = prefs.getStringList('blocked_packages') ?? [];

    // Parse dhikr logs
    List<DailyDhikr> dhikrList = _parseLogs(prefs, 'dhikr_logs_local', startDate);

    // Parse ayat logs
    List<DailyDhikr> ayatList = _parseLogs(prefs, 'ayat_logs_local', startDate);

    // Calculate period totals
    int periodDhikr = dhikrList.fold(0, (sum, d) => sum + d.count);
    int periodAyat = ayatList.fold(0, (sum, d) => sum + d.count);

    // Try Supabase for additional data
    try {
      final startStr = startDate.toIso8601String();

      final dhikrResponse = await _supabase
          .from('dhikr_logs')
          .select()
          .gte('created_at', startStr)
          .order('created_at', ascending: true);

      if (dhikrResponse.isNotEmpty) {
        int supabaseDhikr = 0;
        Map<String, int> supabaseDailyMap = {};
        for (final row in dhikrResponse) {
          final count = row['count'] as int? ?? 0;
          supabaseDhikr += count;
          final dateStr = row['logged_at']?.toString() ?? row['created_at']?.toString().substring(0, 10) ?? '';
          if (dateStr.isNotEmpty) {
            supabaseDailyMap[dateStr] = (supabaseDailyMap[dateStr] ?? 0) + count;
          }
        }
        if (supabaseDhikr > periodDhikr) {
          periodDhikr = supabaseDhikr;
          dhikrList = supabaseDailyMap.entries.map((e) {
            return DailyDhikr(date: DateTime.tryParse(e.key) ?? DateTime.now(), count: e.value);
          }).toList();
          dhikrList.sort((a, b) => a.date.compareTo(b.date));
        }
      }
    } catch (_) {}

    final displayDhikr = periodDhikr > 0 ? periodDhikr : totalDhikr;
    final displayAyat = periodAyat > 0 ? periodAyat : totalAyat;

    state = StatsData(
      totalDhikr: displayDhikr,
      totalAyatRecitation: displayAyat,
      appsBlocked: blockedList.length,
      currentStreak: currentStreak,
      dailyDhikr: dhikrList,
      dailyAyat: ayatList,
      isLoading: false,
    );
  }

  List<DailyDhikr> _parseLogs(SharedPreferences prefs, String key, DateTime startDate) {
    List<DailyDhikr> result = [];
    try {
      final logsJson = prefs.getString(key) ?? '[]';
      final List<dynamic> logs = jsonDecode(logsJson);

      Map<String, int> dailyMap = {};
      for (final log in logs) {
        final date = log['logged_at']?.toString() ?? '';
        final count = log['count'] as int? ?? 0;
        if (date.isNotEmpty) {
          final logDate = DateTime.tryParse(date);
          if (logDate != null && logDate.isAfter(startDate)) {
            dailyMap[date] = (dailyMap[date] ?? 0) + count;
          }
        }
      }

      result = dailyMap.entries.map((e) {
        return DailyDhikr(date: DateTime.tryParse(e.key) ?? DateTime.now(), count: e.value);
      }).toList();
      result.sort((a, b) => a.date.compareTo(b.date));
    } catch (_) {}
    return result;
  }

  Future<void> logDhikr({required int count, required String dhikrType}) async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getInt('total_dhikr_count') ?? 0;
    await prefs.setInt('total_dhikr_count', current + count);

    final today = DateTime.now().toIso8601String().substring(0, 10);
    final lastActive = prefs.getString('last_active_date') ?? '';
    if (lastActive != today) {
      final streak = prefs.getInt('current_streak') ?? 0;
      final yesterday = DateTime.now().subtract(const Duration(days: 1)).toIso8601String().substring(0, 10);
      if (lastActive == yesterday) {
        await prefs.setInt('current_streak', streak + 1);
      } else {
        await prefs.setInt('current_streak', 1);
      }
      await prefs.setString('last_active_date', today);
    }

    final logsJson = prefs.getString('dhikr_logs_local') ?? '[]';
    final List<dynamic> logs = jsonDecode(logsJson);
    logs.add({
      'count': count,
      'dhikr_type': dhikrType,
      'logged_at': today,
      'created_at': DateTime.now().toIso8601String(),
    });
    await prefs.setString('dhikr_logs_local', jsonEncode(logs));

    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId != null) {
        await _supabase.from('dhikr_logs').insert({
          'user_id': userId,
          'count': count,
          'dhikr_type': dhikrType,
          'logged_at': today,
          'created_at': DateTime.now().toIso8601String(),
        });
      }
    } catch (_) {}

    await loadStats(StatsPeriod.week);
  }
}

final statsProvider = StateNotifierProvider<StatsNotifier, StatsData>(
  (ref) => StatsNotifier(),
);

final selectedPeriodProvider = StateProvider<StatsPeriod>((ref) => StatsPeriod.week);