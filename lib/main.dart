import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicialización de Firebase protegida contra ausencia de credenciales en desarrollo
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint('Aviso de inicialización Firebase (se configurará vía flutterfire configure): $e');
  }

  runApp(
    const ProviderScope(
      child: EcoRouteApp(),
    ),
  );
}

class EcoRouteApp extends ConsumerWidget {
  const EcoRouteApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'EcoRoute',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: router,
    );
  }
}
