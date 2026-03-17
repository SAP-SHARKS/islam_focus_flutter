import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:islam_focus_flutter/features/blocking/providers/blocking_provider.dart';
import 'package:islam_focus_flutter/features/auth/screens/auth_gate.dart';

// Usage data provider for "Most Used" tab
final appUsageDataProvider = FutureProvider<Map<String, int>>((ref) async {
  try {
    const channel = MethodChannel('com.example.islamfocus/usage_stats');
    final result = await channel.invokeMethod('getAppUsageStats', {'days': 7});
    if (result != null) {
      final Map<String, int> usageMap = {};
      for (final app in (result as List)) {
        final pkg = app['packageName']?.toString() ?? '';
        final time = (app['totalTimeMs'] as num?)?.toInt() ?? 0;
        if (pkg.isNotEmpty && time > 60000) {
          usageMap[pkg] = time;
        }
      }
      return usageMap;
    }
  } catch (_) {}
  return {};
});

String _formatDuration(int ms) {
  final minutes = ms ~/ 60000;
  final hours = minutes ~/ 60;
  final remainMinutes = minutes % 60;
  if (hours > 0) return '${hours}h ${remainMinutes}m this week';
  if (minutes > 0) return '${minutes}m this week';
  return '< 1m this week';
}

// ===== MAIN BLOCKED APPS SCREEN (from Settings) =====
class BlockedAppsScreen extends ConsumerStatefulWidget {
  const BlockedAppsScreen({super.key});
  @override
  ConsumerState<BlockedAppsScreen> createState() => _BlockedAppsScreenState();
}

