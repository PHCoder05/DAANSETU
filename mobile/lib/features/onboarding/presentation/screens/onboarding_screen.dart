import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../config/theme.dart';
import '../../../../config/routes.dart';
import '../../../auth/presentation/screens/splash_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingItem> _items = [
    OnboardingItem(
      title: 'Donate Excess Food',
      description: 'Connect with nearby NGOs to donate food, clothes, and essentials. Reduce waste and help those in need.',
      icon: Icons.volunteer_activism_rounded,
      gradientColors: [const Color(0xFFE23744), const Color(0xFFFF6B6B)],
      bgDecoColor: const Color(0xFFFFE0E3),
    ),
    OnboardingItem(
      title: 'Track Real-time',
      description: 'See exactly where your donation is. From pickup to delivery, track the journey on our live map.',
      icon: Icons.location_on_rounded,
      gradientColors: [const Color(0xFFF39C12), const Color(0xFFF9D423)],
      bgDecoColor: const Color(0xFFFFF3DB),
    ),
    OnboardingItem(
      title: 'Make an Impact',
      description: 'Earn impact points, climb the leaderboard, and collect badges for your contributions to society.',
      icon: Icons.emoji_events_rounded,
      gradientColors: [const Color(0xFF9B59B6), const Color(0xFFC39BD3)],
      bgDecoColor: const Color(0xFFF0E6F6),
    ),
  ];

  void _completeOnboarding() async {
    await SplashScreen.markOnboardingComplete();
    if (mounted) context.go(AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          // Animated background gradient
          AnimatedContainer(
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  _items[_currentPage].gradientColors[0].withOpacity(0.08),
                  _items[_currentPage].gradientColors[1].withOpacity(0.04),
                  AppTheme.white,
                ],
              ),
            ),
          ),

          // Decorative circles
          Positioned(
            top: -size.width * 0.3,
            right: -size.width * 0.2,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 600),
              width: size.width * 0.7,
              height: size.width * 0.7,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _items[_currentPage].bgDecoColor.withOpacity(0.5),
              ),
            ),
          ),
          Positioned(
            bottom: -size.width * 0.15,
            left: -size.width * 0.15,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 600),
              width: size.width * 0.5,
              height: size.width * 0.5,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _items[_currentPage].bgDecoColor.withOpacity(0.3),
              ),
            ),
          ),

          // Main content
          SafeArea(
            child: Column(
              children: [
                // Top bar with skip
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Page counter
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: _items[_currentPage].gradientColors[0].withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${_currentPage + 1} / ${_items.length}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: _items[_currentPage].gradientColors[0],
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: _completeOnboarding,
                        child: Text(
                          'Skip',
                          style: TextStyle(
                            color: AppTheme.darkGray,
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Page view
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: _items.length,
                    onPageChanged: (index) => setState(() => _currentPage = index),
                    itemBuilder: (context, index) {
                      final item = _items[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 40),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Icon with decorative rings
                            Stack(
                              alignment: Alignment.center,
                              children: [
                                // Outer ring
                                Container(
                                  width: 180,
                                  height: 180,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: item.gradientColors[0].withOpacity(0.1),
                                      width: 2,
                                    ),
                                  ),
                                ).animate().scale(delay: 100.ms, duration: 500.ms, curve: Curves.easeOutBack),
                                // Middle ring
                                Container(
                                  width: 150,
                                  height: 150,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: item.gradientColors[0].withOpacity(0.06),
                                  ),
                                ).animate().scale(delay: 200.ms, duration: 500.ms, curve: Curves.easeOutBack),
                                // Icon circle with gradient
                                Container(
                                  width: 110,
                                  height: 110,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: item.gradientColors,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: item.gradientColors[0].withOpacity(0.35),
                                        blurRadius: 30,
                                        offset: const Offset(0, 10),
                                      ),
                                    ],
                                  ),
                                  child: Icon(item.icon, size: 50, color: Colors.white),
                                ).animate().scale(delay: 300.ms, duration: 500.ms, curve: Curves.easeOutBack),
                              ],
                            ),

                            const SizedBox(height: 56),

                            // Title
                            Text(
                              item.title,
                              style: const TextStyle(
                                fontSize: 30,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.black,
                                letterSpacing: -0.5,
                                height: 1.2,
                              ),
                              textAlign: TextAlign.center,
                            ).animate().slideY(begin: 0.3, end: 0, delay: 200.ms).fade(delay: 200.ms),

                            const SizedBox(height: 16),

                            // Description
                            Text(
                              item.description,
                              style: TextStyle(
                                fontSize: 16,
                                color: AppTheme.darkGray,
                                height: 1.6,
                                fontWeight: FontWeight.w400,
                              ),
                              textAlign: TextAlign.center,
                            ).animate().slideY(begin: 0.3, end: 0, delay: 300.ms).fade(delay: 300.ms),
                          ],
                        ),
                      );
                    },
                  ),
                ),

                // Bottom controls
                Padding(
                  padding: const EdgeInsets.fromLTRB(40, 0, 40, 40),
                  child: Column(
                    children: [
                      // Pill indicators
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(_items.length, (index) {
                          final isActive = index == _currentPage;
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 400),
                            curve: Curves.easeOutCubic,
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            height: 6,
                            width: isActive ? 28 : 6,
                            decoration: BoxDecoration(
                              color: isActive
                                  ? _items[_currentPage].gradientColors[0]
                                  : AppTheme.lightGray,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          );
                        }),
                      ),

                      const SizedBox(height: 36),

                      // Action button with gradient
                      SizedBox(
                        width: double.infinity,
                        height: 58,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: _items[_currentPage].gradientColors,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: _items[_currentPage].gradientColors[0].withOpacity(0.4),
                                blurRadius: 16,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: () {
                              if (_currentPage < _items.length - 1) {
                                _pageController.nextPage(
                                  duration: const Duration(milliseconds: 400),
                                  curve: Curves.easeInOutCubic,
                                );
                              } else {
                                _completeOnboarding();
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  _currentPage < _items.length - 1 ? 'Continue' : 'Get Started',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Icon(
                                  _currentPage < _items.length - 1
                                      ? Icons.arrow_forward_rounded
                                      : Icons.rocket_launch_rounded,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class OnboardingItem {
  final String title;
  final String description;
  final IconData icon;
  final List<Color> gradientColors;
  final Color bgDecoColor;

  OnboardingItem({
    required this.title,
    required this.description,
    required this.icon,
    required this.gradientColors,
    required this.bgDecoColor,
  });
}
