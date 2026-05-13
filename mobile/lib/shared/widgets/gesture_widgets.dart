import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../config/theme.dart';

/// Swipeable card with actions (like iOS mail)
class SwipeableCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onSwipeLeft;
  final VoidCallback? onSwipeRight;
  final IconData leftIcon;
  final IconData rightIcon;
  final Color leftColor;
  final Color rightColor;
  final String? leftLabel;
  final String? rightLabel;

  const SwipeableCard({
    super.key,
    required this.child,
    this.onSwipeLeft,
    this.onSwipeRight,
    this.leftIcon = Icons.delete,
    this.rightIcon = Icons.check,
    this.leftColor = AppTheme.error,
    this.rightColor = AppTheme.success,
    this.leftLabel,
    this.rightLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: UniqueKey(),
      background: _buildBackground(rightColor, rightIcon, rightLabel, Alignment.centerLeft),
      secondaryBackground: _buildBackground(leftColor, leftIcon, leftLabel, Alignment.centerRight),
      confirmDismiss: (direction) async {
        HapticFeedback.mediumImpact();
        if (direction == DismissDirection.startToEnd && onSwipeRight != null) {
          onSwipeRight!();
          return false; // Don't dismiss, just trigger action
        } else if (direction == DismissDirection.endToStart && onSwipeLeft != null) {
          onSwipeLeft!();
          return false;
        }
        return false;
      },
      child: child,
    );
  }

  Widget _buildBackground(Color color, IconData icon, String? label, Alignment alignment) {
    return Container(
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (alignment == Alignment.centerRight) ...[
            if (label != null) Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            const SizedBox(width: 8),
          ],
          Icon(icon, color: Colors.white),
          if (alignment == Alignment.centerLeft) ...[
            const SizedBox(width: 8),
            if (label != null) Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ],
      ),
    );
  }
}

/// Long press options menu
class LongPressMenu extends StatelessWidget {
  final Widget child;
  final List<LongPressMenuItem> items;

  const LongPressMenu({
    super.key,
    required this.child,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: () {
        HapticFeedback.mediumImpact();
        showModalBottomSheet(
          context: context,
          backgroundColor: Colors.transparent,
          builder: (context) => Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 8),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppTheme.lightGray,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...items.map((item) => ListTile(
                    leading: Icon(item.icon, color: item.isDestructive ? AppTheme.error : null),
                    title: Text(
                      item.label,
                      style: TextStyle(
                        color: item.isDestructive ? AppTheme.error : null,
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      item.onTap();
                    },
                  ),),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        );
      },
      child: child,
    );
  }
}

class LongPressMenuItem {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool isDestructive;

  const LongPressMenuItem({
    required this.label,
    required this.icon,
    required this.onTap,
    this.isDestructive = false,
  });
}

/// Double-tap to like animation (Instagram-style)
class DoubleTapLike extends StatefulWidget {
  final Widget child;
  final VoidCallback? onDoubleTap;
  final Color? heartColor;

  const DoubleTapLike({
    super.key,
    required this.child,
    this.onDoubleTap,
    this.heartColor,
  });

  @override
  State<DoubleTapLike> createState() => _DoubleTapLikeState();
}

class _DoubleTapLikeState extends State<DoubleTapLike>
    with SingleTickerProviderStateMixin {
  bool _showHeart = false;
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.2), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 1.2, end: 1.0), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 20),
    ]).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleDoubleTap() {
    HapticFeedback.mediumImpact();
    widget.onDoubleTap?.call();
    setState(() => _showHeart = true);
    _controller.forward(from: 0).then((_) {
      if (mounted) setState(() => _showHeart = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onDoubleTap: _handleDoubleTap,
      child: Stack(
        alignment: Alignment.center,
        children: [
          widget.child,
          if (_showHeart)
            ScaleTransition(
              scale: _scaleAnimation,
              child: Icon(
                Icons.favorite,
                size: 100,
                color: widget.heartColor ?? Colors.white,
              ),
            ),
        ],
      ),
    );
  }
}
