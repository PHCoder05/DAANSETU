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
      color: AppTheme.primaryRed,
    ),
    OnboardingItem(
      title: 'Track Real-time',
      description: 'See exactly where your donation is. From pickup to delivery, track the journey on our live map.',
      icon: Icons.location_on_rounded,
      color: AppTheme.accentOrange,
    ),
    OnboardingItem(
      title: 'Make an Impact',
      description: 'Earn impact points, climb the leaderboard, and collect badges for your contributions to society.',
      icon: Icons.emoji_events_rounded,
      color: Color(0xFF9B59B6),
    ),
  ];
  
  /// Mark onboarding as complete and navigate to login
  void _completeOnboarding() async {
    await SplashScreen.markOnboardingComplete();
    if (mounted) context.go(AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.white,
      body: SafeArea(
        child: Column(
          children: [
            // Skip Button
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: _completeOnboarding,  // Mark complete on skip
                child: const Text('Skip', style: TextStyle(color: AppTheme.gray, fontWeight: FontWeight.bold)),
              ),
            ),
            
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _items.length,
                onPageChanged: (index) => setState(() => _currentPage = index),
                itemBuilder: (context, index) {
                  final item = _items[index];
                  return Padding(
                    padding: const EdgeInsets.all(40.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Icon Circle
                        Container(
                          padding: const EdgeInsets.all(30),
                          decoration: BoxDecoration(
                            color: item.color.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(item.icon, size: 80, color: item.color),
                        ).animate().scale(delay: 200.ms, curve: Curves.easeOutBack),
                        
                        const SizedBox(height: 48),
                        
                        // Text
                        Text(
                          item.title,
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.black,
                          ),
                          textAlign: TextAlign.center,
                        ).animate().slideY(begin: 0.2, end: 0).fade(),
                        
                        const SizedBox(height: 16),
                        
                        Text(
                          item.description,
                          style: TextStyle(
                            fontSize: 16,
                            color: AppTheme.gray,
                            height: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ).animate().slideY(begin: 0.2, end: 0, delay: 100.ms).fade(),
                      ],
                    ),
                  );
                },
              ),
            ),
            
            // Bottom Controls
            Padding(
              padding: const EdgeInsets.all(40.0),
              child: Column(
                children: [
                  // Indicators
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_items.length, (index) {
                      final isActive = index == _currentPage;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        height: 8,
                        width: isActive ? 24 : 8,
                        decoration: BoxDecoration(
                          color: isActive ? _items[_currentPage].color : AppTheme.lightGray,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () {
                        if (_currentPage < _items.length - 1) {
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        } else {
                          _completeOnboarding();  // Mark complete on Get Started
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _items[_currentPage].color,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      child: Text(
                        _currentPage < _items.length - 1 ? 'Next' : 'Get Started',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ).animate(target: _currentPage == _items.length - 1 ? 1 : 0),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class OnboardingItem {
  final String title;
  final String description;
  final IconData icon;
  final Color color;

  OnboardingItem({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });
}
