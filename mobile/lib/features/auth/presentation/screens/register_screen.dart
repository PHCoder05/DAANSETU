import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../../config/routes.dart';
import '../../../../config/constants.dart';
import '../../../../config/theme.dart';
import '../../../../shared/providers/auth_provider.dart';
import '../../../../shared/widgets/custom_snackbar.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  
  String _selectedRole = AppConstants.roleDonor;
  bool _obscurePassword = true;
  
  // NGO-specific fields
  final _registrationNumberController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    _registrationNumberController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
  
  Future<void> _register() async {
    if (_formKey.currentState?.validate() ?? false) {
      Map<String, dynamic> data = {
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'password': _passwordController.text,
        'role': _selectedRole,
        'phone': _phoneController.text.trim(),
      };
      
      if (_selectedRole == AppConstants.roleNgo) {
        data['ngoDetails'] = {
          'registrationNumber': _registrationNumberController.text.trim(),
          'description': _descriptionController.text.trim(),
        };
      }
      
      final success = await ref.read(authStateProvider.notifier).register(data);
      
      if (success && mounted) {
        CustomSnackBar.success(context, 'Welcome to DaanSetu! Account created.');
        await Future.delayed(const Duration(milliseconds: 500)); // Short delay to see the message
        if (mounted) context.go(AppRoutes.home);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final isKeyboardOpen = bottomInset > 0;
    
    return Scaffold(
      backgroundColor: AppTheme.white,
      resizeToAvoidBottomInset: true,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(isKeyboardOpen ? 40 : 56),
        child: AppBar(
          backgroundColor: AppTheme.white,
          toolbarHeight: isKeyboardOpen ? 40 : 56,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            onPressed: () => context.go(AppRoutes.login),
            iconSize: isKeyboardOpen ? 20 : 24,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: 20,
            vertical: isKeyboardOpen ? 8 : 16,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with Tagline - compresses when keyboard opens
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 200),
                          style: Theme.of(context).textTheme.headlineSmall!.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.black,
                            fontSize: isKeyboardOpen ? 18 : 24,
                          ),
                          child: const Text('Create Account'),
                        ),
                        // Hide tagline when keyboard is open
                        if (!isKeyboardOpen) ...[
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryRed.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'India\'s No.1 App for Seamless Donations',
                              style: TextStyle(
                                color: AppTheme.primaryRed,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                
                SizedBox(height: isKeyboardOpen ? 8 : 16),
                
                // Role Selection (Compact) - smaller when keyboard opens
                if (!isKeyboardOpen) ...[
                  Text('I want to join as', style: Theme.of(context).textTheme.labelMedium),
                  const SizedBox(height: 8),
                ],
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  height: isKeyboardOpen ? 50 : 80,
                  child: Row(
                    children: [
                      Expanded(
                        child: _RoleCard(
                          title: 'Donor',
                          subtitle: isKeyboardOpen ? '' : 'Donate',
                          icon: Icons.favorite_rounded,
                          isSelected: _selectedRole == AppConstants.roleDonor,
                          onTap: () => setState(() => _selectedRole = AppConstants.roleDonor),
                          compact: true,
                          ultraCompact: isKeyboardOpen,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _RoleCard(
                          title: 'NGO',
                          subtitle: isKeyboardOpen ? '' : 'Organization',
                          icon: Icons.business_rounded,
                          isSelected: _selectedRole == AppConstants.roleNgo,
                          onTap: () => setState(() => _selectedRole = AppConstants.roleNgo),
                          compact: true,
                          ultraCompact: isKeyboardOpen,
                        ),
                      ),
                    ],
                  ),
                ),
                
                SizedBox(height: isKeyboardOpen ? 8 : 16),
                
                // Fields (Expanded to fill space)
                Expanded(
                  child: SingleChildScrollView(
                    physics: const ClampingScrollPhysics(),
                    child: Column(
                      children: [
                        _buildField('Full Name', _nameController, 'Enter name', Icons.person_outline, isCompact: isKeyboardOpen),
                        _buildField('Email', _emailController, 'Enter email', Icons.email_outlined, keyboardType: TextInputType.emailAddress, isCompact: isKeyboardOpen),
                        _buildField('Phone', _phoneController, 'Enter phone', Icons.phone_outlined, keyboardType: TextInputType.phone, required: false, isCompact: isKeyboardOpen),
                        
                        // Password
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Password', style: Theme.of(context).textTheme.labelMedium),
                            const SizedBox(height: 4),
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              decoration: InputDecoration(
                                hintText: 'Password',
                                isDense: true,
                                contentPadding: EdgeInsets.all(isKeyboardOpen ? 10 : 12),
                                prefixIcon: Icon(Icons.lock_outline, size: 20, color: AppTheme.gray),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                    color: AppTheme.gray,
                                    size: 20,
                                  ),
                                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) return 'Required';
                                if (value.length < 6) return 'Min 6 chars';
                                return null;
                              },
                            ),
                            SizedBox(height: isKeyboardOpen ? 8 : 12),
                          ],
                        ),
                        
                        // NGO-specific fields
                        if (_selectedRole == AppConstants.roleNgo) ...[
                          Container(
                            padding: EdgeInsets.all(isKeyboardOpen ? 8 : 12),
                            decoration: BoxDecoration(
                              color: AppTheme.offWhite,
                              borderRadius: AppTheme.borderRadiusMedium,
                            ),
                            child: Column(
                              children: [
                                _buildField('Reg. Number', _registrationNumberController, 'Registration No.', Icons.numbers, isCompact: isKeyboardOpen),
                                _buildField('Description', _descriptionController, 'About NGO', Icons.description_outlined, maxLines: 2, required: false, isCompact: isKeyboardOpen),
                              ],
                            ),
                          ),
                          SizedBox(height: isKeyboardOpen ? 8 : 12),
                        ],
                      ],
                    ),
                  ),
                ),
                
                // Error Message
                if (authState.error != null)
                  Padding(
                     padding: const EdgeInsets.only(bottom: 6),
                     child: Text(authState.error!, style: const TextStyle(color: AppTheme.error, fontSize: 11)),
                  ),
                
                // Register Button
                SizedBox(
                  width: double.infinity,
                  height: isKeyboardOpen ? 44 : 48,
                  child: ElevatedButton(
                    onPressed: authState.isLoading ? null : _register,
                    child: authState.isLoading
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.white))
                        : Text(_selectedRole == AppConstants.roleNgo ? 'Register NGO' : 'Create Account'),
                  ),
                ),
                
                SizedBox(height: isKeyboardOpen ? 4 : 12),
                
                // Login Link - hide when keyboard is open to save space
                if (!isKeyboardOpen)
                  Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text("Already have an account? ", style: TextStyle(color: AppTheme.darkGray, fontSize: 12)),
                        InkWell(
                          onTap: () => context.go(AppRoutes.login),
                          child: const Text('Sign In', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.primaryRed)),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildField(String label, TextEditingController controller, String hint, IconData icon, {TextInputType? keyboardType, int maxLines = 1, bool required = true, bool isCompact = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelMedium),
        SizedBox(height: isCompact ? 4 : 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            isDense: isCompact,
            contentPadding: EdgeInsets.all(isCompact ? 10 : 12),
            prefixIcon: Icon(icon, color: AppTheme.gray, size: isCompact ? 18 : 22),
          ),
          validator: required ? (value) {
            if (value == null || value.isEmpty) return 'Please enter $label';
            return null;
          } : null,
        ),
        SizedBox(height: isCompact ? 12 : 20),
      ],
    );
  }
}

