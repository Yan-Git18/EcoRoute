import 'package:flutter/material.dart';

import '../../domain/usecases/assign_staff_roles.dart';
import '../../../auth/domain/entities/user_entity.dart';

class AdminStaffBatchScreen extends StatefulWidget {
  const AdminStaffBatchScreen({
    super.key,
    required this.assignStaffRoles,
    required this.onAssigned,
  });

  final AssignStaffRoles assignStaffRoles;
  final ValueChanged<List<UserEntity>> onAssigned;

  @override
  State<AdminStaffBatchScreen> createState() => _AdminStaffBatchScreenState();
}

class _AdminStaffBatchScreenState extends State<AdminStaffBatchScreen> {
  final _emails = TextEditingController();
  final _selected = <String>{};
  final _assigned = <String>{};
  final _failed = <String, String>{};
  List<StaffRoleCandidate>? _candidates;
  bool _busy = false;

  @override
  void dispose() {
    _emails.dispose();
    super.dispose();
  }

  Future<void> _lookup() async {
    if (_busy) return;
    FocusScope.of(context).unfocus();
    setState(() => _busy = true);
    final candidates = await widget.assignStaffRoles.lookup(_emails.text);
    if (!mounted) return;
    setState(() {
      _candidates = candidates;
      _selected.addAll(
        candidates
            .where((candidate) => candidate.canAssign)
            .map((candidate) => candidate.user!.id),
      );
      _busy = false;
    });
  }

  Future<void> _assign() async {
    if (_busy || _selected.isEmpty) return;
    final users = [
      for (final candidate in _candidates!)
        if (candidate.user case final user? when _selected.contains(user.id))
          user,
    ];

    setState(() => _busy = true);
    final results = await widget.assignStaffRoles.assign(users);
    if (!mounted) return;
    final successful = <UserEntity>[];
    setState(() {
      for (final (user, result) in results) {
        if (result.isSuccess) {
          _assigned.add(user.id);
          _selected.remove(user.id);
          _failed.remove(user.id);
          successful.add(user);
        } else {
          _failed[user.id] = result.failureOrNull!.message;
        }
      }
      _busy = false;
    });
    if (successful.isNotEmpty) widget.onAssigned(successful);
  }

  @override
  Widget build(BuildContext context) {
    final candidates = _candidates;
    return PopScope(
      canPop: !_busy,
      child: Scaffold(
        appBar: AppBar(title: const Text('Asignar Personal por lote')),
        bottomNavigationBar: candidates == null
            ? null
            : SafeArea(
                minimum: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_busy) const LinearProgressIndicator(),
                    if (_selected.isNotEmpty)
                      FilledButton(
                        onPressed: _busy ? null : _assign,
                        child: Text('Asignar rol a ${_selected.length}'),
                      ),
                    OutlinedButton(
                      onPressed: _busy
                          ? null
                          : () => setState(() {
                              _candidates = null;
                              _selected.clear();
                              _assigned.clear();
                              _failed.clear();
                            }),
                      child: const Text('Editar correos'),
                    ),
                  ],
                ),
              ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (candidates == null) ...[
              TextField(
                controller: _emails,
                enabled: !_busy,
                minLines: 5,
                maxLines: 10,
                keyboardType: TextInputType.multiline,
                autocorrect: false,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  labelText: 'Correos registrados',
                  hintText: 'rosa@ejemplo.com\nluis@ejemplo.com',
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Pega los correos separados por saltos de línea, comas o punto y coma.',
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _busy || _emails.text.trim().isEmpty
                    ? null
                    : _lookup,
                child: const Text('Buscar y revisar'),
              ),
              if (_busy) const LinearProgressIndicator(),
            ] else ...[
              if (candidates.isEmpty) const Text('Ingresa al menos un correo.'),
              Text(
                '${_selected.length} seleccionados · ${_assigned.length} asignados',
              ),
              for (final candidate in candidates) _candidateTile(candidate),
            ],
          ],
        ),
      ),
    );
  }

  Widget _candidateTile(StaffRoleCandidate candidate) {
    final user = candidate.user;
    final assigned = _assigned.contains(user?.id);
    final status = assigned
        ? 'Rol asignado'
        : _failed[user?.id] ?? candidate.status;
    final title = Text(user == null ? candidate.email : user.name);
    final subtitle = Text(
      user == null ? status : '${candidate.email}\n$status',
    );
    if (user == null || !candidate.canAssign || assigned) {
      return ListTile(
        title: title,
        subtitle: subtitle,
        trailing: assigned ? const Icon(Icons.check_circle_outline) : null,
      );
    }
    return CheckboxListTile(
      title: title,
      subtitle: subtitle,
      value: _selected.contains(user.id),
      onChanged: _busy
          ? null
          : (checked) => setState(() {
              if (checked == true) {
                _selected.add(user.id);
              } else {
                _selected.remove(user.id);
              }
            }),
    );
  }
}
