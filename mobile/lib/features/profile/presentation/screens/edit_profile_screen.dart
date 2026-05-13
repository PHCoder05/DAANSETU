import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import '../../../../config/constants.dart';
import '../../../../core/api/api_client.dart';
import '../../../../shared/widgets/custom_snackbar.dart';
import '../../../../shared/providers/auth_provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authStateProvider).user;
    if (user != null) {
      _nameController.text = user.name;
      _phoneController.text = user.phone ?? '';
      _addressController.text = user.address ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    HapticFeedback.lightImpact();
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 50,
        maxWidth: 800,
      );
      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      if (mounted) CustomSnackBar.error(context, 'Failed to pick image');
    }
  }

  Future<void> _submit() async {
    if (_formKey.currentState?.validate() ?? false) {
      HapticFeedback.mediumImpact();
      setState(() => _isSubmitting = true);

      try {
        final apiClient = ref.read(apiClientProvider);

        // 1. Update Profile Text Data
        final payload = {
          'name': _nameController.text.trim(),
          'phone': _phoneController.text.trim(),
          'address': _addressController.text.trim(),
        };

        final response = await apiClient.updateProfile(payload);

        if (response.statusCode == 200) {
          // 2. Upload Image if selected
          if (_selectedImage != null) {
            try {
              await apiClient.uploadProfileImage(_selectedImage!.path);
            } catch (imageError) {
              debugPrint('Image upload failed: $imageError');
            }
          }

          // Refresh the user profile
          await ref.read(authStateProvider.notifier).refreshProfile();

          if (mounted) {
            CustomSnackBar.success(context, 'Profile updated successfully!');
            context.pop();
          }
        }
      } catch (e) {
        String errorMessage = 'Failed to update profile';
        if (e is DioException && e.response?.data != null) {
          final data = e.response!.data;
          if (data is Map && data['message'] != null) {
            errorMessage = data['message'];
          }
        }
        if (mounted) {
          CustomSnackBar.error(context, errorMessage);
        }
      } finally {
        if (mounted) {
          setState(() => _isSubmitting = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).user;
    
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ═══════════════════════════════════════════════════════════
          // PREMIUM HEADER
          // ═══════════════════════════════════════════════════════════
          SliverToBoxAdapter(
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Gradient Background
                Container(
                  height: 220,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFFE23744), Color(0xFFFF6B6B)],
                    ),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(40),
                      bottomRight: Radius.circular(40),
                    ),
                  ),
                  child: Stack(
                    children: [
                      // Decorative circles
                      Positioned(
                        top: -30,
                        right: -30,
                        child: Container(
                          width: 150,
                          height: 150,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.08),
                          ),
                        ),
                      ),
                      // App bar content
                      SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                          child: Row(
                            children: [
                              IconButton(
                                icon: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.arrow_back_ios_new_rounded,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                ),
                                onPressed: () => context.pop(),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Edit Profile',
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // ═══════════════════════════════════════════════════════════
                // AVATAR SECTION
                // ═══════════════════════════════════════════════════════════
                Positioned(
                  top: 130,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: GestureDetector(
                      onTap: _pickImage,
                      child: Stack(
                        children: [
                          // Glow effect
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFE23744).withValues(alpha: 0.4),
                                  blurRadius: 25,
                                  spreadRadius: 5,
                                ),
                              ],
                            ),
                            child: Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: const LinearGradient(
                                  colors: [Color(0xFFE23744), Color(0xFFFF8A8A)],
                                ),
                                border: Border.all(color: Colors.white, width: 4),
                              ),
                              child: ClipOval(
                                child: _selectedImage != null
                                    ? Image.file(
                                        _selectedImage!,
                                        fit: BoxFit.cover,
                                        width: 120,
                                        height: 120,
                                      )
                                    : user?.profileImage != null
                                        ? Image.network(
                                            '${AppConstants.apiBaseUrl.replaceAll('/api', '')}${user!.profileImage}',
                                            fit: BoxFit.cover,
                                            width: 120,
                                            height: 120,
                                            errorBuilder: (context, error, stackTrace) =>
                                                _buildAvatarPlaceholder(),
                                          )
                                        : _buildAvatarPlaceholder(),
                              ),
                            ),
                          ).animate().scale(
                                duration: 500.ms,
                                curve: Curves.easeOutBack,
                              ),

                          // Camera button
                          Positioned(
                            bottom: 4,
                            right: 4,
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.15),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.camera_alt_rounded,
                                size: 20,
                                color: Color(0xFFE23744),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Spacer
          const SliverToBoxAdapter(child: SizedBox(height: 80)),

          // ═══════════════════════════════════════════════════════════
          // FORM SECTION
          // ═══════════════════════════════════════════════════════════
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Center(
                      child: Column(
                        children: [
                          Text(
                            'Tap to change photo',
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 32),

                    // Name Field
                    _PremiumTextField(
                      label: 'Full Name',
                      hint: 'Enter your name',
                      icon: Icons.person_outline_rounded,
                      controller: _nameController,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your name';
                        }
                        return null;
                      },
                    ).animate(delay: 100.ms).fade().slideX(begin: -0.1, end: 0),

                    const SizedBox(height: 20),

                    // Phone Field
                    _PremiumTextField(
                      label: 'Phone Number',
                      hint: 'Enter your phone number',
                      icon: Icons.phone_outlined,
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                    ).animate(delay: 150.ms).fade().slideX(begin: -0.1, end: 0),

                    const SizedBox(height: 20),

                    // Address Field
                    _PremiumTextField(
                      label: 'Address',
                      hint: 'Enter your address',
                      icon: Icons.location_on_outlined,
                      controller: _addressController,
                      maxLines: 2,
                    ).animate(delay: 200.ms).fade().slideX(begin: -0.1, end: 0),

                    const SizedBox(height: 40),

                    // Submit Button
                    _PremiumButton(
                      text: 'Save Changes',
                      isLoading: _isSubmitting,
                      onTap: _submit,
                    ).animate(delay: 250.ms).fade().slideY(begin: 0.2, end: 0),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarPlaceholder() {
    return Center(
      child: Text(
        _nameController.text.isNotEmpty 
            ? _nameController.text[0].toUpperCase() 
            : 'U',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 48,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// PREMIUM COMPONENTS
// ═══════════════════════════════════════════════════════════════════════════

class _PremiumTextField extends StatefulWidget {
  final String label;
  final String hint;
  final IconData icon;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final int maxLines;
  final String? Function(String?)? validator;

  const _PremiumTextField({
    required this.label,
    required this.hint,
    required this.icon,
    required this.controller,
    this.keyboardType,
    this.maxLines = 1,
    this.validator,
  });

  @override
  State<_PremiumTextField> createState() => _PremiumTextFieldState();
}

class _PremiumTextFieldState extends State<_PremiumTextField> {
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1A1A2E),
          ),
        ),
        const SizedBox(height: 10),
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _isFocused 
                  ? const Color(0xFFE23744) 
                  : Colors.grey.withValues(alpha: 0.15),
              width: _isFocused ? 2 : 1,
            ),
            boxShadow: _isFocused
                ? [
                    BoxShadow(
                      color: const Color(0xFFE23744).withValues(alpha: 0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: Focus(
            onFocusChange: (hasFocus) {
              setState(() => _isFocused = hasFocus);
            },
            child: TextFormField(
              controller: widget.controller,
              keyboardType: widget.keyboardType,
              maxLines: widget.maxLines,
              style: const TextStyle(
                fontSize: 15,
                color: Color(0xFF1A1A2E),
              ),
              decoration: InputDecoration(
                hintText: widget.hint,
                hintStyle: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 14,
                ),
                prefixIcon: Container(
                  padding: const EdgeInsets.all(12),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _isFocused
                          ? const Color(0xFFE23744).withValues(alpha: 0.1)
                          : Colors.grey.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      widget.icon,
                      color: _isFocused 
                          ? const Color(0xFFE23744) 
                          : Colors.grey[500],
                      size: 20,
                    ),
                  ),
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                focusedErrorBorder: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
              ),
              validator: widget.validator,
            ),
          ),
        ),
      ],
    );
  }
}

class _PremiumButton extends StatefulWidget {
  final String text;
  final bool isLoading;
  final VoidCallback onTap;

  const _PremiumButton({
    required this.text,
    required this.isLoading,
    required this.onTap,
  });

  @override
  State<_PremiumButton> createState() => _PremiumButtonState();
}

class _PremiumButtonState extends State<_PremiumButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.isLoading ? null : widget.onTap,
      child: AnimatedScale(
        scale: _isPressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          width: double.infinity,
          height: 56,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFE23744), Color(0xFFFF6B6B)],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFE23744).withValues(alpha: 0.4),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Center(
            child: widget.isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.check_circle_outline_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        widget.text,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
