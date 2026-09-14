import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../viewmodels/create_report_viewmodel.dart';
import '../widgets/wizard_stepper_indicator.dart';
import 'steps/step_1_category_view.dart';
import 'steps/step_2_photo_view.dart';
import 'steps/step_3_location_view.dart';
import 'steps/step_4_details_view.dart';
import 'steps/step_5_success_view.dart';

/// Pantalla contenedora del Wizard interactivo de Creación de Reportes en 5 pasos.
///
/// Ubicación: `lib/features/citizen/presentation/views/create_report_wizard_screen.dart`
/// Capa: Presentation (Views)
class CreateReportWizardScreen extends ConsumerWidget {
  const CreateReportWizardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(createReportViewModelProvider);
    final viewModel = ref.read(createReportViewModelProvider.notifier);

    // Escucha de mensajes de error o validación
    ref.listen(createReportViewModelProvider, (previous, next) {
      if (next.errorMessage != null && next.errorMessage != previous?.errorMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    });

    final isLastStep = state.currentStep == 5;

    return PopScope(
      canPop: state.currentStep == 1 || isLastStep,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (state.currentStep > 1 && !isLastStep) {
          viewModel.prevStep();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF0F172A)),
            onPressed: () {
              if (state.currentStep > 1 && !isLastStep) {
                viewModel.prevStep();
              } else {
                context.pop();
              }
            },
          ),
          centerTitle: true,
          title: Text(
            isLastStep ? 'Estado del reporte' : 'Crear reporte',
            style: const TextStyle(
              color: Color(0xFF0F172A),
              fontWeight: FontWeight.w700,
              fontSize: 17,
            ),
          ),
        ),
        body: SafeArea(
          child: Column(
            children: [
              // Barra de progreso y pasos conectados (sólo visible del paso 1 al 4)
              if (!isLastStep)
                WizardStepperIndicator(currentStep: state.currentStep),

              // Contenido dinámico según el paso activo
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  transitionBuilder: (child, animation) {
                    return FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0.05, 0),
                          end: Offset.zero,
                        ).animate(animation),
                        child: child,
                      ),
                    );
                  },
                  child: KeyedSubtree(
                    key: ValueKey<int>(state.currentStep),
                    child: switch (state.currentStep) {
                      1 => const Step1CategoryView(),
                      2 => const Step2PhotoView(),
                      3 => const Step3LocationView(),
                      4 => const Step4DetailsView(),
                      5 => const Step5SuccessView(),
                      _ => const Step1CategoryView(),
                    },
                  ),
                ),
              ),

              // Botón inferior de avance "Siguiente" o "Enviar reporte"
              if (!isLastStep)
                _WizardBottomBar(
                  currentStep: state.currentStep,
                  isSubmitting: state.isSubmitting,
                  canAdvance: switch (state.currentStep) {
                    1 => state.canAdvanceFromStep1,
                    2 => state.canAdvanceFromStep2,
                    3 => state.canAdvanceFromStep3,
                    4 => state.canAdvanceFromStep4,
                    _ => true,
                  },
                  onNextPressed: viewModel.nextStep,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WizardBottomBar extends StatelessWidget {
  final int currentStep;
  final bool isSubmitting;
  final bool canAdvance;
  final VoidCallback onNextPressed;

  const _WizardBottomBar({
    required this.currentStep,
    required this.isSubmitting,
    required this.canAdvance,
    required this.onNextPressed,
  });

  @override
  Widget build(BuildContext context) {
    final isStep4 = currentStep == 4;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFF1F5F9), width: 1.2)),
      ),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton(
          onPressed: (canAdvance && !isSubmitting) ? onNextPressed : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            disabledBackgroundColor: const Color(0xFFCBD5E1),
            disabledForegroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(26),
            ),
          ),
          child: isSubmitting
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Colors.white,
                  ),
                )
              : Text(
                  isStep4 ? 'Enviar reporte' : 'Siguiente',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                  ),
                ),
        ),
      ),
    );
  }
}
