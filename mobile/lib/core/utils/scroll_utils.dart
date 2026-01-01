import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Keyboard dismiss wrapper - dismisses keyboard when tapping outside
class KeyboardDismiss extends StatelessWidget {
  final Widget child;
  
  const KeyboardDismiss({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      behavior: HitTestBehavior.translucent,
      child: child,
    );
  }
}

/// Auto-scroll wrapper for forms to keep focused field visible
class FormAutoScroll extends StatelessWidget {
  final Widget child;
  final ScrollController? controller;
  final EdgeInsets padding;
  
  const FormAutoScroll({
    super.key,
    required this.child,
    this.controller,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      controller: controller,
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: padding,
      child: child,
    );
  }
}

/// Scroll-to-top FAB that appears after scrolling down
class ScrollToTopFab extends StatefulWidget {
  final ScrollController controller;
  final double showAfter;
  
  const ScrollToTopFab({
    super.key,
    required this.controller,
    this.showAfter = 300,
  });

  @override
  State<ScrollToTopFab> createState() => _ScrollToTopFabState();
}

class _ScrollToTopFabState extends State<ScrollToTopFab> {
  bool _showButton = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onScroll);
  }

  void _onScroll() {
    final shouldShow = widget.controller.offset > widget.showAfter;
    if (shouldShow != _showButton) {
      setState(() => _showButton = shouldShow);
    }
  }

  void _scrollToTop() {
    HapticFeedback.lightImpact();
    widget.controller.animateTo(
      0,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: _showButton ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 200),
      child: FloatingActionButton.small(
        onPressed: _scrollToTop,
        child: const Icon(Icons.arrow_upward),
      ),
    );
  }
}

/// Bounce scroll physics (iOS-like)
class BouncingScrollWrapper extends StatelessWidget {
  final Widget child;
  
  const BouncingScrollWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return ScrollConfiguration(
      behavior: const ScrollBehavior().copyWith(
        physics: const BouncingScrollPhysics(),
      ),
      child: child,
    );
  }
}

/// Scrolling behavior helper
class ScrollHelper {
  /// Scroll to element with key
  static void scrollToKey(GlobalKey key, {Duration duration = const Duration(milliseconds: 300)}) {
    final context = key.currentContext;
    if (context != null) {
      Scrollable.ensureVisible(
        context,
        duration: duration,
        curve: Curves.easeOutCubic,
      );
    }
  }

  /// Check if scroll is at bottom
  static bool isAtBottom(ScrollController controller, {double threshold = 50}) {
    if (!controller.hasClients) return false;
    final maxScroll = controller.position.maxScrollExtent;
    final currentScroll = controller.offset;
    return currentScroll >= (maxScroll - threshold);
  }

  /// Check if scroll is at top
  static bool isAtTop(ScrollController controller, {double threshold = 10}) {
    if (!controller.hasClients) return false;
    return controller.offset <= threshold;
  }
}
