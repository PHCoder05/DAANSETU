import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// UI/UX Utilities for improved user experience
/// Best practices: Haptic feedback, animations, accessibility
class UXHelpers {
  /// Provides haptic feedback for button taps
  static void lightTap() {
    HapticFeedback.lightImpact();
  }

  /// Provides haptic feedback for selection changes
  static void selectionClick() {
    HapticFeedback.selectionClick();
  }

  /// Provides medium haptic feedback for important actions
  static void mediumTap() {
    HapticFeedback.mediumImpact();
  }

  /// Provides heavy haptic feedback for destructive/critical actions
  static void heavyTap() {
    HapticFeedback.heavyImpact();
  }

  /// Success feedback (vibration pattern)
  static void successFeedback() {
    HapticFeedback.mediumImpact();
    Future.delayed(const Duration(milliseconds: 100), () {
      HapticFeedback.lightImpact();
    });
  }

  /// Error feedback
  static void errorFeedback() {
    HapticFeedback.heavyImpact();
  }
}

/// Standard animation durations for consistency
class AnimationDurations {
  static const Duration instant = Duration(milliseconds: 100);
  static const Duration fast = Duration(milliseconds: 200);
  static const Duration normal = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 500);
  static const Duration pageTransition = Duration(milliseconds: 350);
}

/// Standard animation curves
class AnimationCurves {
  static const Curve standard = Curves.easeInOut;
  static const Curve enter = Curves.easeOut;
  static const Curve exit = Curves.easeIn;
  static const Curve bounce = Curves.elasticOut;
  static const Curve smooth = Curves.easeInOutCubic;
}

/// Semantic labels for accessibility
class A11yLabels {
  // Navigation
  static const String home = 'Home';
  static const String back = 'Go back';
  static const String close = 'Close';
  static const String menu = 'Open menu';
  static const String more = 'More options';
  
  // Actions
  static const String search = 'Search';
  static const String filter = 'Filter results';
  static const String refresh = 'Refresh';
  static const String share = 'Share';
  static const String save = 'Save';
  static const String delete = 'Delete';
  static const String edit = 'Edit';
  
  // Donations
  static const String donate = 'Donate item';
  static const String claim = 'Claim donation';
  static const String viewDetails = 'View details';
  
  // Profile
  static const String profile = 'Your profile';
  static const String settings = 'Settings';
  static const String notifications = 'Notifications';
  static const String logout = 'Log out';
}

/// Touch target sizes (minimum 48x48 for accessibility)
class TouchTargets {
  static const double minimum = 48.0;
  static const double comfortable = 56.0;
  static const double large = 64.0;
}
