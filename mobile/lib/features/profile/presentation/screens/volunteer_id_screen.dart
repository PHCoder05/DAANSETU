import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../../config/theme.dart';
import '../../../../shared/providers/auth_provider.dart';

class VolunteerIdScreen extends ConsumerWidget {
  const VolunteerIdScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).user;
    
    return Scaffold(
      backgroundColor: AppTheme.scaffoldLight,
      appBar: AppBar(
        title: const Text('Digital Volunteer ID'),
        backgroundColor: AppTheme.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Text(
              'Show this ID to donors or authorities to verify your identity as a DaanSetu representative.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.gray, fontSize: 13),
            ),
            const SizedBox(height: 32),
            
            // The ID Card
            _buildIdCard(context, user),
            
            const SizedBox(height: 40),
            
            // Security Info
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.lightGray),
              ),
              child: const Column(
                children: [
                  Row(
                    children: [
                      Icon(Icons.security_rounded, color: AppTheme.primaryRed),
                      SizedBox(width: 12),
                      Text('Security Features', style: TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  Divider(height: 24),
                  _SecurityFeatureItem(text: 'Real-time verification via QR Code'),
                  _SecurityFeatureItem(text: 'Encrypted user credentials'),
                  _SecurityFeatureItem(text: 'Official NGO partnership badge'),
                ],
              ),
            ).animate().fadeIn(delay: 400.ms),
            
            const SizedBox(height: 24),
            
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.download_rounded),
                label: const Text('Save to Gallery'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIdCard(BuildContext context, dynamic user) {
    return Container(
      width: double.infinity,
      height: 480,
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            // Top Accent
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 120,
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppTheme.primaryRed, Color(0xFFC0392B)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: const Padding(
                  padding: EdgeInsets.all(20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'DAANSETU',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 2),
                      ),
                      Icon(Icons.verified_user_rounded, color: Colors.white, size: 28),
                    ],
                  ),
                ),
              ),
            ),
            
            // Photo & Info
            Positioned(
              top: 80,
              left: 0,
              right: 0,
              child: Column(
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 4),
                      boxShadow: AppTheme.cardShadow,
                    ),
                    child: CircleAvatar(
                      radius: 56,
                      backgroundColor: AppTheme.offWhite,
                      backgroundImage: user?.profileImage != null ? NetworkImage(user!.profileImage!) : null,
                      child: user?.profileImage == null ? const Icon(Icons.person, size: 64, color: AppTheme.gray) : null,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    user?.name ?? 'John Doe',
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryRed.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      user?.role?.toUpperCase() ?? 'VOLUNTEER',
                      style: const TextStyle(color: AppTheme.primaryRed, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Trust Score
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildStatItem('Reputation', '750+'),
                      Container(width: 1, height: 30, color: AppTheme.lightGray, margin: const EdgeInsets.symmetric(horizontal: 24)),
                      _buildStatItem('Role', 'Elite Partner'),
                    ],
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // QR Verification
                  QrImageView(
                    data: 'DAANSETU-VERIFY-${user?.id}',
                    version: QrVersions.auto,
                    size: 100.0,
                    eyeStyle: const QrEyeStyle(
                      eyeShape: QrEyeShape.square,
                      color: AppTheme.black,
                    ),
                    dataModuleStyle: const QrDataModuleStyle(
                      dataModuleShape: QrDataModuleShape.square,
                      color: AppTheme.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'SCAN TO VERIFY',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1, color: AppTheme.gray),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ).animate().scale(duration: 500.ms, curve: Curves.easeOutBack);
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.gray)),
      ],
    );
  }
}

class _SecurityFeatureItem extends StatelessWidget {
  final String text;
  const _SecurityFeatureItem({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline, size: 16, color: AppTheme.success),
          const SizedBox(width: 8),
          Text(text, style: const TextStyle(fontSize: 13, color: AppTheme.darkGray)),
        ],
      ),
    );
  }
}
