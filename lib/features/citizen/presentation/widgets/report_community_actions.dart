import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/report_community.dart';
import '../../domain/entities/report_entity.dart';
import '../viewmodels/report_community_providers.dart';
import 'report_community_summary_label.dart';

class ReportCommunityActions extends ConsumerStatefulWidget {
  final ReportEntity report;
  final String userId;

  const ReportCommunityActions({
    super.key,
    required this.report,
    required this.userId,
  });

  @override
  ConsumerState<ReportCommunityActions> createState() =>
      _ReportCommunityActionsState();
}

class _ReportCommunityActionsState
    extends ConsumerState<ReportCommunityActions> {
  bool _saving = false;
  String? _error;

  Future<void> _submit({int? rating}) async {
    if (_saving) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    final repository = ref.read(reportCommunityRepositoryProvider);
    final reportId = widget.report.id;
    final result = await (rating == null
        ? repository.support(reportId)
        : repository.rate(reportId, rating));
    if (!mounted) return;
    setState(() {
      _saving = false;
      _error = result.failureOrNull?.message;
    });
    if (result.isSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            rating == null ? 'Apoyo registrado.' : 'Calificación registrada.',
          ),
        ),
      );
    }
  }

  Future<void> _selectRating() async {
    final rating = await showDialog<int>(
      context: context,
      builder: (context) => const _CleanupRatingDialog(),
    );
    if (rating != null && mounted) await _submit(rating: rating);
  }

  Widget? _action(ReportParticipation participation) {
    final report = widget.report;
    final isAuthor = report.citizenId == widget.userId;
    if (report.status == ReportStatus.resolved) {
      if (participation.rating case final rating?) {
        return Text('Tu calificación · $rating de 5');
      }
      if (isAuthor || participation.supported) {
        return FilledButton.tonal(
          onPressed: _saving ? null : _selectRating,
          child: const Text('Calificar la limpieza'),
        );
      }
      return null;
    }
    if (participation.supported) return const Text('Ya apoyaste este reporte.');
    if (isAuthor || report.status == ReportStatus.cancelled) return null;
    return FilledButton.tonal(
      onPressed: _saving ? null : () => _submit(),
      child: const Text('A mí también me afecta'),
    );
  }

  @override
  Widget build(BuildContext context) {
    final reportId = widget.report.id;
    final provider = reportParticipationProvider((reportId, widget.userId));
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Participación comunitaria',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            ReportCommunitySummaryLabel(
              reportId: reportId,
              showWhenEmpty: true,
            ),
            ref
                .watch(provider)
                .when(
                  data: (participation) =>
                      _action(participation) ?? const SizedBox.shrink(),
                  error: (_, _) => TextButton(
                    onPressed: () => ref.invalidate(provider),
                    child: const Text('Reintentar cargar tu participación'),
                  ),
                  loading: () => const LinearProgressIndicator(),
                ),
            if (_saving) const LinearProgressIndicator(),
            if (_error case final error?)
              Text(
                error,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
          ],
        ),
      ),
    );
  }
}

class _CleanupRatingDialog extends StatefulWidget {
  const _CleanupRatingDialog();

  @override
  State<_CleanupRatingDialog> createState() => _CleanupRatingDialogState();
}

class _CleanupRatingDialogState extends State<_CleanupRatingDialog> {
  int? _rating;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('¿Cómo quedó la limpieza?'),
      content: Wrap(
        alignment: WrapAlignment.center,
        children: [
          for (var rating = 1; rating <= 5; rating++)
            IconButton(
              tooltip: rating == 1 ? '1 estrella' : '$rating estrellas',
              isSelected: rating == _rating,
              icon: Icon(
                rating <= (_rating ?? 0) ? Icons.star : Icons.star_border,
              ),
              onPressed: () => setState(() => _rating = rating),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Volver'),
        ),
        FilledButton(
          onPressed: _rating == null
              ? null
              : () => Navigator.pop(context, _rating),
          child: const Text('Enviar calificación'),
        ),
      ],
    );
  }
}
