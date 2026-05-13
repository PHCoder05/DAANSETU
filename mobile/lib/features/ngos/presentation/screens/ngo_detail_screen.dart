import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../../config/theme.dart';
import '../../../../core/api/api_client.dart';
import '../../../../shared/models/user.dart';
import '../../../../shared/providers/auth_provider.dart';

class NgoDetailScreen extends ConsumerStatefulWidget {
  final String ngoId;
  
  const NgoDetailScreen({super.key, required this.ngoId});

  @override
  ConsumerState<NgoDetailScreen> createState() => _NgoDetailScreenState();
}

class _NgoDetailScreenState extends ConsumerState<NgoDetailScreen> {
  User? _ngo;
  List<Map<String, dynamic>> _reviews = [];
  double _averageRating = 0;
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _loadNgoDetails();
  }
  
  Future<void> _loadNgoDetails() async {
    try {
      final apiClient = ref.read(apiClientProvider);
      
      // Load NGO details
      final ngoResponse = await apiClient.getNgo(widget.ngoId);
      if (ngoResponse.statusCode == 200) {
        setState(() {
          _ngo = User.fromJson(ngoResponse.data['ngo']);
        });
      }
      
      // Load reviews
      final reviewsResponse = await apiClient.getNgoReviews(widget.ngoId);
      if (reviewsResponse.statusCode == 200) {
        setState(() {
          _reviews = List<Map<String, dynamic>>.from(reviewsResponse.data['reviews'] ?? []);
          _averageRating = (reviewsResponse.data['averageRating'] ?? 0).toDouble();
        });
      }
    } catch (e) {
      // Handle error
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppTheme.scaffoldLight,
        body: Center(child: CircularProgressIndicator(color: AppTheme.primaryRed)),
      );
    }
    
    if (_ngo == null) {
      return Scaffold(
        backgroundColor: AppTheme.scaffoldLight,
        appBar: AppBar(backgroundColor: AppTheme.white),
        body: const Center(child: Text('NGO not found')),
      );
    }
    
    final ngo = _ngo!;
    
    return Scaffold(
      backgroundColor: AppTheme.scaffoldLight,
      body: CustomScrollView(
        slivers: [
          // Hero Header with Gradient & Image
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            backgroundColor: AppTheme.primaryRed,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Background Pattern/Image
                  Image.asset(
                    'assets/images/placeholder_ngo.png', // Fallback
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(color: AppTheme.primaryRed),
                  ),
                  // Gradient Overlay
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.7),
                        ],
                        stops: const [0.6, 1.0],
                      ),
                    ),
                  ),
                  // Content Overlay
                  Positioned(
                    bottom: 20,
                    left: 20,
                    right: 20,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        // Logo Card
                        Hero(
                          tag: 'ngo_logo_${ngo.id}',
                          child: Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: AppTheme.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.2),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                ngo.name.isNotEmpty ? ngo.name[0].toUpperCase() : 'N',
                                style: const TextStyle(
                                  color: AppTheme.primaryRed,
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Name & Verification
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      ngo.name,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        shadows: [
                                          Shadow(
                                            color: Colors.black45,
                                            offset: Offset(0, 2),
                                            blurRadius: 4,
                                          ),
                                        ],
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (ngo.isVerifiedNgo) ...[
                                    const SizedBox(width: 8),
                                    const Icon(Icons.verified, color: AppTheme.success, size: 24),
                                  ],
                                ],
                              ),
                              if (ngo.ngoDetails?.registrationNumber != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    'Reg No: ${ngo.ngoDetails!.registrationNumber}',
                                    style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.9),
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Rating Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppTheme.white,
                      borderRadius: AppTheme.borderRadiusMedium,
                      boxShadow: AppTheme.cardShadow,
                    ),
                    child: Row(
                      children: [
                        Column(
                          children: [
                            Text(
                              _averageRating.toStringAsFixed(1),
                              style: const TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.accentOrange,
                              ),
                            ),
                            Row(
                              children: List.generate(5, (index) {
                                return Icon(
                                  index < _averageRating.round() 
                                      ? Icons.star_rounded 
                                      : Icons.star_outline_rounded,
                                  color: AppTheme.accentOrange,
                                  size: 18,
                                );
                              }),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${_reviews.length} reviews',
                              style: const TextStyle(color: AppTheme.gray, fontSize: 12),
                            ),
                          ],
                        ),
                        const SizedBox(width: 24),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _RatingBar(label: '5', value: _getRatingPercentage(5)),
                              _RatingBar(label: '4', value: _getRatingPercentage(4)),
                              _RatingBar(label: '3', value: _getRatingPercentage(3)),
                              _RatingBar(label: '2', value: _getRatingPercentage(2)),
                              _RatingBar(label: '1', value: _getRatingPercentage(1)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ).animate().fade().slideY(begin: 0.1, end: 0),
                  
                  const SizedBox(height: 24),
                  
                  // About
                  Text(
                    'About',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.white,
                      borderRadius: AppTheme.borderRadiusMedium,
                      boxShadow: AppTheme.cardShadow,
                    ),
                    child: Text(
                      ngo.ngoDetails?.description ?? 'No description provided.',
                      style: const TextStyle(color: AppTheme.darkGray, height: 1.6),
                    ),
                  ).animate(delay: 100.ms).fade().slideY(begin: 0.1, end: 0),
                  
                  const SizedBox(height: 24),
                  
                  // Contact Info
                  Text(
                    'Contact Information',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.white,
                      borderRadius: AppTheme.borderRadiusMedium,
                      boxShadow: AppTheme.cardShadow,
                    ),
                    child: Column(
                      children: [
                        _ContactRow(icon: Icons.email_outlined, value: ngo.email),
                        if (ngo.phone != null)
                          _ContactRow(icon: Icons.phone_outlined, value: ngo.phone!),
                        if (ngo.address != null)
                          _ContactRow(icon: Icons.location_on_outlined, value: ngo.address!),
                        if (ngo.ngoDetails?.website != null)
                          _ContactRow(icon: Icons.language_rounded, value: ngo.ngoDetails!.website!),
                      ],
                    ),
                  ).animate(delay: 200.ms).fade().slideY(begin: 0.1, end: 0),
                  
                  const SizedBox(height: 16),
                  
                  // Message Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        context.push('/chat/${ngo.id}', extra: {'name': ngo.name});
                      },
                      icon: const Icon(Icons.chat_bubble_outline_rounded),
                      label: const Text('Message NGO'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryRed,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 4,
                        shadowColor: AppTheme.primaryRed.withValues(alpha: 0.4),
                      ),
                    ),
                  ).animate(delay: 250.ms).fade().slideY(begin: 0.1, end: 0),
                  
                  const SizedBox(height: 24),
                  
                  // Reviews
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Reviews',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${_reviews.length} reviews',
                        style: const TextStyle(color: AppTheme.gray),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  if (_reviews.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(40),
                      decoration: BoxDecoration(
                        color: AppTheme.offWhite,
                        borderRadius: AppTheme.borderRadiusMedium,
                      ),
                      child: const Column(
                        children: [
                          Icon(Icons.rate_review_outlined, size: 48, color: AppTheme.gray),
                          SizedBox(height: 12),
                          Text('No reviews yet', style: TextStyle(color: AppTheme.gray)),
                        ],
                      ),
                    )
                  else
                    ...List.generate(_reviews.length.clamp(0, 5), (index) {
                      final review = _reviews[index];
                      final authState = ref.watch(authStateProvider);
                      final isMyNgo = authState.user?.id == widget.ngoId;
                      
                      return _ReviewCard(
                        reviewId: review['_id'],
                        reviewerName: review['donor']?['name'] ?? 'Anonymous',
                        rating: (review['rating'] ?? 0).toDouble(),
                        comment: review['comment'] ?? '',
                        date: review['createdAt'] != null 
                            ? DateTime.parse(review['createdAt']) 
                            : DateTime.now(),
                        response: review['response'],
                        canRespond: isMyNgo && review['response'] == null,
                        onRespond: (reviewId, response) => _submitResponse(reviewId, response),
                      ).animate(delay: Duration(milliseconds: 300 + index * 100)).fade().slideY(begin: 0.1, end: 0);
                    }),
                  
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submitResponse(String reviewId, String response) async {
    try {
      final apiClient = ref.read(apiClientProvider);
      final res = await apiClient.respondToReview(reviewId, response);
      
      if (res.statusCode == 200) {
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
             const SnackBar(content: Text('Response submitted successfully'), backgroundColor: AppTheme.success),
           );
           _loadNgoDetails(); // Refresh
        }
      }
    } catch (e) {
       if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
             const SnackBar(content: Text('Failed to submit response'), backgroundColor: AppTheme.error),
          );
       }
    }
  }
  
  double _getRatingPercentage(int rating) {
    if (_reviews.isEmpty) return 0;
    final count = _reviews.where((r) => r['rating'] == rating).length;
    return count / _reviews.length;
  }
}