class _BlockedAppsScreenState extends ConsumerState<BlockedAppsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final blockState = ref.watch(blockingProvider);
    final usageAsync = ref.watch(appUsageDataProvider);
    Map<String, int> usageMap = {};
    usageAsync.whenData((data) => usageMap = data);

    final allApps = List<InstalledApp>.from(blockState.installedApps);
    final blockedApps = allApps.where((a) => blockState.blockedPackages.contains(a.packageName)).toList();
    final mostUsedApps = List<InstalledApp>.from(allApps);
    mostUsedApps.sort((a, b) => (usageMap[b.packageName] ?? 0).compareTo(usageMap[a.packageName] ?? 0));
    final topUsed = mostUsedApps.where((a) => (usageMap[a.packageName] ?? 0) > 60000).toList();
    allApps.sort((a, b) => a.appName.toLowerCase().compareTo(b.appName.toLowerCase()));

    return Scaffold(
      backgroundColor: const Color(0xFFFDF8F4),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFDF8F4), elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: Color(0xFF1A1A1A)), onPressed: () => Navigator.pop(context)),
        title: Text('Select Apps to Lock', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: const Color(0xFF1A1A1A))),
      ),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            child: TabBar(
              controller: _tabController,
              labelColor: const Color(0xFF1A1A1A),
              unselectedLabelColor: const Color(0xFF999999),
              labelStyle: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600),
              unselectedLabelStyle: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w500),
              indicatorColor: const Color(0xFF1DB954),
              indicatorWeight: 3,
              labelPadding: const EdgeInsets.symmetric(horizontal: 4),
              tabs: [
                Tab(child: Text('Most Used (${topUsed.length})', overflow: TextOverflow.ellipsis, maxLines: 1)),
                Tab(child: Text('All Apps (${allApps.length})', overflow: TextOverflow.ellipsis, maxLines: 1)),
                Tab(child: Text('Locked (${blockedApps.length})', overflow: TextOverflow.ellipsis, maxLines: 1)),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: blockState.isLoadingApps
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF1DB954)))
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _AppList(apps: topUsed, blockState: blockState, ref: ref, usageMap: usageMap),
                      _AppList(apps: allApps, blockState: blockState, ref: ref, usageMap: usageMap),
                      _AppList(apps: blockedApps, blockState: blockState, ref: ref, usageMap: usageMap, emptyMsg: 'No locked apps yet'),
                    ],
                  ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            child: SizedBox(
              width: double.infinity, height: 56,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1DB954), foregroundColor: Colors.white, elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                child: Text('Save Changes', style: GoogleFonts.poppins(fontSize: 17, fontWeight: FontWeight.w600)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ===== FIRST TIME SETUP SCREEN =====
class FirstTimeBlockedAppsScreen extends ConsumerStatefulWidget {
  const FirstTimeBlockedAppsScreen({super.key});
  @override
  ConsumerState<FirstTimeBlockedAppsScreen> createState() => _FirstTimeBlockedAppsScreenState();
}

class _FirstTimeBlockedAppsScreenState extends ConsumerState<FirstTimeBlockedAppsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() { _tabController.dispose(); super.dispose(); }

  Future<void> _finishSetup() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('app_blocking_setup_complete', true);
    if (mounted) {
      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => AuthGate()), (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final blockState = ref.watch(blockingProvider);
    final usageAsync = ref.watch(appUsageDataProvider);
    Map<String, int> usageMap = {};
    usageAsync.whenData((data) => usageMap = data);

    final allApps = List<InstalledApp>.from(blockState.installedApps);
    final blockedApps = allApps.where((a) => blockState.blockedPackages.contains(a.packageName)).toList();
    final mostUsedApps = List<InstalledApp>.from(allApps);
    mostUsedApps.sort((a, b) => (usageMap[b.packageName] ?? 0).compareTo(usageMap[a.packageName] ?? 0));
    final topUsed = mostUsedApps.where((a) => (usageMap[a.packageName] ?? 0) > 60000).toList();
    allApps.sort((a, b) => a.appName.toLowerCase().compareTo(b.appName.toLowerCase()));

    return Scaffold(
      backgroundColor: const Color(0xFFFDF8F4),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Select Apps to Lock', style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold, color: const Color(0xFF1A1A1A))),
                const SizedBox(height: 8),
                Text('Choose apps you want Islam Focus to intervene before opening.', style: GoogleFonts.poppins(fontSize: 14, color: const Color(0xFF888888), height: 1.5)),
              ]),
            ),
            const SizedBox(height: 16),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              child: TabBar(
                controller: _tabController,
                labelColor: const Color(0xFF1A1A1A),
                unselectedLabelColor: const Color(0xFF999999),
                labelStyle: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600),
                unselectedLabelStyle: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w500),
                indicatorColor: const Color(0xFF1DB954),
                indicatorWeight: 3,
                labelPadding: const EdgeInsets.symmetric(horizontal: 4),
                tabs: [
                  Tab(child: Text('Most Used (${topUsed.length})', overflow: TextOverflow.ellipsis, maxLines: 1)),
                  Tab(child: Text('All Apps (${allApps.length})', overflow: TextOverflow.ellipsis, maxLines: 1)),
                  Tab(child: Text('Locked (${blockedApps.length})', overflow: TextOverflow.ellipsis, maxLines: 1)),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: blockState.isLoadingApps
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF1DB954)))
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _AppList(apps: topUsed, blockState: blockState, ref: ref, usageMap: usageMap),
                        _AppList(apps: allApps, blockState: blockState, ref: ref, usageMap: usageMap),
                        _AppList(apps: blockedApps, blockState: blockState, ref: ref, usageMap: usageMap, emptyMsg: 'No locked apps yet'),
                      ],
                    ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: SizedBox(
                width: double.infinity, height: 56,
                child: ElevatedButton(
                  onPressed: _finishSetup,
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1DB954), foregroundColor: Colors.white, elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                  child: Text(blockState.blockedPackages.isEmpty ? 'Skip for Now' : 'Save Changes', style: GoogleFonts.poppins(fontSize: 17, fontWeight: FontWeight.w600)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ===== APP LIST WIDGET =====
class _AppList extends StatelessWidget {
  final List<InstalledApp> apps;
  final BlockingState blockState;
  final WidgetRef ref;
  final Map<String, int> usageMap;
  final String? emptyMsg;

  const _AppList({required this.apps, required this.blockState, required this.ref, required this.usageMap, this.emptyMsg});

  @override
  Widget build(BuildContext context) {
    if (apps.isEmpty) {
      return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.apps_rounded, size: 48, color: const Color(0xFF1DB954).withOpacity(0.15)),
          const SizedBox(height: 16),
          Text(emptyMsg ?? 'No apps found', style: GoogleFonts.poppins(fontSize: 14, color: const Color(0xFF888888))),
        ]),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: apps.length,
      itemBuilder: (context, index) {
        final app = apps[index];
        final isBlocked = blockState.blockedPackages.contains(app.packageName);
        final usageTime = usageMap[app.packageName] ?? 0;

        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              onTap: () => ref.read(blockingProvider.notifier).toggleAppBlocking(app.packageName),
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    Container(
                      width: 48, height: 48,
                      decoration: BoxDecoration(
                        color: isBlocked ? const Color(0xFF1DB954).withOpacity(0.1) : const Color(0xFFF5F5F5),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        _getAppIcon(app.packageName),
                        color: isBlocked ? const Color(0xFF1DB954) : const Color(0xFF888888),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(app.appName, style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w500, color: const Color(0xFF1A1A1A))),
                          if (usageTime > 60000)
                            Text(_formatDuration(usageTime), style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFF999999)))
                          else
                            Text(app.packageName, style: GoogleFonts.poppins(fontSize: 11, color: const Color(0xFFBBBBBB)), overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                    Container(
                      width: 28, height: 28,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: isBlocked ? const Color(0xFF1DB954) : Colors.transparent,
                        border: Border.all(color: isBlocked ? const Color(0xFF1DB954) : const Color(0xFFCCCCCC), width: 2),
                      ),
                      child: isBlocked ? const Icon(Icons.check, size: 18, color: Colors.white) : null,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  IconData _getAppIcon(String pkg) {
    if (pkg.contains('whatsapp')) return Icons.message_rounded;
    if (pkg.contains('facebook')) return Icons.facebook_rounded;
    if (pkg.contains('instagram')) return Icons.camera_alt_rounded;
    if (pkg.contains('youtube')) return Icons.play_circle_filled_rounded;
    if (pkg.contains('tiktok') || pkg.contains('musically')) return Icons.music_note_rounded;
    if (pkg.contains('twitter')) return Icons.tag_rounded;
    if (pkg.contains('snapchat')) return Icons.chat_bubble_rounded;
    if (pkg.contains('telegram')) return Icons.send_rounded;
    if (pkg.contains('reddit')) return Icons.forum_rounded;
    if (pkg.contains('discord')) return Icons.headset_mic_rounded;
    if (pkg.contains('spotify')) return Icons.library_music_rounded;
    if (pkg.contains('netflix')) return Icons.movie_rounded;
    if (pkg.contains('chrome') || pkg.contains('browser')) return Icons.language_rounded;
    if (pkg.contains('game') || pkg.contains('pubg') || pkg.contains('clash')) return Icons.sports_esports_rounded;
    return Icons.apps_rounded;
  }
}