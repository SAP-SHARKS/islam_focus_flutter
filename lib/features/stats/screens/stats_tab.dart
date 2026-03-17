import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:islam_focus_flutter/features/stats/providers/stats_provider.dart';

class StatsTab extends ConsumerWidget {
  const StatsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final stats = ref.watch(statsProvider);
    final selectedPeriod = ref.watch(selectedPeriodProvider);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: stats.isLoading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFF1DB954)))
            : SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Statistics', style: GoogleFonts.poppins(fontSize: 28, fontWeight: FontWeight.bold, color: const Color(0xFF1A1A1A))),
                    const SizedBox(height: 4),
                    Text('Your spiritual overview', style: GoogleFonts.poppins(fontSize: 15, color: const Color(0xFF888888), fontWeight: FontWeight.w500)),
                    const SizedBox(height: 32),

                    // Period Selector
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE8E8E8))),
                      child: Row(children: [
                        _PeriodTab(label: 'Week', isSelected: selectedPeriod == StatsPeriod.week, color: theme.primaryColor,
                          onTap: () { ref.read(selectedPeriodProvider.notifier).state = StatsPeriod.week; ref.read(statsProvider.notifier).loadStats(StatsPeriod.week); }),
                        _PeriodTab(label: 'Month', isSelected: selectedPeriod == StatsPeriod.month, color: theme.primaryColor,
                          onTap: () { ref.read(selectedPeriodProvider.notifier).state = StatsPeriod.month; ref.read(statsProvider.notifier).loadStats(StatsPeriod.month); }),
                        _PeriodTab(label: 'Year', isSelected: selectedPeriod == StatsPeriod.year, color: theme.primaryColor,
                          onTap: () { ref.read(selectedPeriodProvider.notifier).state = StatsPeriod.year; ref.read(statsProvider.notifier).loadStats(StatsPeriod.year); }),
                      ]),
                    ),
                    const SizedBox(height: 32),

                    // Stats Cards
                    Row(children: [
                      Expanded(child: _StatGridCard(label: 'Total Dhikr', value: _formatNumber(stats.totalDhikr), icon: Icons.favorite_rounded, color: const Color(0xFFFF5722))),
                      const SizedBox(width: 16),
                      Expanded(child: _StatGridCard(label: 'Ayat Recited', value: '${stats.totalAyatRecitation}', icon: Icons.menu_book_rounded, color: const Color(0xFF4285F4))),
                    ]),
                    const SizedBox(height: 16),
                    Row(children: [
                      Expanded(child: _StatGridCard(label: 'Apps Blocked', value: '${stats.appsBlocked}', icon: Icons.block_rounded, color: const Color(0xFFE91E63))),
                      const SizedBox(width: 16),
                      Expanded(child: _StatGridCard(label: 'Current Streak', value: '${stats.currentStreak} d', icon: Icons.local_fire_department_rounded, color: const Color(0xFFFF9800))),
                    ]),
                    const SizedBox(height: 32),

                    // Dhikr Bar Graph
                    _BarGraphCard(
                      title: 'Dhikr Activity',
                      icon: Icons.favorite_rounded,
                      iconColor: const Color(0xFFFF5722),
                      barColor: const Color(0xFFFF5722),
                      data: stats.dailyDhikr,
                      period: selectedPeriod,
                      emptyMessage: 'Start doing dhikr to see your activity',
                    ),
                    const SizedBox(height: 20),

                    // Ayat Recitation Bar Graph
                    _BarGraphCard(
                      title: 'Ayat Recitation',
                      icon: Icons.menu_book_rounded,
                      iconColor: const Color(0xFF4285F4),
                      barColor: const Color(0xFF4285F4),
                      data: stats.dailyAyat,
                      period: selectedPeriod,
                      emptyMessage: 'Start reading Quran to see your activity',
                    ),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
      ),
    );
  }

  String _formatNumber(int n) {
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}k';
    return '$n';
  }
}

