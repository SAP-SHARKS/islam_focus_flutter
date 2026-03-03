// lib/features/blocking/screens/blocked_apps_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:islam_focus_flutter/features/blocking/providers/blocking_provider.dart';

class BlockedAppsScreen extends ConsumerStatefulWidget {
  const BlockedAppsScreen({super.key});

  @override
  ConsumerState<BlockedAppsScreen> createState() => _BlockedAppsScreenState();
}

class _BlockedAppsScreenState extends ConsumerState<BlockedAppsScreen> {
  String _searchQuery = '';
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final blockState = ref.watch(blockingProvider);
    final filteredApps = blockState.installedApps.where((app) {
      return app.appName.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    // Separate blocked and unblocked
    final blockedApps = filteredApps
        .where((app) => blockState.blockedPackages.contains(app.packageName))
        .toList();
    final unblockedApps = filteredApps
        .where((app) => !blockState.blockedPackages.contains(app.packageName))
        .toList();

    return Scaffold(
      backgroundColor: const Color(0xFFFDF8F4),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFDF8F4),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: Color(0xFF1A1A1A)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Select Apps to Block',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1A1A1A),
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _searchQuery = v),
              style: GoogleFonts.poppins(fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Search apps...',
                hintStyle: GoogleFonts.poppins(fontSize: 14, color: const Color(0xFFAAAAAA)),
                prefixIcon: const Icon(Icons.search, color: Color(0xFF999999), size: 20),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFFE8E8E8)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFFE8E8E8)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFF1DB954)),
                ),
              ),
            ),
          ),

          // Blocked count
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1DB954).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${blockState.blockedPackages.length} apps blocked',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1DB954),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // App list
          Expanded(
            child: blockState.isLoadingApps
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF1DB954)))
                : ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    children: [
                      // Blocked apps section
                      if (blockedApps.isNotEmpty) ...[
                        _sectionHeader('BLOCKED APPS', blockedApps.length),
                        const SizedBox(height: 8),
                        ...blockedApps.map((app) => _AppTile(
                              app: app,
                              isBlocked: true,
                              onTap: () => ref
                                  .read(blockingProvider.notifier)
                                  .toggleAppBlocking(app.packageName),
                            )),
                        const SizedBox(height: 20),
                      ],

                      // All apps section
                      _sectionHeader('ALL APPS', unblockedApps.length),
                      const SizedBox(height: 8),
                      ...unblockedApps.map((app) => _AppTile(
                            app: app,
                            isBlocked: false,
                            onTap: () => ref
                                .read(blockingProvider.notifier)
                                .toggleAppBlocking(app.packageName),
                          )),
                      const SizedBox(height: 20),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title, int count) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        '$title ($count)',
        style: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF999999),
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

/// Single app tile
class _AppTile extends StatelessWidget {
  final InstalledApp app;
  final bool isBlocked;
  final VoidCallback onTap;

  const _AppTile({
    required this.app,
    required this.isBlocked,
    required this.onTap,
  });

  IconData _getAppIcon(String packageName) {
    if (packageName.contains('instagram')) return Icons.camera_alt_rounded;
    if (packageName.contains('facebook')) return Icons.facebook_rounded;
    if (packageName.contains('tiktok') || packageName.contains('musically')) return Icons.music_note_rounded;
    if (packageName.contains('twitter')) return Icons.tag_rounded;
    if (packageName.contains('snapchat')) return Icons.chat_bubble_rounded;
    if (packageName.contains('youtube')) return Icons.play_circle_filled_rounded;
    if (packageName.contains('whatsapp')) return Icons.message_rounded;
    if (packageName.contains('reddit')) return Icons.forum_rounded;
    if (packageName.contains('discord')) return Icons.headset_mic_rounded;
    if (packageName.contains('spotify')) return Icons.library_music_rounded;
    if (packageName.contains('netflix')) return Icons.movie_rounded;
    if (packageName.contains('telegram')) return Icons.send_rounded;
    if (packageName.contains('pinterest')) return Icons.push_pin_rounded;
    if (packageName.contains('linkedin')) return Icons.work_rounded;
    if (packageName.contains('pubg') || packageName.contains('clash') || packageName.contains('candy') || packageName.contains('genshin')) {
      return Icons.sports_esports_rounded;
    }
    return Icons.apps_rounded;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            child: Row(
              children: [
                // App icon
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: isBlocked
                        ? const Color(0xFF1DB954).withOpacity(0.1)
                        : const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getAppIcon(app.packageName),
                    color: isBlocked
                        ? const Color(0xFF1DB954)
                        : const Color(0xFF888888),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),

                // App name
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        app.appName,
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF1A1A1A),
                        ),
                      ),
                      Text(
                        app.packageName,
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: const Color(0xFFBBBBBB),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                // Toggle
                Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(7),
                    color: isBlocked ? const Color(0xFF1DB954) : Colors.transparent,
                    border: Border.all(
                      color: isBlocked ? const Color(0xFF1DB954) : const Color(0xFFCCCCCC),
                      width: 2,
                    ),
                  ),
                  child: isBlocked
                      ? const Icon(Icons.check, size: 18, color: Colors.white)
                      : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
