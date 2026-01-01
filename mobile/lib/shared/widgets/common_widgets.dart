import 'package:flutter/material.dart';
import '../../config/theme.dart';

/// Avatar widget with fallback initials
class UserAvatar extends StatelessWidget {
  final String? imageUrl;
  final String name;
  final double size;
  final Color? backgroundColor;
  final VoidCallback? onTap;
  final bool showBorder;
  final bool isOnline;

  const UserAvatar({
    super.key,
    this.imageUrl,
    required this.name,
    this.size = 40,
    this.backgroundColor,
    this.onTap,
    this.showBorder = false,
    this.isOnline = false,
  });

  String get _initials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  Color get _backgroundColor {
    if (backgroundColor != null) return backgroundColor!;
    
    // Generate consistent color from name
    final colors = [
      AppTheme.primaryRed,
      AppTheme.primaryGreen,
      AppTheme.accentBlue,
      AppTheme.accentOrange,
      const Color(0xFF9B59B6),
      const Color(0xFF1ABC9C),
    ];
    return colors[name.hashCode % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    final avatar = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: showBorder
            ? Border.all(color: Colors.white, width: 2)
            : null,
      ),
      child: ClipOval(
        child: imageUrl != null && imageUrl!.isNotEmpty
            ? Image.network(
                imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _buildInitials(),
              )
            : _buildInitials(),
      ),
    );

    if (isOnline || onTap != null) {
      return Stack(
        children: [
          onTap != null
              ? GestureDetector(onTap: onTap, child: avatar)
              : avatar,
          if (isOnline)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: size * 0.28,
                height: size * 0.28,
                decoration: BoxDecoration(
                  color: AppTheme.success,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
              ),
            ),
        ],
      );
    }

    return avatar;
  }

  Widget _buildInitials() {
    return Container(
      color: _backgroundColor,
      child: Center(
        child: Text(
          _initials,
          style: TextStyle(
            color: Colors.white,
            fontSize: size * 0.4,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

/// Rating stars display
class RatingStars extends StatelessWidget {
  final double rating;
  final int totalStars;
  final double size;
  final Color? activeColor;
  final Color? inactiveColor;
  final bool showText;

  const RatingStars({
    super.key,
    required this.rating,
    this.totalStars = 5,
    this.size = 16,
    this.activeColor,
    this.inactiveColor,
    this.showText = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ...List.generate(totalStars, (index) {
          final starValue = index + 1;
          IconData icon;
          
          if (rating >= starValue) {
            icon = Icons.star_rounded;
          } else if (rating > starValue - 1) {
            icon = Icons.star_half_rounded;
          } else {
            icon = Icons.star_outline_rounded;
          }
          
          return Icon(
            icon,
            size: size,
            color: rating >= starValue - 0.5
                ? (activeColor ?? Colors.amber)
                : (inactiveColor ?? AppTheme.lightGray),
          );
        }),
        if (showText) ...[
          const SizedBox(width: 4),
          Text(
            rating.toStringAsFixed(1),
            style: TextStyle(
              fontSize: size * 0.75,
              fontWeight: FontWeight.w600,
              color: AppTheme.charcoal,
            ),
          ),
        ],
      ],
    );
  }
}

/// Interactive rating input
class RatingInput extends StatelessWidget {
  final int rating;
  final ValueChanged<int> onChanged;
  final double size;
  final Color? activeColor;

  const RatingInput({
    super.key,
    required this.rating,
    required this.onChanged,
    this.size = 32,
    this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final starValue = index + 1;
        return GestureDetector(
          onTap: () => onChanged(starValue),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Icon(
              rating >= starValue ? Icons.star_rounded : Icons.star_outline_rounded,
              size: size,
              color: rating >= starValue
                  ? (activeColor ?? Colors.amber)
                  : AppTheme.lightGray,
            ),
          ),
        );
      }),
    );
  }
}

/// Circular progress with percentage
class CircularProgress extends StatelessWidget {
  final double progress; // 0.0 to 1.0
  final double size;
  final double strokeWidth;
  final Color? progressColor;
  final Color? backgroundColor;
  final Widget? center;

  const CircularProgress({
    super.key,
    required this.progress,
    this.size = 60,
    this.strokeWidth = 6,
    this.progressColor,
    this.backgroundColor,
    this.center,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: progress,
            strokeWidth: strokeWidth,
            valueColor: AlwaysStoppedAnimation(progressColor ?? AppTheme.primaryRed),
            backgroundColor: backgroundColor ?? AppTheme.lightGray,
          ),
          center ?? Text(
            '${(progress * 100).toInt()}%',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: size * 0.22,
            ),
          ),
        ],
      ),
    );
  }
}
