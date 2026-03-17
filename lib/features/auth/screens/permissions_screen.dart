import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:islam_focus_flutter/features/auth/providers/permission_provider.dart';
import 'package:iconsax/iconsax.dart';

class PermissionsScreen extends ConsumerStatefulWidget {
  const PermissionsScreen({super.key});

  @override
  ConsumerState<PermissionsScreen> createState() => _PermissionsScreenState();
}

class _PermissionsScreenState extends ConsumerState<PermissionsScreen> with WidgetsBindingObserver {
  bool _waitingForPermission = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _waitingForPermission) {
      _waitingForPermission = false;
      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted) {
          ref.read(permissionProvider.notifier).checkPermissions();
        }
      });
    }
  }

  void _openAccessibility() {
    _waitingForPermission = true;
    ref.read(permissionProvider.notifier).requestAccessibility();
  }

  void _openUsageStats() {
    _waitingForPermission = true;
    ref.read(permissionProvider.notifier).requestUsageStats();
  }

  @override
  Widget build(BuildContext context) {
    final permissionState = ref.watch(permissionProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: const Color(0xFFFDF8F4),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Icon(
                  Iconsax.setting_2,
                  size: 40,
                  color: Color(0xFF1DB954),
                ),
              ),
              const SizedBox(height: 32),

              Text(
                'Permissions Required',
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1A1A1A),
                ),
              ),
              const SizedBox(height: 12),

              Text(
                'These permissions are needed for app blocking.\nYou will be redirected to Settings — just enable\nand come back.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: const Color(0xFF888888),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 48),

              _PermissionCard(
                title: 'Accessibility Service',
                subtitle: 'Detects when apps open',
                icon: Iconsax.user_tag,
                iconColor: const Color(0xFF4285F4),
                isGranted: permissionState.isAccessibilityGranted,
                onTap: _openAccessibility,
              ),
              const SizedBox(height: 16),

              _PermissionCard(
                title: 'App Usage Permission',
                subtitle: 'Analyzes screen time',
                icon: Iconsax.mobile,
                iconColor: const Color(0xFF9C27B0),
                isGranted: permissionState.isUsageStatsGranted,
                onTap: _openUsageStats,
              ),

              const Spacer(),

              // Refresh button - in case auto detect doesn't work
              if (!permissionState.allGranted)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: TextButton.icon(
                    onPressed: () {
                      ref.read(permissionProvider.notifier).checkPermissions();
                    },
                    icon: const Icon(Icons.refresh_rounded, size: 18, color: Color(0xFF1DB954)),
                    label: Text(
                      'Refresh permission status',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: const Color(0xFF1DB954),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),

              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: permissionState.allGranted
                      ? () {
                          ref.read(permissionProvider.notifier).checkPermissions();
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1DB954),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: const Color(0xFFE8E8E8),
                    disabledForegroundColor: const Color(0xFF999999),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    permissionState.allGranted ? 'Continue' : 'Complete steps above',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _PermissionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final bool isGranted;
  final VoidCallback onTap;

  const _PermissionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.isGranted,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isGranted ? null : onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isGranted ? const Color(0xFF1DB954) : const Color(0xFFE8E8E8),
            width: isGranted ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isGranted
                      ? const Color(0xFF1DB954).withOpacity(0.1)
                      : iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isGranted ? Icons.check_circle_rounded : icon,
                  color: isGranted ? const Color(0xFF1DB954) : iconColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1A1A1A),
                      ),
                    ),
                    Text(
                      isGranted ? 'Permission granted' : subtitle,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: isGranted ? const Color(0xFF1DB954) : const Color(0xFF888888),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                isGranted ? Icons.check_circle_rounded : Icons.arrow_forward_ios_rounded,
                size: isGranted ? 24 : 16,
                color: isGranted ? const Color(0xFF1DB954) : const Color(0xFFCCCCCC),
              ),
            ],
          ),
        ),
      ),
    );
  }
}