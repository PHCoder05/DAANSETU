import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:reactive_forms/reactive_forms.dart';
import '../../../../config/theme.dart';
import '../../../../core/api/api_client.dart';
import '../../../../shared/widgets/custom_snackbar.dart';

class ContactSupportScreen extends ConsumerStatefulWidget {
  const ContactSupportScreen({super.key});

  @override
  ConsumerState<ContactSupportScreen> createState() => _ContactSupportScreenState();
}

class _ContactSupportScreenState extends ConsumerState<ContactSupportScreen> {
  final FormGroup form = fb.group({
    'issue': ['', Validators.required],
    'message': ['', Validators.required],
    'contactEmail': ['', Validators.email],
    'contactPhone': [''],
  });

  bool _isSubmitting = false;

  final List<String> _issueTypes = [
    'Verification Issue',
    'Donation Status',
    'Technical Problem',
    'NGO Complaint',
    'Account Deletion',
    'Other',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffoldLight,
      appBar: AppBar(
        title: const Text('Contact Support'),
        backgroundColor: AppTheme.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ReactiveForm(
          formGroup: form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 32),
              
              const Text('Issue Category', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 8),
              ReactiveDropdownField<String>(
                formControlName: 'issue',
                decoration: InputDecoration(
                  hintText: 'Select an issue type',
                  filled: true,
                  fillColor: AppTheme.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                items: _issueTypes.map((type) => DropdownMenuItem(value: type, child: Text(type))).toList(),
              ),
              
              const SizedBox(height: 20),
              
              const Text('Message', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 8),
              ReactiveTextField(
                formControlName: 'message',
                maxLines: 5,
                decoration: InputDecoration(
                  hintText: 'Describe your problem in detail...',
                  filled: true,
                  fillColor: AppTheme.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              
              const SizedBox(height: 20),
              
              const Text('Contact Email (Optional)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 8),
              ReactiveTextField(
                formControlName: 'contactEmail',
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  hintText: 'your@email.com',
                  filled: true,
                  fillColor: AppTheme.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              
              const SizedBox(height: 32),
              
              SliverToBoxAdapter(child: Container()), // Dummy for spacing
              
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryRed,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 4,
                    shadowColor: AppTheme.primaryRed.withValues(alpha: 0.3),
                  ),
                  child: _isSubmitting
                      ? const CircularProgressIndicator(color: AppTheme.white)
                      : const Text(
                          'Submit Request',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.white),
                        ),
                ),
              ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2, end: 0),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'How can we help?',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppTheme.charcoal),
        ).animate().fadeIn().slideX(),
        const SizedBox(height: 8),
        const Text(
          'Our support team typically responds within 24 hours.',
          style: TextStyle(fontSize: 14, color: AppTheme.gray),
        ).animate().fadeIn(delay: 200.ms),
      ],
    );
  }

  Future<void> _submitForm() async {
    if (form.valid) {
      setState(() => _isSubmitting = true);
      try {
        final apiClient = ref.read(apiClientProvider);
        await apiClient.requestSupport(
          issue: form.control('issue').value,
          message: form.control('message').value,
          contactEmail: form.control('contactEmail').value,
        );
        
        if (mounted) {
          CustomSnackBar.success(context, 'Support request submitted successfully');
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          CustomSnackBar.error(context, 'Failed to submit request. Please try again.');
        }
      } finally {
        if (mounted) setState(() => _isSubmitting = false);
      }
    } else {
      form.markAllAsTouched();
      CustomSnackBar.warning(context, 'Please fill in all required fields');
    }
  }
}
