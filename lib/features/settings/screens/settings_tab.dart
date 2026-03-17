import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:islam_focus_flutter/features/auth/providers/auth_provider.dart';
import 'package:islam_focus_flutter/features/blocking/screens/intervention_settings_screen.dart';
import 'package:islam_focus_flutter/features/blocking/screens/blocked_apps_screen.dart';
import 'package:islam_focus_flutter/features/blocking/providers/blocking_provider.dart';
import 'package:islam_focus_flutter/features/settings/screens/notifications_screen.dart';
import 'package:islam_focus_flutter/features/settings/screens/appearance_screen.dart';
import 'package:islam_focus_flutter/features/settings/screens/about_screen.dart';
import 'package:islam_focus_flutter/features/auth/screens/login_screen.dart';
import 'package:iconsax/iconsax.dart';

final verseSettingsProvider = StateNotifierProvider<VerseSettingsNotifier, VerseSettings>((ref) => VerseSettingsNotifier());

class VerseSettings {
  final String translationLanguage;
  final bool showTranslation;

  const VerseSettings({
    this.translationLanguage = 'English',
    this.showTranslation = true,
  });

  VerseSettings copyWith({String? translationLanguage, bool? showTranslation}) {
    return VerseSettings(
      translationLanguage: translationLanguage ?? this.translationLanguage,
      showTranslation: showTranslation ?? this.showTranslation,
    );
  }
}

class VerseSettingsNotifier extends StateNotifier<VerseSettings> {
  VerseSettingsNotifier() : super(const VerseSettings()) { _load(); }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = VerseSettings(
      translationLanguage: prefs.getString('verse_language') ?? 'English',
      showTranslation: prefs.getBool('verse_show_translation') ?? true,
    );
  }

  Future<void> setLanguage(String lang) async {
    state = state.copyWith(translationLanguage: lang);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('verse_language', lang);
  }

  Future<void> toggleTranslation(bool val) async {
    state = state.copyWith(showTranslation: val);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('verse_show_translation', val);
  }
}

class SettingsTab extends ConsumerWidget {
  const SettingsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final authState = ref.watch(authProvider);
    final blockState = ref.watch(blockingProvider);
    final verseSettings = ref.watch(verseSettingsProvider);
    final isLoggedIn = authState.isAuthenticated;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Settings', style: GoogleFonts.poppins(fontSize: 28, fontWeight: FontWeight.bold, color: const Color(0xFF1A1A1A))),
              const SizedBox(height: 4),
              Text('Customize your experience', style: GoogleFonts.poppins(fontSize: 15, color: const Color(0xFF888888), fontWeight: FontWeight.w500)),
              const SizedBox(height: 32),

