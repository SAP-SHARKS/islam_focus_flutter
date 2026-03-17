import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:islam_focus_flutter/features/blocking/providers/blocking_provider.dart';
import 'package:islam_focus_flutter/features/blocking/screens/blocked_apps_screen.dart';

class InterventionSettingsScreen extends ConsumerWidget {
  const InterventionSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final blockState = ref.watch(blockingProvider);
    final settings = blockState.interventionSettings;

    return Scaffold(
      backgroundColor: const Color(0xFFFDF8F4),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFDF8F4),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: Color(0xFF1A1A1A)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('App Blocking & Settings', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: const Color(0xFF1A1A1A))),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          const _SectionLabel(label: 'BLOCKED APPS'),
          const SizedBox(height: 8),
          _SettingsTile(icon: Icons.block_rounded, iconColor: Colors.red,
            title: 'Manage Blocked Apps', subtitle: '${blockState.blockedPackages.length} apps selected',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BlockedAppsScreen()))),
          const SizedBox(height: 24),

          const _SectionLabel(label: 'INTERVENTION BOOSTERS'),
          const SizedBox(height: 8),
          _SettingsTile(icon: Icons.tune_rounded, iconColor: const Color(0xFF6C63FF),
            title: 'Intervention Mode', subtitle: _modeLabel(settings.mode),
            onTap: () => _showModePicker(context, ref, settings)),
          if (settings.mode == 'standard_dhikr')
            _SettingsTile(icon: Icons.edit_rounded, iconColor: const Color(0xFF1DB954),
              title: 'Dhikr Text', subtitle: 'Currently: ${settings.dhikrText}',
              onTap: () => _showDhikrTextPicker(context, ref, settings)),
          _SettingsTile(icon: Icons.timer_rounded, iconColor: const Color(0xFFFF9800),
            title: 'Intervention Duration', subtitle: '${settings.breathingDurationSeconds} seconds',
            onTap: () => _showDurationPicker(context, ref, settings)),
          _SettingsTile(icon: Icons.palette_rounded, iconColor: const Color(0xFF00BCD4),
            title: 'Fill Color', subtitle: settings.fillColor,
            trailing: Container(width: 24, height: 24, decoration: BoxDecoration(color: _hexToColor(settings.fillColor), shape: BoxShape.circle, border: Border.all(color: const Color(0xFFE0E0E0)))),
            onTap: () => _showColorPicker(context, ref, settings)),
          const SizedBox(height: 24),

          const _SectionLabel(label: 'PERMISSIONS'),
          const SizedBox(height: 8),
          _SettingsTile(icon: Icons.accessibility_new_rounded, iconColor: const Color(0xFF2196F3),
            title: 'Accessibility Service', subtitle: blockState.accessibilityEnabled ? 'Enabled' : 'Required for app blocking',
            trailing: Text(blockState.accessibilityEnabled ? 'On' : 'Off', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: blockState.accessibilityEnabled ? const Color(0xFF1DB954) : Colors.red)),
            onTap: () => ref.read(blockingProvider.notifier).openAccessibilitySettings()),
          _SettingsTile(icon: Icons.data_usage_rounded, iconColor: const Color(0xFF4CAF50),
            title: 'App Usage Permission', subtitle: blockState.usagePermissionEnabled ? 'Enabled' : 'Required to detect apps',
            trailing: Text(blockState.usagePermissionEnabled ? 'On' : 'Off', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: blockState.usagePermissionEnabled ? const Color(0xFF1DB954) : Colors.red)),
            onTap: () => ref.read(blockingProvider.notifier).openUsageAccessSettings()),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  String _modeLabel(String mode) {
    switch (mode) {
      case 'standard_dhikr': return 'Standard Dhikr';
      case 'quran_verse': return 'Quran Verse';
      default: return 'Standard Dhikr';
    }
  }

  Color _hexToColor(String hex) {
    hex = hex.replaceAll('#', '');
    if (hex.length == 6) hex = 'FF$hex';
    return Color(int.parse(hex, radix: 16));
  }

  void _showModePicker(BuildContext context, WidgetRef ref, InterventionSettings settings) {
    _showOptionsPicker(context: context, title: 'Intervention Mode', options: [
      ('standard_dhikr', 'Standard Dhikr', 'Timer + tap to count dhikr'),
      ('quran_verse', 'Quran Verse', 'Read Quran ayat in sequence'),
    ], selected: settings.mode, onSelect: (val) => ref.read(blockingProvider.notifier).updateSettings(settings.copyWith(mode: val)));
  }

  void _showDhikrTextPicker(BuildContext context, WidgetRef ref, InterventionSettings settings) {
    _showOptionsPicker(context: context, title: 'Dhikr Text', options: [
      ('SubhanAllah', 'SubhanAllah', 'Glory be to Allah'),
      ('Alhamdulillah', 'Alhamdulillah', 'All praise is due to Allah'),
      ('Allahu Akbar', 'Allahu Akbar', 'Allah is the Greatest'),
      ('La ilaha illallah', 'La ilaha illallah', 'There is no god but Allah'),
      ('Astaghfirullah', 'Astaghfirullah', 'I seek forgiveness from Allah'),
      ('SubhanAllahi wa bihamdihi', 'SubhanAllahi wa bihamdihi', 'Glory be to Allah and His praise'),
    ], selected: settings.dhikrText, onSelect: (val) => ref.read(blockingProvider.notifier).updateSettings(settings.copyWith(dhikrText: val)));
  }

  void _showDurationPicker(BuildContext context, WidgetRef ref, InterventionSettings settings) {
    _showOptionsPicker(context: context, title: 'Intervention Duration', options: [
      ('10', '10 seconds', 'Quick pause'),
      ('15', '15 seconds', 'Default'),
      ('20', '20 seconds', 'Extended'),
      ('30', '30 seconds', 'Deep focus'),
    ], selected: settings.breathingDurationSeconds.toString(), onSelect: (val) => ref.read(blockingProvider.notifier).updateSettings(settings.copyWith(breathingDurationSeconds: int.parse(val))));
  }

  void _showColorPicker(BuildContext context, WidgetRef ref, InterventionSettings settings) {
    final colors = [('#1DB954', 'Green'), ('#5B9BD5', 'Blue'), ('#9C27B0', 'Purple'), ('#FF9800', 'Orange'), ('#E91E63', 'Pink'), ('#00BCD4', 'Teal'), ('#FF5722', 'Deep Orange'), ('#607D8B', 'Blue Grey')];
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 20),
                Text('Fill Color', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                Wrap(spacing: 16, runSpacing: 16, children: colors.map((c) {
                  final isSelected = settings.fillColor.toUpperCase() == c.$1.toUpperCase();
                  return GestureDetector(onTap: () { ref.read(blockingProvider.notifier).updateSettings(settings.copyWith(fillColor: c.$1)); Navigator.pop(ctx); },
                    child: Column(children: [
                      Container(width: 52, height: 52, decoration: BoxDecoration(color: _hexToColor(c.$1), shape: BoxShape.circle, border: Border.all(color: isSelected ? const Color(0xFF1A1A1A) : Colors.transparent, width: 3)),
                        child: isSelected ? const Icon(Icons.check, color: Colors.white, size: 24) : null),
                      const SizedBox(height: 4),
                      Text(c.$2, style: GoogleFonts.poppins(fontSize: 11, color: const Color(0xFF666666))),
                    ]));
                }).toList()),
                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showOptionsPicker({required BuildContext context, required String title, required List<(String, String, String)> options, required String selected, required Function(String) onSelect}) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return SafeArea(
          child: DraggableScrollableSheet(
            initialChildSize: 0.5,
            minChildSize: 0.3,
            maxChildSize: 0.85,
            expand: false,
            builder: (context, scrollController) {
              return Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
                    const SizedBox(height: 20),
                    Text(title, style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    Expanded(
                      child: ListView.builder(
                        controller: scrollController,
                        itemCount: options.length,
                        itemBuilder: (context, index) {
                          final opt = options[index];
                          final isSelected = selected == opt.$1;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: GestureDetector(
                              onTap: () { onSelect(opt.$1); Navigator.pop(ctx); },
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                                decoration: BoxDecoration(
                                  color: isSelected ? const Color(0xFF1DB954).withOpacity(0.08) : const Color(0xFFF8F8F8),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: isSelected ? const Color(0xFF1DB954) : const Color(0xFFE8E8E8), width: isSelected ? 2 : 1),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(opt.$2, style: GoogleFonts.poppins(fontSize: 15, fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500, color: isSelected ? const Color(0xFF1DB954) : const Color(0xFF333333))),
                                          if (opt.$3.isNotEmpty) Text(opt.$3, style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFF999999))),
                                        ],
                                      ),
                                    ),
                                    if (isSelected) const Icon(Icons.check_circle, color: Color(0xFF1DB954), size: 22),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});
  @override
  Widget build(BuildContext context) {
    return Text(label, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF1DB954), letterSpacing: 1));
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon; final Color iconColor;
  final String title; final String subtitle; final Widget? trailing; final VoidCallback onTap;
  const _SettingsTile({required this.icon, required this.iconColor, required this.title, required this.subtitle, this.trailing, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return Padding(padding: const EdgeInsets.only(bottom: 6), child: Material(color: Colors.white, borderRadius: BorderRadius.circular(14),
      child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(14),
        child: Padding(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(children: [
            Container(width: 40, height: 40, decoration: BoxDecoration(color: iconColor.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: iconColor, size: 20)),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500, color: const Color(0xFF1A1A1A))),
              Text(subtitle, style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFF999999))),
            ])),
            if (trailing != null) trailing!,
            if (trailing == null) const Icon(Icons.chevron_right_rounded, color: Color(0xFFCCCCCC), size: 22),
          ])))));
  }
}