import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../../config/images.dart';
import '../../../../config/constants.dart';
import '../../../../config/routes.dart';
import '../../../../config/theme.dart';
import '../../../../core/api/api_client.dart';
import '../../../../shared/widgets/custom_snackbar.dart';
import '../../../../shared/widgets/custom_snackbar.dart';
import '../../../../shared/widgets/step_indicator.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'dart:io';
import 'package:geolocator/geolocator.dart';
import '../../../../shared/models/donation.dart';
import '../widgets/voice_form_modal.dart';

class CreateDonationScreen extends ConsumerStatefulWidget {
  final Donation? initialData;
  const CreateDonationScreen({super.key, this.initialData});

  @override
  ConsumerState<CreateDonationScreen> createState() => _CreateDonationScreenState();
}

class _CreateDonationScreenState extends ConsumerState<CreateDonationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _quantityController = TextEditingController();
  final _addressController = TextEditingController();
  final _instructionsController = TextEditingController();
  
  String _selectedCategory = 'food';
  String _selectedCondition = 'good';
  String _selectedPriority = 'normal';
  String _selectedUnit = 'kg';
  bool _isSubmitting = false;
  bool _showSuccess = false; // New state for success view
  double? _selectedLat;
  double? _selectedLng;
  bool _gettingLocation = false;
  bool _isAnalyzing = false;
  List<dynamic> _recommendations = [];

  // Wizard State
  int _currentStep = 0;
  final int _totalSteps = 3;
  late PageController _pageController;

  final List<String> _units = ['kg', 'pieces', 'boxes', 'bags', 'bottles', 'items'];
  final List<XFile> _selectedImages = [];
  final ImagePicker _picker = ImagePicker();
  
  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    
    if (widget.initialData != null) {
      _titleController.text = widget.initialData!.title;
      _descriptionController.text = widget.initialData!.description;
      _quantityController.text = widget.initialData!.quantity?.toString() ?? '';
      _addressController.text = widget.initialData!.pickupLocation.address ?? '';
      _instructionsController.text = widget.initialData!.pickupInstructions ?? '';
      _selectedCategory = widget.initialData!.category;
      _selectedCondition = widget.initialData!.condition;
      _selectedPriority = widget.initialData!.priority;
      _selectedUnit = widget.initialData!.unit ?? 'kg';
      _selectedLat = widget.initialData!.pickupLocation.lat;
      _selectedLng = widget.initialData!.pickupLocation.lng;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _quantityController.dispose();
    _addressController.dispose();
    _instructionsController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < _totalSteps - 1) {
      if (_validateCurrentStep()) {
        HapticFeedback.lightImpact();
        setState(() => _currentStep++);
        _pageController.animateToPage(
          _currentStep,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    } else {
      _submit();
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      HapticFeedback.lightImpact();
      setState(() => _currentStep--);
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      context.pop();
    }
  }

  bool _validateCurrentStep() {
    // specific validation for each step could go here
    // for now, we rely on the global form key but ideally we'd separate keys
    return _formKey.currentState?.validate() ?? false; 
  }
  
  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 50, // Compress to avoid huge payloads
        maxWidth: 800,
      );
      if (image != null) {
        setState(() {
          _selectedImages.add(image);
        });
      }
    } catch (e) {
      CustomSnackBar.error(context, 'Failed to pick image');
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  Future<void> _runAIAnalysis() async {
    if (_selectedImages.isEmpty) {
      CustomSnackBar.info(context, 'Please add a photo first for AI analysis.');
      return;
    }

    setState(() => _isAnalyzing = true);
    HapticFeedback.selectionClick();

    try {
      final img = _selectedImages.first;
      final bytes = await img.readAsBytes();
      final base64Str = base64Encode(bytes);
      
      final apiClient = ref.read(apiClientProvider);
      final response = await apiClient.analyzeImage('data:image/jpeg;base64,$base64Str');
      
      if (response.statusCode == 200) {
        final data = response.data['data'];
        setState(() {
          _titleController.text = data['title'] ?? _titleController.text;
          _descriptionController.text = data['description'] ?? _descriptionController.text;
          _selectedCategory = data['category'] ?? _selectedCategory;
          _quantityController.text = data['estimatedQuantity']?.toString() ?? _quantityController.text;
          _selectedUnit = data['suggestedUnit'] ?? _selectedUnit;
          _selectedPriority = data['urgency'] ?? _selectedPriority;
        });
        
        if (mounted) {
          CustomSnackBar.success(context, 'AI analysis complete! Fields auto-filled.');
          
          // Fetch recommendations
          _fetchRecommendations(data['category'] ?? _selectedCategory);
        }
      }
    } catch (e) {
      if (mounted) {
        CustomSnackBar.error(context, 'AI analysis failed. Please fill manually.');
      }
    } finally {
      if (mounted) setState(() => _isAnalyzing = false);
    }
  }

  Future<void> _showVoiceAssistant() async {
    HapticFeedback.mediumImpact();
    final result = await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const VoiceFormModal(),
    );

    if (result != null && result is Map<String, dynamic> && mounted) {
      setState(() {
        _titleController.text = result['title'] ?? _titleController.text;
        _descriptionController.text = result['description'] ?? _descriptionController.text;
        _selectedCategory = result['category'] ?? _selectedCategory;
        _quantityController.text = result['quantity']?.toString() ?? _quantityController.text;
        _selectedUnit = result['unit'] ?? _selectedUnit;
        _selectedCondition = result['condition'] ?? _selectedCondition;
        _selectedPriority = result['priority'] ?? _selectedPriority;
      });
      
      CustomSnackBar.success(context, 'Setu AI has filled the form for you!');
    }
  }

  Future<void> _fetchRecommendations(String category) async {
    try {
      final apiClient = ref.read(apiClientProvider);
      final response = await apiClient.getRecommendedNgos(
        category,
        lat: _selectedLat,
        lng: _selectedLng,
      );
      
      if (response.statusCode == 200) {
        setState(() {
          _recommendations = response.data['data'] ?? [];
        });
      }
    } catch (e) {
      debugPrint('Recommendation fetch failed: $e');
    }
  }

  Future<void> _submit() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() => _isSubmitting = true);
      HapticFeedback.mediumImpact();
      
      try {
        // Convert images to Base64
        List<String> base64Images = [];
        for (var img in _selectedImages) {
          final bytes = await img.readAsBytes();
          final base64Str = base64Encode(bytes);
          base64Images.add('data:image/jpeg;base64,$base64Str');
        }

        final apiClient = ref.read(apiClientProvider);
        final payload = {
          'title': _titleController.text.trim(),
          'description': _descriptionController.text.trim(),
          'category': _selectedCategory,
          'condition': _selectedCondition,
          'priority': _selectedPriority,
          'quantity': int.tryParse(_quantityController.text) ?? 1,
          'unit': _selectedUnit,
          'images': base64Images.isNotEmpty 
              ? base64Images 
              : (widget.initialData != null && widget.initialData!.images.isNotEmpty ? widget.initialData!.images : [AppImages.getByCategory(_selectedCategory)]),
          'pickupLocation': {
            'address': _addressController.text.trim(),
            'lat': _selectedLat ?? 0.0,
            'lng': _selectedLng ?? 0.0,
          },
          'pickupInstructions': _instructionsController.text.trim(),
        };
        
        final response = widget.initialData != null 
            ? await apiClient.updateDonation(widget.initialData!.id, payload)
            : await apiClient.createDonation(payload);
        
        if (response.statusCode == 201 || response.statusCode == 200) {
          // Show Success View instead of snackbar + pop
          setState(() {
             _isSubmitting = false;
             _showSuccess = true;
          });
          HapticFeedback.heavyImpact();
        }
      } catch (e) {
        CustomSnackBar.error(context, widget.initialData != null ? 'Failed to update donation' : 'Failed to create donation');
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_showSuccess) {
      return _buildSuccessView();
    }

    return Scaffold(
      backgroundColor: AppTheme.scaffoldLight,
      appBar: AppBar(
        backgroundColor: AppTheme.white,
        elevation: 0,
        title: Text(
          widget.initialData != null ? 'Edit Donation' : 'Create Donation',
          style: const TextStyle(color: AppTheme.black, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: AppTheme.black),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            StepIndicator(currentStep: _currentStep, totalSteps: _totalSteps),
            
            Expanded(
              child: Form(
                key: _formKey,
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(), // Disable swipe
                  children: [
                    _buildStep1Essentials(),
                    _buildStep2Details(),
                    _buildStep3Logistics(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildStep1Essentials() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'The Essentials',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ).animate().fadeIn().slideX(),
          const SizedBox(height: 8),
          const Text('What would you like to donate today?', style: TextStyle(color: AppTheme.gray)),
          const SizedBox(height: 32),
          
          _buildField('Title', _titleController, 'Thinking of...', Icons.title_rounded)
              .animate(delay: 100.ms).fadeIn().slideY(begin: 0.1),
          
          _buildField('Description', _descriptionController, 'A brief description...', Icons.description_outlined, maxLines: 3)
              .animate(delay: 200.ms).fadeIn().slideY(begin: 0.1),
              
          Text('Category', style: Theme.of(context).textTheme.labelLarge)
              .animate(delay: 300.ms).fadeIn(),
          const SizedBox(height: 12),
          _CategorySelector(
            selected: _selectedCategory,
            onChanged: (value) => setState(() => _selectedCategory = value),
          ).animate(delay: 350.ms).fadeIn().slideY(begin: 0.1),
          
          if (_selectedImages.isNotEmpty) ...[
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.primaryRed.withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.primaryRed.withOpacity(0.1)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.auto_awesome_rounded, color: AppTheme.primaryRed),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Try "Snap & Donate" AI',
                          style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryRed),
                        ),
                      ),
                      if (_isAnalyzing)
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryRed),
                        )
                      else
                        TextButton(
                          onPressed: _runAIAnalysis,
                          child: const Text('Run Analysis'),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Our AI will analyze your photo to automatically fill in the category, title, and description.',
                    style: TextStyle(fontSize: 12, color: AppTheme.gray),
                  ),
                ],
              ),
            ).animate().fadeIn().scale(),
          ],
          
          if (_recommendations.isNotEmpty) ...[
            const SizedBox(height: 32),
            Text(
              'Best Matches for this Donation',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ).animate().fadeIn(),
            const SizedBox(height: 12),
            ..._recommendations.map((ngo) => _buildRecommendationCard(ngo)).toList(),
          ],
        ],
      ),
    );
  }

  Widget _buildRecommendationCard(dynamic ngo) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primaryRed.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: AppTheme.offWhite,
              borderRadius: BorderRadius.circular(12),
              image: ngo['profileImage'] != null 
                  ? DecorationImage(image: NetworkImage(ngo['profileImage']), fit: BoxFit.cover)
                  : null,
            ),
            child: ngo['profileImage'] == null ? const Icon(Icons.business_rounded, color: AppTheme.gray) : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        ngo['name'] ?? 'NGO',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.success.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${ngo['matchScore']}% Match',
                        style: const TextStyle(color: AppTheme.success, fontWeight: FontWeight.bold, fontSize: 10),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  ngo['matchingReason'] ?? '',
                  style: const TextStyle(color: AppTheme.gray, fontSize: 12),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn().slideX(begin: 0.1);
  }

  Widget _buildStep2Details() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
           Text(
            'Fine Details',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ).animate().fadeIn().slideX(),
          const SizedBox(height: 8),
          const Text('Help us understand the item better.', style: TextStyle(color: AppTheme.gray)),
          const SizedBox(height: 32),

          // Image Picker Mock
          Text('Add Photos', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 12),
          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _selectedImages.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  // Add Button
                  return GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      width: 100,
                      margin: const EdgeInsets.only(right: 12),
                      decoration: BoxDecoration(
                        color: AppTheme.offWhite,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.primaryRed.withOpacity(0.3)),
                      ),
                      child: const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.add_a_photo_rounded, color: AppTheme.primaryRed, size: 32),
                            SizedBox(height: 4),
                            Text('Add', style: TextStyle(color: AppTheme.primaryRed, fontWeight: FontWeight.bold, fontSize: 12)),
                          ],
                        ),
                      ),
                    ),
                  );
                }
                
                final startIdx = index - 1;
                final imageFile = _selectedImages[startIdx];
                return Stack(
                  children: [
                    Container(
                      width: 100,
                      margin: const EdgeInsets.only(right: 12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        image: DecorationImage(
                          image: FileImage(File(imageFile.path)),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    
                    // AI Assistant Button
                      Row(
                        children: [
                          Expanded(
                            child: _buildActionButton(
                              icon: Icons.auto_awesome_rounded,
                              label: 'AI Photo Analysis',
                              onTap: _runAIAnalysis,
                              isLoading: _isAnalyzing,
                              color: AppTheme.accentOrange,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildActionButton(
                              icon: Icons.mic_rounded,
                              label: 'Voice Assistant',
                              onTap: _showVoiceAssistant,
                              color: AppTheme.primaryRed,
                            ),
                          ),
                        ],
                      ).animate().fadeIn(delay: 400.ms).slideX(),

                      const SizedBox(height: 24),
                    
                    Positioned(
                      top: 4,
                      right: 16,
                      child: GestureDetector(
                        onTap: () => _removeImage(startIdx),
                        child: Container(
                           padding: const EdgeInsets.all(4),
                           decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                           child: const Icon(Icons.close, color: Colors.white, size: 14),
                        ),
                      ),
                    ),
                  ],
                ).animate().scale();
              },
            ),
          ),
          const SizedBox(height: 24),

          Row(
            children: [
              Expanded(child: _buildDropdown('Condition', _selectedCondition, AppConstants.donationConditions, (v) => setState(() => _selectedCondition = v!))),
              const SizedBox(width: 16),
              Expanded(child: _buildDropdown('Priority', _selectedPriority, AppConstants.priorityLevels, (v) => setState(() => _selectedPriority = v!))),
            ],
          ).animate(delay: 200.ms).fadeIn().slideY(begin: 0.1),
          const SizedBox(height: 20),
          
          Row(
            children: [
              Expanded(flex: 2, child: _buildField('Quantity', _quantityController, 'e.g. 10', Icons.numbers_rounded, keyboardType: TextInputType.number, required: false)),
              const SizedBox(width: 16),
              Expanded(flex: 2, child: _buildDropdown('Unit', _selectedUnit, _units, (v) => setState(() => _selectedUnit = v!))),
            ],
          ).animate(delay: 300.ms).fadeIn().slideY(begin: 0.1),
        ],
      ),
    );
  }

  Widget _buildStep3Logistics() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
           Text(
            'Logistics',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ).animate().fadeIn().slideX(),
          const SizedBox(height: 8),
          const Text('Where should we pick this up?', style: TextStyle(color: AppTheme.gray)),
          const SizedBox(height: 32),

          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.white,
              borderRadius: AppTheme.borderRadiusMedium,
              boxShadow: AppTheme.cardShadow,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.location_on_rounded, color: AppTheme.primaryRed),
                        const SizedBox(width: 8),
                        Text('Pickup Location', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                      ],
                    ),
                    TextButton.icon(
                      onPressed: _gettingLocation ? null : _getCurrentLocation,
                      icon: _gettingLocation 
                          ? const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2)) 
                          : const Icon(Icons.my_location, size: 16),
                      label: Text(_gettingLocation ? 'Locating...' : 'Use Current'),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _buildField('Address', _addressController, 'Enter full address', Icons.home_outlined),
                if (_selectedLat != null)
                   Padding(
                     padding: const EdgeInsets.only(bottom: 16),
                     child: Row(
                       children: [
                         const Icon(Icons.check_circle, size: 14, color: AppTheme.success),
                         const SizedBox(width: 4),
                         Text(
                           'Precise location pinned (${_selectedLat!.toStringAsFixed(4)}, ${_selectedLng!.toStringAsFixed(4)})',
                           style: const TextStyle(fontSize: 11, color: AppTheme.success),
                         ),
                       ],
                     ),
                   ),
                _buildField('Instructions', _instructionsController, 'Any landmarks or instructions?', Icons.info_outline_rounded, maxLines: 2, required: false),
              ],
            ),
          ).animate().fadeIn().slideY(begin: 0.1),
        ],
      ),
    );
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _gettingLocation = true);
    
    try {
      // PERMISSION CHECK
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw 'Location services are disabled.';
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw 'Location permissions are denied';
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        throw 'Location permissions are permanently denied, we cannot request permissions.';
      }

      // GET POSITION
      final Position position = await Geolocator.getCurrentPosition();
      
      setState(() {
        _selectedLat = position.latitude;
        _selectedLng = position.longitude;
        if (_addressController.text.isEmpty) {
          _addressController.text = "Pinned Location (Lat: ${position.latitude.toStringAsFixed(4)})";
        }
      });
      
      CustomSnackBar.success(context, 'Location retrieved successfully!');
      
    } catch (e) {
      CustomSnackBar.error(context, e.toString());
    } finally {
      setState(() => _gettingLocation = false);
    }
  }

  Widget _buildBottomBar() {
    final isLastStep = _currentStep == _totalSteps - 1;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            if (_currentStep > 0)
              TextButton(
                onPressed: _prevStep,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                ),
                child: const Text('Back', style: TextStyle(color: AppTheme.darkGray)),
              ),
            
            Expanded(
              child: SizedBox(
                height: 54,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _nextStep,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryRed,  // Always red for visibility
                    elevation: isLastStep ? 4 : 2,
                  ),
                  child: _isSubmitting
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.5, color: AppTheme.white))
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(isLastStep ? (widget.initialData != null ? 'Save Changes' : 'Post Donation') : 'Next Step'),
                            const SizedBox(width: 10),
                            Icon(isLastStep ? Icons.check_circle_outline : Icons.arrow_forward_rounded, color: AppTheme.white),
                          ],
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessView() {
    return Scaffold(
      backgroundColor: AppTheme.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(30),
                decoration: BoxDecoration(
                  color: AppTheme.success.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_rounded, size: 80, color: AppTheme.success),
              ).animate().scale(duration: 500.ms, curve: Curves.easeOutBack),
              
              const SizedBox(height: 32),
              
              Text(
                'Thank You!',
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.charcoal,
                ),
              ).animate(delay: 200.ms).fadeIn().slideY(begin: 0.2),
              
              const SizedBox(height: 16),
              
              Text(
                widget.initialData != null 
                    ? 'Your donation has been updated successfully.' 
                    : 'Your donation has been posted successfully.\nNGOs nearby will be notified properly.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, color: AppTheme.gray, height: 1.5),
              ).animate(delay: 400.ms).fadeIn(),
              
              const SizedBox(height: 48),
              
              SizedBox(
                width: 200,
                height: 50,
                child: ElevatedButton(
                  onPressed: () => context.go(AppRoutes.donations),
                  child: const Text('Back to Donations'),
                ),
              ).animate(delay: 600.ms).fadeIn().slideY(begin: 0.2),
            ],
          ),
        ),
      ),
    );
  }

  // Helper Methods (Same as before mostly)
  Widget _buildField(String label, TextEditingController controller, String hint, IconData icon, {TextInputType? keyboardType, int maxLines = 1, bool required = true}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          style: const TextStyle(fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: AppTheme.gray),
            filled: true,
            fillColor: AppTheme.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppTheme.lightGray),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppTheme.lightGray),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppTheme.primaryRed),
            ),
          ),
          validator: required ? (value) {
            if (value == null || value.isEmpty) return 'Required';
            return null;
          } : null,
        ),
        const SizedBox(height: 20),
      ],
    );
  }
  
  Widget _buildDropdown(String label, String value, List<String> items, void Function(String?) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: AppTheme.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.lightGray),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              items: items.map((item) => DropdownMenuItem(
                value: item,
                child: Text(item[0].toUpperCase() + item.substring(1)),
              )).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}

