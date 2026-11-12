import 'package:flutter/material.dart';

/// Marcador estilizado con efecto pulso para representar la ubicación GPS del usuario en el mapa.
///
/// Principio DRY y SRP: Reutilizado en [CitizenMapView] y [Step3LocationView].
/// Ubicación: `lib/core/widgets/map/user_pulse_marker.dart`
/// Capa: Core (Widgets)
class UserPulseMarker extends StatelessWidget {
  final double outerSize;
  final double innerSize;

  const UserPulseMarker({
    super.key,
    this.outerSize = 40.0,
    this.innerSize = 16.0,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: outerSize,
          height: outerSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF2563EB).withAlpha(45),
            border: Border.all(
              color: const Color(0xFF2563EB).withAlpha(130),
              width: 1.5,
            ),
          ),
        ),
        Container(
          width: innerSize,
          height: innerSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF2563EB),
            border: Border.all(color: Colors.white, width: 2.5),
            boxShadow: const [
              BoxShadow(
                color: Color(0x40000000),
                blurRadius: 5,
                offset: Offset(0, 2),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

