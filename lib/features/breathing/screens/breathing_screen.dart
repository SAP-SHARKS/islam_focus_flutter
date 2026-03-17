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
  static const int _totalCycles = 3;

  @override
  void initState() {
    super.initState();
    _breathController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    );
    _breathAnimation = CurvedAnimation(
      parent: _breathController,
      curve: Curves.easeInOutSine,
    );
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

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
      backgroundColor: Colors.white,
      body: AnimatedBuilder(
        animation: Listenable.merge([_breathAnimation, _pulseAnimation]),
        builder: (context, child) {
          final breathValue = _breathAnimation.value;
          final progress = breathValue < 0.5 ? breathValue * 2 : 2 - breathValue * 2;
          
          return SafeArea(
            child: _isCompleted
                ? _buildCompletedView(appTheme)
                : _buildBreathingView(progress, appTheme, size),
          );
        },
      ),
    );
  }

  Widget _buildBreathingView(double progress, AppThemeData appTheme, Size size) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        children: [
          const SizedBox(height: 20),
          // Phase and Progress
          Text(
            _phaseText,
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w500,
              color: appTheme.textPrimary.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Cycle ${_cycleCount + 1} of $_totalCycles',
            style: GoogleFonts.poppins(fontSize: 14, color: appTheme.textSecondary),
          ),
          
          const Spacer(),

          // --- ARABIC BOX (Extended & Centered) ---
          Container(
            width: double.infinity,
            constraints: BoxConstraints(minHeight: size.height * 0.25),
            padding: const EdgeInsets.all(25),
            decoration: BoxDecoration(
              color: appTheme.primaryColor.withOpacity(0.05),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: appTheme.primaryColor.withOpacity(0.1)),
            ),
            child: Center(
              child: SingleChildScrollView(
                child: Text(
                  'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ', // Aapka Arabic text
                  textAlign: TextAlign.center,
                  style: GoogleFonts.amiri(
                    fontSize: 32,
                    height: 1.6,
                    fontWeight: FontWeight.bold,
                    color: appTheme.textPrimary,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // --- TRANSLATION BOX ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              "In the name of Allah, the Entirely Merciful, the Especially Merciful.",
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: appTheme.textSecondary,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),

          const Spacer(),

          // --- NAVIGATION BUTTONS ---
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildNavButton("Previous", Icons.arrow_back_ios_new, appTheme, () {}),
              _buildNavButton("Next", Icons.arrow_forward_ios, appTheme, () {}, isNext: true),
            ],
          ),
          
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildNavButton(String text, IconData icon, AppThemeData appTheme, VoidCallback onTap, {bool isNext = false}) {
    return TextButton