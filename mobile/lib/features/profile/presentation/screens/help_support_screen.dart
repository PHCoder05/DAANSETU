import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../../config/theme.dart';
import '../../../../config/routes.dart';
import '../../../../core/api/api_client.dart';
import 'package:url_launcher/url_launcher.dart';

final mySupportRequestsProvider = FutureProvider.autoDispose<List<dynamic>>((ref) async {
  final apiClient = ref.watch(apiClientProvider);
  final response = await apiClient.getMySupportRequests();
  if (response.statusCode == 200) {
    return response.data['data'] as List? ?? [];
  }
  return [];
});

class HelpSupportScreen extends ConsumerWidget {
  const HelpSupportScreen({super.key});

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
  Widget build(BuildContext context, WidgetRef ref) {
    final requestsAsync = ref.watch(mySupportRequestsProvider);

    return Scaffold(
      backgroundColor: AppTheme.scaffoldLight,
      appBar: AppBar(
        title: const Text('Help & Support'),
        backgroundColor: AppTheme.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildRaiseTicketCard(context),
          const SizedBox(height: 16),
          _buildContactCard(
            context,
            icon: Icons.chat_bubble_outline_rounded,
            title: 'Live Support Chat',
            subtitle: 'Chat with our admin team now',
            actionText: 'Live Chat',
            onTap: () => context.push('/chat/admin_support', extra: {'name': 'DaanSetu Support'}),
          ),
          const SizedBox(height: 16),
          _buildContactCard(
            context,
            icon: Icons.email_outlined,
            title: 'Email Support',
            subtitle: 'Get in touch with our support team',
            actionText: 'support@daansetu.com',
            onTap: _launchEmail,
          ),
          
          const SizedBox(height: 32),
          
          _buildMyTicketsSection(context, requestsAsync),
          
          const SizedBox(height: 32),
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

  Widget _buildRaiseTicketCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primaryRed, AppTheme.primaryRed.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: AppTheme.borderRadiusMedium,
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryRed.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          const Icon(Icons.support_agent_rounded, size: 48, color: AppTheme.white),
          const SizedBox(height: 16),
          const Text(
            'Need Technical Assistance?',
            style: TextStyle(color: AppTheme.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Raise a support ticket and our team will get back to you shortly.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.offWhite, fontSize: 13),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => context.go('${AppRoutes.profile}/help-support/contact'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.white,
              foregroundColor: AppTheme.primaryRed,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            ),
            child: const Text('Raise a Ticket', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    ).animate().fadeIn().scale(delay: 100.ms);
  }

  Widget _buildMyTicketsSection(BuildContext context, AsyncValue<List<dynamic>> requestsAsync) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'My Recent Tickets',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppTheme.gray,
          ),
        ),
        const SizedBox(height: 12),
        requestsAsync.when(
          data: (requests) {
            if (requests.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(24),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppTheme.white,
                  borderRadius: AppTheme.borderRadiusMedium,
                  border: Border.all(color: AppTheme.offWhite),
                ),
                child: const Center(
                  child: Text('No tickets found', style: TextStyle(color: AppTheme.gray)),
                ),
              );
            }
            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: requests.length > 3 ? 3 : requests.length,
              itemBuilder: (context, index) {
                final ticket = requests[index];
                return _buildTicketItem(ticket);
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Text('Error: $e'),
        ),
      ],
    );
  }

  Widget _buildTicketItem(Map<String, dynamic> ticket) {
    final status = ticket['status'] ?? 'pending';
    final color = status == 'resolved' ? AppTheme.success : AppTheme.warning;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.confirmation_number_outlined, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ticket['issue'] ?? 'Unknown Issue',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                Text(
                  ticket['message'] ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: AppTheme.gray),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              status.toUpperCase(),
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color),
            ),
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
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.primaryRed.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 24, color: AppTheme.primaryRed),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Text(subtitle, style: const TextStyle(color: AppTheme.gray, fontSize: 12)),
              ],
            ),
          ),
          IconButton(
            onPressed: onTap,
            icon: const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: AppTheme.gray),
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
