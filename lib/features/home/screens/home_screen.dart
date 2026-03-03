// lib/features/home/screens/home_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:islam_focus_flutter/features/home/screens/focus_tab.dart';
import 'package:islam_focus_flutter/features/stats/screens/stats_tab.dart';
import 'package:islam_focus_flutter/features/goals/screens/goals_tab.dart';

/// Current tab index provider
final currentTabProvider = StateProvider<int>((ref) => 0);

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentTab = ref.watch(currentTabProvider);
    final theme = Theme.of(context);

    return Scaffold(
      body: IndexedStack(
        index: currentTab,
        children: const [
          FocusTab(),
          StatsTab(),
          GoalsTab(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: currentTab,
          onTap: (index) => ref.read(currentTabProvider.notifier).state = index,
          selectedLabelStyle: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: GoogleFonts.poppins(fontSize: 11),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.self_improvement_rounded),
              activeIcon: Icon(Icons.self_improvement_rounded),
              label: 'Focus',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.bar_chart_rounded),
              activeIcon: Icon(Icons.bar_chart_rounded),
              label: 'Statistics',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.flag_rounded),
              activeIcon: Icon(Icons.flag_rounded),
              label: 'Goals',
            ),
          ],
        ),
      ),
    );
  }
}
