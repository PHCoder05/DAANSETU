import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../config/theme.dart';
import '../../config/constants.dart';
import 'dart:math' as math;

/// Beautiful loading widget with animated gradient and optional quote
class AppLoader extends StatelessWidget {
  final String? message;
  final bool showQuote;
  final double size;
  final Color? color;
  
  const AppLoader({
    super.key,
    this.message,
    this.showQuote = false,
    this.size = 40,
    this.color,
  });
  
  /// Simple spinner loader
  const AppLoader.simple({
    super.key,
    this.size = 32,
    this.color,
  }) : message = null, showQuote = false;
  
  /// Full page loader with quote
  const AppLoader.fullPage({
    super.key,
    this.message,
    this.showQuote = true,
    this.size = 50,
    this.color,
  });
  
  @override
  Widget build(BuildContext context) {
    if (showQuote) {
      return _FullPageLoader(message: message, size: size, color: color);
    }
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          _AnimatedSpinner(size: size, color: color ?? AppTheme.primaryRed),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(
              message!,
              style: const TextStyle(
                color: AppTheme.gray,
                fontSize: 14,
              ),
            ),
          ],
        ],
      ),
    );
  }
  
  static Widget listSkeleton({int itemCount = 5}) {
    return ListSkeleton(itemCount: itemCount);
  }
}

/// Animated gradient spinner
class _AnimatedSpinner extends StatefulWidget {
  final double size;
  final Color color;
  
  const _AnimatedSpinner({required this.size, required this.color});
  
  @override
  State<_AnimatedSpinner> createState() => _AnimatedSpinnerState();
}

class _AnimatedSpinnerState extends State<_AnimatedSpinner>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat();
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.rotate(
          angle: _controller.value * 2 * math.pi,
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: SweepGradient(
                colors: [
                  widget.color.withValues(alpha: 0),
                  widget.color.withValues(alpha: 0.5),
                  widget.color,
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
            child: Center(
              child: Container(
                width: widget.size * 0.75,
                height: widget.size * 0.75,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Theme.of(context).scaffoldBackgroundColor,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Full page loader with inspirational quote
class _FullPageLoader extends StatefulWidget {
  final String? message;
  final double size;
  final Color? color;
  
  const _FullPageLoader({this.message, required this.size, this.color});
  
  @override
  State<_FullPageLoader> createState() => _FullPageLoaderState();
}

class _FullPageLoaderState extends State<_FullPageLoader> {
  late String _quote;
  
  @override
  void initState() {
    super.initState();
    _quote = AppConstants.getRandomQuote();
  }
  
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated Logo/Spinner
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primaryRed.withValues(alpha: 0.1),
                    AppTheme.primaryRed.withValues(alpha: 0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  _AnimatedSpinner(
                    size: widget.size,
                    color: widget.color ?? AppTheme.primaryRed,
                  ),
                  Icon(
                    Icons.volunteer_activism_rounded,
                    color: AppTheme.primaryRed.withValues(alpha: 0.3),
                    size: 32,
                  ).animate(onPlay: (c) => c.repeat(reverse: true))
                      .scale(begin: const Offset(0.9, 0.9), end: const Offset(1.1, 1.1), duration: 1000.ms),
                ],
              ),
            ).animate().fade().scale(begin: const Offset(0.8, 0.8)),
            
            const SizedBox(height: 32),
            
            // Quote Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.format_quote_rounded,
                    color: AppTheme.primaryRed.withValues(alpha: 0.3),
                    size: 28,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _quote,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 15,
                      height: 1.5,
                      color: AppTheme.charcoal,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ).animate(delay: 200.ms).fade().slideY(begin: 0.1, end: 0),
            
            const SizedBox(height: 24),
            
            // Loading message
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppTheme.gray,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  widget.message ?? 'Loading...',
                  style: const TextStyle(
                    color: AppTheme.gray,
                    fontSize: 13,
                  ),
                ),
              ],
            ).animate(delay: 400.ms).fade(),
          ],
        ),
      ),
    );
  }
}

/// Skeleton loading placeholder
class SkeletonLoader extends StatelessWidget {
  final double? width;
  final double height;
  final double borderRadius;
  
  const SkeletonLoader({
    super.key,
    this.width,
    this.height = 16,
    this.borderRadius = 8,
  });
  
  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppTheme.lightGray.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    ).animate(onPlay: (c) => c.repeat())
        .shimmer(duration: 1200.ms, color: Colors.white.withValues(alpha: 0.5));
  }
}

/// Card skeleton for lists
class CardSkeleton extends StatelessWidget {
  const CardSkeleton({super.key});
  
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
          ),
        ],
      ),
      child: const Row(
        children: [
          SkeletonLoader(width: 50, height: 50, borderRadius: 14),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonLoader(width: 120, height: 14),
                SizedBox(height: 8),
                SkeletonLoader(width: double.infinity, height: 10),
                SizedBox(height: 6),
                SkeletonLoader(width: 80, height: 10),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Multiple card skeletons
class ListSkeleton extends StatelessWidget {
  final int itemCount;
  
  const ListSkeleton({super.key, this.itemCount = 5});
  
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        return const CardSkeleton()
            .animate(delay: (index * 100).ms)
            .fade()
            .slideY(begin: 0.1, end: 0);
      },
    );
  }
}
