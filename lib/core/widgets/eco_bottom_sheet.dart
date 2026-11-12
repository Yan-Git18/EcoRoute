import 'package:flutter/material.dart';

/// Scaffolding estandarizado para BottomSheets modales en EcoRoute.
///
/// Principio DRY y SRP: Unifica el estilo visual (bordes redondeados superiores,
/// barra gris de arrastre 'drag handle', padding responsivo al teclado e ícono de cierre)
/// evitando duplicación en todos los modales de la aplicación.
/// Ubicación: `lib/core/widgets/eco_bottom_sheet.dart`
/// Capa: Core (Widgets)
class EcoBottomSheet {
  static Future<T?> show<T>({
    required BuildContext context,
    required String title,
    required List<Widget> children,
    Widget? trailingHeader,
    bool isScrollControlled = true,
    CrossAxisAlignment crossAxisAlignment = CrossAxisAlignment.start,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: isScrollControlled,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            top: 20,
            left: 24,
            right: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: crossAxisAlignment,
            children: [
              // Barra superior de arrastre
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // Cabecera con título y botón de cierre
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ),
                  trailingHeader ??
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                ],
              ),
              const SizedBox(height: 16),
              ...children,
            ],
          ),
        );
      },
    );
  }
}

