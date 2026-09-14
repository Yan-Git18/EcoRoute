import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// Indicador visual superior con 5 pasos numerados y líneas conectadas.
///
/// Ubicación: `lib/features/citizen/presentation/widgets/wizard_stepper_indicator.dart`
/// Capa: Presentation (Widgets)
class WizardStepperIndicator extends StatelessWidget {
  final int currentStep;
  final int totalSteps;

  const WizardStepperIndicator({
    super.key,
    required this.currentStep,
    this.totalSteps = 5,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: List.generate(totalSteps * 2 - 1, (index) {
          if (index.isOdd) {
            // Línea conectora entre círculos
            final stepIndex = (index + 1) ~/ 2;
            final isCompleted = stepIndex < currentStep;
            return Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                height: 2.5,
                decoration: BoxDecoration(
                  color: isCompleted ? AppColors.primary : const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            );
          } else {
            // Círculo numerado
            final stepNumber = (index ~/ 2) + 1;
            final isActive = stepNumber == currentStep;
            final isCompleted = stepNumber < currentStep;

            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: (isActive || isCompleted)
                    ? AppColors.primary
                    : const Color(0xFFF1F5F9),
                border: Border.all(
                  color: (isActive || isCompleted)
                      ? AppColors.primary
                      : const Color(0xFFE2E8F0),
                  width: 1.5,
                ),
                boxShadow: isActive
                    ? [
                        BoxShadow(
                          color: AppColors.primary.withAlpha(80),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        )
                      ]
                    : null,
              ),
              child: Center(
                child: isCompleted
                    ? const Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: 16,
                      )
                    : Text(
                        '$stepNumber',
                        style: TextStyle(
                          color: isActive ? Colors.white : const Color(0xFF94A3B8),
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
              ),
            );
          }
        }),
      ),
    );
  }
}
