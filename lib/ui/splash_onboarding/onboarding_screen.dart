import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../data/models/user_profile.dart';
import '../../providers/app_providers.dart';
import '../navigation/main_navigation_screen.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  final TextEditingController _nameController = TextEditingController();
  int _currentPage = 0;
  String _generatedUsername = '@kolam_artisan';

  final List<_OnboardingPageData> _introPages = [
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

  int get _totalPages => _introPages.length + 1; // 3 intro pages + 1 profile setup page

  @override
  void initState() {
    super.initState();
    _nameController.addListener(() {
      setState(() {
        _generatedUsername = UserProfile.generateUsername(_nameController.text);
      });
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _onNext() {
    if (_currentPage < _totalPages - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  void _onSkip() {
    if (_currentPage < _totalPages - 1) {
      // Jump directly to Name setup page so they can enter their name
      _pageController.animateToPage(
        _totalPages - 1,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  Future<void> _completeOnboarding() async {
    final rawName = _nameController.text.trim();
    final finalName = rawName.isNotEmpty ? rawName : 'Kolam Artisan';
    final finalUsername = UserProfile.generateUsername(finalName);

    // Save profile name & auto-generated username
    await ref.read(userProfileProvider.notifier).updateProfileName(
      name: finalName,
      username: finalUsername,
    );

    // Mark onboarding completed in storage
    final storage = ref.read(storageServiceProvider);
    await storage.setOnboardingCompleted(true);

    if (mounted) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 500),
          pageBuilder: (_, animation, secondaryAnimation) => const MainNavigationScreen(),
          transitionsBuilder: (_, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      );
    }
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
                  if (_currentPage < _totalPages - 1)
                    TextButton(
                      onPressed: _onSkip,
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
                itemCount: _totalPages,
                itemBuilder: (context, index) {
                  if (index < _introPages.length) {
                    return _buildIntroPage(_introPages[index], isDark);
                  } else {
                    return _buildNameInputPage(isDark);
                  }
                },
              ),
            ),

            // Bottom Navigation Indicators & Button
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 12, 28, 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Dots indicator
                  Row(
                    children: List.generate(_totalPages, (idx) {
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
                        Text(_currentPage == _totalPages - 1 ? 'Enter KolamKari' : 'Continue'),
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

  Widget _buildIntroPage(_OnboardingPageData data, bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(28.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon circle with cultural styling
          Container(
            width: 110,
            height: 110,
            decoration: BoxDecoration(
              color: data.highlightColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
              border: Border.all(
                color: data.highlightColor.withValues(alpha: 0.5),
                width: 2,
              ),
            ),
            child: Icon(data.icon, size: 54, color: data.highlightColor),
          ),
          const SizedBox(height: 28),

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
  }

  Widget _buildNameInputPage(bool isDark) {
    final initials = _nameController.text.trim().isNotEmpty
        ? _nameController.text
            .trim()
            .split(' ')
            .map((w) => w.isNotEmpty ? w[0].toUpperCase() : '')
            .take(2)
            .join()
        : 'KA';

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 16),

          // Dynamic User Initial / Sacred Avatar Emblem
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.terracottaRed, Color(0xFFD97706)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.turmericGold,
                width: 2.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.terracottaRed.withValues(alpha: 0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Center(
              child: Text(
                initials,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Tag
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.turmericAmber.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              'YOUR ARTISAN IDENTITY',
              style: AppTypography.tagText.copyWith(
                color: AppColors.turmericAmber,
                letterSpacing: 1.0,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Title
          Text(
            'Welcome to the Sanctuary',
            style: AppTypography.displayTitle.copyWith(
              fontSize: 24,
              color: isDark ? AppColors.textLight : AppColors.textDark,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),

          Text(
            'What should we call you on your Kolam journey?',
            style: AppTypography.bodyText.copyWith(
              color: isDark ? Colors.white70 : AppColors.textMuted,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),

          // Name Input Field
          Container(
            decoration: BoxDecoration(
              color: isDark ? AppColors.slateCard : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: TextField(
              controller: _nameController,
              autofocus: false,
              textCapitalization: TextCapitalization.words,
              style: AppTypography.cardTitle.copyWith(
                fontSize: 16,
                color: isDark ? Colors.white : AppColors.textDark,
              ),
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: 'Enter your full name (e.g. Sampurna)',
                hintStyle: AppTypography.bodyText.copyWith(
                  color: isDark ? Colors.white38 : Colors.grey.shade400,
                  fontSize: 14,
                ),
                prefixIcon: const Icon(Icons.person_outline_rounded, color: AppColors.terracottaRed),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Live Auto-Generated Username Handle Display
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1B4B) : const Color(0xFFFFF8E1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.turmericGold.withValues(alpha: 0.5),
                width: 1.0,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.alternate_email_rounded, size: 16, color: AppColors.turmericGold),
                const SizedBox(width: 6),
                Text(
                  'Auto-generated handle: ',
                  style: AppTypography.caption.copyWith(
                    fontSize: 12,
                    color: isDark ? Colors.white70 : Colors.brown.shade700,
                  ),
                ),
                Text(
                  _generatedUsername,
                  style: AppTypography.caption.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.turmericGold : AppColors.terracottaRed,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
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
