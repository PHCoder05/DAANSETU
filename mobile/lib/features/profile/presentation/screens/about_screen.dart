import 'package:flutter/material.dart';
import '../../../../config/theme.dart';
import 'package:flutter_animate/flutter_animate.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffoldLight,
      appBar: AppBar(
        title: const Text('About DAANSETU'),
        backgroundColor: AppTheme.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 20),
            // Logo
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppTheme.white,
                shape: BoxShape.circle,
                boxShadow: AppTheme.cardShadow,
              ),
              padding: const EdgeInsets.all(16),
              child: Image.asset(
                'assets/images/logo.png',
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(Icons.volunteer_activism_rounded, size: 60, color: AppTheme.primaryRed);
                },
              ),
            ).animate().scale(duration: 500.ms, curve: Curves.easeOutBack),
            
            const SizedBox(height: 32),
            
            Text(
              'DAANSETU',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryRed,
              ),
            ).animate().fade().slideY(begin: 0.2, end: 0),
            
            Text(
              'Bridging Hearts, Sharing Hope',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppTheme.gray,
                fontStyle: FontStyle.italic,
              ),
            ).animate().fade(delay: 200.ms).slideY(begin: 0.2, end: 0),
            
            const SizedBox(height: 40),
            
            _buildSection(
              context, 
              'Our Mission', 
              'To connect generous donors with verified NGOs, making the process of donation transparent, efficient, and impactful. We believe in the power of giving to transform lives and communities.',
              delay: 300,
            ),
            
            _buildSection(
              context, 
              'How It Works', 
              'Donors can list items like food, clothes, medicines, and more. Verified NGOs can view these listings and claim them for their beneficiaries. Our platform ensures that your donations reach the right hands.',
              delay: 400,
            ),
            
            _buildSection(
              context, 
              'Join Us', 
              'Whether you have something to give or you represent an organization that needs support, DAANSETU is your platform. Together, we can build a bridge of kindness.',
              delay: 500,
            ),
            
            const SizedBox(height: 40),
            
            // Developer Credits Section
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primaryRed.withOpacity(0.05),
                    AppTheme.accentOrange.withOpacity(0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: AppTheme.borderRadiusMedium,
                border: Border.all(color: AppTheme.primaryRed.withOpacity(0.1)),
              ),
              child: Column(
                children: [
                  const Icon(Icons.code_rounded, color: AppTheme.primaryRed, size: 32),
                  const SizedBox(height: 12),
                  Text(
                    'Developed with ❤️ by',
                    style: TextStyle(
                      color: AppTheme.gray,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Pankaj Hadole',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.charcoal,
                    ),
                  ),
                ],
              ),
            ).animate().fade(delay: 600.ms).scale(begin: const Offset(0.95, 0.95)),
            
            const SizedBox(height: 24),
            
            const Text(
              'Version 1.0.0',
              style: TextStyle(color: AppTheme.gray),
            ),
            const SizedBox(height: 8),
            const Text(
              '© 2025 DAANSETU',
              style: TextStyle(color: AppTheme.gray),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSection(BuildContext context, String title, String content, {int delay = 0}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: AppTheme.borderRadiusMedium,
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppTheme.charcoal,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: AppTheme.darkGray,
              height: 1.5,
            ),
          ),
        ],
      ),
    ).animate().fade(delay: Duration(milliseconds: delay)).slideY(begin: 0.1, end: 0);
  }
}
