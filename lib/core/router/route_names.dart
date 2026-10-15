/// Constantes con los nombres y rutas de navegación de EcoRoute.
/// 
/// Ubicación: `lib/core/router/route_names.dart`
/// Capa: Core (Router)
class RouteNames {
  RouteNames._();

  // Auth & Onboarding
  static const String welcome = '/welcome';
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';

  // Ciudadano
  static const String citizenHome = '/citizen';
  static const String citizenCreateReport = '/citizen/create-report';
  static const String citizenMyReports = '/citizen/my-reports';
  static const String citizenReportDetail = '/citizen/report/:id';
  static const String citizenMap = '/citizen/map';
  static const String citizenProfile = '/citizen/profile';

  // Personal de Limpieza / Recolección
  static const String staffHome = '/staff';
  static const String staffTasks = '/staff/tasks';
  static const String staffTaskDetail = '/staff/task/:id';
  static const String staffRouteMap = '/staff/route';
  static const String staffEvidence = '/staff/evidence/:id';
  static const String staffProfile = '/staff/profile';

  // Administrador Municipal
  static const String adminDashboard = '/admin';
  static const String adminReports = '/admin/reports';
  static const String adminReportDetail = '/admin/report/:id';
  static const String adminAssignStaff = '/admin/assign/:id';
  static const String adminLiveMap = '/admin/live-map';
  static const String adminRoutePlanner = '/admin/route-planner';
  static const String adminMetrics = '/admin/metrics';
  static const String adminTeams = '/admin/teams';
  static const String adminStaff = '/admin/staff';
}
