import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_names.dart';
import '../../domain/entities/municipal_crew_entity.dart';
import '../viewmodels/admin_reports_viewmodel.dart';
import '../widgets/admin_back_button.dart';
import '../widgets/admin_bottom_nav_bar.dart';
import '../widgets/admin_crew_card.dart';
import 'admin_crew_editor_screen.dart';
import '../widgets/admin_load_notice.dart';
import 'admin_crew_detail_screen.dart';

class AdminCrewsScreen extends ConsumerStatefulWidget {
  const AdminCrewsScreen({super.key});

  @override
  ConsumerState<AdminCrewsScreen> createState() => _AdminCrewsScreenState();
}

class _AdminCrewsScreenState extends ConsumerState<AdminCrewsScreen> {
  final _search = TextEditingController();
  MunicipalCrewStatus? _status;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminReportsViewModelProvider);
    final viewModel = ref.read(adminReportsViewModelProvider.notifier);
    final staff = ref.watch(adminTeamStaffProvider);
    final query = _search.text.trim().toLowerCase();
    final filteredCrews = state.teams.where((crew) {
      return (_status == null || _status == crew.status) &&
          [
            crew.name,
            crew.vehicleCode,
            crew.vehiclePlate,
            crew.leadStaffName,
          ].any((field) => field.toLowerCase().contains(query));
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        leading: const AdminBackButton(),
        title: const Text('Equipos'),
        actions: [
          _ResourceShortcut(
            icon: Icons.local_shipping_outlined,
            label: 'Flota',
            onPressed: () => context.push(RouteNames.adminFleet),
          ),
          _ResourceShortcut(
            icon: Icons.badge_outlined,
            label: 'Personal',
            onPressed: () => context.push(RouteNames.adminStaff),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualizar equipos',
            onPressed: state.isLoading
                ? null
                : () {
                    ref.invalidate(adminTeamStaffProvider);
                    viewModel.refresh();
                  },
          ),
        ],
      ),
      body: Column(
        children: [
          AdminLoadNotice(
            state: state,
            onRetry: viewModel.refresh,
            showReports: false,
          ),
          if (state.hasLoadedCrews) ...[
            ColoredBox(
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _search,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        hintText: 'Buscar equipos',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _search.text.isEmpty
                            ? null
                            : IconButton(
                                icon: const Icon(Icons.clear),
                                tooltip: 'Limpiar búsqueda',
                                onPressed: () => setState(_search.clear),
                              ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          for (final status in [
                            null,
                            ...MunicipalCrewStatus.values,
                          ])
                            Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ChoiceChip(
                                label: Text(status?.label ?? 'Todos'),
                                selected: _status == status,
                                onSelected: (_) =>
                                    setState(() => _status = status),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Divider(height: 1),
            if (staff.hasError)
              TextButton.icon(
                onPressed: () => ref.invalidate(adminTeamStaffProvider),
                icon: const Icon(Icons.refresh),
                label: const Text('Volver a cargar integrantes'),
              ),
            Expanded(
              child: filteredCrews.isEmpty
                  ? Center(
                      child: Text(
                        state.teams.isEmpty
                            ? 'Aún no hay equipos registrados.'
                            : 'No se encontraron equipos.',
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 88),
                      itemCount: filteredCrews.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final crew = filteredCrews[index];
                        return AdminCrewCard(
                          crew: crew,
                          onTap: () => Navigator.of(context).push<void>(
                            MaterialPageRoute(
                              builder: (_) =>
                                  AdminCrewDetailScreen(crewId: crew.id),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ],
      ),
      floatingActionButton: state.hasLoadedCrews
          ? FloatingActionButton.extended(
              onPressed: staff.hasValue && !staff.isLoading
                  ? () => openAdminCrewEditor(context, ref)
                  : null,
              backgroundColor: const Color(0xFF0A5835),
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add),
              label: const Text('Nuevo equipo'),
            )
          : null,
      bottomNavigationBar: const AdminBottomNavBar(currentIndex: 4),
    );
  }
}

class _ResourceShortcut extends StatelessWidget {
  const _ResourceShortcut({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18),
          Text(label, style: const TextStyle(fontSize: 11)),
        ],
      ),
    );
  }
}
