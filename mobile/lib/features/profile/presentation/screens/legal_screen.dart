import 'package:flutter/material.dart';
import '../../../../config/theme.dart';
import 'package:go_router/go_router.dart';

class LegalScreen extends StatelessWidget {
  final String title;
  final String content;

  const LegalScreen({super.key, required this.title, required this.content});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.white,
      appBar: AppBar(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppTheme.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Text(
          content,
          style: const TextStyle(
            fontSize: 16,
            height: 1.6,
            color: AppTheme.darkGray,
          ),
        ),
      ),
    );
  }
}

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const LegalScreen(
      title: 'Privacy Policy',
      content: '''
**Privacy Policy for DAANSETU**

*Last updated: December 13, 2025*

**1. Introduction**
Welcome to DAANSETU. We value your trust and are committed to protecting your personal information. This Privacy Policy explains how we collect, use, and safeguard your data.

**2. Information We Collect**
We collect information you provide directly to us, such as your name, email address, phone number, and location when you register or create a donation. We may also collect images of donations you upload.

**3. How We Use Your Information**
We use your information to:
- Facilitate the donation process.
- Verify user identities and NGO credentials.
- Communicate with you regarding your donations or claims.
- Improve our platform and user experience.

**4. Data Sharing**
We do not sell your personal data. We share your contact information with verified NGOs only when a donation claim is confirmed, to facilitate pickup/delivery.

**5. Data Security**
We implement industry-standard security measures to protect your data. However, no method of transmission over the internet is 100% secure.

**6. Contact Us**
If you have any questions about this Privacy Policy, please contact us at support@daansetu.com.
      ''',
    );
  }
}

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const LegalScreen(
      title: 'Terms of Service',
      content: '''
**Terms of Service for DAANSETU**

*Last updated: December 13, 2025*

**1. Acceptance of Terms**
By accessing or using DAANSETU, you agree to be bound by these Terms of Service.

**2. User Responsibilities**
- You must provide accurate and complete information.
- You are responsible for the condition of items you donate.
- NGOs must ensure the proper use of donated items.

**3. Prohibited Content**
You may not post content that is illegal, offensive, or violates the rights of others.

**4. Accounts**
We reserve the right to suspend or terminate accounts that violate our terms.

**5. Limitation of Liability**
DAANSETU is a platform connecting donors and NGOs. We are not responsible for the actions of users off-platform.

**6. Changes to Terms**
We may modify these terms at any time. Continued use of the platform constitutes acceptance of updated terms.
      ''',
    );
  }
}
