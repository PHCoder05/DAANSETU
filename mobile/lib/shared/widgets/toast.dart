import 'package:flutter/material.dart';
import '../../config/theme.dart';

/// Success Toast
void showSuccessToast(BuildContext context, String message) {
  _showToast(context, message, AppTheme.success, Icons.check_circle);
}

/// Error Toast
void showErrorToast(BuildContext context, String message) {
  _showToast(context, message, AppTheme.error, Icons.error);
}

/// Warning Toast
void showWarningToast(BuildContext context, String message) {
  _showToast(context, message, AppTheme.warning, Icons.warning);
}

/// Info Toast
void showInfoToast(BuildContext context, String message) {
  _showToast(context, message, AppTheme.info, Icons.info);
}

void _showToast(BuildContext context, String message, Color color, IconData icon) {
  final overlay = Overlay.of(context);
  late OverlayEntry overlayEntry;
  
  overlayEntry = OverlayEntry(
    builder: (context) => _ToastWidget(
      message: message,
      color: color,
      icon: icon,
      onDismiss: () => overlayEntry.remove(),
    ),
  );
  
  overlay.insert(overlayEntry);
}

class _ToastWidget extends StatefulWidget {
  final String message;
  final Color color;
  final IconData icon;
  final VoidCallback onDismiss;
  
  const _ToastWidget({
    required this.message,
    required this.color,
    required this.icon,
    required this.onDismiss,
  });

  @override
  State<_ToastWidget> createState() => _ToastWidgetState();
}

class _ToastWidgetState extends State<_ToastWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _controller.forward();
    
    // Auto dismiss after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        _controller.reverse().then((_) => widget.onDismiss());
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SlideTransition(
            position: _slideAnimation,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Material(
                color: Colors.transparent,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: widget.color,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: widget.color.withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(widget.icon, color: Colors.white, size: 20),
                      const SizedBox(width: 12),
                      Flexible(
                        child: Text(
                          widget.message,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
