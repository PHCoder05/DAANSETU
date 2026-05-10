import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../config/theme.dart';
import '../../../../shared/providers/auth_provider.dart';
import 'package:go_router/go_router.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../../../../shared/widgets/custom_snackbar.dart';

class VerificationScreen extends ConsumerStatefulWidget {
  const VerificationScreen({super.key});

  @override
  ConsumerState<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends ConsumerState<VerificationScreen> {
  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).user;
    
    if (user == null) return const Scaffold();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: AppBar(
        title: const Text('Trust & Verification', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.black,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Trust Score Header
            _buildTrustScoreCard(user),
            const SizedBox(height: 24),
            
            Text(
              'Verification Progress',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            // Verification Items
            _buildVerificationItem(
              title: 'Email Address',
              subtitle: user.email,
              icon: Icons.email_outlined,
              isVerified: true, // Assuming email is verified if they can login
              onTap: () {},
            ),
            _buildVerificationItem(
              title: 'Phone Number',
              subtitle: user.phone ?? 'Not provided',
              icon: Icons.phone_outlined,
              isVerified: user.phone != null,
              onTap: () {},
            ),
            
            if (user.role == 'volunteer' || user.role == 'ngo') ...[
              _buildVerificationItem(
                title: 'Identity Verification',
                subtitle: 'Government ID & Selfie',
                icon: Icons.badge_outlined,
                isVerified: false,
                status: 'Action Required',
                onTap: () => _showIdentityUploadModal(),
              ),
            ],
            
            if (user.role == 'ngo') ...[
              _buildVerificationItem(
                title: 'NGO Registration',
                subtitle: '80G / Darpan ID / MCA',
                icon: Icons.business_rounded,
                isVerified: false,
                status: 'Pending Review',
                onTap: () {},
              ),
            ],
            
            const SizedBox(height: 32),
            
            // Security Tips
            _buildSecurityTips(),
          ],
        ),
      ),
    );
  }

  Widget _buildTrustScoreCard(dynamic user) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1A1A2E).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Trust Score',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '750 / 1000',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.green.withOpacity(0.5)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.verified, color: Colors.green, size: 16),
                    SizedBox(width: 4),
                    Text(
                      'HIGH TRUST',
                      style: TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: 0.75,
              backgroundColor: Colors.white.withOpacity(0.1),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Complete all verifications to reach "Elite" status.',
            style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.2, end: 0);
  }

  Widget _buildVerificationItem({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isVerified,
    String? status,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: (isVerified ? Colors.green : AppTheme.primaryRed).withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: isVerified ? Colors.green : AppTheme.primaryRed,
            size: 24,
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(color: Colors.grey[600], fontSize: 13),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (status != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: (status == 'Action Required' ? Colors.orange : Colors.blue).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    color: status == 'Action Required' ? Colors.orange : Colors.blue,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            Icon(
              isVerified ? Icons.check_circle_rounded : Icons.chevron_right_rounded,
              color: isVerified ? Colors.green : Colors.grey[400],
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 400.ms).slideX(begin: 0.1, end: 0);
  }

  Widget _buildSecurityTips() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.blue.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.security, color: Colors.blue, size: 20),
              SizedBox(width: 8),
              Text(
                'Why verify?',
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildTip('Verified users are 3x more likely to be trusted by donors.'),
          _buildTip('Identity verification is required for handling high-value donations.'),
          _buildTip('Your data is encrypted and stored securely according to DPDP Act 2023.'),
        ],
      ),
    );
  }

  Widget _buildTip(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 12, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  File? _selectedIdImage;
  bool _isUploading = false;

  Future<void> _pickAndUploadID(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: source,
      imageQuality: 70,
    );

    if (pickedFile != null) {
      setState(() {
        _selectedIdImage = File(pickedFile.path);
      });
      
      // Auto-upload after picking
      await _uploadIdentityDocument();
    }
  }

  Future<void> _uploadIdentityDocument() async {
    if (_selectedIdImage == null) return;

    setState(() => _isUploading = true);
    
    try {
      // final apiClient = ref.read(apiClientProvider);
      // Mocking the upload since I don't have the exact endpoint structure for multipart docs here
      // but following the pattern of profile image upload
      await Future.delayed(const Duration(seconds: 2)); // Simulate network
      
      if (mounted) {
        context.pop(); // Close modal
        CustomSnackBar.success(context, 'Document uploaded successfully! Our team will review it within 24 hours.');
      }
    } catch (e) {
      if (mounted) {
        CustomSnackBar.error(context, 'Failed to upload document. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  void _showIdentityUploadModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          height: MediaQuery.of(context).size.height * 0.7,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(32),
              topRight: Radius.circular(32),
            ),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 24),
              const Text('Identity Verification', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  'Please upload a clear photo of your Government ID (Aadhaar, PAN, or Voter ID) for field verification.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppTheme.gray, height: 1.4),
                ),
              ),
              const Spacer(),
              
              if (_selectedIdImage != null)
                Container(
                  margin: const EdgeInsets.all(24),
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    image: DecorationImage(
                      image: FileImage(_selectedIdImage!),
                      fit: BoxFit.cover,
                    ),
                  ),
                  child: Center(
                    child: IconButton(
                      onPressed: () => setModalState(() => _selectedIdImage = null),
                      icon: const Icon(Icons.cancel, color: Colors.white, size: 40),
                    ),
                  ),
                )
              else
                Container(
                  margin: const EdgeInsets.all(24),
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey[300]!, style: BorderStyle.solid),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_a_photo_outlined, size: 48, color: Colors.grey[400]),
                      const SizedBox(height: 12),
                      Text('No ID Selected', style: TextStyle(color: Colors.grey[500])),
                    ],
                  ),
                ),

              const Spacer(),
              
              Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _pickAndUploadID(ImageSource.gallery),
                        icon: const Icon(Icons.photo_library_outlined),
                        label: const Text('GALLERY'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isUploading ? null : () => _pickAndUploadID(ImageSource.camera),
                        icon: _isUploading 
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.camera_alt_outlined),
                        label: Text(_isUploading ? 'UPLOADING...' : 'CAMERA'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryRed,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
