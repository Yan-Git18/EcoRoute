import 'package:flutter/material.dart';

import '../viewmodels/admin_reports_state.dart';

class AdminLoadNotice extends StatelessWidget {
  const AdminLoadNotice({
    super.key,
    required this.state,
    required this.onRetry,
    this.showReports = true,
  });

  final AdminReportsState state;
  final VoidCallback onRetry;
  final bool showReports;

  @override
  Widget build(BuildContext context) {
    final messages = [
      if (showReports && state.reportsLoadFailed)
        state.hasLoadedReports
            ? 'No se pudieron actualizar los reportes. Se muestran los datos de la última carga exitosa.'
            : 'No se pudieron cargar los reportes.',
      if (state.crewsLoadFailed)
        state.hasLoadedCrews
            ? 'No se pudieron actualizar las cuadrillas. Se muestran los datos de la última carga exitosa.'
            : 'No se pudieron cargar las cuadrillas.',
      if (showReports && state.totalsLoadFailed)
        state.totals == null
            ? 'No se pudieron cargar los totales municipales.'
            : 'Los totales municipales corresponden a la última consulta exitosa.',
    ];

    if (messages.isEmpty && !state.isLoading) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (state.isLoading) const LinearProgressIndicator(semanticsLabel: 'Cargando datos municipales'),
        if (messages.isNotEmpty)
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Expanded(child: Semantics(liveRegion: true, child: Text(messages.join('\n')))),
                  TextButton(
                    onPressed: state.isLoading ? null : onRetry,
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
