import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:islam_focus_flutter/core/theme/theme_provider.dart';
import 'package:islam_focus_flutter/core/theme/app_theme.dart';

class AppearanceScreen extends ConsumerWidget {
  const AppearanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentTheme = ref.watch(themeProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFFDF8F4),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFDF8F4),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: Color(0xFF1A1A1A)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Appearance', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: const Color(0xFF1A1A1A))),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        children: [
          Text('THEME', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF1DB954), letterSpacing: 1)),
          const SizedBox(height: 16),

          // Theme options
          _ThemeCard(
            title: 'Light Calm',
            subtitle: 'Warm beige with green accents',
            colors: [const Color(0xFFFDF8F4), const Color(0xFF1DB954), const Color(0xFFF0C27B)],
            isSelected: currentTheme.brightness == Brightness.light,
            onTap: () {
              ref.read(themeProvider.notifier).updateTheme(AppThemeData.lightCalm());
            },
          ),
          const SizedBox(height: 12),

          _ThemeCard(
            title: 'Ocean Blue',
            subtitle: 'Cool blue tones for focus',
            colors: [const Color(0xFFF0F4FF), const Color(0xFF5B9BD5), const Color(0xFF2E7D6F)],
            isSelected: false,
            onTap: () {
              // Could add more themes later
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('More themes coming soon!'),
                  backgroundColor: const Color(0xFF1DB954),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              );
            },
          ),
          const SizedBox(height: 12),

          _ThemeCard(
            title: 'Dark Mode',
            subtitle: 'Easy on the eyes at night',
            colors: [const Color(0xFF1A1A2E), const Color(0xFF1DB954), const Color(0xFF16213E)],
            isSelected: false,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Dark mode coming soon!'),
                  backgroundColor: const Color(0xFF1DB954),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              );
            },
          ),

          const SizedBox(height: 32),
          Text('DISPLAY', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF1DB954), letterSpacing: 1)),
          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Current Theme Preview', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600, color: const Color(0xFF1A1A1A))),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _ColorPreview(label: 'Primary', color: currentTheme.primaryColor),
                    const SizedBox(width: 12),
                    _ColorPreview(label: 'Secondary', color: currentTheme.secondaryColor),
                    const SizedBox(width: 12),
                    _ColorPreview(label: 'Accent', color: currentTheme.accentColor),
                    const SizedBox(width: 12),
                    _ColorPreview(label: 'Background', color: currentTheme.backgroundColor),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

class _ThemeCard extends StatelessWidget {
  final String title; final String subtitle;
  final List<Color> colors; final bool isSelected; final VoidCallback onTap;

  const _ThemeCard({required this.title, required this.subtitle, required this.colors, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isSelected ? const Color(0xFF1DB954) : const Color(0xFFE8E8E8), width: isSelected ? 2 : 1),
        ),
        child: Row(
          children: [
            // Color preview circles
            Row(
              children: colors.map((c) => Container(
                width: 28, height: 28,
                margin: const EdgeInsets.only(right: 6),
                decoration: BoxDecoration(shape: BoxShape.circle, color: c, border: Border.all(color: const Color(0xFFE0E0E0), width: 0.5)),
              )).toList(),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600, color: const Color(0xFF1A1A1A))),
                  Text(subtitle, style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFF999999))),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle_rounded, color: Color(0xFF1DB954), size: 24)
            else
              const Icon(Icons.circle_outlined, color: Color(0xFFDDDDDD), size: 24),
          ],
        ),
      ),
    );
  }
}

class _ColorPreview extends StatelessWidget {
  final String label; final Color color;
  const _ColorPreview({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Container(
            height: 40,
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFE0E0E0), width: 0.5)),
          ),
          const SizedBox(height: 6),
          Text(label, style: GoogleFonts.poppins(fontSize: 10, color: const Color(0xFF999999)), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}