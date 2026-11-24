import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../auth/domain/entities/user_entity.dart';

class AdminAccountDrawer extends StatelessWidget {
  const AdminAccountDrawer({
    super.key,
    required this.user,
    required this.isSigningOut,
    required this.onViewAccount,
    required this.onChangePassword,
    required this.onLogout,
  });

  final UserEntity? user;
  final bool isSigningOut;
  final VoidCallback? onViewAccount;
  final VoidCallback? onChangePassword;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    void choose(VoidCallback action) {
      Navigator.pop(context);
      action();
    }

    final account = user;
    final viewAccount = onViewAccount;
    final changePassword = onChangePassword;

    return Drawer(
      semanticLabel: 'Menú de cuenta',
      backgroundColor: Colors.white,
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        margin: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEAF4EE),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const CircleAvatar(
                              radius: 21,
                              backgroundColor: AppColors.forest,
                              foregroundColor: Colors.white,
                              child: Icon(
                                Icons.manage_accounts_outlined,
                                size: 22,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              account?.name ?? 'Administrador municipal',
                              style: const TextStyle(
                                color: AppColors.forest,
                                fontSize: 19,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            if (account != null &&
                                account.email.isNotEmpty) ...[
                              const SizedBox(height: 3),
                              Text(
                                account.email,
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      ListTile(
                        leading: const Icon(Icons.person_outline_rounded),
                        title: const Text('Datos de la cuenta'),
                        onTap: viewAccount == null
                            ? null
                            : () => choose(viewAccount),
                      ),
                      ListTile(
                        leading: const Icon(Icons.lock_outline_rounded),
                        title: const Text('Cambiar contraseña'),
                        onTap: changePassword == null
                            ? null
                            : () => choose(changePassword),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 20, 8, 8),
                    child: Column(
                      children: [
                        const Divider(indent: 8, endIndent: 8),
                        ListTile(
                          leading: const Icon(Icons.logout_rounded),
                          title: const Text('Cerrar sesión'),
                          iconColor: const Color(0xFFB91C1C),
                          textColor: const Color(0xFFB91C1C),
                          onTap: isSigningOut ? null : () => choose(onLogout),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
