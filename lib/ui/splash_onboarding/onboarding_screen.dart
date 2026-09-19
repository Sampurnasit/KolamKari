import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../navigation/main_navigation_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<_OnboardingPageData> _pages = [
    const _OnboardingPageData(
      title: 'Sacred Living Heritage',
      subtitle: 'Preserving India\'s ancient threshold art for the digital era.',
      description: 'Drawn at dawn with rice flour to feed insects and sanctify homes, Kolam is an unbroken living tradition of cultural meditation and hospitality.',
      icon: Icons.grain_rounded,
      tag: 'CULTURE & HERITAGE',
      highlightColor: AppColors.terracottaRed,
    ),
    const _OnboardingPageData(
      title: 'Ethnomathematics & Algorithms',
      subtitle: 'Eulerian loops, knot theory, and dihedral symmetry groups.',
      description: 'Centuries before modern computer science, Indian women mastered closed continuous loops and fractal symmetry with effortless dexterity.',
      icon: Icons.functions_rounded,
      tag: 'SACRED GEOMETRY',
      highlightColor: AppColors.turmericAmber,
    ),
    const _OnboardingPageData(
      title: 'Create & Analyze with AI',
      subtitle: 'Draw freely on pulli grids with real-time on-device geometry analysis.',
      description: 'Experience live mirror symmetry modes, test for reflection axes and rotational invariance, and build your digital collection of sacred patterns.',
      icon: Icons.auto_awesome_rounded,
      tag: 'SMART STUDIO',
      highlightColor: AppColors.tulsiGreen,
    ),
  ];

  void _onNext() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  void _completeOnboarding() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.grain_rounded, color: AppColors.terracottaRed, size: 22),
                      const SizedBox(width: 8),
                      Text('KolamKari', style: AppTypography.displayTitle.copyWith(fontSize: 20)),
                    ],
                  ),
                  TextButton(
                    onPressed: _completeOnboarding,
                    child: Text('Skip', style: AppTypography.tagText.copyWith(color: AppColors.textMuted)),
                  ),
                ],
              ),
            ),

            // Page View
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (idx) => setState(() => _currentPage = idx),
                itemCount: _pages.length,
                itemBuilder: (context, index) {
                  final data = _pages[index];
                  return Padding(
                    padding: const EdgeInsets.all(28.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Icon circle with cultural styling
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: data.highlightColor.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: data.highlightColor.withValues(alpha: 0.5),
                              width: 2,
                            ),
                          ),
                          child: Icon(data.icon, size: 58, color: data.highlightColor),
                        ),
                        const SizedBox(height: 32),

                        // Tag
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                          decoration: BoxDecoration(
                            color: data.highlightColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            data.tag,
                            style: AppTypography.tagText.copyWith(
                              color: data.highlightColor,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Title
                        Text(
                          data.title,
                          style: AppTypography.displayTitle.copyWith(
                            fontSize: 24,
                            color: isDark ? AppColors.textLight : AppColors.textDark,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),

                        // Subtitle
                        Text(
                          data.subtitle,
                          style: AppTypography.cardTitle.copyWith(
                            color: AppColors.turmericAmber,
                            fontSize: 15,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),

                        // Description
                        Text(
                          data.description,
                          style: AppTypography.bodyText.copyWith(
                            color: isDark ? Colors.white70 : AppColors.textMuted,
                            fontSize: 14,
                            height: 1.6,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Bottom Navigation Indicators & Button
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 16, 28, 28),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Dots indicator
                  Row(
                    children: List.generate(_pages.length, (idx) {
                      final isSel = _currentPage == idx;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: const EdgeInsets.only(right: 6),
                        width: isSel ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: isSel ? AppColors.terracottaRed : AppColors.borderLight,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  ),

                  // Next / Start Button
                  ElevatedButton(
                    onPressed: _onNext,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_currentPage == _pages.length - 1 ? 'Enter KolamKari' : 'Continue'),
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_forward_rounded, size: 18),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingPageData {
  final String title;
  final String subtitle;
  final String description;
  final IconData icon;
  final String tag;
  final Color highlightColor;

  const _OnboardingPageData({
    required this.title,
    required this.subtitle,
    required this.description,
    required this.icon,
    required this.tag,
    required this.highlightColor,
  });
}
