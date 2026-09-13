import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/admin/presentation/views/admin_dashboard_screen.dart';
import '../../features/auth/domain/entities/user_entity.dart';
import '../../features/auth/presentation/viewmodels/auth_viewmodel.dart';
import '../../features/auth/presentation/views/login_screen.dart';
import '../../features/auth/presentation/views/register_screen.dart';
import '../../features/citizen/presentation/views/citizen_home_screen.dart';
import '../../features/staff/presentation/views/staff_home_screen.dart';
import 'route_names.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authViewModelProvider);

  return GoRouter(
    initialLocation: RouteNames.login,
    debugLogDiagnostics: false,
    redirect: (BuildContext context, GoRouterState state) {
      final isAuthenticated = authState.isAuthenticated;
      final currentPath = state.uri.path;
      final isAuthRoute = currentPath == RouteNames.login || currentPath == RouteNames.register;

      // 1. Si no está autenticado y no está en login/register, redirigir a Login
      if (!isAuthenticated) {
        return isAuthRoute ? null : RouteNames.login;
      }

      // 2. Si está autenticado y está en Login o Register, redirigir según su Rol
      final role = authState.user?.role ?? UserRole.citizen;
      final defaultRolePath = switch (role) {
        UserRole.citizen => RouteNames.citizenHome,
        UserRole.staff => RouteNames.staffHome,
        UserRole.admin => RouteNames.adminDashboard,
      };

      if (isAuthRoute) {
        return defaultRolePath;
      }

      // 3. Protección de rutas por Rol (RBAC)
      if (role == UserRole.citizen && (currentPath.startsWith('/staff') || currentPath.startsWith('/admin'))) {
        return RouteNames.citizenHome;
      }
      if (role == UserRole.staff && (currentPath.startsWith('/citizen') || currentPath.startsWith('/admin'))) {
        return RouteNames.staffHome;
      }
      if (role == UserRole.admin && (currentPath.startsWith('/citizen') || currentPath.startsWith('/staff'))) {
        return RouteNames.adminDashboard;
      }

      return null;
    },
    routes: [
      // Rutas de Autenticación
      GoRoute(
        path: RouteNames.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: RouteNames.register,
        builder: (context, state) => const RegisterScreen(),
      ),

      // Rutas Ciudadano
      GoRoute(
        path: RouteNames.citizenHome,
        builder: (context, state) => const CitizenHomeScreen(),
      ),

      // Rutas Personal de Limpieza
      GoRoute(
        path: RouteNames.staffHome,
        builder: (context, state) => const StaffHomeScreen(),
      ),

      // Rutas Administrador Municipal
      GoRoute(
        path: RouteNames.adminDashboard,
        builder: (context, state) => const AdminDashboardScreen(),
      ),
    ],
  );
});
