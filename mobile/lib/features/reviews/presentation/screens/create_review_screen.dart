import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../../config/theme.dart';
import '../../../../core/api/api_client.dart';
import '../../../../shared/widgets/custom_snackbar.dart';

class CreateReviewScreen extends ConsumerStatefulWidget {
  final String donationId;
  final String ngoId;
  final String ngoName;
  
  const CreateReviewScreen({
    super.key,
    required this.donationId,
    required this.ngoId,
    required this.ngoName,
  });

  @override
  ConsumerState<CreateReviewScreen> createState() => _CreateReviewScreenState();
}

class _CreateReviewScreenState extends ConsumerState<CreateReviewScreen> {
  final _commentController = TextEditingController();
  int _rating = 5;
  bool _isSubmitting = false;
  
  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }
  
  Future<void> _submit() async {
    setState(() => _isSubmitting = true);
    
    try {
      final apiClient = ref.read(apiClientProvider);
      final response = await apiClient.createReview({
        'donationId': widget.donationId,
        'ngoId': widget.ngoId,
        'rating': _rating,
        'comment': _commentController.text.trim(),
      });
      
      if (response.statusCode == 201 || response.statusCode == 200) {
        if (mounted) {
          CustomSnackBar.success(context, 'Review submitted successfully!');
          context.pop();
        }
      }
    } catch (e) {
      if (mounted) {
        CustomSnackBar.error(context, 'Failed to submit review');
      }
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffoldLight,
      appBar: AppBar(
        backgroundColor: AppTheme.white,
        title: const Text('Leave a Review'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // NGO Info Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.white,
                borderRadius: AppTheme.borderRadiusMedium,
                boxShadow: AppTheme.cardShadow,
              ),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: const Color(0xFF9B59B6).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        widget.ngoName.isNotEmpty ? widget.ngoName[0].toUpperCase() : 'N',
                        style: const TextStyle(
                          color: Color(0xFF9B59B6),
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Rating NGO',
                          style: TextStyle(color: AppTheme.gray, fontSize: 12),
                        ),
                        Text(
                          widget.ngoName,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ).animate().fade().slideY(begin: 0.1, end: 0),
            
            const SizedBox(height: 32),
            
            // Rating Section
            Center(
              child: Column(
                children: [
                  Text(
                    'How was your experience?',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      final starRating = index + 1;
                      return GestureDetector(
                        onTap: () => setState(() => _rating = starRating),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Icon(
                            starRating <= _rating ? Icons.star_rounded : Icons.star_outline_rounded,
                            size: 48,
                            color: AppTheme.accentOrange,
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _getRatingLabel(_rating),
                    style: TextStyle(
                      color: AppTheme.accentOrange,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ).animate(delay: 100.ms).fade().scale(),
            
            const SizedBox(height: 32),
            
            // Comment Section
            Text(
              'Write a Review (Optional)',
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _commentController,
              maxLines: 5,
              maxLength: 1000,
              decoration: InputDecoration(
                hintText: 'Share your experience with this NGO...',
                alignLabelWithHint: true,
              ),
            ).animate(delay: 200.ms).fade().slideY(begin: 0.1, end: 0),
            
            const SizedBox(height: 32),
            
            // Tips
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.info.withOpacity(0.1),
                borderRadius: AppTheme.borderRadiusMedium,
                border: Border.all(color: AppTheme.info.withOpacity(0.2)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.lightbulb_outline_rounded, color: AppTheme.info, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tips for a helpful review',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppTheme.info,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '• Mention how responsive the NGO was\n• Describe the pickup/delivery experience\n• Share if you would donate to them again',
                          style: TextStyle(
                            color: AppTheme.darkGray,
                            fontSize: 13,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ).animate(delay: 300.ms).fade(),
            
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
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.send_rounded, color: AppTheme.white),
                          SizedBox(width: 10),
                          Text('Submit Review'),
                        ],
                      ),
              ),
            ).animate(delay: 400.ms).fade().slideY(begin: 0.1, end: 0),
          ],
        ),
      ),
    );
  }
  
  String _getRatingLabel(int rating) {
    switch (rating) {
      case 1: return 'Poor';
      case 2: return 'Fair';
      case 3: return 'Good';
      case 4: return 'Very Good';
      case 5: return 'Excellent';
      default: return '';
    }
  }
}
