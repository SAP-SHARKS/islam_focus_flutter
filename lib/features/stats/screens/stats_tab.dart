// lib/features/stats/screens/stats_tab.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:islam_focus_flutter/core/widgets/common_widgets.dart';

class StatsTab extends ConsumerWidget {
  const StatsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Statistics',
              style: GoogleFonts.poppins(
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Track your spiritual journey',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 24),

            // Period Selector
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurface.withOpacity(0.06),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  _PeriodTab(label: 'Week', isSelected: true),
                  _PeriodTab(label: 'Month', isSelected: false),
                  _PeriodTab(label: 'Year', isSelected: false),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Stats Cards
            Row(
              children: [
                Expanded(
                  child: StatCard(
                    title: 'Total Dhikr',
                    value: '0',
                    icon: Icons.favorite_rounded,
                    iconColor: theme.colorScheme.secondary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: StatCard(
                    title: 'Sessions',
                    value: '0',
                    icon: Icons.air_rounded,
                    iconColor: theme.primaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: StatCard(
                    title: 'Apps Blocked',
                    value: '0',
                    icon: Icons.block_rounded,
                    iconColor: theme.colorScheme.error,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: StatCard(
                    title: 'Streak',
                    value: '0 days',
                    icon: Icons.local_fire_department_rounded,
                    iconColor: Colors.orange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),

            // Chart Placeholder
            const SectionHeader(title: 'Weekly Overview'),
            const SizedBox(height: 12),
            Card(
              child: Container(
                width: double.infinity,
                height: 200,
                padding: const EdgeInsets.all(20),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.bar_chart_rounded,
                        size: 48,
                        color: theme.primaryColor.withOpacity(0.3),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Start tracking to see your progress',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: theme.colorScheme.onSurface.withOpacity(0.5),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 28),

            // Achievements
            const SectionHeader(title: 'Achievements'),
            const SizedBox(height: 12),
            const _AchievementCard(
              icon: Icons.stars_rounded,
              title: 'First Dhikr',
              subtitle: 'Complete your first dhikr session',
              isUnlocked: false,
            ),
            const SizedBox(height: 8),
            const _AchievementCard(
              icon: Icons.air_rounded,
              title: 'Mindful Breather',
              subtitle: 'Complete 10 breathing exercises',
              isUnlocked: false,
            ),
            const SizedBox(height: 8),
            const _AchievementCard(
              icon: Icons.local_fire_department_rounded,
              title: '7-Day Streak',
              subtitle: 'Use the app for 7 consecutive days',
              isUnlocked: false,
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class _PeriodTab extends StatelessWidget {
  final String label;
  final bool isSelected;

  const _PeriodTab({required this.label, required this.isSelected});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? theme.primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
          child: Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              color: isSelected ? Colors.white : theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ),
      ),
    );
  }
}

class _AchievementCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isUnlocked;

  const _AchievementCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isUnlocked,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: ListTile(
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: isUnlocked
                ? Colors.amber.withOpacity(0.15)
                : theme.colorScheme.onSurface.withOpacity(0.06),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: isUnlocked ? Colors.amber : theme.colorScheme.onSurface.withOpacity(0.3),
          ),
        ),
        title: Text(
          title,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: isUnlocked
                ? theme.colorScheme.onSurface
                : theme.colorScheme.onSurface.withOpacity(0.5),
          ),
        ),
        subtitle: Text(
          subtitle,
          style: GoogleFonts.poppins(fontSize: 12),
        ),
        trailing: isUnlocked
            ? const Icon(Icons.check_circle, color: Colors.amber)
            : Icon(Icons.lock_outline, color: theme.colorScheme.onSurface.withOpacity(0.3)),
      ),
    );
  }
}
