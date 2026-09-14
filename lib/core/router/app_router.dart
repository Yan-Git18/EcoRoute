import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/admin/presentation/views/admin_dashboard_screen.dart';
import '../../features/auth/domain/entities/user_entity.dart';
import '../../features/auth/presentation/viewmodels/auth_state.dart';
import '../../features/auth/presentation/viewmodels/auth_viewmodel.dart';
import '../../features/auth/presentation/views/login_screen.dart';
import '../../features/auth/presentation/views/register_screen.dart';
import '../../features/auth/presentation/views/welcome_screen.dart';
import '../../features/citizen/domain/entities/report_entity.dart';
import '../../features/citizen/presentation/views/citizen_home_screen.dart';
import '../../features/citizen/presentation/views/citizen_map_screen.dart';
import '../../features/citizen/presentation/views/citizen_profile_screen.dart';
import '../../features/citizen/presentation/views/create_report_wizard_screen.dart';
import '../../features/citizen/presentation/views/my_reports_screen.dart';
import '../../features/citizen/presentation/views/report_detail_screen.dart';
import '../../features/staff/presentation/views/staff_home_screen.dart';
import 'route_names.dart';

/// Notificador reactivo para GoRouter que escucha cambios de autenticación
/// sin provocar la recreación continua del router.
class RouterNotifier extends ChangeNotifier {
  final Ref _ref;

  RouterNotifier(this._ref) {
    _ref.listen<AuthState>(
      authViewModelProvider,
      (previous, next) {
        if (previous?.isAuthenticated != next.isAuthenticated ||
            previous?.isInitialized != next.isInitialized ||
            previous?.user?.role != next.user?.role) {
          notifyListeners();
        }
      },
    );
  }
}

final routerNotifierProvider = Provider<RouterNotifier>((ref) {
  return RouterNotifier(ref);
});

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = ref.watch(routerNotifierProvider);

  return GoRouter(
    initialLocation: RouteNames.welcome,
    refreshListenable: notifier,
    debugLogDiagnostics: false,
    redirect: (BuildContext context, GoRouterState state) {
      final authState = ref.read(authViewModelProvider);
      final isAuthenticated = authState.isAuthenticated;
      final currentPath = state.uri.path;
      final isPublicRoute = currentPath == RouteNames.welcome ||
          currentPath == RouteNames.login ||
          currentPath == RouteNames.register;

      // 1. Si no está autenticado y no está en ruta pública, redirigir a Bienvenida
      if (!isAuthenticated) {
        return isPublicRoute ? null : RouteNames.welcome;
      }

      // 2. Si está autenticado y está en ruta pública, redirigir según su Rol
      final role = authState.user?.role ?? UserRole.citizen;
      final defaultRolePath = switch (role) {
        UserRole.citizen => RouteNames.citizenHome,
        UserRole.staff => RouteNames.staffHome,
        UserRole.admin => RouteNames.adminDashboard,
      };

      if (isPublicRoute) {
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
      // Ruta de Bienvenida / Onboarding
      GoRoute(
        path: RouteNames.welcome,
        builder: (context, state) => const WelcomeScreen(),
      ),

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
      GoRoute(
        path: RouteNames.citizenCreateReport,
        builder: (context, state) => const CreateReportWizardScreen(),
      ),
      GoRoute(
        path: RouteNames.citizenMyReports,
        builder: (context, state) => const MyReportsScreen(),
      ),
      GoRoute(
        path: RouteNames.citizenReportDetail,
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          final extra = state.extra is ReportEntity ? state.extra as ReportEntity : null;
          return ReportDetailScreen(reportId: id, initialReport: extra);
        },
      ),
      GoRoute(
        path: RouteNames.citizenMap,
        builder: (context, state) => const CitizenMapScreen(),
      ),
      GoRoute(
        path: RouteNames.citizenProfile,
        builder: (context, state) => const CitizenProfileScreen(),
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
