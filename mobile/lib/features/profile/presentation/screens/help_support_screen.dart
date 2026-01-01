import 'package:flutter/material.dart';
import '../../../../config/theme.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri)) {
      debugPrint('Could not launch $url');
    }
  }

  Future<void> _launchEmail() async {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: 'support@daansetu.com',
      query: 'subject=DAANSETU Support Request',
    );
    if (!await launchUrl(emailLaunchUri)) {
      debugPrint('Could not launch email');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffoldLight,
      appBar: AppBar(
        title: const Text('Help & Support'),
        backgroundColor: AppTheme.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildContactCard(
            context,
            icon: Icons.email_outlined,
            title: 'Email Support',
            subtitle: 'Get in touch with our support team',
            actionText: 'support@daansetu.com',
            onTap: _launchEmail,
          ),
          
          const SizedBox(height: 24),
          Text(
            'Frequently Asked Questions',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppTheme.gray,
            ),
          ),
          const SizedBox(height: 16),
          
          _buildFaqItem(
            'How do I make a donation?',
            'Go to the Home tab and click on the "+" button. Fill in the details of your donation, upload photos, and submit. NGOs will be able to see your donation and claim it.',
          ),
          _buildFaqItem(
            'Who can see my personal details?',
            'Only verified NGOs who claim your donation will be able to see your contact details to coordinate the pickup/delivery. Your privacy is important to us.',
          ),
          _buildFaqItem(
            'How are NGOs verified?',
            'We have a strict verification process where NGOs must submit their registration documents. Our admin team verifies each document before approving the NGO account.',
          ),
          _buildFaqItem(
            'What items can I donate?',
            'You can donate food, clothes, medicines, books, electronics, furniture, and more. Please ensure the items are in good condition and usable.',
          ),
          _buildFaqItem(
            'Is there a pickup service?',
            'Currently, the pickup needs to be coordinated between the donor and the NGO. We are working on partnering with delivery services soon.',
          ),
        ],
      ),
    );
  }

  Widget _buildContactCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required String actionText,
    required VoidCallback onTap,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: AppTheme.borderRadiusMedium,
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.primaryRed.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 32, color: AppTheme.primaryRed),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppTheme.gray),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: onTap,
            child: Text(
              actionText,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryRed,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFaqItem(String question, String answer) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: AppTheme.borderRadiusMedium,
        boxShadow: AppTheme.cardShadow,
      ),
      child: ExpansionTile(
        title: Text(
          question,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          Text(
            answer,
            style: const TextStyle(
              color: AppTheme.darkGray,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
