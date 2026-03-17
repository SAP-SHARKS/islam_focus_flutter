import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFFDF8F4),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFDF8F4),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: Color(0xFF1A1A1A)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('About', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: const Color(0xFF1A1A1A))),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          children: [
            const SizedBox(height: 20),

            // App Icon
            Container(
              width: 100, height: 100,
              decoration: BoxDecoration(
                color: theme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(28),
              ),
              child: Icon(Icons.self_improvement_rounded, size: 52, color: theme.primaryColor),
            ),
            const SizedBox(height: 20),

            Text('Islam Focus', style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold, color: const Color(0xFF1A1A1A))),
            const SizedBox(height: 4),
            Text('Version 1.0.0', style: GoogleFonts.poppins(fontSize: 14, color: const Color(0xFF999999))),
            const SizedBox(height: 8),
            Text('Digital Wellness with Islamic Values', style: GoogleFonts.poppins(fontSize: 14, color: const Color(0xFF888888), fontWeight: FontWeight.w500)),

            const SizedBox(height: 40),

            // Description
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Our Mission', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: const Color(0xFF1A1A1A))),
                  const SizedBox(height: 12),
                  Text(
                    'Islam Focus helps you build a mindful relationship with technology. '
                    'By replacing mindless scrolling with dhikr, Quran recitation, and breathing exercises, '
                    'we help you stay connected to Allah while using your phone.',
                    style: GoogleFonts.poppins(fontSize: 14, color: const Color(0xFF666666), height: 1.7),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Features
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Features', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: const Color(0xFF1A1A1A))),
                  const SizedBox(height: 16),
                  _FeatureItem(icon: Icons.block_rounded, color: const Color(0xFFE91E63), text: 'App blocking with Islamic interventions'),
                  _FeatureItem(icon: Icons.favorite_rounded, color: const Color(0xFFFF5722), text: 'Dhikr counter with tap tracking'),
                  _FeatureItem(icon: Icons.menu_book_rounded, color: const Color(0xFF4285F4), text: 'Quran verse reflections'),
                  _FeatureItem(icon: Icons.air_rounded, color: const Color(0xFF1DB954), text: 'Breathing exercises for mindfulness'),
                  _FeatureItem(icon: Icons.bar_chart_rounded, color: const Color(0xFF9C27B0), text: 'Screen time tracking and statistics'),
                  _FeatureItem(icon: Icons.shield_rounded, color: const Color(0xFFFF9800), text: 'Time saved from distractions'),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Quran verse
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.primaryColor.withOpacity(0.06),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  Text(
                    'فَاذْكُرُونِي أَذْكُرْكُمْ',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.amiri(fontSize: 24, color: theme.primaryColor, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '"So remember Me; I will remember you."',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(fontSize: 14, color: const Color(0xFF666666), fontStyle: FontStyle.italic),
                  ),
                  const SizedBox(height: 4),
                  Text('Al-Baqarah 2:152', style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFF999999))),
                ],
              ),
            ),

            const SizedBox(height: 32),
            Text('Made with ❤️ for the Ummah', style: GoogleFonts.poppins(fontSize: 13, color: const Color(0xFFAAAAAA))),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class _FeatureItem extends StatelessWidget {
  final IconData icon; final Color color; final String text;
  const _FeatureItem({required this.icon, required this.color, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(child: Text(text, style: GoogleFonts.poppins(fontSize: 14, color: const Color(0xFF444444), height: 1.4))),
        ],
      ),
    );
  }
}