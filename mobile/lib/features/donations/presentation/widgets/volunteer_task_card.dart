import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../config/theme.dart';
import '../../../../shared/models/donation.dart';
import '../../../../shared/widgets/smart_donation_image.dart';

/// specialized task card for Volunteers - Swiggy/Zomato Partner style
class VolunteerTaskCard extends StatelessWidget {
  final Donation donation;
  final VoidCallback onTap;
  final bool isActive;

  const VolunteerTaskCard({
    super.key,
    required this.donation,
    required this.onTap,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: AppTheme.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            )
          ],
          border: isActive ? Border.all(color: AppTheme.primaryRed.withOpacity(0.3), width: 1.5) : null,
        ),
        child: Column(
          children: [
            // Top Section: Image & Basic Info
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  // Image thumbnail
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: SizedBox(
                      width: 80,
                      height: 80,
                      child: SmartDonationImage(
                        imageUrl: donation.images.isNotEmpty ? donation.images.first : null,
                        category: donation.category,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: _getStatusColor(donation.status).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                donation.status.toUpperCase(),
                                style: TextStyle(
                                  color: _getStatusColor(donation.status),
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            if (donation.isUrgent) ...[
                              const SizedBox(width: 6),
                              const Icon(Icons.local_fire_department_rounded, color: AppTheme.primaryRed, size: 14),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          donation.title,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            const Icon(Icons.location_on_rounded, size: 12, color: AppTheme.gray),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                donation.pickupLocation.address ?? "Address unknown",
                                style: TextStyle(color: AppTheme.gray, fontSize: 12),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Distance / Earnings
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        donation.distance != null 
                            ? "${(donation.distance! / 1000).toStringAsFixed(1)} km" 
                            : "N/A", 
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)
                      ),
                      Text("Distance", style: TextStyle(color: AppTheme.gray, fontSize: 10)),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.success.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          "+15 Pts",
                          style: TextStyle(color: AppTheme.success, fontWeight: FontWeight.bold, fontSize: 10),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            const Divider(height: 1, color: AppTheme.offWhite),
            
            // Bottom Section: Primary Action CTA
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  if (isActive) ...[
                     const Icon(Icons.delivery_dining_rounded, color: AppTheme.primaryRed, size: 20),
                     const SizedBox(width: 8),
                     Text(
                       _getTransitStatus(donation.status),
                       style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppTheme.primaryRed),
                     ),
                  ] else ...[
                    const Icon(Icons.timer_outlined, color: AppTheme.gray, size: 18),
                    const SizedBox(width: 8),
                    const Text(
                      "Pickup available now",
                      style: TextStyle(color: AppTheme.gray, fontSize: 13),
                    ),
                  ],
                  const Spacer(),
                  TextButton(
                    onPressed: onTap,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      backgroundColor: isActive ? AppTheme.black : AppTheme.primaryRed.withOpacity(0.1),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Text(
                      isActive ? "VIEW TASK" : "CLAIM PICKUP",
                      style: TextStyle(
                        color: isActive ? Colors.white : AppTheme.primaryRed,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
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

  Color _getStatusColor(String status) {
    switch (status) {
      case 'available': return AppTheme.success;
      case 'claimed': return AppTheme.warning;
      case 'in-transit': return AppTheme.info;
      default: return AppTheme.gray;
    }
  }

  String _getTransitStatus(String status) {
    if (status == 'claimed') return "Proceed to Pickup";
    if (status == 'in-transit') return "On the way to NGO";
    return "Status unknown";
  }
}
