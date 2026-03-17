import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:islam_focus_flutter/features/stats/providers/stats_provider.dart';

final appUsageProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  try {
    const channel = MethodChannel('com.example.islamfocus/usage_stats');
    final result = await channel.invokeMethod('getAppUsageStats', {'days': 1});
    if (result != null) {
      return (result as List).map((e) => Map<String, dynamic>.from(e)).toList();
    }
  } catch (_) {}
  return [];
});

final appIconProvider = FutureProvider.family<Uint8List?, String>((ref, packageName) async {
  try {
    const channel = MethodChannel('com.example.islamfocus/usage_stats');
    final result = await channel.invokeMethod('getAppIcon', {'packageName': packageName});
    if (result != null && result is String && result.isNotEmpty) {
      return base64Decode(result);
    }
  } catch (_) {}
  return null;
});

class FocusTab extends ConsumerWidget {
  const FocusTab({super.key});

  String _formatDuration(int ms) {
    final totalSeconds = ms ~/ 1000;
    final minutes = totalSeconds ~/ 60;
    final hours = minutes ~/ 60;
    final remainMinutes = minutes % 60;
    if (hours > 0) return '${hours}h ${remainMinutes}m';
    if (minutes > 0) return '${minutes}m';
    final seconds = totalSeconds % 60;
    if (seconds > 0) return '${seconds}s';
    return '0s';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final stats = ref.watch(statsProvider);
    final usageAsync = ref.watch(appUsageProvider);

    int totalScreenTimeMs = 0;
    List<Map<String, dynamic>> topApps = [];

    usageAsync.whenData((usageData) {
      for (final app in usageData) {
        final timeMs = (app['totalTimeMs'] as num?)?.toInt() ?? 0;
        totalScreenTimeMs += timeMs;
        if (timeMs > 60000) topApps.add(app);
      }
      topApps.sort((a, b) => ((b['totalTimeMs'] as num?)?.toInt() ?? 0)
          .compareTo((a['totalTimeMs'] as num?)?.toInt() ?? 0));
      if (topApps.length > 10) topApps = topApps.sublist(0, 10);
    });

    final isLoading = usageAsync.isLoading;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),

              // Daily Quote
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFFE8E8E8)),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.primaryColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.format_quote_rounded, color: theme.primaryColor, size: 24),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '"Verily, in the remembrance of Allah do hearts find rest."',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 16, fontWeight: FontWeight.w600,
                        color: const Color(0xFF1A1A1A), height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text("Surah Ar-Ra'd 13:28",
                        style: GoogleFonts.poppins(fontSize: 13, color: const Color(0xFF888888), fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Stats Cards - Skeleton ya real
              isLoading
                  ? _SkeletonStatCards()
                  : Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _StatCard(
                                label: 'Screen Time Today',
                                value: _formatDuration(totalScreenTimeMs),
                                icon: Icons.phone_android_rounded,
                                color: const Color(0xFFFF5722),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _StatCard(
                                label: 'Ayat Recited',
                                value: '${stats.totalAyatRecitation}',
                                icon: Icons.menu_book_rounded,
                                color: const Color(0xFF1DB954),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _StatCard(
                                label: 'Blocked Apps',
                                value: '${stats.appsBlocked}',
                                icon: Icons.block_rounded,
                                color: const Color(0xFFE91E63),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _StatCard(
                                label: 'Dhikr Count',
                                value: '${stats.totalDhikr}',
                                icon: Icons.favorite_rounded,
                                color: const Color(0xFF4285F4),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

              const SizedBox(height: 28),

              // Today's App Usage
              Text("Today's App Usage",
                  style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF1A1A1A))),
              const SizedBox(height: 16),

              if (isLoading)
                Column(children: List.generate(5, (_) => const _SkeletonAppCard()))
              else if (topApps.isNotEmpty)
                ...topApps.map((app) {
                  final timeMs = (app['totalTimeMs'] as num?)?.toInt() ?? 0;
                  final isBlocked = app['isBlocked'] as bool? ?? false;
                  final maxTime = (topApps.first['totalTimeMs'] as num?)?.toInt() ?? 1;
                  final progress = timeMs / maxTime;
                  final appName = app['appName']?.toString() ?? app['packageName']?.toString() ?? '';
                  final packageName = app['packageName']?.toString() ?? '';

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isBlocked ? const Color(0xFFFFCDD2) : const Color(0xFFE8E8E8),
                        ),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              _AppIcon(packageName: packageName, isBlocked: isBlocked, ref: ref),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(appName,
                                    style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500, color: const Color(0xFF1A1A1A)),
                                    overflow: TextOverflow.ellipsis),
                              ),
                              if (isBlocked)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(color: const Color(0xFFFFEBEE), borderRadius: BorderRadius.circular(6)),
                                  child: Text('Blocked', style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w600, color: const Color(0xFFE91E63))),
                                ),
                              const SizedBox(width: 8),
                              Text(_formatDuration(timeMs),
                                  style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF333333))),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: progress,
                              backgroundColor: const Color(0xFFF0F0F0),
                              valueColor: AlwaysStoppedAnimation(
                                isBlocked ? const Color(0xFFE91E63) : const Color(0xFF1DB954),
                              ),
                              minHeight: 4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                })
              else
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0xFFE8E8E8)),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.phone_android_rounded, size: 48, color: theme.primaryColor.withOpacity(0.15)),
                      const SizedBox(height: 16),
                      Text('Usage data will appear here\nas you use your phone today.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(fontSize: 14, color: const Color(0xFF888888), height: 1.5)),
                    ],
                  ),
                ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

