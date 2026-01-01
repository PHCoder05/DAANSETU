import 'package:flutter/material.dart';
import '../../config/theme.dart';

/// Badge widget for notifications, counts, etc.
class CountBadge extends StatelessWidget {
  final int count;
  final Widget child;
  final Color? backgroundColor;
  final Color? textColor;
  final bool showZero;
  final double size;
  
  const CountBadge({
    super.key,
    required this.count,
    required this.child,
    this.backgroundColor,
    this.textColor,
    this.showZero = false,
    this.size = 18,
  });

  @override
  Widget build(BuildContext context) {
    if (count <= 0 && !showZero) {
      return child;
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        Positioned(
          right: -6,
          top: -6,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            constraints: BoxConstraints(minWidth: size, minHeight: size),
            decoration: BoxDecoration(
              color: backgroundColor ?? AppTheme.primaryRed,
              borderRadius: BorderRadius.circular(size / 2),
              border: Border.all(color: Colors.white, width: 1.5),
            ),
            child: Center(
              child: Text(
                count > 99 ? '99+' : count.toString(),
                style: TextStyle(
                  color: textColor ?? Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Dot badge (no count, just indicator)
class DotBadge extends StatelessWidget {
  final bool show;
  final Widget child;
  final Color? color;
  
  const DotBadge({
    super.key,
    required this.show,
    required this.child,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    if (!show) return child;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        Positioned(
          right: 0,
          top: 0,
          child: Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: color ?? AppTheme.primaryRed,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}

/// Status badge/chip for inline status display
class StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;
  
  const StatusBadge({
    super.key,
    required this.label,
    required this.color,
    this.icon,
  });

  /// Predefined status badges
  factory StatusBadge.available() => const StatusBadge(
    label: 'Available',
    color: AppTheme.success,
    icon: Icons.check_circle,
  );

  factory StatusBadge.claimed() => const StatusBadge(
    label: 'Claimed',
    color: AppTheme.warning,
    icon: Icons.pending,
  );

  factory StatusBadge.delivered() => const StatusBadge(
    label: 'Delivered',
    color: AppTheme.info,
    icon: Icons.done_all,
  );

  factory StatusBadge.expired() => const StatusBadge(
    label: 'Expired',
    color: AppTheme.error,
    icon: Icons.timer_off,
  );

  factory StatusBadge.urgent() => const StatusBadge(
    label: 'Urgent',
    color: AppTheme.error,
    icon: Icons.priority_high,
  );

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
