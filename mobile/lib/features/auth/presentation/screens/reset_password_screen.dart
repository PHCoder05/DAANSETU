import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../../config/routes.dart';
import '../../../../config/theme.dart';
import '../../../../core/api/api_client.dart';
import '../../../../shared/widgets/custom_snackbar.dart';

class ResetPasswordScreen extends ConsumerStatefulWidget {
  final String token;
  const ResetPasswordScreen({super.key, required this.token});

  @override
  ConsumerState<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isSubmitting = false;
  bool _isValidating = true;
  bool _isValid = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _verifyToken();
  }

  Future<void> _verifyToken() async {
    try {
      final apiClient = ref.read(apiClientProvider);
      final response = await apiClient.verifyResetToken(widget.token);
      if (response.statusCode == 200) {
        setState(() {
          _isValid = true;
          _isValidating = false;
        });
      }
    } catch (e) {
      setState(() => _isValidating = false);
      if (mounted) {
        CustomSnackBar.error(context, 'Invalid or expired reset link');
        context.go(AppRoutes.login);
      }
    }
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() => _isSubmitting = true);
      try {
        final apiClient = ref.read(apiClientProvider);
        final response = await apiClient.resetPassword(widget.token, _passwordController.text.trim());
        
        if (response.statusCode == 200) {
          if (mounted) {
            CustomSnackBar.success(context, 'Password reset successfully! Please login with your new password.');
            context.go(AppRoutes.login);
          }
        }
      } catch (e) {
        if (mounted) {
          CustomSnackBar.error(context, 'Failed to reset password. The link may be expired.');
        }
      } finally {
        if (mounted) setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isValidating) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppTheme.primaryRed)),
      );
    }

    if (!_isValid) return const SizedBox.shrink();

    return Scaffold(
      backgroundColor: AppTheme.white,
      appBar: AppBar(
        backgroundColor: AppTheme.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppTheme.black),
          onPressed: () => context.go(AppRoutes.login),
        ),
        title: const Text('Reset Password', style: TextStyle(color: AppTheme.black, fontWeight: FontWeight.bold)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Create New Password',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppTheme.black),
                ).animate().fadeIn().slideX(),
                const SizedBox(height: 8),
                Text(
                  'Your new password must be different from previous passwords.',
                  style: TextStyle(color: AppTheme.gray, fontSize: 14),
                ).animate().fadeIn(delay: 100.ms),
                
                const SizedBox(height: 40),
                
                Text('New Password', style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: AppTheme.inputDecoration('Enter new password').copyWith(
                    prefixIcon: const Icon(Icons.lock_outline_rounded),
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  validator: (v) => (v?.length ?? 0) < 6 ? 'Password must be at least 6 characters' : null,
                ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),
                
                const SizedBox(height: 24),
                
                Text('Confirm Password', style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscurePassword,
                  decoration: AppTheme.inputDecoration('Confirm new password').copyWith(
                    prefixIcon: const Icon(Icons.lock_outline_rounded),
                  ),
                  validator: (v) => v != _passwordController.text ? 'Passwords do not match' : null,
                ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1),
                
                const SizedBox(height: 40),
                
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.black,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: _isSubmitting
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Reset Password', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.1)),
                  ),
                ).animate().fadeIn(delay: 400.ms).scale(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