// ===== SKELETON STAT CARDS =====
class _SkeletonStatCards extends StatefulWidget {
  @override
  State<_SkeletonStatCards> createState() => _SkeletonStatCardsState();
}

class _SkeletonStatCardsState extends State<_SkeletonStatCards>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.3, end: 0.7).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, _) {
        final c = Color.lerp(const Color(0xFFE8E8E8), const Color(0xFFF5F5F5), _animation.value)!;
        return Column(
          children: [
            Row(
              children: [
                Expanded(child: _skeletonCard(c)),
                const SizedBox(width: 16),
                Expanded(child: _skeletonCard(c)),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _skeletonCard(c)),
                const SizedBox(width: 16),
                Expanded(child: _skeletonCard(c)),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _skeletonCard(Color c) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE8E8E8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(width: 36, height: 36, decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(10))),
          const SizedBox(height: 14),
          Container(height: 22, width: 70, decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(6))),
          const SizedBox(height: 6),
          Container(height: 12, width: 100, decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(6))),
        ],
      ),
    );
  }
}

// ===== SKELETON APP CARD =====
class _SkeletonAppCard extends StatefulWidget {
  const _SkeletonAppCard();

  @override
  State<_SkeletonAppCard> createState() => _SkeletonAppCardState();
}

class _SkeletonAppCardState extends State<_SkeletonAppCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.3, end: 0.7).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final shimmerColor = Color.lerp(const Color(0xFFE8E8E8), const Color(0xFFF5F5F5), _animation.value)!;
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE8E8E8)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(width: 40, height: 40, decoration: BoxDecoration(color: shimmerColor, borderRadius: BorderRadius.circular(12))),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(height: 14, width: double.infinity, decoration: BoxDecoration(color: shimmerColor, borderRadius: BorderRadius.circular(6))),
                          const SizedBox(height: 6),
                          Container(height: 10, width: 80, decoration: BoxDecoration(color: shimmerColor, borderRadius: BorderRadius.circular(6))),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(height: 14, width: 40, decoration: BoxDecoration(color: shimmerColor, borderRadius: BorderRadius.circular(6))),
                  ],
                ),
                const SizedBox(height: 10),
                Container(height: 4, width: double.infinity, decoration: BoxDecoration(color: shimmerColor, borderRadius: BorderRadius.circular(4))),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ===== APP ICON =====
class _AppIcon extends StatelessWidget {
  final String packageName;
  final bool isBlocked;
  final WidgetRef ref;

  const _AppIcon({required this.packageName, required this.isBlocked, required this.ref});

  @override
  Widget build(BuildContext context) {
    final iconAsync = ref.watch(appIconProvider(packageName));
    return Container(
      width: 40, height: 40,
      decoration: BoxDecoration(
        color: isBlocked ? const Color(0xFFFFEBEE) : const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: iconAsync.when(
        data: (iconBytes) {
          if (iconBytes != null && iconBytes.isNotEmpty) {
            return Image.memory(iconBytes, width: 40, height: 40, fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _fallbackIcon());
          }
          return _fallbackIcon();
        },
        loading: () => const Center(child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 1.5, color: Color(0xFF1DB954)))),
        error: (_, __) => _fallbackIcon(),
      ),
    );
  }

  Widget _fallbackIcon() {
    return Icon(isBlocked ? Icons.block_rounded : Icons.apps_rounded,
        color: isBlocked ? const Color(0xFFE91E63) : const Color(0xFF888888), size: 22);
  }
}

// ===== STAT CARD =====
class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE8E8E8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 14),
          Text(value, style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold, color: const Color(0xFF1A1A1A))),
          Text(label, style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFF888888), fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}