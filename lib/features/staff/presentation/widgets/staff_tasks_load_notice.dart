import 'package:flutter/material.dart';

class StaffTasksLoadNotice extends StatelessWidget {
  const StaffTasksLoadNotice({
    super.key,
    required this.isLoading,
    required this.errorMessage,
    required this.onRetry,
  });

  final bool isLoading;
  final String? errorMessage;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const LinearProgressIndicator(
        semanticsLabel: 'Cargando tareas asignadas',
      );
    }
    final message = errorMessage;
    if (message == null) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Expanded(child: Text(message)),
            TextButton(onPressed: onRetry, child: const Text('Reintentar')),
          ],
        ),
      ),
    );
  }
}
