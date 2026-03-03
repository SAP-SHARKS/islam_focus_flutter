// lib/features/onboarding/screens/onboarding_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:islam_focus_flutter/features/auth/screens/login_screen.dart';

/// Onboarding data model
class OnboardingData {
  String? gender;
  String? ageRange;
  String? azkarFrequency;
  String? quranTime;
  List<String> goals = [];
}

final onboardingDataProvider = StateProvider<OnboardingData>((ref) => OnboardingData());

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final int _totalPages = 8;

  // Selections
  String? _selectedGender;
  String? _selectedAge;
  String? _selectedAzkar;
  String? _selectedQuran;
  String? _selectedPreference;
  final List<String> _selectedGoals = [];

  void _nextPage() {
    if (_currentPage < _totalPages - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  void _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_complete', true);
    await prefs.setString('gender', _selectedGender ?? '');
    await prefs.setString('age_range', _selectedAge ?? '');
    await prefs.setString('azkar_frequency', _selectedAzkar ?? '');
    await prefs.setString('quran_time', _selectedQuran ?? '');
    await prefs.setStringList('goals', _selectedGoals);
    await prefs.setString('preference', _selectedPreference ?? '');

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF8F4),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 16),
            // Progress indicator
            _buildProgressBar(),
            const SizedBox(height: 8),

            // Pages
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (index) => setState(() => _currentPage = index),
                children: [
                  _buildMotivationPage1(),
                  _buildMotivationPage2(),
                  _buildMotivationPage3(),
                  _buildGenderPage(),
                  _buildAgePage(),
                  _buildAzkarPage(),
                  _buildQuranPage(),
                  _buildGoalsPage(),
                ],
              ),
            ),

            // Continue button
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _canProceed() ? _nextPage : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1DB954),
                    disabledBackgroundColor: const Color(0xFF1DB954).withOpacity(0.4),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    _currentPage == _totalPages - 1 ? 'Get Started' : 'Continue',
                    style: GoogleFonts.poppins(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _canProceed() {
    switch (_currentPage) {
      case 0:
      case 1:
      case 2:
        return true; // Motivation pages always can proceed
      case 3:
        return _selectedGender != null;
      case 4:
        return _selectedAge != null;
      case 5:
        return _selectedAzkar != null;
      case 6:
        return _selectedQuran != null;
      case 7:
        return _selectedGoals.isNotEmpty;
      default:
        return true;
    }
  }

  // ==========================================
  // PROGRESS BAR
  // ==========================================
  Widget _buildProgressBar() {
    // Group pages into sections
    int section;
    String sectionLabel;
    if (_currentPage <= 2) {
      section = 1;
      sectionLabel = 'Welcome';
    } else if (_currentPage <= 4) {
      section = 2;
      sectionLabel = 'About You';
    } else {
      section = 3;
      sectionLabel = 'Your Habits';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          Row(
            children: [
              // Section circles with connecting lines
              for (int i = 1; i <= 3; i++) ...[
                if (i > 1)
                  Expanded(
                    child: Container(
                      height: 3,
                      color: i <= section ? const Color(0xFF1A1A1A) : const Color(0xFFE0E0E0),
                    ),
                  ),
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: i <= section ? const Color(0xFF1A1A1A) : const Color(0xFFE0E0E0),
                  ),
                  child: Center(
                    child: Text(
                      '$i',
                      style: GoogleFonts.poppins(
                        color: i <= section ? Colors.white : const Color(0xFF999999),
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Text(
            sectionLabel,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: const Color(0xFF666666),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // MOTIVATION PAGE 1
  // ==========================================
  Widget _buildMotivationPage1() {
    return _buildMotivationLayout(
      icon: Icons.phone_android_rounded,
      title: 'Turn Screen Time\nInto Hasanat',
      description:
          'Every moment you spend on your phone can be an opportunity to earn rewards from Allah. Islam Focus helps you transform idle scrolling into meaningful worship.',
      verse: 'فَاذْكُرُونِي أَذْكُرْكُمْ',
      verseTranslation: '"So remember Me; I will remember you."\n— Al-Baqarah 2:152',
    );
  }

  // ==========================================
  // MOTIVATION PAGE 2
  // ==========================================
  Widget _buildMotivationPage2() {
    return _buildMotivationLayout(
      icon: Icons.self_improvement_rounded,
      title: 'Break Free From\nDigital Distractions',
      description:
          'Social media and apps steal hours from your day. Islam Focus intervenes before you open distracting apps, giving you a moment to breathe and reconnect with your purpose.',
      verse: 'أَلَا بِذِكْرِ اللَّهِ تَطْمَئِنُّ الْقُلُوبُ',
      verseTranslation: '"Verily, in the remembrance of Allah\ndo hearts find rest."\n— Ar-Ra\'d 13:28',
    );
  }

  // ==========================================
  // MOTIVATION PAGE 3
  // ==========================================
  Widget _buildMotivationPage3() {
    return _buildMotivationLayout(
      icon: Icons.favorite_rounded,
      title: 'Build Habits That\nPlease Allah',
      description:
          'Track your dhikr, set spiritual goals, and build a daily routine that brings you closer to Allah. Small consistent deeds are the most beloved to Him.',
      verse: 'أَحَبُّ الأَعْمَالِ إِلَى اللَّهِ أَدْوَمُهَا وَإِنْ قَلَّ',
      verseTranslation: '"The most beloved deeds to Allah are\nthe most consistent, even if small."\n— Sahih Bukhari',
    );
  }

  Widget _buildMotivationLayout({
    required IconData icon,
    required String title,
    required String description,
    required String verse,
    required String verseTranslation,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(flex: 2),
          // Icon
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: const Color(0xFF1DB954).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 48, color: const Color(0xFF1DB954)),
          ),
          const SizedBox(height: 32),
          // Title
          Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1A1A1A),
              height: 1.3,
            ),
          ),
          const SizedBox(height: 16),
          // Description
          Text(
            description,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 15,
              color: const Color(0xFF666666),
              height: 1.6,
            ),
          ),
          const Spacer(flex: 1),
          // Arabic verse
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF1DB954).withOpacity(0.06),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Text(
                  verse,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.amiri(
                    fontSize: 22,
                    color: const Color(0xFF1DB954),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  verseTranslation,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: const Color(0xFF888888),
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(flex: 2),
        ],
      ),
    );
  }

  // ==========================================
  // GENDER PAGE
  // ==========================================
  Widget _buildGenderPage() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const SizedBox(height: 16),
          Text(
            'Select your Gender',
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1A1A1A),
            ),
          ),
          const Spacer(),
          Row(
            children: [
              Expanded(
                child: _GenderCard(
                  icon: Icons.male_rounded,
                  label: 'Male',
                  isSelected: _selectedGender == 'Male',
                  onTap: () => setState(() => _selectedGender = 'Male'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _GenderCard(
                  icon: Icons.female_rounded,
                  label: 'Female',
                  isSelected: _selectedGender == 'Female',
                  onTap: () => setState(() => _selectedGender = 'Female'),
                ),
              ),
            ],
          ),
          const Spacer(),
        ],
      ),
    );
  }

  // ==========================================
  // AGE PAGE
  // ==========================================
  Widget _buildAgePage() {
    final ages = ['18-24', '25-34', '35-44', '45-54', '55+'];
    return _buildSelectionPage(
      title: 'What is your Age?',
      options: ages,
      selected: _selectedAge,
      onSelect: (val) => setState(() => _selectedAge = val),
    );
  }

  // ==========================================
  // AZKAR PAGE
  // ==========================================
  Widget _buildAzkarPage() {
    final options = [
      'Morning & Evening daily',
      'Sometimes',
      'Rarely',
      'I want to start',
    ];
    return _buildSelectionPage(
      title: 'How often do you\ndo Azkar?',
      options: options,
      selected: _selectedAzkar,
      onSelect: (val) => setState(() => _selectedAzkar = val),
    );
  }

  // ==========================================
  // QURAN PAGE
  // ==========================================
  Widget _buildQuranPage() {
    final options = [
      'Daily - at least 1 page',
      'A few times a week',
      'Occasionally',
      'Rarely',
      'I want to start reading',
    ];
    return _buildSelectionPage(
      title: 'How much Quran\ndo you recite?',
      options: options,
      selected: _selectedQuran,
      onSelect: (val) => setState(() => _selectedQuran = val),
    );
  }

  // ==========================================
  // GOALS PAGE
  // ==========================================
  Widget _buildGoalsPage() {
    final goals = [
      ('🕌', 'Be consistent in prayers'),
      ('📖', 'Read Quran daily'),
      ('🤲', 'Make Azkar a habit'),
      ('📵', 'Reduce screen time'),
      ('🧠', 'Understand the Quran'),
      ('📚', 'Study the Sunnah'),
      ('🕋', 'Get closer to Allah'),
      ('🌙', 'Explore Islam deeper'),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Center(
            child: Text(
              'What are your goals?',
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1A1A1A),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Center(
            child: Text(
              'Choose up to 3',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: const Color(0xFF999999),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: ListView.separated(
              itemCount: goals.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final goal = goals[index];
                final isSelected = _selectedGoals.contains(goal.$2);
                return _GoalTile(
                  emoji: goal.$1,
                  label: goal.$2,
                  isSelected: isSelected,
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        _selectedGoals.remove(goal.$2);
                      } else if (_selectedGoals.length < 3) {
                        _selectedGoals.add(goal.$2);
                      }
                    });
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // REUSABLE SELECTION PAGE
  // ==========================================
  Widget _buildSelectionPage({
    required String title,
    required List<String> options,
    required String? selected,
    required Function(String) onSelect,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1A1A1A),
            ),
          ),
          const Spacer(),
          ...options.map((option) {
            final isSelected = selected == option;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: GestureDetector(
                onTap: () => onSelect(option),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF1DB954).withOpacity(0.08)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF1DB954)
                          : const Color(0xFFE8E8E8),
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Text(
                    option,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: isSelected
                          ? const Color(0xFF1DB954)
                          : const Color(0xFF333333),
                    ),
                  ),
                ),
              ),
            );
          }),
          const Spacer(),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}

// ==========================================
// GENDER CARD WIDGET
// ==========================================
class _GenderCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _GenderCard({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 32),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF1DB954).withOpacity(0.08)
              : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF1DB954)
                : const Color(0xFFE8E8E8),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF1DB954).withOpacity(0.15)
                    : const Color(0xFFF5F5F5),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 36,
                color: isSelected
                    ? const Color(0xFF1DB954)
                    : const Color(0xFF666666),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isSelected
                    ? const Color(0xFF1DB954)
                    : const Color(0xFF333333),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// GOAL TILE WIDGET
// ==========================================
class _GoalTile extends StatelessWidget {
  final String emoji;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _GoalTile({
    required this.emoji,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF1DB954).withOpacity(0.08)
              : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF1DB954)
                : const Color(0xFFE8E8E8),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected
                      ? const Color(0xFF1DB954)
                      : const Color(0xFF333333),
                ),
              ),
            ),
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                color: isSelected
                    ? const Color(0xFF1DB954)
                    : Colors.transparent,
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF1DB954)
                      : const Color(0xFFCCCCCC),
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 18, color: Colors.white)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
