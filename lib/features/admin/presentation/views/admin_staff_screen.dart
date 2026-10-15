import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../viewmodels/admin_staff_viewmodel.dart';

/// Pantalla de Gestión Segura de Personal Municipal.
///
/// Principio de Privacidad:
/// - Muestra exclusivamente la lista de trabajadores activos (rol 'staff').
/// - Búsqueda por coincidencia exacta de correo para evitar exponer datos o correos de ciudadanos.
///
/// Ubicación: `lib/features/admin/presentation/views/admin_staff_screen.dart`
/// Capa: Presentation (Administrador)
class AdminStaffScreen extends ConsumerStatefulWidget {
  const AdminStaffScreen({super.key});

  @override
  ConsumerState<AdminStaffScreen> createState() => _AdminStaffScreenState();
}

class _AdminStaffScreenState extends ConsumerState<AdminStaffScreen> {
  final TextEditingController _emailSearchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void dispose() {
    _emailSearchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onSearch() {
    final query = _emailSearchController.text.trim();
    _searchFocusNode.unfocus();
    ref.read(adminStaffViewModelProvider.notifier).searchExactEmail(query);
  }

  void _confirmPromote(UserEntity user) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: const [
            Icon(Icons.badge_rounded, color: Color(0xFF0A5835)),
            SizedBox(width: 8),
            Text('Promover a Personal', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '¿Confirmas la asignación de este usuario como Personal de Limpieza y Recolección?',
              style: TextStyle(fontSize: 14, color: Color(0xFF334155)),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(user.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 2),
                  Text(user.email, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'El usuario podrá acceder de inmediato a la interfaz de cuadrillas y tareas municipales en su dispositivo.',
              style: TextStyle(fontSize: 12, color: Color(0xFF047857), fontStyle: FontStyle.italic),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar', style: TextStyle(color: Color(0xFF64748B))),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              final success = await ref
                  .read(adminStaffViewModelProvider.notifier)
                  .promoteToStaff(user);
              if (mounted && success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('¡${user.name} ahora es Personal Municipal!'),
                    backgroundColor: const Color(0xFF047857),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0A5835),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Confirmar Asignación'),
          ),
        ],
      ),
    );
  }

  void _confirmDemote(UserEntity user) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: const [
            Icon(Icons.person_remove_rounded, color: Color(0xFFE11D48)),
            SizedBox(width: 8),
            Text('Revertir a Ciudadano', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          '¿Estás seguro de quitar el rol de trabajador a ${user.name}? Volverá a tener el rol de Ciudadano y perderá acceso a la gestión de tareas.',
          style: const TextStyle(fontSize: 14, color: Color(0xFF334155)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar', style: TextStyle(color: Color(0xFF64748B))),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              final success = await ref
                  .read(adminStaffViewModelProvider.notifier)
                  .demoteToCitizen(user);
              if (mounted && success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${user.name} volvió a rol Ciudadano.'),
                    backgroundColor: const Color(0xFF334155),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE11D48),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Revertir Rol'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminStaffViewModelProvider);
    final viewModel = ref.read(adminStaffViewModelProvider.notifier);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF0F172A)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Gestión de Personal',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Color(0xFF0F172A),
            letterSpacing: -0.3,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF475569)),
            tooltip: 'Actualizar lista',
            onPressed: () => viewModel.loadInitialData(),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => viewModel.loadInitialData(),
        color: const Color(0xFF0A5835),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Tarjeta informativa de privacidad
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFA7F3D0)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Icon(Icons.shield_outlined, color: Color(0xFF059669), size: 20),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Privacidad protegida: Para resguardar a los ciudadanos, la búsqueda requiere el correo exacto y solo se listan los trabajadores activos.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF065F46),
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 2. Buscador por correo exacto
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(8),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Asignar nuevo trabajador',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Ingresa el correo exacto con el que el usuario se registró en la app:',
                      style: TextStyle(fontSize: 12.5, color: Color(0xFF64748B)),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _emailSearchController,
                            focusNode: _searchFocusNode,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.search,
                            onSubmitted: (_) => _onSearch(),
                            decoration: InputDecoration(
                              hintText: 'ej. empleado@correo.com',
                              hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13.5),
                              prefixIcon: const Icon(Icons.email_outlined, color: Color(0xFF0A5835), size: 20),
                              suffixIcon: _emailSearchController.text.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear_rounded, size: 18, color: Color(0xFF94A3B8)),
                                      onPressed: () {
                                        _emailSearchController.clear();
                                        viewModel.clearSearch();
                                        setState(() {});
                                      },
                                    )
                                  : null,
                              filled: true,
                              fillColor: const Color(0xFFF8FAFC),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Color(0xFF0A5835), width: 1.5),
                              ),
                            ),
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: state.isSearching ? null : _onSearch,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0A5835),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                          child: state.isSearching
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                )
                              : const Text('Buscar', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                        ),
                      ],
                    ),

                    if (state.errorMessage != null) ...[
                      const SizedBox(height: 10),
                      Text(
                        state.errorMessage!,
                        style: const TextStyle(fontSize: 12, color: Color(0xFFDC2626), fontWeight: FontWeight.w500),
                      ),
                    ],

                    // 3. Resultado de Búsqueda
                    if (state.hasSearched) ...[
                      const SizedBox(height: 16),
                      const Divider(height: 1, color: Color(0xFFF1F5F9)),
                      const SizedBox(height: 14),
                      if (state.searchedUser == null)
                        _buildNoUserFoundCard(state.searchedEmail ?? '')
                      else
                        _buildSearchedUserCard(state.searchedUser!),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 4. Sección: Lista de Trabajadores Activos
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Text(
                        'Personal Activo',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0A5835).withAlpha(20),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${state.staffMembers.length}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0A5835),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),

              if (state.isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: CircularProgressIndicator(color: Color(0xFF0A5835)),
                  ),
                )
              else if (state.staffMembers.isEmpty)
                _buildEmptyStaffState()
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: state.staffMembers.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final staff = state.staffMembers[index];
                    return _buildStaffItemCard(staff);
                  },
                ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNoUserFoundCard(String email) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.person_search_rounded, color: Color(0xFFD97706), size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Usuario no encontrado',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF92400E)),
                ),
                const SizedBox(height: 2),
                Text(
                  'No existe ninguna cuenta registrada con "$email". Asegúrate de que el trabajador se haya registrado primero en la aplicación.',
                  style: const TextStyle(fontSize: 12, color: Color(0xFFB45309), height: 1.3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchedUserCard(UserEntity user) {
    final isStaff = user.isStaff;
    final isAdmin = user.isAdmin;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isStaff ? const Color(0xFF10B981) : const Color(0xFFE2E8F0),
          width: isStaff ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: isStaff ? const Color(0xFF0A5835) : const Color(0xFF64748B),
                child: Text(
                  user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.name,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                    ),
                    Text(
                      user.email,
                      style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isStaff
                      ? const Color(0xFFDCFCE7)
                      : (isAdmin ? const Color(0xFFFEF3C7) : const Color(0xFFF1F5F9)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  user.role.displayName,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isStaff
                        ? const Color(0xFF166534)
                        : (isAdmin ? const Color(0xFF92400E) : const Color(0xFF475569)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Botón de acción según el rol actual
          if (!isStaff && !isAdmin)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _confirmPromote(user),
                icon: const Icon(Icons.badge_rounded, size: 18),
                label: const Text('Asignar como Personal de Limpieza'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0A5835),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            )
          else if (isStaff)
            Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Color(0xFF059669), size: 18),
                const SizedBox(width: 6),
                const Expanded(
                  child: Text(
                    'Este usuario ya forma parte del personal municipal.',
                    style: TextStyle(fontSize: 12, color: Color(0xFF059669), fontWeight: FontWeight.w600),
                  ),
                ),
                TextButton(
                  onPressed: () => _confirmDemote(user),
                  style: TextButton.styleFrom(foregroundColor: const Color(0xFFE11D48)),
                  child: const Text('Revertir', style: TextStyle(fontSize: 12)),
                ),
              ],
            )
          else if (isAdmin)
            const Text(
              'Esta cuenta tiene permisos de Administrador Municipal.',
              style: TextStyle(fontSize: 12, color: Color(0xFF92400E), fontStyle: FontStyle.italic),
            ),
        ],
      ),
    );
  }

  Widget _buildStaffItemCard(UserEntity staff) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(5),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFF0A5835).withAlpha(15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.engineering_rounded, color: Color(0xFF0A5835), size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  staff.name,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Color(0xFF0F172A)),
                ),
                const SizedBox(height: 2),
                Text(
                  staff.email,
                  style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                ),
                if (staff.phoneNumber != null && staff.phoneNumber!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(Icons.phone_outlined, size: 12, color: Color(0xFF94A3B8)),
                      const SizedBox(width: 4),
                      Text(staff.phoneNumber!, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                    ],
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.remove_circle_outline_rounded, color: Color(0xFFE11D48), size: 20),
            tooltip: 'Revertir a Ciudadano',
            onPressed: () => _confirmDemote(staff),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyStaffState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.badge_outlined, size: 48, color: Color(0xFF94A3B8)),
          SizedBox(height: 12),
          Text(
            'No hay personal asignado todavía',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Color(0xFF334155),
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Busca arriba el correo de tu trabajador para asignarlo como Personal de Limpieza.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12.5, color: Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }
}
