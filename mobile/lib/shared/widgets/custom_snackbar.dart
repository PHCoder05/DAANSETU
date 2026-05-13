import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../config/theme.dart';

/// Beautiful custom snackbar widget with different variants
enum SnackBarType { success, error, warning, info }

class CustomSnackBar {
  static void show(
    BuildContext context, {
    required String message,
    SnackBarType type = SnackBarType.info,
    Duration duration = const Duration(seconds: 3),
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    // Haptic feedback
    HapticFeedback.lightImpact();
    
    final snackBar = SnackBar(
      content: _SnackBarContent(
        message: message,
        type: type,
        actionLabel: actionLabel,
        onAction: onAction,
      ),
      backgroundColor: Colors.transparent,
      elevation: 0,
      duration: duration,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(16),
      padding: EdgeInsets.zero,
    );

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(snackBar);
  }

  static void success(BuildContext context, String message) {
    show(context, message: message, type: SnackBarType.success);
  }

  static void error(BuildContext context, String message, {VoidCallback? onRetry}) {
    show(
      context,
      message: message,
      type: SnackBarType.error,
      actionLabel: onRetry != null ? 'Retry' : null,
      onAction: onRetry,
    );
  }

  static void warning(BuildContext context, String message) {
    show(context, message: message, type: SnackBarType.warning);
  }

  static void info(BuildContext context, String message) {
    show(context, message: message, type: SnackBarType.info);
  }
}

class _SnackBarContent extends StatelessWidget {
  final String message;
  final SnackBarType type;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _SnackBarContent({
    required this.message,
    required this.type,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final config = _getConfig();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: config.backgroundColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: config.backgroundColor.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Icon
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              config.icon,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          // Message
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          // Action Button
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(width: 8),
            TextButton(
              onPressed: () {
                HapticFeedback.lightImpact();
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                onAction?.call();
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.white.withValues(alpha: 0.2),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                actionLabel!,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  _SnackBarConfig _getConfig() {
    switch (type) {
      case SnackBarType.success:
        return _SnackBarConfig(
          backgroundColor: AppTheme.success,
          icon: Icons.check_circle_rounded,
        );
      case SnackBarType.error:
        return _SnackBarConfig(
          backgroundColor: AppTheme.error,
          icon: Icons.error_rounded,
        );
      case SnackBarType.warning:
        return _SnackBarConfig(
          backgroundColor: AppTheme.warning,
          icon: Icons.warning_rounded,
        );
      case SnackBarType.info:
        return _SnackBarConfig(
          backgroundColor: AppTheme.info,
          icon: Icons.info_rounded,
        );
    }
  }
}

class _SnackBarConfig {
  final Color backgroundColor;
  final IconData icon;

  _SnackBarConfig({required this.backgroundColor, required this.icon});
}
