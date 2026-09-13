import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_assets.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';

/// Modelo interno de datos para cada diapositiva de bienvenida.
class WelcomeSlideData {
  final String title;
  final String subtitle;
  final String backgroundImage;

  const WelcomeSlideData({
    required this.title,
    required this.subtitle,
    required this.backgroundImage,
  });
}

/// Pantalla de bienvenida / Onboarding para EcoRoute.
/// 
/// Ubicación: `lib/features/auth/presentation/views/welcome_screen.dart`
/// Capa: Presentation (Views)
class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<WelcomeSlideData> _slides = const [
    WelcomeSlideData(
      title: 'EcoRoute',
      subtitle: 'Juntos por ciudades\nmás limpias',
      backgroundImage: AppAssets.welcomeIllustration,
    ),
    WelcomeSlideData(
      title: 'EcoRoute',
      subtitle: 'Reporta incidencias\nen tiempo real',
      backgroundImage: AppAssets.welcomeIllustration1,
    ),
    WelcomeSlideData(
      title: 'EcoRoute',
      subtitle: 'Rutas inteligentes y\nciudades limpias',
      backgroundImage: AppAssets.welcomeIllustration2,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onNextPressed() {
    if (_currentPage < _slides.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    } else {
      context.push(RouteNames.register);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final topLogoSpacing = (size.height * 0.12).clamp(90.0, 130.0);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // 1. Imagen de Fondo a Pantalla Completa con transición animada entre vistas
          Positioned.fill(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              transitionBuilder: (child, animation) {
                return FadeTransition(opacity: animation, child: child);
              },
              child: Image.asset(
                _slides[_currentPage].backgroundImage,
                key: ValueKey<int>(_currentPage),
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
                alignment: Alignment.center,
                errorBuilder: (context, error, stackTrace) {
                  return Image.asset(
                    AppAssets.welcomeIllustration,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                  );
                },
              ),
            ),
          ),

          // 2. Degradado sutil superior para asegurar contraste con la barra de estado y el botón Saltar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 130,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withAlpha(210),
                    Colors.white.withAlpha(80),
                    Colors.white.withAlpha(0),
                  ],
                ),
              ),
            ),
          ),

          // 3. Botón Superior "Saltar"
          SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.only(right: 20.0, top: 8.0),
                child: TextButton(
                  onPressed: () => context.go(RouteNames.login),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.forest,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  ),
                  child: const Text(
                    'Saltar',
                    style: TextStyle(
                      color: AppColors.forest,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // 4. PageView de las 3 vistas (Logo invertido posicionado más abajo + Subtítulo en 2 líneas)
          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: _slides.length,
                    onPageChanged: (index) {
                      setState(() {
                        _currentPage = index;
                      });
                    },
                    itemBuilder: (context, index) {
                      final slide = _slides[index];

                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32.0),
                        child: Column(
                          children: [
                            // Espacio vertical para ubicar el logo un poco más abajo en la composición
                            SizedBox(height: topLogoSpacing),

                            // Logo invertido oficial para fondo blanco (logo_invertido.webp)
                            Image.asset(
                              AppAssets.logoInverted,
                              height: 175,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) {
                                return Image.asset(
                                  AppAssets.logo,
                                  height: 175,
                                  fit: BoxFit.contain,
                                );
                              },
                            ),
                            const SizedBox(height: 16),

                            // Subtítulo en 2 líneas como en la imagen original
                            Text(
                              slide.subtitle,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: AppColors.forest,
                                height: 1.25,
                                letterSpacing: -0.3,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                // Espacio inferior para evitar solapamiento con el panel blanco
                const SizedBox(height: 180),
              ],
            ),
          ),

          // 5. Panel Inferior Fijo con Indicador de 3 Puntos + Botones
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(28, 20, 28, 36),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(15),
                    blurRadius: 18,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Indicador de 3 puntos (Dots)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_slides.length, (index) {
                      final isActive = index == _currentPage;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        height: 7,
                        width: isActive ? 26 : 8,
                        decoration: BoxDecoration(
                          color: isActive
                              ? AppColors.primary
                              : AppColors.primarySoft,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 22),

                  // Botón Principal Píldora: "Comenzar"
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: _onNextPressed,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 2,
                        shadowColor: AppColors.primary.withAlpha(90),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                      ),
                      child: const Text(
                        'Comenzar',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Botón Secundario: "Ya tengo una cuenta"
                  TextButton(
                    onPressed: () => context.push(RouteNames.login),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primaryDark,
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    ),
                    child: const Text(
                      'Ya tengo una cuenta',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryDark,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
