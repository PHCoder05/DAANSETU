import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../config/routes.dart';
import '../../../../config/theme.dart';
import '../../../../core/api/api_client.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isSubmitting = false;
  bool _isSuccess = false;
  
  String? _previewUrl;
  
  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }
  
  Future<void> _submit() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _isSubmitting = true;
        _previewUrl = null;
      });
      
      try {
        final apiClient = ref.read(apiClientProvider);
        final response = await apiClient.requestPasswordReset(_emailController.text.trim());
        
        if (response.statusCode == 200) {
          // Check for previewUrl in response (for Ethereal Email test mode)
          if (response.data != null && 
              response.data['data'] != null && 
              response.data['data']['previewUrl'] != null) {
            _previewUrl = response.data['data']['previewUrl'];
          }
          
          setState(() => _isSuccess = true);
        }
      } catch (e) {
        // Even on error, show success message for security (don't reveal if email exists)
        setState(() => _isSuccess = true);
      } finally {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isSuccess) {
      return Scaffold(
        backgroundColor: AppTheme.white,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppTheme.success.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.mark_email_read_rounded,
                    size: 64,
                    color: AppTheme.success,
                  ),
                ).animate().scale(curve: Curves.easeOutBack),
                
                const SizedBox(height: 32),
                
                Text(
                  'Check Your Email',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ).animate().fade(),
                
                const SizedBox(height: 12),
                
                Text(
                  'We have sent password reset instructions to ${_emailController.text}',
                  style: TextStyle(color: AppTheme.gray),
                  textAlign: TextAlign.center,
                ).animate().fade(),
                
                // Show "Open Test Email" button if we have a preview URL
                if (_previewUrl != null) ...[
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.accentOrange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.accentOrange.withOpacity(0.3)),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Note: Since this is a Demo, no real email was sent.',
                          style: TextStyle(color: AppTheme.accentOrange, fontSize: 12, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              final Uri url = Uri.parse(_previewUrl!);
                              if (await canLaunchUrl(url)) {
                                await launchUrl(url, mode: LaunchMode.externalApplication);
                              }
                            }, 
                            icon: const Icon(Icons.open_in_browser_rounded),
                            label: const Text('Open Test Email Inbox'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.accentOrange,
                              side: BorderSide(color: AppTheme.accentOrange),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ).animate().fade().slideY(begin: 0.2, end: 0),
                ],
                
                const SizedBox(height: 32),
                
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: () => context.go(AppRoutes.login),
                    child: const Text('Back to Login'),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                TextButton(
                  onPressed: () {
                    setState(() {
                      _isSuccess = false;
                      _emailController.clear();
                      _previewUrl = null;
                    });
                  },
                  child: const Text('Try another email'),
                ),
              ],
            ),
          ),
        ),
      );
    }
    
    return Scaffold(
      backgroundColor: AppTheme.white,
      appBar: AppBar(
        backgroundColor: AppTheme.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.go(AppRoutes.login),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                
                // Icon
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryRed.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.lock_reset_rounded,
                      size: 48,
                      color: AppTheme.primaryRed,
                    ),
                  ),
                ).animate().scale(duration: 500.ms, curve: Curves.easeOutBack),
                
                const SizedBox(height: 32),
                
                // Title
                Text(
                  'Forgot Password?',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.black,
                  ),
                ).animate().fade().slideY(begin: 0.2, end: 0),
                
                const SizedBox(height: 8),
                
                Text(
                  "Don't worry! Enter your email and we'll send you reset instructions.",
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppTheme.gray,
                  ),
                ).animate(delay: 100.ms).fade(),
                
                const SizedBox(height: 40),
                
                // Email Field
                Text(
                  'Email Address',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    hintText: 'Enter your email',
                    prefixIcon: Icon(Icons.email_outlined, color: AppTheme.gray),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email';
                    }
                    if (!value.contains('@')) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ).animate(delay: 200.ms).fade().slideX(begin: -0.05, end: 0),
                
                const SizedBox(height: 32),
                
                // Submit Button
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submit,
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: AppTheme.white,
                            ),
                          )
                        : const Text('Send Reset Link'),
                  ),
                ).animate(delay: 300.ms).fade().slideY(begin: 0.1, end: 0),
                
                const SizedBox(height: 24),
                
                // Back to Login
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Remember your password? ',
                        style: TextStyle(color: AppTheme.darkGray),
                      ),
                      TextButton(
                        onPressed: () => context.go(AppRoutes.login),
                        child: const Text(
                          'Sign In',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ).animate(delay: 400.ms).fade(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
