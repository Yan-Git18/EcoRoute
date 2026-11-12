import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ecoroute/core/widgets/profile/about_app_modal.dart';
import 'package:ecoroute/core/widgets/profile/eco_profile_menu_item.dart';
import 'package:ecoroute/core/widgets/profile/profile_change_password_modal.dart';
import 'package:ecoroute/core/widgets/profile/profile_data_modal.dart';
import 'package:ecoroute/core/widgets/profile/profile_logout_dialog.dart';
import 'package:ecoroute/core/widgets/profile/profile_notifications_modal.dart';

void main() {
  testWidgets('Renderiza ProfileDataModal correctamente y muestra datos', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => ProfileDataModal.show(
                context,
                name: 'Juan Pérez',
                email: 'juan@ecoroute.com',
                phone: '987654321',
                roleLabel: 'Ciudadano Eco',
              ),
              child: const Text('Abrir'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();

    expect(find.text('Mis datos personales'), findsOneWidget);
    expect(find.text('Juan Pérez'), findsOneWidget);
    expect(find.text('juan@ecoroute.com'), findsOneWidget);
    expect(find.text('987654321'), findsOneWidget);
    expect(find.text('Ciudadano Eco'), findsOneWidget);

    await tester.tap(find.text('Cerrar'));
    await tester.pumpAndSettle();
    expect(find.text('Mis datos personales'), findsNothing);
  });

  testWidgets('Renderiza AboutAppModal y lo cierra', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => AboutAppModal.show(context),
              child: const Text('Abrir'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();

    expect(find.text('Acerca de EcoRoute'), findsOneWidget);
    expect(find.text('EcoRoute'), findsOneWidget);
    expect(find.text('Versión 1.0.0 • Gestión Inteligente de Residuos'), findsOneWidget);

    await tester.tap(find.text('Entendido'));
    await tester.pumpAndSettle();
    expect(find.text('Acerca de EcoRoute'), findsNothing);
  });

  testWidgets('Renderiza ProfileChangePasswordModal correctamente', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: Consumer(
              builder: (context, ref, _) => ElevatedButton(
                onPressed: () => ProfileChangePasswordModal.show(
                  context,
                  ref,
                  email: 'test@ecoroute.com',
                ),
                child: const Text('Abrir'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();

    expect(find.text('Cambiar contraseña'), findsOneWidget);
    expect(find.text('test@ecoroute.com'), findsOneWidget);
    expect(find.text('Enviar enlace de restablecimiento'), findsOneWidget);

    await tester.tap(find.text('Enviar enlace de restablecimiento'));
    await tester.pumpAndSettle();
  });

  testWidgets('Renderiza ProfileNotificationsModal con opciones', (tester) async {
    bool toggled = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => ProfileNotificationsModal.show(
                context,
                options: [
                  NotificationOptionItem(
                    title: 'Alertas de recogida',
                    subtitle: 'Notificar cuando el camión esté cerca',
                    initialValue: true,
                    onChanged: (val) => toggled = val,
                  ),
                ],
              ),
              child: const Text('Abrir'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();

    expect(find.text('Preferencias de Notificaciones'), findsOneWidget);
    expect(find.text('Alertas de recogida'), findsOneWidget);

    await tester.tap(find.byType(SwitchListTile));
    await tester.pumpAndSettle();
    expect(toggled, isFalse);

    await tester.tap(find.text('Guardar preferencias'));
    await tester.pumpAndSettle();
  });

  testWidgets('Renderiza ProfileLogoutDialog y ejecuta confirmación', (tester) async {
    bool confirmed = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => ProfileLogoutDialog.show(
                context,
                onConfirm: () => confirmed = true,
              ),
              child: const Text('Abrir'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();

    expect(find.text('¿Cerrar sesión?'), findsOneWidget);
    expect(find.text('Cancelar'), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, 'Cerrar sesión'), findsOneWidget);

    await tester.tap(find.widgetWithText(ElevatedButton, 'Cerrar sesión'));
    await tester.pumpAndSettle();
    expect(confirmed, isTrue);
  });

  testWidgets('EcoProfileMenuItem renderiza y responde al tap', (tester) async {
    bool tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: EcoProfileMenuItem(
            icon: Icons.settings,
            title: 'Configuración',
            onTap: () => tapped = true,
          ),
        ),
      ),
    );

    expect(find.text('Configuración'), findsOneWidget);
    await tester.tap(find.text('Configuración'));
    expect(tapped, isTrue);
  });
}
