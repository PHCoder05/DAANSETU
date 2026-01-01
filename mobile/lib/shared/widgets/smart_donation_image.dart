import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../config/images.dart';
import '../../config/theme.dart';

class SmartDonationImage extends StatelessWidget {
  final String? imageUrl;
  final String category;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;

  const SmartDonationImage({
    super.key,
    this.imageUrl,
    required this.category,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    // 1. Determine local asset or network URL
    final hasValidUrl = imageUrl != null && imageUrl!.isNotEmpty;
    final fallbackUrl = AppImages.getByCategory(category);
    final targetUrl = hasValidUrl ? imageUrl! : fallbackUrl;
    
    // 2. Build Image
    Widget imageWidget = CachedNetworkImage(
      imageUrl: targetUrl,
      width: width,
      height: height,
      fit: fit,
      placeholder: (context, url) => Container(
        width: width,
        height: height,
        color: AppTheme.lightGray,
        child: const Center(
          child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryRed),
        ),
      ),
      errorWidget: (context, url, _) => CachedNetworkImage(
        imageUrl: fallbackUrl,
        width: width,
        height: height,
        fit: fit,
      ),
    );

    // 3. Apply Radius
    if (borderRadius != null) {
      return ClipRRect(
        borderRadius: borderRadius!,
        child: imageWidget,
      );
    }

    return imageWidget;
  }
}
