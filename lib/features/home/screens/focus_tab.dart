// lib/features/home/screens/focus_tab.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:islam_focus_flutter/core/widgets/common_widgets.dart';
import 'package:islam_focus_flutter/features/auth/providers/auth_provider.dart';
import 'package:islam_focus_flutter/features/breathing/screens/breathing_screen.dart';
import 'package:islam_focus_flutter/features/blocking/screens/intervention_settings_screen.dart';

/// Dhikr counter provider
final dhikrCountProvider = StateProvider<int>((ref) => 0);

class FocusTab extends ConsumerWidget {
  const FocusTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final dhikrCount = ref.watch(dhikrCountProvider);
    final authState = ref.watch(authProvider);
    final userName = authState.user?.userMetadata?['full_name'] ?? 'User';

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Assalamu Alaikum',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                    Text(
                      userName,
                      style: GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                // Profile / Settings
                GestureDetector(
                  onTap: () {
                    // TODO: Open settings / profile
                  },
                  child: CircleAvatar(
                    radius: 22,
                    backgroundColor: theme.primaryColor.withOpacity(0.1),
                    child: Icon(
                      Icons.person_outline,
                      color: theme.primaryColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),

            // Daily Quote Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.primaryColor,
                    theme.colorScheme.secondary,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.format_quote_rounded,
                    color: Colors.white.withOpacity(0.6),
                    size: 28,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Verily, in the remembrance of Allah\ndo hearts find rest.',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '— Quran 13:28',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Quick Stats Row
            Row(
              children: [
                Expanded(
                  child: StatCard(
                    title: 'Today\'s Dhikr',
                    value: '$dhikrCount',
                    icon: Icons.favorite_rounded,
                    iconColor: theme.colorScheme.secondary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: StatCard(
                    title: 'Focus Time',
                    value: '0h',
                    icon: Icons.timer_rounded,
                    iconColor: theme.primaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),

            // Dhikr Counter
            const SectionHeader(
              title: 'Dhikr Counter',
              subtitle: 'Tap to count',
            ),
            const SizedBox(height: 12),
            Center(
              child: GestureDetector(
                onTap: () {
                  ref.read(dhikrCountProvider.notifier).state++;
                },
                child: Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: theme.primaryColor.withOpacity(0.08),
                    border: Border.all(
                      color: theme.primaryColor.withOpacity(0.3),
                      width: 3,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$dhikrCount',
                        style: GoogleFonts.poppins(
                          fontSize: 42,
                          fontWeight: FontWeight.bold,
                          color: theme.primaryColor,
                        ),
                      ),
                      Text(
                        'SubhanAllah',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: TextButton(
                onPressed: () {
                  ref.read(dhikrCountProvider.notifier).state = 0;
                },
                child: Text(
                  'Reset Counter',
                  style: GoogleFonts.poppins(fontSize: 13, color: theme.colorScheme.error),
                ),
              ),
            ),
            const SizedBox(height: 28),

            // Quick Actions
            const SectionHeader(title: 'Quick Actions'),
            const SizedBox(height: 12),

            // Breathing Exercise Button
            _QuickActionCard(
              icon: Icons.air_rounded,
              title: 'Breathing Exercise',
              subtitle: 'Calm your mind & soul',
              color: theme.primaryColor,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const BreathingScreen()),
                );
              },
            ),
            const SizedBox(height: 12),

            // App Blocking
            _QuickActionCard(
              icon: Icons.block_rounded,
              title: 'App Blocking',
              subtitle: 'Manage blocked apps & settings',
              color: theme.colorScheme.secondary,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const InterventionSettingsScreen()),
                );
              },
            ),
            const SizedBox(height: 32),

            // Sign Out
            Center(
              child: TextButton.icon(
                onPressed: () => ref.read(authProvider.notifier).signOut(),
                icon: Icon(Icons.logout_rounded, color: theme.colorScheme.error, size: 18),
                label: Text(
                  'Sign Out',
                  style: GoogleFonts.poppins(
                    color: theme.colorScheme.error,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

/// Quick action card widget
class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
