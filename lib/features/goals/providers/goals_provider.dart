import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:uuid/uuid.dart';

class Goal {
  final String id;
  final String title;
  final String description;
  final int targetValue;
  final int currentValue;
  final String goalType;
  final bool isCompleted;
  final DateTime createdAt;

  Goal({
    required this.id,
    required this.title,
    this.description = '',
    this.targetValue = 100,
    this.currentValue = 0,
    this.goalType = 'custom',
    this.isCompleted = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  double get progress => targetValue > 0 ? (currentValue / targetValue).clamp(0.0, 1.0) : 0.0;
  int get progressPercent => (progress * 100).toInt();

  Goal copyWith({
    String? title,
    String? description,
    int? targetValue,
    int? currentValue,
    String? goalType,
    bool? isCompleted,
  }) {
    return Goal(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      targetValue: targetValue ?? this.targetValue,
      currentValue: currentValue ?? this.currentValue,
      goalType: goalType ?? this.goalType,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'target_value': targetValue,
        'current_value': currentValue,
        'goal_type': goalType,
        'is_completed': isCompleted,
        'created_at': createdAt.toIso8601String(),
      };

  factory Goal.fromJson(Map<String, dynamic> json) {
    return Goal(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      targetValue: json['target_value'] ?? 100,
      currentValue: json['current_value'] ?? 0,
      goalType: json['goal_type'] ?? 'custom',
      isCompleted: json['is_completed'] ?? false,
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
    );
  }
}

class GoalsState {
  final List<Goal> goals;
  final bool isLoading;
  final String? error;

  const GoalsState({
    this.goals = const [],
    this.isLoading = true,
    this.error,
  });

  GoalsState copyWith({List<Goal>? goals, bool? isLoading, String? error}) {
    return GoalsState(
      goals: goals ?? this.goals,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class GoalsNotifier extends StateNotifier<GoalsState> {
  GoalsNotifier() : super(const GoalsState()) {
    loadGoals();
  }

  final _supabase = Supabase.instance.client;
  final _uuid = const Uuid();

  bool get _isLoggedIn => _supabase.auth.currentUser != null;
  String? get _userId => _supabase.auth.currentUser?.id;

  Future<void> loadGoals() async {
    state = state.copyWith(isLoading: true);

    // Always load local first
    final localGoals = await _loadLocalGoals();

    if (_isLoggedIn) {
      try {
        final response = await _supabase
            .from('goals')
            .select()
            .eq('user_id', _userId!)
            .order('created_at', ascending: false);

        final serverGoals = (response as List).map((g) => Goal.fromJson(g)).toList();

        // Merge: server goals + local goals not on server
        final serverIds = serverGoals.map((g) => g.id).toSet();
        final mergedGoals = [...serverGoals];
        for (final local in localGoals) {
          if (!serverIds.contains(local.id)) {
            mergedGoals.add(local);
            // Sync local goal to server
            _syncGoalToServer(local);
          }
        }

        state = GoalsState(goals: mergedGoals, isLoading: false);
        _cacheGoals(mergedGoals);
      } catch (e) {
        state = GoalsState(goals: localGoals, isLoading: false);
      }
    } else {
      state = GoalsState(goals: localGoals, isLoading: false);
    }
  }

  Future<void> addGoal({
    required String title,
    required String description,
    required int targetValue,
    String goalType = 'custom',
  }) async {
    final newId = _uuid.v4();
    final now = DateTime.now();

    final newGoal = Goal(
      id: newId,
      title: title,
      description: description,
      targetValue: targetValue,
      goalType: goalType,
      createdAt: now,
    );

    // Add to state immediately
    final updated = [newGoal, ...state.goals];
    state = state.copyWith(goals: updated);
    _cacheGoals(updated);

    // Try saving to Supabase if logged in
    if (_isLoggedIn) {
      try {
        await _supabase.from('goals').insert({
          'id': newId,
          'user_id': _userId,
          'title': title,
          'description': description,
          'target_value': targetValue,
          'current_value': 0,
          'goal_type': goalType,
          'is_completed': false,
          'created_at': now.toIso8601String(),
          'updated_at': now.toIso8601String(),
        });
      } catch (_) {
        // Saved locally, will sync later
      }
    }
  }

  Future<void> updateGoalProgress(String goalId, int newValue) async {
    final goalIndex = state.goals.indexWhere((g) => g.id == goalId);
    if (goalIndex == -1) return;

    final goal = state.goals[goalIndex];
    final isCompleted = newValue >= goal.targetValue;

    final updated = List<Goal>.from(state.goals);
    updated[goalIndex] = goal.copyWith(currentValue: newValue, isCompleted: isCompleted);
    state = state.copyWith(goals: updated);
    _cacheGoals(updated);

    if (_isLoggedIn) {
      try {
        await _supabase.from('goals').update({
          'current_value': newValue,
          'is_completed': isCompleted,
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('id', goalId);
      } catch (_) {}
    }
  }

  Future<void> deleteGoal(String goalId) async {
    final updated = state.goals.where((g) => g.id != goalId).toList();
    state = state.copyWith(goals: updated);
    _cacheGoals(updated);

    if (_isLoggedIn) {
      try {
        await _supabase.from('goals').delete().eq('id', goalId);
      } catch (_) {}
    }
  }

  Future<void> _syncGoalToServer(Goal goal) async {
    if (!_isLoggedIn) return;
    try {
      await _supabase.from('goals').upsert({
        'id': goal.id,
        'user_id': _userId,
        'title': goal.title,
        'description': goal.description,
        'target_value': goal.targetValue,
        'current_value': goal.currentValue,
        'goal_type': goal.goalType,
        'is_completed': goal.isCompleted,
        'created_at': goal.createdAt.toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (_) {}
  }

  Future<void> _cacheGoals(List<Goal> goals) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = goals.map((g) => g.toJson()).toList();
      await prefs.setString('cached_goals', jsonEncode(jsonList));
    } catch (_) {}
  }

  Future<List<Goal>> _loadLocalGoals() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString('cached_goals');
      if (cached != null) {
        final List<dynamic> jsonList = jsonDecode(cached);
        return jsonList.map((g) => Goal.fromJson(g)).toList();
      }
    } catch (_) {}
    return [];
  }
}

final goalsProvider = StateNotifierProvider<GoalsNotifier, GoalsState>(
  (ref) => GoalsNotifier(),
);