// ===== BAR GRAPH CARD =====
class _BarGraphCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color iconColor;
  final Color barColor;
  final List<DailyDhikr> data;
  final StatsPeriod period;
  final String emptyMessage;

  const _BarGraphCard({
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.barColor,
    required this.data,
    required this.period,
    required this.emptyMessage,
  });

  List<_BarData> _prepareData() {
    if (data.isEmpty) return [];

    final now = DateTime.now();
    final Map<String, int> grouped = {};

    switch (period) {
      case StatsPeriod.week:
        // Show last 7 days
        for (int i = 6; i >= 0; i--) {
          final date = now.subtract(Duration(days: i));
          final key = '${date.day}/${date.month}';
          grouped[key] = 0;
        }
        for (final d in data) {
          final key = '${d.date.day}/${d.date.month}';
          if (grouped.containsKey(key)) {
            grouped[key] = (grouped[key] ?? 0) + d.count;
          }
        }
        break;

      case StatsPeriod.month:
        // Show last 4 weeks
        for (int i = 3; i >= 0; i--) {
          final weekStart = now.subtract(Duration(days: i * 7 + now.weekday - 1));
          final key = 'W${4 - i}';
          grouped[key] = 0;
        }
        for (final d in data) {
          final weeksAgo = now.difference(d.date).inDays ~/ 7;
          if (weeksAgo < 4) {
            final key = 'W${4 - weeksAgo}';
            grouped[key] = (grouped[key] ?? 0) + d.count;
          }
        }
        break;

      case StatsPeriod.year:
        // Show last 12 months
        for (int i = 11; i >= 0; i--) {
          final month = DateTime(now.year, now.month - i, 1);
          final monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
          final key = monthNames[month.month - 1];
          grouped[key] = 0;
        }
        for (final d in data) {
          final monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
          final key = monthNames[d.date.month - 1];
          if (grouped.containsKey(key)) {
            grouped[key] = (grouped[key] ?? 0) + d.count;
          }
        }
        break;
    }

    return grouped.entries.map((e) => _BarData(label: e.key, value: e.value)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final bars = _prepareData();
    final total = bars.fold<int>(0, (sum, b) => sum + b.value);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE8E8E8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: iconColor.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, color: iconColor, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(title, style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF1A1A1A))),
              ),
              Text('Total: $total', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: iconColor)),
            ],
          ),
          const SizedBox(height: 24),

          // Bar Graph or Empty
          if (bars.isEmpty || total == 0)
            SizedBox(
              height: 100,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.bar_chart_rounded, size: 40, color: iconColor.withOpacity(0.15)),
                    const SizedBox(height: 8),
                    Text(emptyMessage, style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFF888888)), textAlign: TextAlign.center),
                  ],
                ),
              ),
            )
          else
            SizedBox(
              height: 160,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: bars.map((bar) {
                  final maxVal = bars.map((b) => b.value).reduce((a, b) => a > b ? a : b);
                  final barHeight = maxVal > 0 ? (bar.value / maxVal) * 110.0 : 0.0;

                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          // Value on top
                          Text(
                            bar.value > 0 ? '${bar.value}' : '',
                            style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w600, color: barColor),
                          ),
                          const SizedBox(height: 4),
                          // Bar
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            height: barHeight < 4 && bar.value > 0 ? 4 : barHeight,
                            decoration: BoxDecoration(
                              color: bar.value > 0 ? barColor : barColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(height: 6),
                          // Label
                          Text(
                            bar.label,
                            style: GoogleFonts.poppins(fontSize: period == StatsPeriod.year ? 8 : 10, color: const Color(0xFF999999)),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }
}

class _BarData {
  final String label;
  final int value;
  _BarData({required this.label, required this.value});
}

// ===== PERIOD TAB =====
class _PeriodTab extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;
  const _PeriodTab({required this.label, required this.isSelected, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(color: isSelected ? color : Colors.transparent, borderRadius: BorderRadius.circular(12)),
          child: Center(
            child: Text(label, style: GoogleFonts.poppins(fontSize: 14, fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500, color: isSelected ? Colors.white : const Color(0xFF888888))),
          ),
        ),
      ),
    );
  }
}

// ===== STAT CARD =====
class _StatGridCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _StatGridCard({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFE8E8E8))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 16),
          Text(value, style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold, color: const Color(0xFF1A1A1A))),
          Text(label, style: GoogleFonts.poppins(fontSize: 13, color: const Color(0xFF888888), fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}