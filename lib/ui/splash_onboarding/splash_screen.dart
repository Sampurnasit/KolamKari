import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../providers/app_providers.dart';
import '../navigation/main_navigation_screen.dart';
import 'onboarding_screen.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    // Entrance scale & fade animation
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _scaleAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOutBack,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );

    _fadeController.forward();

    _navigateNext();
  }

  Future<void> _navigateNext() async {
    // Show splash screen for 2.2 seconds to allow smooth branding entrance
    await Future.delayed(const Duration(milliseconds: 2200));
    if (!mounted) return;

    final storage = ref.read(storageServiceProvider);
    final hasCompletedOnboarding = storage.isOnboardingCompleted();

    final targetScreen = hasCompletedOnboarding
        ? const MainNavigationScreen()
        : const OnboardingScreen();

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 650),
        pageBuilder: (_, animation, secondaryAnimation) => targetScreen,
        transitionsBuilder: (_, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [
                    const Color(0xFF0F172A),
                    const Color(0xFF1E1B4B),
                    AppColors.slateDark,
                  ]
                : [
                    const Color(0xFFFFFBF5),
                    const Color(0xFFFFF5EB),
                    AppColors.riceFlourBg,
                  ],
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 3),

              // Animated Kolam Icon Centerpiece (High-Contrast in Light & Dark mode)
              ScaleTransition(
                scale: _scaleAnimation,
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Container(
                    width: 250,
                    height: 250,
                    padding: const EdgeInsets.all(12),
                    child: Image.asset(
                      'assets/kolam/Kolam-icon.png',
                      fit: BoxFit.contain,
                      color: isDark ? const Color(0xFFFFFFFF) : const Color(0xFF9E2A2B),
                      colorBlendMode: BlendMode.srcIn,
                      errorBuilder: (context, error, stackTrace) {
                        return Image.asset(
                          'lib/ui/splash_onboarding/Kolam-icon.png',
                          fit: BoxFit.contain,
                          color: isDark ? const Color(0xFFFFFFFF) : const Color(0xFF9E2A2B),
                          colorBlendMode: BlendMode.srcIn,
                          errorBuilder: (ctx, err, st) {
                            return Icon(
                              Icons.grain_rounded,
                              size: 140,
                              color: isDark ? AppColors.turmericGold : AppColors.terracottaRed,
                            );
                          },
                        );
                      },
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // App Title & Tagline
              FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  children: [
                    Text(
                      'KolamKari',
                      style: AppTypography.displayTitle.copyWith(
                        fontSize: 34,
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : AppColors.terracottaRed,
                        shadows: [
                          if (isDark)
                            BoxShadow(
                              color: AppColors.terracottaRed.withValues(alpha: 0.5),
                              blurRadius: 16,
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 24,
                          height: 1.5,
                          color: AppColors.turmericGold.withValues(alpha: 0.7),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'SACRED LIVING GEOMETRY',
                          style: AppTypography.tagText.copyWith(
                            fontSize: 11,
                            letterSpacing: 2.0,
                            fontWeight: FontWeight.w700,
                            color: isDark ? AppColors.turmericGold : const Color(0xFF8D6E63),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 24,
                          height: 1.5,
                          color: AppColors.turmericGold.withValues(alpha: 0.7),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const Spacer(flex: 3),
            ],
          ),
        ),
      ),
    );
  }
}
