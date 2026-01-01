import 'package:flutter/material.dart';
import '../../config/theme.dart';

/// Shimmer effect for loading states
class ShimmerBox extends StatefulWidget {
  final double width;
  final double height;
  final BorderRadius? borderRadius;
  
  const ShimmerBox({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius,
  });

  @override
  State<ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<ShimmerBox>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
    
    _animation = Tween<double>(begin: -2, end: 2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: widget.borderRadius ?? BorderRadius.circular(8),
            gradient: LinearGradient(
              begin: Alignment(_animation.value, 0),
              end: Alignment(_animation.value + 1, 0),
              colors: isDark
                  ? [
                      AppTheme.cardDark,
                      AppTheme.cardDark.withOpacity(0.5),
                      AppTheme.cardDark,
                    ]
                  : [
                      AppTheme.lightGray,
                      AppTheme.lightGray.withOpacity(0.3),
                      AppTheme.lightGray,
                    ],
            ),
          ),
        );
      },
    );
  }
}

/// Card Shimmer Skeleton
class CardSkeleton extends StatelessWidget {
  const CardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const ShimmerBox(width: 60, height: 60, borderRadius: BorderRadius.all(Radius.circular(8))),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    ShimmerBox(width: double.infinity, height: 16),
                    SizedBox(height: 8),
                    ShimmerBox(width: 100, height: 12),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const ShimmerBox(width: double.infinity, height: 12),
          const SizedBox(height: 8),
          const ShimmerBox(width: 150, height: 12),
        ],
      ),
    );
  }
}

/// List Skeleton - shows multiple card skeletons
class ListSkeleton extends StatelessWidget {
  final int itemCount;
  
  const ListSkeleton({super.key, this.itemCount = 5});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      physics: const NeverScrollableScrollPhysics(),
      itemCount: itemCount,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) => const CardSkeleton(),
    );
  }
}

/// Profile Skeleton
class ProfileSkeleton extends StatelessWidget {
  const ProfileSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 24),
        const ShimmerBox(
          width: 100,
          height: 100,
          borderRadius: BorderRadius.all(Radius.circular(50)),
        ),
        const SizedBox(height: 16),
        const ShimmerBox(width: 150, height: 20),
        const SizedBox(height: 8),
        const ShimmerBox(width: 200, height: 14),
        const SizedBox(height: 32),
        ...List.generate(
          4,
          (index) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: const [
                ShimmerBox(width: 40, height: 40, borderRadius: BorderRadius.all(Radius.circular(20))),
                SizedBox(width: 16),
                Expanded(child: ShimmerBox(width: double.infinity, height: 16)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
