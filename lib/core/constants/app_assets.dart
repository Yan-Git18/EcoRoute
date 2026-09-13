/// Rutas centralizadas de assets (imágenes e iconos) en EcoRoute.
///
/// Ubicación: `lib/core/constants/app_assets.dart`
/// Capa: Core (Constants)
class AppAssets {
  AppAssets._();

  static const String _imagesPath = 'assets/images';
  static const String _iconsPath = 'assets/icons';

  // Imágenes principales (puedes agregar los nombres de tus archivos aquí)
  static const String logo = '$_imagesPath/EcoRoute_logo.png';
  static const String logoInverted = '$_imagesPath/logo_invertido.webp';
  static const String welcomeIllustration = '$_imagesPath/Ilustration_welcome.jpeg';
  static const String welcomeIllustration1 = '$_imagesPath/Ilustration_welcome_1.jpeg';
  static const String welcomeIllustration2 = '$_imagesPath/Ilustration_welcome_2.jpeg';
  static const String welcomeIllustration3 = '$_imagesPath/Ilustration_welcome_3.jpeg';
  static const String loginIllustration = '$_imagesPath/Ilustration_login.jpeg';
  static const String registerIllustration = '$_imagesPath/Ilustration_register.jpeg';

  // Iconos personalizados
  static const String iconEco = '$_iconsPath/icon_eco.png';
  static const String iconRecycle = '$_iconsPath/icon_recycle.png';
}
