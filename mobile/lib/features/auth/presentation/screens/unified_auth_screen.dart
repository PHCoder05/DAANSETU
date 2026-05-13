import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../../config/routes.dart';
import '../../../../config/constants.dart';
import '../../../../config/theme.dart';
import '../../../../shared/providers/auth_provider.dart';
import '../../../../shared/widgets/custom_snackbar.dart';

/// Unified authentication screen - Zomato-style single screen for login/signup
/// Auto-detects whether user is new or existing based on email
class UnifiedAuthScreen extends ConsumerStatefulWidget {
  const UnifiedAuthScreen({super.key});

  @override
  ConsumerState<UnifiedAuthScreen> createState() => _UnifiedAuthScreenState();
}

class _UnifiedAuthScreenState extends ConsumerState<UnifiedAuthScreen> 
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  
  // NGO-specific fields
  final _registrationNumberController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  bool _obscurePassword = true;
  String _selectedRole = AppConstants.roleDonor;
  
  // Auth flow states
  AuthFlowState _flowState = AuthFlowState.emailEntry;
  bool _isCheckingEmail = false;
  bool _isUserExists = false;
  
  late AnimationController _animationController;
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }
  
  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _registrationNumberController.dispose();
    _descriptionController.dispose();
    _animationController.dispose();
    super.dispose();
  }
  
  Future<void> _checkEmail() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      CustomSnackBar.error(context, 'Please enter a valid email');
      return;
    }
    
    setState(() => _isCheckingEmail = true);
    HapticFeedback.lightImpact();
    
    try {
      // Check if email exists via API
      final exists = await ref.read(authStateProvider.notifier).checkEmailExists(email);
      
      setState(() {
        _isUserExists = exists;
        _flowState = AuthFlowState.credentials;
        _isCheckingEmail = false;
      });
      
      _animationController.forward();
      HapticFeedback.mediumImpact();
    } catch (e) {
      // On error, default to showing full registration form
      setState(() {
        _isUserExists = false;
        _flowState = AuthFlowState.credentials;
        _isCheckingEmail = false;
      });
      _animationController.forward();
    }
  }
  
  void _goBackToEmail() {
    HapticFeedback.selectionClick();
    setState(() {
      _flowState = AuthFlowState.emailEntry;
      _passwordController.clear();
      _nameController.clear();
      _phoneController.clear();
    });
    _animationController.reverse();
  }
  
  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    
    HapticFeedback.mediumImpact();
    
    if (_isUserExists) {
      // Login
      final success = await ref.read(authStateProvider.notifier).login(
        _emailController.text.trim(),
        _passwordController.text,
      );
      
      if (success && mounted) {
        HapticFeedback.heavyImpact();
        // Small delay to ensure state is fully updated
        await Future.delayed(const Duration(milliseconds: 100));
        if (mounted) _navigateAfterAuth();
      }
    } else {
      // Register
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
        HapticFeedback.heavyImpact();
        CustomSnackBar.success(context, 'Welcome to DaanSetu!');
        await Future.delayed(const Duration(milliseconds: 300));
        if (mounted) _navigateAfterAuth();
      }
    }
  }
  
  void _navigateAfterAuth() {
    final user = ref.read(authStateProvider).user;
    debugPrint('_navigateAfterAuth: user=${user?.name}, role=${user?.role}, isAdmin=${user?.isAdmin}');
    
    if (user?.isAdmin == true) {
      debugPrint('_navigateAfterAuth: Navigating to admin dashboard');
      context.go(AppRoutes.adminDashboard);
    } else {
      debugPrint('_navigateAfterAuth: Navigating to home');
      context.go(AppRoutes.home);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final isKeyboardOpen = bottomInset > 50;
    final screenHeight = MediaQuery.of(context).size.height;
    
    return Scaffold(
      backgroundColor: AppTheme.white,
      resizeToAvoidBottomInset: true,
      body: GestureDetector(
        // Allow tapping outside to dismiss keyboard
        onTap: () => FocusScope.of(context).unfocus(),
        child: Stack(
          children: [
            // Background gradient
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                height: screenHeight * 0.4,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppTheme.primaryRed.withValues(alpha: 0.08),
                      AppTheme.accentOrange.withValues(alpha: 0.05),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            
            // Decorative circles - use Opacity instead of conditional removal
            AnimatedOpacity(
              duration: const Duration(milliseconds: 150),
              opacity: isKeyboardOpen ? 0 : 1,
              child: IgnorePointer(
                child: Stack(
                  children: [
                    // Floating gradient orbs for modern look
                    Positioned(
                      top: -40,
                      right: -30,
                      child: Container(
                        width: 160,
                        height: 160,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              AppTheme.primaryRed.withValues(alpha: 0.3),
                              AppTheme.primaryRed.withValues(alpha: 0.05),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 80,
                      left: -60,
                      child: Container(
                        width: 140,
                        height: 140,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              AppTheme.accentOrange.withValues(alpha: 0.25),
                              AppTheme.accentOrange.withValues(alpha: 0.05),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 200,
                      right: 20,
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              Colors.green.withValues(alpha: 0.2),
                              Colors.green.withValues(alpha: 0.05),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Main content
            SafeArea(
              child: Column(
                children: [
                  // Header section - Zomato style with colorful gradient
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: isKeyboardOpen ? 12 : 20,
                    ),
                    decoration: BoxDecoration(
                      gradient: isKeyboardOpen ? null : LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppTheme.primaryRed,
                          AppTheme.primaryRed.withValues(alpha: 0.9),
                          const Color(0xFFFF6B6B),
                        ],
                      ),
                      borderRadius: isKeyboardOpen ? null : const BorderRadius.only(
                        bottomLeft: Radius.circular(32),
                        bottomRight: Radius.circular(32),
                      ),
                      boxShadow: isKeyboardOpen ? null : [
                        BoxShadow(
                          color: AppTheme.primaryRed.withValues(alpha: 0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Back button row (only in credentials state)
                        if (_flowState == AuthFlowState.credentials)
                          Align(
                            alignment: Alignment.centerLeft,
                            child: GestureDetector(
                              onTap: _goBackToEmail,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: isKeyboardOpen 
                                    ? AppTheme.offWhite 
                                    : Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.arrow_back_ios_new_rounded,
                                  size: 18,
                                  color: isKeyboardOpen ? AppTheme.darkGray : Colors.white,
                                ),
                              ),
                            ),
                          ),
                        
                        SizedBox(height: _flowState == AuthFlowState.credentials ? 8 : 0),
                        
                        // Logo icon
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: isKeyboardOpen ? 40 : 64,
                          height: isKeyboardOpen ? 40 : 64,
                          decoration: BoxDecoration(
                            color: isKeyboardOpen ? AppTheme.primaryRed : Colors.white,
                            borderRadius: BorderRadius.circular(isKeyboardOpen ? 10 : 16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.15),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.volunteer_activism_rounded,
                            size: isKeyboardOpen ? 20 : 32,
                            color: isKeyboardOpen ? Colors.white : AppTheme.primaryRed,
                          ),
                        ),
                        
                        // App name and tagline 
                        AnimatedSize(
                          duration: const Duration(milliseconds: 200),
                          child: AnimatedOpacity(
                            duration: const Duration(milliseconds: 150),
                            opacity: isKeyboardOpen ? 0 : 1,
                            child: isKeyboardOpen 
                              ? const SizedBox.shrink()
                              : Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const SizedBox(height: 14),
                                    Text(
                                      'DAANSETU',
                                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                        letterSpacing: 3,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: Colors.white.withValues(alpha: 0.3),
                                          width: 1,
                                        ),
                                      ),
                                      child: const Text(
                                        '🇮🇳 India\'s #1 Donation Platform',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                  ],
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Form section
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const ClampingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Dynamic title
                            Text(
                              _flowState == AuthFlowState.emailEntry
                                  ? 'Get Started'
                                  : (_isUserExists ? 'Welcome Back!' : 'Create Account'),
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.black,
                                fontSize: 22,
                              ),
                            ),
                            
                            // Subtitle - use AnimatedOpacity
                            AnimatedOpacity(
                              duration: const Duration(milliseconds: 150),
                              opacity: isKeyboardOpen ? 0 : 1,
                              child: AnimatedSize(
                                duration: const Duration(milliseconds: 200),
                                child: isKeyboardOpen
                                  ? const SizedBox(height: 8)
                                  : Padding(
                                      padding: const EdgeInsets.only(top: 4, bottom: 8),
                                      child: Text(
                                        _flowState == AuthFlowState.emailEntry
                                            ? 'Enter your email to continue'
                                            : (_isUserExists 
                                                ? 'Sign in to continue making a difference' 
                                                : 'Join our community of change-makers'),
                                        style: const TextStyle(
                                          color: AppTheme.gray,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                              ),
                            ),
                            
                            const SizedBox(height: 16),
                            
                            // Email field
                            _buildEmailField(),
                            
                            // Additional fields based on flow state
                            if (_flowState == AuthFlowState.credentials) ...[
                              const SizedBox(height: 16),
                              
                              // Show different fields for login vs register
                              if (_isUserExists)
                                _buildLoginFields(authState)
                              else
                                _buildRegistrationFields(isKeyboardOpen),
                            ],
                            
                            // Error message
                            if (authState.error != null) ...[
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppTheme.error.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.error_outline, color: AppTheme.error, size: 18),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        authState.error!,
                                        style: const TextStyle(color: AppTheme.error, fontSize: 13),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            
                            const SizedBox(height: 20),
                            
                            // Main action button
                            _buildActionButton(authState),
                            
                            // Forgot password link (only for login)
                            if (_flowState == AuthFlowState.credentials && _isUserExists) ...[
                              const SizedBox(height: 12),
                              Center(
                                child: TextButton(
                                  onPressed: () => context.push(AppRoutes.forgotPassword),
                                  child: const Text(
                                    'Forgot Password?',
                                    style: TextStyle(fontWeight: FontWeight.w500),
                                  ),
                                ),
                              ),
                            ],
                            
                            // Toggle between login/register hint  - use opacity
                            AnimatedOpacity(
                              duration: const Duration(milliseconds: 150),
                              opacity: (!isKeyboardOpen && _flowState == AuthFlowState.credentials) ? 1 : 0,
                              child: (!isKeyboardOpen && _flowState == AuthFlowState.credentials)
                                ? Center(
                                    child: TextButton(
                                      onPressed: () {
                                        setState(() => _isUserExists = !_isUserExists);
                                        HapticFeedback.selectionClick();
                                      },
                                      child: Text(
                                        _isUserExists 
                                            ? "Don't have an account? Sign Up" 
                                            : 'Already have an account? Sign In',
                                        style: const TextStyle(
                                          color: AppTheme.darkGray,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                  )
                                : const SizedBox.shrink(),
                            ),
                            
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildEmailField() {
    final isEditable = _flowState == AuthFlowState.emailEntry;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Email', style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 6),
        TextFormField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          textInputAction: isEditable ? TextInputAction.done : TextInputAction.next,
          readOnly: !isEditable,
          onFieldSubmitted: isEditable ? (_) => _checkEmail() : null,
          style: TextStyle(
            color: isEditable ? AppTheme.black : AppTheme.darkGray,
          ),
          decoration: InputDecoration(
            hintText: 'Enter your email',
            prefixIcon: const Icon(Icons.email_outlined, color: AppTheme.gray),
            suffixIcon: !isEditable
                ? IconButton(
                    icon: const Icon(Icons.edit, size: 18),
                    color: AppTheme.gray,
                    onPressed: _goBackToEmail,
                  )
                : null,
            filled: !isEditable,
            fillColor: !isEditable ? AppTheme.offWhite : null,
          ),
          validator: (value) {
            if (value == null || value.isEmpty) return 'Please enter your email';
            if (!value.contains('@')) return 'Please enter a valid email';
            return null;
          },
        ),
      ],
    );
  }
  
  Widget _buildLoginFields(AuthState authState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Password', style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 6),
        TextFormField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          textInputAction: TextInputAction.done,
          onFieldSubmitted: (_) => _submit(),
          decoration: InputDecoration(
            hintText: 'Enter your password',
            prefixIcon: const Icon(Icons.lock_outline, color: AppTheme.gray),
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                color: AppTheme.gray,
              ),
              onPressed: () {
                HapticFeedback.selectionClick();
                setState(() => _obscurePassword = !_obscurePassword);
              },
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) return 'Please enter your password';
            return null;
          },
        ),
      ],
    ).animate().fade().slideY(begin: 0.1, end: 0);
  }
  
  Widget _buildRegistrationFields(bool isKeyboardOpen) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Role selection (compact)
        Text('I want to join as', style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _RoleChip(
                label: 'Donor',
                icon: Icons.favorite_rounded,
                isSelected: _selectedRole == AppConstants.roleDonor,
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _selectedRole = AppConstants.roleDonor);
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _RoleChip(
                label: 'NGO',
                icon: Icons.business_rounded,
                isSelected: _selectedRole == AppConstants.roleNgo,
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _selectedRole = AppConstants.roleNgo);
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _RoleChip(
                label: 'Volunteer',
                icon: Icons.handshake_rounded,
                isSelected: _selectedRole == AppConstants.roleVolunteer,
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _selectedRole = AppConstants.roleVolunteer);
                },
              ),
            ),
          ],
        ),
        
        SizedBox(height: isKeyboardOpen ? 12 : 16),
        
        // Name field
        _buildTextField('Full Name', _nameController, 'Enter your name', Icons.person_outline),
        
        // Password field
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Password', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 6),
            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                hintText: 'Min. 6 characters',
                prefixIcon: const Icon(Icons.lock_outline, color: AppTheme.gray),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    color: AppTheme.gray,
                  ),
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    setState(() => _obscurePassword = !_obscurePassword);
                  },
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) return 'Required';
                if (value.length < 6) return 'Min 6 characters';
                return null;
              },
            ),
            const SizedBox(height: 12),
          ],
        ),
        
        // Phone field (optional)
        _buildTextField('Phone (Optional)', _phoneController, 'Enter phone number', Icons.phone_outlined, required: false, keyboardType: TextInputType.phone),
        
        // NGO-specific fields
        if (_selectedRole == AppConstants.roleNgo) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.offWhite,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'NGO Details',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryRed,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 12),
                _buildTextField('Registration Number', _registrationNumberController, 'NGO registration no.', Icons.numbers),
                _buildTextField('Description', _descriptionController, 'About your NGO', Icons.description_outlined, maxLines: 2, required: false),
              ],
            ),
          ).animate().fade().slideY(begin: 0.1, end: 0),
        ],
      ],
    ).animate().fade().slideY(begin: 0.1, end: 0);
  }
  
  Widget _buildTextField(
    String label, 
    TextEditingController controller, 
    String hint, 
    IconData icon, 
    {bool required = true, int maxLines = 1, TextInputType? keyboardType,}
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: AppTheme.gray),
          ),
          validator: required ? (value) {
            if (value == null || value.isEmpty) return 'Required';
            return null;
          } : null,
        ),
        const SizedBox(height: 12),
      ],
    );
  }
  
  Widget _buildActionButton(AuthState authState) {
    final isLoading = authState.isLoading || _isCheckingEmail;
    
    String buttonText;
    if (_flowState == AuthFlowState.emailEntry) {
      buttonText = 'Continue';
    } else if (_isUserExists) {
      buttonText = 'Sign In';
    } else {
      buttonText = _selectedRole == AppConstants.roleNgo ? 'Register NGO' : 'Create Account';
    }
    
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: isLoading 
            ? null 
            : (_flowState == AuthFlowState.emailEntry ? _checkEmail : _submit),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryRed,
          foregroundColor: AppTheme.white,
          elevation: 4,
          shadowColor: AppTheme.primaryRed.withValues(alpha: 0.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: AppTheme.white,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    buttonText,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (_flowState == AuthFlowState.emailEntry) ...[
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward_rounded, size: 20),
                  ],
                ],
              ),
      ),
    );
  }
}

// Auth flow states
enum AuthFlowState {
  emailEntry,    // Initial state - user enters email
  credentials,   // User enters password (login) or full form (register)
}

// Role selection chip widget
class _RoleChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;
  
  const _RoleChip({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });
  
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryRed : AppTheme.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppTheme.primaryRed : AppTheme.lightGray,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected ? [
            BoxShadow(
              color: AppTheme.primaryRed.withValues(alpha: 0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ] : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? AppTheme.white : AppTheme.primaryRed,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 12,
                color: isSelected ? AppTheme.white : AppTheme.black,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
