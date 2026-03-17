import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:islam_focus_flutter/features/goals/providers/goals_provider.dart';

class GoalsTab extends ConsumerWidget {
  const GoalsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final goalsState = ref.watch(goalsProvider);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: goalsState.isLoading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFF1DB954)))
            : SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'My Goals',
                      style: GoogleFonts.poppins(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1A1A1A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Your spiritual objectives',
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        color: const Color(0xFF888888),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 32),

                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: () => _showAddGoalDialog(context, ref),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.primaryColor,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.add_rounded, size: 20),
                            const SizedBox(width: 8),
                            Text('Add New Goal', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 16)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    if (goalsState.goals.isEmpty)
                      _buildEmptyState(theme)
                    else
                      ...goalsState.goals.map((goal) => Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: _GoalCard(goal: goal),
                          )),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE8E8E8)),
      ),
      child: Column(
        children: [
          Icon(Icons.flag_rounded, size: 48, color: theme.primaryColor.withOpacity(0.15)),
          const SizedBox(height: 16),
          Text(
            'No goals yet!\nTap "Add New Goal" to get started.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(fontSize: 14, color: const Color(0xFF888888), height: 1.5),
          ),
        ],
      ),
    );
  }

  void _showAddGoalDialog(BuildContext context, WidgetRef ref) {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    final targetController = TextEditingController(text: '100');
    String selectedType = 'custom';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return DraggableScrollableSheet(
              initialChildSize: 0.85,
              minChildSize: 0.5,
              maxChildSize: 0.95,
              expand: false,
              builder: (context, scrollController) {
                return SingleChildScrollView(
                  controller: scrollController,
                  padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40, height: 4,
                          decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text('Add New Goal', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 20),

                      Text('Goal Type', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF888888))),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _GoalTypeChip(label: 'Dhikr', value: 'dhikr', selected: selectedType, onTap: (v) => setModalState(() => selectedType = v)),
                          _GoalTypeChip(label: 'Quran', value: 'quran', selected: selectedType, onTap: (v) => setModalState(() => selectedType = v)),
                          _GoalTypeChip(label: 'Digital Fast', value: 'digital_fast', selected: selectedType, onTap: (v) => setModalState(() => selectedType = v)),
                          _GoalTypeChip(label: 'Custom', value: 'custom', selected: selectedType, onTap: (v) => setModalState(() => selectedType = v)),
                        ],
                      ),
                      const SizedBox(height: 20),

                      TextField(
                        controller: titleController,
                        decoration: const InputDecoration(labelText: 'Goal Title', hintText: 'e.g., Read Quran daily'),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: descController,
                        decoration: const InputDecoration(labelText: 'Description (optional)', hintText: 'e.g., Read at least 1 page after Fajr'),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: targetController,
                        decoration: const InputDecoration(labelText: 'Target Value', hintText: 'e.g., 100'),
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 28),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: () {
                            final title = titleController.text.trim();
                            if (title.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Text('Please enter a goal title'),
                                  backgroundColor: Colors.red.shade600,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                              );
                              return;
                            }

                            ref.read(goalsProvider.notifier).addGoal(
                                  title: title,
                                  description: descController.text.trim(),
                                  targetValue: int.tryParse(targetController.text) ?? 100,
                                  goalType: selectedType,
                                );
                            Navigator.pop(context);
                          },
                          child: const Text('Add Goal'),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}

class _GoalTypeChip extends StatelessWidget {
  final String label;
  final String value;
  final String selected;
  final Function(String) onTap;

  const _GoalTypeChip({required this.label, required this.value, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isSelected = selected == value;
    return GestureDetector(
      onTap: () => onTap(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1DB954) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? const Color(0xFF1DB954) : const Color(0xFFE0E0E0)),
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : const Color(0xFF666666),
          ),
        ),
      ),
    );
  }
}

class _GoalCard extends ConsumerWidget {
  final Goal goal;
  const _GoalCard({required this.goal});

  Color _getGoalColor(String type) {
    switch (type) {
      case 'dhikr': return const Color(0xFFFF5722);
      case 'quran': return const Color(0xFF4285F4);
      case 'digital_fast': return const Color(0xFF1DB954);
      default: return const Color(0xFF9C27B0);
    }
  }

  IconData _getGoalIcon(String type) {
    switch (type) {
      case 'dhikr': return Icons.favorite_rounded;
      case 'quran': return Icons.menu_book_rounded;
      case 'digital_fast': return Icons.phone_android_rounded;
      default: return Icons.flag_rounded;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = _getGoalColor(goal.goalType);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE8E8E8)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(_getGoalIcon(goal.goalType), color: color, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(goal.title, style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: const Color(0xFF1A1A1A))),
                    if (goal.description.isNotEmpty)
                      Text(goal.description, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.poppins(fontSize: 13, color: const Color(0xFF888888))),
                  ],
                ),
              ),
              Text(
                '${goal.progressPercent}%',
                style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: color),
              ),
            ],
          ),
          const SizedBox(height: 16),

          Stack(
            children: [
              Container(
                height: 8, width: double.infinity,
                decoration: BoxDecoration(color: const Color(0xFFF5F5F5), borderRadius: BorderRadius.circular(4)),
              ),
              FractionallySizedBox(
                widthFactor: goal.progress,
                child: Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              Text(
                '${goal.currentValue} / ${goal.targetValue}',
                style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFF999999)),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () {
                  final newValue = goal.currentValue + 1;
                  ref.read(goalsProvider.notifier).updateGoalProgress(goal.id, newValue);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text('+1', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: color)),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      title: const Text('Delete Goal?'),
                      content: Text('Are you sure you want to delete "${goal.title}"?'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                        TextButton(
                          onPressed: () {
                            ref.read(goalsProvider.notifier).deleteGoal(goal.id);
                            Navigator.pop(ctx);
                          },
                          child: const Text('Delete', style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),
                  );
                },
                child: const Icon(Icons.delete_outline_rounded, size: 20, color: Color(0xFFCCCCCC)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}