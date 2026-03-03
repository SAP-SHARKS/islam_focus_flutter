// lib/features/breathing/screens/breathing_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:islam_focus_flutter/core/theme/app_theme.dart';
import 'package:islam_focus_flutter/core/theme/theme_provider.dart';

class BreathingScreen extends ConsumerStatefulWidget {
  const BreathingScreen({super.key});

  @override
  ConsumerState<BreathingScreen> createState() => _BreathingScreenState();
}

class _BreathingScreenState extends ConsumerState<BreathingScreen>
    with TickerProviderStateMixin {
  late AnimationController _breathController;
  late AnimationController _pulseController;
  late Animation<double> _breathAnimation;
  late Animation<double> _pulseAnimation;

  bool _isCompleted = false;
  String _phaseText = 'Breathe In...';
  int _cycleCount = 0;
  static const int _totalCycles = 3; // 3 full breath cycles

  @override
  void initState() {
    super.initState();

    // Main breathing animation: 0→1→0 over 8 seconds (4s in, 4s out)
    _breathController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    );

    _breathAnimation = CurvedAnimation(
      parent: _breathController,
      curve: Curves.easeInOutSine,
    );

    // Subtle background pulse
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Listen to breathing phases
    _breathController.addListener(() {
      setState(() {
        if (_breathController.value < 0.5) {
          _phaseText = 'Breathe In...';
        } else {
          _phaseText = 'Breathe Out...';
        }
      });
    });

    _breathController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _cycleCount++;
        if (_cycleCount >= _totalCycles) {
          setState(() => _isCompleted = true);
          _pulseController.stop();
        } else {
          _breathController.reset();
          _breathController.forward();
        }
      }
    });

    // Start
    _breathController.forward();
  }

  @override
  void dispose() {
    _breathController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appTheme = ref.watch(themeProvider);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: AnimatedBuilder(
        animation: Listenable.merge([_breathAnimation, _pulseAnimation]),
        builder: (context, child) {
          // Interpolate background color based on breath phase
          final breathValue = _breathAnimation.value;
          // 0→0.5 is inhale, 0.5→1 is exhale, create a triangle wave
          final progress = breathValue < 0.5
              ? breathValue * 2 // 0→1 during inhale
              : 2 - breathValue * 2; // 1→0 during exhale

          final bgColor = Color.lerp(
            appTheme.breathingStartColor,
            appTheme.breathingEndColor,
            progress,
          )!;

          return Container(
            width: size.width,
            height: size.height,
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 1.2,
                colors: [
                  bgColor.withOpacity(0.3),
                  bgColor,
                ],
              ),
            ),
            child: SafeArea(
              child: _isCompleted
                  ? _buildCompletedView(appTheme)
                  : _buildBreathingView(progress, appTheme, size),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBreathingView(
      double progress, AppThemeData appTheme, Size size) {
    final circleSize = 120.0 + (progress * 80.0); // 120→200

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Spacer(flex: 2),

        // Phase text
        Text(
          _phaseText,
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.w300,
            color: appTheme.textPrimary.withOpacity(0.8),
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 40),

        // Breathing circle
        Transform.scale(
          scale: _pulseAnimation.value,
          child: Container(
            width: circleSize,
            height: circleSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: appTheme.primaryColor.withOpacity(0.15 + progress * 0.2),
              border: Border.all(
                color: appTheme.primaryColor.withOpacity(0.4),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: appTheme.primaryColor.withOpacity(0.2 * progress),
                  blurRadius: 40 * progress,
                  spreadRadius: 10 * progress,
                ),
              ],
            ),
            child: Center(
              child: Text(
                '${(progress * 100).toInt()}%',
                style: GoogleFonts.poppins(
                  fontSize: 32,
                  fontWeight: FontWeight.w600,
                  color: appTheme.primaryColor,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 40),

        // Cycle indicator
        Text(
          'Cycle ${_cycleCount + 1} of $_totalCycles',
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: appTheme.textSecondary,
          ),
        ),

        const Spacer(flex: 2),

        // Islamic reminder
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Text(
            'بِسْمِ اللَّهِ الرَّحْمَنِ الرَّحِيمِ',
            textAlign: TextAlign.center,
            style: GoogleFonts.amiri(
              fontSize: 22,
              color: appTheme.textPrimary.withOpacity(0.5),
            ),
          ),
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildCompletedView(AppThemeData appTheme) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(),

          // Checkmark
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: appTheme.successColor.withOpacity(0.1),
            ),
            child: Icon(
              Icons.check_rounded,
              size: 52,
              color: appTheme.successColor,
            ),
          ),
          const SizedBox(height: 24),

          Text(
            'Well Done!',
            style: GoogleFonts.poppins(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: appTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'You completed the breathing exercise.\nHow do you feel now?',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 15,
              color: appTheme.textSecondary,
              height: 1.5,
            ),
          ),

          const Spacer(),

          // Two buttons
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // Continue to app
              },
              child: const Text('Continue to App'),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: OutlinedButton(
              onPressed: () {
                // User chooses not to open distracting app
                Navigator.pop(context);
                // TODO: Could log this choice for stats
              },
              child: const Text("I Don't Want to Open"),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

/// No custom AnimatedBuilder needed - using Flutter's built-in AnimatedBuilder