class _RatingBar extends StatelessWidget {
  final String label;
  final double value;
  
  const _RatingBar({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.gray)),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              height: 6,
              decoration: BoxDecoration(
                color: AppTheme.lightGray,
                borderRadius: BorderRadius.circular(3),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: value,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppTheme.accentOrange,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ContactRow extends StatelessWidget {
  final IconData icon;
  final String value;
  
  const _ContactRow({required this.icon, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppTheme.gray),
          const SizedBox(width: 12),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final String reviewId;
  final String reviewerName;
  final double rating;
  final String comment;
  final DateTime date;
  final String? response;
  final bool canRespond;
  final Function(String, String)? onRespond;
  
  const _ReviewCard({
    required this.reviewId,
    required this.reviewerName,
    required this.rating,
    required this.comment,
    required this.date,
    this.response,
    this.canRespond = false,
    this.onRespond,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: AppTheme.borderRadiusMedium,
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppTheme.primaryRed.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    reviewerName.isNotEmpty ? reviewerName[0].toUpperCase() : 'A',
                    style: const TextStyle(
                      color: AppTheme.primaryRed,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      reviewerName,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Row(
                      children: [
                        ...List.generate(5, (index) => Icon(
                          index < rating.round() ? Icons.star_rounded : Icons.star_outline_rounded,
                          size: 14,
                          color: AppTheme.accentOrange,
                        ),),
                        const SizedBox(width: 8),
                        Text(
                          _formatDate(date),
                          style: const TextStyle(fontSize: 11, color: AppTheme.gray),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (canRespond)
                TextButton.icon(
                  onPressed: () => _showResponseDialog(context),
                  icon: const Icon(Icons.reply_rounded, size: 16),
                  label: const Text('Reply', style: TextStyle(fontSize: 12)),
                  style: TextButton.styleFrom(foregroundColor: AppTheme.primaryRed),
                ),
            ],
          ),
          if (comment.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(comment, style: const TextStyle(color: AppTheme.darkGray, height: 1.4)),
          ],
          if (response != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.offWhite,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'NGO Response:',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Text(response!, style: const TextStyle(color: AppTheme.darkGray, fontSize: 13)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
  
  void _showResponseDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Respond to Review'),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Write your response here...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                onRespond?.call(reviewId, controller.text.trim());
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryRed),
            child: const Text('Submit', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
