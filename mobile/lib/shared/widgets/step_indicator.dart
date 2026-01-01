import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../config/theme.dart';

class StepIndicator extends StatelessWidget {
  final int currentStep;
  final int totalSteps;

  const StepIndicator({
    super.key,
    required this.currentStep,
    required this.totalSteps,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: [
          for (int i = 0; i < totalSteps; i++) ...[
            Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                height: 6,
                decoration: BoxDecoration(
                  color: i <= currentStep 
                      ? AppTheme.primaryRed 
                      : AppTheme.lightGray.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(3),
                  boxShadow: i <= currentStep 
                      ? [BoxShadow(color: AppTheme.primaryRed.withOpacity(0.3), blurRadius: 4, offset: const Offset(0, 2))]
                      : null,
                ),
              ),
            ),
            if (i < totalSteps - 1) const SizedBox(width: 8),
          ],
        ],
      ).animate().fade().slideX(begin: -0.1, end: 0),
    );
  }
}
