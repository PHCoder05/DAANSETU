import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../config/theme.dart';
import '../../../../shared/models/donation.dart';

/// Premium Zomato-style Donation Card with image overlay design
class DonationCard extends StatelessWidget {
  final Donation donation;
  final VoidCallback? onTap;
  final bool isRecommended;
  
  const DonationCard({
    super.key,
    required this.donation,
    this.onTap,
    this.isRecommended = false,
  });

  @override
  Widget build(BuildContext context) {
    final categoryColor = AppTheme.categoryColors[donation.category] ?? AppTheme.gray;
    
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap?.call();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        height: 220,
        decoration: BoxDecoration(
          color: AppTheme.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 15,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Background Image
              _buildImage(categoryColor),
              
              // Gradient Overlay - Zomato style (darker at bottom)
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: const [0.0, 0.3, 0.6, 1.0],
                    colors: [
                      Colors.black.withValues(alpha: 0.1),
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.4),
                      Colors.black.withValues(alpha: 0.85),
                    ],
                  ),
                ),
              ),
              
              // Status Badge - Top Left
              Positioned(
                top: 12,
                left: 12,
                child: _StatusBadge(status: donation.status),
              ),
              
              // Priority Badge - Top Right
              if (donation.isHighPriority)
                Positioned(
                  top: 12,
                  right: 12,
                  child: _PriorityBadge(priority: donation.priority),
                ),
              
              // Quantity Badge - Top Right (if no priority)
              if (!donation.isHighPriority && donation.quantity != null)
                Positioned(
                  top: 12,
                  right: 12,
                  child: _QuantityBadge(quantity: donation.quantity!, unit: donation.unit),
                ),

              // Gemini Recommended Badge - Bottom Right
              if (isRecommended)
                const Positioned(
                  bottom: 12,
                  right: 12,
                  child: _SetuSmartRecommendationBadge(),
                ),
              
              // Content at bottom - Zomato style overlay
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Category chip
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: categoryColor,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _getCategoryIcon(donation.category),
                              size: 12,
                              color: AppTheme.white,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              donation.category.toUpperCase(),
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 8),
                      
                      // Title - Large and bold
                      Text(
                        donation.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          height: 1.2,
                          shadows: [
                            Shadow(
                              color: Colors.black38,
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      
                      const SizedBox(height: 4),
                      
                      // Description
                      Text(
                        donation.description,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withValues(alpha: 0.9),
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      
                      const SizedBox(height: 10),
                      
                      // Location Row
                      if (donation.pickupLocation.address != null)
                        Row(
                          children: [
                            Icon(
                              Icons.location_on,
                              size: 14,
                              color: Colors.white.withValues(alpha: 0.8),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                donation.pickupLocation.address!,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white.withValues(alpha: 0.8),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            // Donor avatar/name hint
                            if (donation.donor != null) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.person,
                                      size: 12,
                                      color: Colors.white.withValues(alpha: 0.9),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      donation.donor!.name.split(' ').first,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.white.withValues(alpha: 0.9),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildImage(Color categoryColor) {
    if (donation.images.isNotEmpty) {
      return Hero(
        tag: 'donation_image_${donation.id}',
        child: CachedNetworkImage(
          imageUrl: donation.images.first,
          fit: BoxFit.cover,
          placeholder: (context, url) => Container(
            color: categoryColor.withValues(alpha: 0.3),
            child: Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: categoryColor,
              ),
            ),
          ),
          errorWidget: (context, url, error) => _buildCategoryImage(categoryColor),
        ),
      );
    }
    return _buildCategoryImage(categoryColor);
  }
  
  Widget _buildCategoryImage(Color categoryColor) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            categoryColor.withValues(alpha: 0.7),
            categoryColor.withValues(alpha: 0.9),
            categoryColor,
          ],
        ),
      ),
      child: Center(
        child: Icon(
          _getCategoryIcon(donation.category),
          size: 64,
          color: Colors.white.withValues(alpha: 0.3),
        ),
      ),
    );
  }
  
  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'food':
        return Icons.restaurant_rounded;
      case 'clothes':
        return Icons.checkroom_rounded;
      case 'books':
        return Icons.menu_book_rounded;
      case 'medical':
        return Icons.medical_services_rounded;
      case 'electronics':
        return Icons.devices_rounded;
      case 'furniture':
        return Icons.chair_rounded;
      default:
        return Icons.inventory_2_rounded;
    }
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    String label;
    IconData icon;
    
    switch (status) {
      case 'available':
        bgColor = AppTheme.success;
        label = 'Available';
        icon = Icons.check_circle_outline;
        break;
      case 'claimed':
        bgColor = AppTheme.warning;
        label = 'Claimed';
        icon = Icons.handshake_outlined;
        break;
      case 'in-transit':
        bgColor = AppTheme.info;
        label = 'In Transit';
        icon = Icons.local_shipping_outlined;
        break;
      case 'delivered':
        bgColor = const Color(0xFF9B59B6);
        label = 'Delivered';
        icon = Icons.task_alt;
        break;
      case 'cancelled':
        bgColor = AppTheme.error;
        label = 'Cancelled';
        icon = Icons.cancel_outlined;
        break;
      default:
        bgColor = AppTheme.gray;
        label = status;
        icon = Icons.info_outline;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _PriorityBadge extends StatelessWidget {
  final String priority;
  
  const _PriorityBadge({required this.priority});

  @override
  Widget build(BuildContext context) {
    final isUrgent = priority == 'urgent';
    final bgColor = isUrgent ? AppTheme.error : AppTheme.accentOrange;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isUrgent ? Icons.local_fire_department : Icons.priority_high,
            size: 13,
            color: Colors.white,
          ),
          const SizedBox(width: 4),
          Text(
            isUrgent ? 'URGENT' : 'HIGH',
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    ).animate(onPlay: (c) => c.repeat(reverse: true))
        .shimmer(duration: const Duration(seconds: 2), color: Colors.white.withValues(alpha: 0.2));
  }
}

class _QuantityBadge extends StatelessWidget {
  final int quantity;
  final String? unit;
  
  const _QuantityBadge({required this.quantity, this.unit});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.inventory_2_outlined,
            size: 13,
            color: Colors.white,
          ),
          const SizedBox(width: 4),
          Text(
            '$quantity ${unit ?? 'items'}',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _SetuSmartRecommendationBadge extends StatelessWidget {
  const _SetuSmartRecommendationBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.black.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.primaryRed.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryRed.withValues(alpha: 0.2),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.auto_awesome_rounded, size: 12, color: AppTheme.primaryRed),
          const SizedBox(width: 4),
          Text(
            'Recommended',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: AppTheme.white.withValues(alpha: 0.9),
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    ).animate(onPlay: (c) => c.repeat())
        .shimmer(duration: 2.seconds, color: AppTheme.primaryRed.withValues(alpha: 0.3));
  }
}