              // Profile
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFE8E8E8))),
                child: Row(
                  children: [
                    Container(width: 56, height: 56, decoration: BoxDecoration(color: theme.primaryColor.withOpacity(0.1), shape: BoxShape.circle),
                      child: Icon(Icons.person_rounded, color: theme.primaryColor, size: 28)),
                    const SizedBox(width: 16),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(isLoggedIn ? (authState.user?.userMetadata?['full_name'] ?? 'User') : 'Guest User',
                        style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: const Color(0xFF1A1A1A))),
                      Text(isLoggedIn ? (authState.user?.email ?? '') : 'Sign in to sync your data',
                        style: GoogleFonts.poppins(fontSize: 13, color: const Color(0xFF888888))),
                    ])),
                    if (!isLoggedIn)
                      GestureDetector(
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen())),
                        child: Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(color: theme.primaryColor, borderRadius: BorderRadius.circular(12)),
                          child: Text('Sign In', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white))),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // App Blocking
              _SectionLabel(label: 'APP BLOCKING'),
              const SizedBox(height: 12),
              _SettingsTile(icon: Icons.block_rounded, iconColor: const Color(0xFFE91E63),
                title: 'Blocked Apps', subtitle: '${blockState.blockedPackages.length} apps selected',
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BlockedAppsScreen()))),
              _SettingsTile(icon: Iconsax.setting_4, iconColor: const Color(0xFF6C63FF),
                title: 'Intervention Settings', subtitle: 'Mode, duration, color',
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const InterventionSettingsScreen()))),
              const SizedBox(height: 28),

              // Verse Display
              _SectionLabel(label: 'VERSE DISPLAY'),
              const SizedBox(height: 12),
              _SettingsTile(
                icon: Icons.language_rounded, iconColor: const Color(0xFF1DB954),
                title: 'Translation Language',
                subtitle: 'Applies to Discovery and Surah reading',
                trailing: GestureDetector(
                  onTap: () => _showLanguagePicker(context, ref, verseSettings),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Text(verseSettings.translationLanguage, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF1DB954))),
                    const SizedBox(width: 4),
                    const Icon(Icons.chevron_right_rounded, color: Color(0xFF1DB954), size: 20),
                  ]),
                ),
                onTap: () => _showLanguagePicker(context, ref, verseSettings),
              ),
              _SettingsTile(
                icon: Icons.translate_rounded, iconColor: const Color(0xFF4285F4),
                title: 'Show Translation',
                subtitle: 'Applies to Discovery and Surah reading',
                trailing: Switch(
                  value: verseSettings.showTranslation,
                  activeColor: const Color(0xFF1DB954),
                  onChanged: (val) => ref.read(verseSettingsProvider.notifier).toggleTranslation(val),
                ),
                onTap: () => ref.read(verseSettingsProvider.notifier).toggleTranslation(!verseSettings.showTranslation),
              ),
              const SizedBox(height: 28),

              // General
              _SectionLabel(label: 'GENERAL'),
              const SizedBox(height: 12),
              _SettingsTile(icon: Iconsax.notification, iconColor: const Color(0xFFFF9800),
                title: 'Notifications', subtitle: 'Reminders and alerts',
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen()))),
              _SettingsTile(icon: Iconsax.moon, iconColor: const Color(0xFF607D8B),
                title: 'Appearance', subtitle: 'Theme and display',
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AppearanceScreen()))),
              _SettingsTile(icon: Iconsax.info_circle, iconColor: const Color(0xFF4285F4),
                title: 'About', subtitle: 'Islam Focus v1.0.0',
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AboutScreen()))),
              const SizedBox(height: 28),

              // Account
              if (isLoggedIn) ...[
                _SectionLabel(label: 'ACCOUNT'),
                const SizedBox(height: 12),
                _SettingsTile(icon: Icons.logout_rounded, iconColor: Colors.red,
                  title: 'Sign Out', subtitle: authState.user?.email ?? '',
                  onTap: () {
                    showDialog(context: context, builder: (ctx) => AlertDialog(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      title: const Text('Sign Out?'), content: const Text('Are you sure you want to sign out?'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                        TextButton(onPressed: () { ref.read(authProvider.notifier).signOut(); Navigator.pop(ctx); },
                          child: const Text('Sign Out', style: TextStyle(color: Colors.red))),
                      ],
                    ));
                  }),
              ],
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  void _showLanguagePicker(BuildContext context, WidgetRef ref, VerseSettings settings) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 20),
              Text('Translation Language', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              _LanguageOption(label: 'English', subtitle: 'Sahih International', isSelected: settings.translationLanguage == 'English',
                onTap: () { ref.read(verseSettingsProvider.notifier).setLanguage('English'); Navigator.pop(ctx); }),
              const SizedBox(height: 8),
              _LanguageOption(label: 'Urdu', subtitle: 'Fateh Muhammad Jalandhry', isSelected: settings.translationLanguage == 'Urdu',
                onTap: () { ref.read(verseSettingsProvider.notifier).setLanguage('Urdu'); Navigator.pop(ctx); }),
            ]),
          ),
        );
      },
    );
  }
}

class _LanguageOption extends StatelessWidget {
  final String label; final String subtitle; final bool isSelected; final VoidCallback onTap;
  const _LanguageOption({required this.label, required this.subtitle, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1DB954).withOpacity(0.08) : const Color(0xFFF8F8F8),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isSelected ? const Color(0xFF1DB954) : const Color(0xFFE8E8E8), width: isSelected ? 2 : 1),
        ),
        child: Row(children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(color: isSelected ? const Color(0xFF1DB954).withOpacity(0.1) : const Color(0xFFF0F0F0), borderRadius: BorderRadius.circular(10)),
            child: Icon(Icons.language_rounded, color: isSelected ? const Color(0xFF1DB954) : const Color(0xFF888888), size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: isSelected ? const Color(0xFF1DB954) : const Color(0xFF333333))),
            Text(subtitle, style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFF999999))),
          ])),
          if (isSelected) const Icon(Icons.check_circle, color: Color(0xFF1DB954), size: 24)
          else const Icon(Icons.circle_outlined, color: Color(0xFFDDDDDD), size: 24),
        ]),
      ),
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.white, borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap, borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(children: [
              Container(width: 42, height: 42,
                decoration: BoxDecoration(color: iconColor.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, color: iconColor, size: 20)),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w500, color: const Color(0xFF1A1A1A))),
                Text(subtitle, style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFF999999))),
              ])),
              if (trailing != null) trailing!,
              if (trailing == null) const Icon(Icons.chevron_right_rounded, color: Color(0xFFCCCCCC), size: 22),
            ]),
          ),
        ),
      ),
    );
  }
}