class _RoleCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;
  final bool compact;
  final bool ultraCompact;
  
  const _RoleCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isSelected,
    required this.onTap,
    this.compact = false,
    this.ultraCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.all(ultraCompact ? 8 : (compact ? 12 : 20)),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryRed : AppTheme.white,
          borderRadius: AppTheme.borderRadiusMedium,
          border: Border.all(
            color: isSelected ? AppTheme.primaryRed : AppTheme.lightGray,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected ? [
            BoxShadow(
              color: AppTheme.primaryRed.withOpacity(0.2),
              blurRadius: ultraCompact ? 6 : 12,
              offset: Offset(0, ultraCompact ? 2 : 4),
            ),
          ] : null,
        ),
        child: ultraCompact 
          ? Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: isSelected ? AppTheme.white : AppTheme.primaryRed,
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: isSelected ? AppTheme.white : AppTheme.black,
                  ),
                ),
              ],
            )
          : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: compact ? 28 : 36,
                  color: isSelected ? AppTheme.white : AppTheme.primaryRed,
                ),
                SizedBox(height: compact ? 8 : 12),
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: compact ? 14 : 16,
                    color: isSelected ? AppTheme.white : AppTheme.black,
                  ),
                ),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: compact ? 11 : 12,
                      color: isSelected ? AppTheme.white.withOpacity(0.8) : AppTheme.gray,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
      ),
    );
  }
}