class _CategorySelector extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;
  
  const _CategorySelector({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final categories = [
      {'id': 'food', 'icon': Icons.restaurant_rounded, 'color': AppTheme.categoryColors['food']},
      {'id': 'clothes', 'icon': Icons.checkroom_rounded, 'color': AppTheme.categoryColors['clothes']},
      {'id': 'books', 'icon': Icons.menu_book_rounded, 'color': AppTheme.categoryColors['books']},
      {'id': 'medical', 'icon': Icons.medical_services_rounded, 'color': AppTheme.categoryColors['medical']},
      {'id': 'electronics', 'icon': Icons.devices_rounded, 'color': AppTheme.categoryColors['electronics']},
      {'id': 'furniture', 'icon': Icons.chair_rounded, 'color': AppTheme.categoryColors['furniture']},
    ];
    
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: categories.map((cat) {
        final isSelected = selected == cat['id'];
        final color = cat['color'] as Color? ?? AppTheme.gray;
        
        return GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            onChanged(cat['id'] as String);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected ? color : AppTheme.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: isSelected ? color : AppTheme.lightGray),
              boxShadow: isSelected ? [BoxShadow(color: color.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 2))] : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(cat['icon'] as IconData, size: 20, color: isSelected ? AppTheme.white : color),
                const SizedBox(width: 8),
                Text(
                  (cat['id'] as String).toUpperCase(),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? AppTheme.white : AppTheme.darkGray,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
