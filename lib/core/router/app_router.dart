import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/admin/presentation/views/admin_crews_screen.dart';
import '../../features/admin/presentation/views/admin_dashboard_screen.dart';
import '../../features/admin/presentation/views/admin_fleet_screen.dart';
import '../../features/admin/presentation/views/admin_live_map_screen.dart';
import '../../features/admin/presentation/views/admin_reports_screen.dart';
import '../../features/admin/presentation/views/admin_report_detail_screen.dart';
import '../../features/admin/presentation/views/admin_profile_screen.dart';
import '../../features/admin/presentation/views/admin_staff_screen.dart';
import '../../features/auth/domain/entities/user_entity.dart';
import '../../features/auth/presentation/viewmodels/auth_state.dart';
import '../../features/auth/presentation/viewmodels/auth_viewmodel.dart';
import '../../features/auth/presentation/views/login_screen.dart';
import '../../features/auth/presentation/views/register_screen.dart';
import '../../features/auth/presentation/views/welcome_screen.dart';
import '../../features/citizen/domain/entities/report_entity.dart';
import '../../features/citizen/presentation/views/citizen_home_screen.dart';
import '../../features/citizen/presentation/views/citizen_map_screen.dart';
import '../../features/citizen/presentation/views/citizen_notifications_screen.dart';
import '../../features/citizen/presentation/views/citizen_profile_screen.dart';
import '../../features/citizen/presentation/views/create_report_wizard_screen.dart';
import '../../features/citizen/presentation/views/my_reports_screen.dart';
import '../../features/citizen/presentation/views/report_detail_screen.dart';
import '../../features/staff/presentation/views/staff_home_screen.dart';
import '../../features/staff/presentation/views/staff_profile_screen.dart';
import '../../features/staff/presentation/views/staff_route_map_screen.dart';
import '../../features/staff/presentation/views/staff_tasks_screen.dart';
import '../geo/cajamarca_urban_zones.dart';
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

      if (!authState.isInitialized &&
          currentPath == RouteNames.adminReports &&
          CajamarcaZone.fromId(
            state.uri.queryParameters[RouteNames.adminReportZoneParameter],
          ) != null) {
        return null;
      }

      // 1. Si no está autenticado y no está en ruta pública, redirigir a Bienvenida
      if (!isAuthenticated) {
        return isPublicRoute ? null : RouteNames.welcome;
      }

      // 2. Si está autenticado y está en ruta pública, redirigir a su ruta por defecto (Principio OCP)
      final role = authState.user?.role ?? UserRole.citizen;

      if (isPublicRoute) {
        return role.defaultRoute;
      }

      // 3. Protección de rutas por Rol mediante política extensible (RBAC - Principio OCP)
      if (!role.isRoutePermitted(currentPath)) {
        return role.defaultRoute;
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
        builder: _reportDetail,
      ),
      GoRoute(
        path: RouteNames.citizenMap,
        builder: (context, state) => const CitizenMapScreen(),
      ),
      GoRoute(
        path: RouteNames.citizenProfile,
        builder: (context, state) => const CitizenProfileScreen(),
      ),
      GoRoute(
        path: RouteNames.citizenNotifications,
        builder: (context, state) => const CitizenNotificationsScreen(),
      ),

      // Rutas Personal de Limpieza
      GoRoute(
        path: RouteNames.staffHome,
        builder: (context, state) => const StaffHomeScreen(),
      ),
      GoRoute(
        path: RouteNames.staffRouteMap,
        builder: (context, state) => const StaffRouteMapScreen(),
      ),
      GoRoute(
        path: RouteNames.staffTasks,
        builder: (context, state) => const StaffTasksScreen(),
      ),
      GoRoute(
        path: RouteNames.staffProfile,
        builder: (context, state) => const StaffProfileScreen(),
      ),

      // Rutas Administrador Municipal
      GoRoute(
        path: RouteNames.adminDashboard,
        builder: (context, state) => const AdminDashboardScreen(),
      ),
      GoRoute(
        path: RouteNames.adminReports,
        builder: (context, state) {
          final zone = CajamarcaZone.fromId(
            state.uri.queryParameters[RouteNames.adminReportZoneParameter],
          );
          if (zone == null) return const AdminReportsScreen();
          return Consumer(
            builder: (context, ref, child) {
              final auth = ref.watch(authViewModelProvider);
              if (!auth.isInitialized || auth.user?.isAdmin != true) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }
              return AdminReportsScreen(key: ValueKey(zone), zone: zone);
            },
          );
        },
      ),
      GoRoute(
        path: RouteNames.adminReportDetail,
        builder: (context, state) => AdminReportDetailScreen(
          reportId: state.pathParameters['id']!,
          initialReport: state.extra is ReportEntity ? state.extra as ReportEntity : null,
        ),
      ),
      GoRoute(
        path: RouteNames.adminLiveMap,
        builder: (context, state) => AdminLiveMapScreen(
          initialCrewId: state.uri.queryParameters['teamId'],
        ),
      ),
      GoRoute(
        path: RouteNames.adminTeams,
        builder: (context, state) => const AdminCrewsScreen(),
      ),
      GoRoute(
        path: RouteNames.adminStaff,
        builder: (context, state) => const AdminStaffScreen(),
      ),
      GoRoute(
        path: RouteNames.adminFleet,
        builder: (context, state) => const AdminFleetScreen(),
      ),
      GoRoute(
        path: RouteNames.adminProfile,
        builder: (context, state) => const AdminProfileScreen(),
      ),
    ],
  );
});

Widget _reportDetail(BuildContext context, GoRouterState state) {
  final extra = state.extra;
  return ReportDetailScreen(
    reportId: state.pathParameters['id']!,
    initialReport: extra is ReportEntity ? extra : null,
  );
}
