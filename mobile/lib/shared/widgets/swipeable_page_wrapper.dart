import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

/// A wrapper widget that enables iOS-style swipe-right-to-go-back gesture
/// Wrap any screen that should support swipe back navigation
class SwipeablePageWrapper extends StatefulWidget {
  final Widget child;
  final bool canSwipeBack;
  final double edgeWidth;
  
  const SwipeablePageWrapper({
    super.key,
    required this.child,
    this.canSwipeBack = true,
    this.edgeWidth = 40.0,
  });
  
  @override
  State<SwipeablePageWrapper> createState() => _SwipeablePageWrapperState();
}

class _SwipeablePageWrapperState extends State<SwipeablePageWrapper> 
    with SingleTickerProviderStateMixin {
  
  late AnimationController _controller;
  double _dragOffset = 0;
  bool _isDragging = false;
  
  static const double _threshold = 0.3; // 30% of screen width to trigger back
  static const double _maxDragRatio = 0.8;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  void _onHorizontalDragStart(DragStartDetails details) {
    // Only allow drag from left edge
    if (!widget.canSwipeBack) return;
    if (!context.canPop()) return;
    
    if (details.localPosition.dx <= widget.edgeWidth) {
      setState(() {
        _isDragging = true;
        _dragOffset = 0;
      });
    }
  }
  
  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    if (!_isDragging) return;
    
    final screenWidth = MediaQuery.of(context).size.width;
    final maxDrag = screenWidth * _maxDragRatio;
    
    setState(() {
      _dragOffset = (_dragOffset + details.delta.dx).clamp(0.0, maxDrag);
    });
  }
  
  void _onHorizontalDragEnd(DragEndDetails details) {
    if (!_isDragging) return;
    
    final screenWidth = MediaQuery.of(context).size.width;
    final thresholdWidth = screenWidth * _threshold;
    
    if (_dragOffset > thresholdWidth || details.velocity.pixelsPerSecond.dx > 500) {
      // Swipe complete - go back
      HapticFeedback.lightImpact();
      context.pop();
    }
    
    // Reset state
    setState(() {
      _isDragging = false;
      _dragOffset = 0;
    });
  }
  
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final progress = _dragOffset / screenWidth;
    
    return GestureDetector(
      onHorizontalDragStart: _onHorizontalDragStart,
      onHorizontalDragUpdate: _onHorizontalDragUpdate,
      onHorizontalDragEnd: _onHorizontalDragEnd,
      child: Stack(
        children: [
          // Shadow layer during drag
          if (_isDragging)
            Positioned.fill(
              child: Container(
                color: Colors.black.withValues(alpha: 0.3 * (1 - progress)),
              ),
            ),
          
          // Main content with transform during drag
          AnimatedContainer(
            duration: _isDragging 
              ? Duration.zero 
              : const Duration(milliseconds: 200),
            transform: Matrix4.translationValues(_dragOffset, 0, 0),
            child: widget.child,
          ),
          
          // Back indicator during drag
          if (_isDragging && _dragOffset > 20)
            Positioned(
              left: 8 + _dragOffset * 0.3,
              top: MediaQuery.of(context).size.height / 2 - 20,
              child: Opacity(
                opacity: (progress * 2).clamp(0.0, 1.0),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 10,
                        offset: const Offset(2, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    size: 18,
                    color: Colors.black87,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
