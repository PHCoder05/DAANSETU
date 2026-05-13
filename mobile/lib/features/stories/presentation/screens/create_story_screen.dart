import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../config/theme.dart';
import '../../../../core/api/api_client.dart';
import '../../../../shared/widgets/custom_snackbar.dart';
import '../screens/impact_stories_screen.dart';

class CreateImpactStoryScreen extends ConsumerStatefulWidget {
  final String? donationId;
  final String? category;

  const CreateImpactStoryScreen({super.key, this.donationId, this.category});

  @override
  ConsumerState<CreateImpactStoryScreen> createState() => _CreateImpactStoryScreenState();
}

class _CreateImpactStoryScreenState extends ConsumerState<CreateImpactStoryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _storyController = TextEditingController();
  final _beneficiariesController = TextEditingController();
  
  List<File> _selectedImages = [];
  bool _isSubmitting = false;
  String _selectedCategory = 'general';

  @override
  void initState() {
    super.initState();
    if (widget.category != null) {
      _selectedCategory = widget.category!.toLowerCase();
    }
  }

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final pickedFiles = await picker.pickMultiImage();
    
    if (pickedFiles.isNotEmpty) {
      setState(() {
        _selectedImages.addAll(pickedFiles.map((e) => File(e.path)));
        if (_selectedImages.length > 5) {
          _selectedImages = _selectedImages.sublist(0, 5);
          CustomSnackBar.info(context, 'Maximum 5 photos allowed');
        }
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedImages.isEmpty) {
      CustomSnackBar.error(context, 'Please add at least one photo of the impact');
      return;
    }

    setState(() => _isSubmitting = true);
    HapticFeedback.mediumImpact();

    try {
      final apiClient = ref.read(apiClientProvider);
      
      // Upload photos first (simulated as base64 for now or actual upload if supported)
      // For this implementation, we'll send base64 or assuming backend handles multipart
      List<String> photoUrls = [];
      for (var _ in _selectedImages) {
        // In a real app, upload to S3/Cloudinary first
        // For demo, we'll pass a placeholder or handle in API client
        photoUrls.add('https://images.unsplash.com/photo-1488521787991-ed7bbaae773c?q=80&w=800'); 
      }

      final response = await apiClient.createImpactStory({
        'title': _titleController.text.trim(),
        'story': _storyController.text.trim(),
        'category': _selectedCategory,
        'beneficiariesCount': int.tryParse(_beneficiariesController.text) ?? 0,
        'photos': photoUrls,
        'donationId': widget.donationId,
      });

      if (response.statusCode == 201) {
        if (mounted) {
          CustomSnackBar.success(context, 'Impact story published! ✨');
          ref.invalidate(impactStoriesProvider);
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) CustomSnackBar.error(context, 'Failed to publish story: $e');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffoldLight,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Share Impact Story', style: TextStyle(color: AppTheme.charcoal, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppTheme.charcoal),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('What happened?'),
              const SizedBox(height: 12),
              TextFormField(
                controller: _titleController,
                style: const TextStyle(color: AppTheme.charcoal),
                decoration: _inputDecoration('Give your story a title...', Icons.title_rounded),
                validator: (v) => v?.isEmpty == true ? 'Title required' : null,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _storyController,
                style: const TextStyle(color: AppTheme.charcoal),
                maxLines: 5,
                decoration: _inputDecoration('Describe the impact. How did it help?', Icons.description_rounded),
                validator: (v) => v?.isEmpty == true ? 'Story details required' : null,
              ),
              const SizedBox(height: 24),
              _buildSectionTitle('Impact Photos'),
              const SizedBox(height: 12),
              _buildImagePicker(),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionTitle('Beneficiaries'),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _beneficiariesController,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(color: AppTheme.charcoal),
                          decoration: _inputDecoration('e.g. 50', Icons.people_rounded),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionTitle('Category'),
                        const SizedBox(height: 8),
                        _buildCategoryDropdown(),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryRed,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _isSubmitting 
                    ? const CircularProgressIndicator(color: AppTheme.white)
                    : const Text('Publish Story', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(color: AppTheme.darkGray, fontSize: 14, fontWeight: FontWeight.w600),
    );
  }

  InputDecoration _inputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: AppTheme.gray),
      prefixIcon: Icon(icon, color: AppTheme.primaryRed, size: 20),
      filled: true,
      fillColor: AppTheme.offWhite,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

  Widget _buildImagePicker() {
    return SizedBox(
      height: 100,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          GestureDetector(
            onTap: _pickImages,
            child: Container(
              width: 100,
              decoration: BoxDecoration(
                color: AppTheme.offWhite,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.lightGray),
              ),
              child: const Icon(Icons.add_a_photo_rounded, color: AppTheme.gray, size: 32),
            ),
          ),
          const SizedBox(width: 12),
          ..._selectedImages.map((file) => Container(
            width: 100,
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              image: DecorationImage(image: FileImage(file), fit: BoxFit.cover),
            ),
            child: Stack(
              children: [
                Positioned(
                  right: 4, top: 4,
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedImages.remove(file)),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                      child: const Icon(Icons.close, color: Colors.white, size: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),),
        ],
      ),
    );
  }

  Widget _buildCategoryDropdown() {
    final categories = ['general', 'food', 'clothes', 'books', 'medical', 'electronics', 'furniture'];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppTheme.offWhite,
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedCategory,
          dropdownColor: AppTheme.white,
          style: const TextStyle(color: AppTheme.charcoal),
          items: categories.map((c) => DropdownMenuItem(value: c, child: Text(c.toUpperCase(), style: const TextStyle(fontSize: 12)))).toList(),
          onChanged: (v) => setState(() => _selectedCategory = v ?? 'general'),
        ),
      ),
    );
  }
}
