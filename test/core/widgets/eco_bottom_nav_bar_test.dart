import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ecoroute/core/widgets/eco_bottom_nav_bar.dart';

void main() {
  testWidgets('EcoBottomNavBar renderiza pestañas y badge correctamente', (tester) async {
    int selectedIndex = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          bottomNavigationBar: EcoBottomNavBar(
            currentIndex: selectedIndex,
            items: [
              EcoBottomNavItem(
                label: 'Inicio',
                activeIcon: Icons.home,
                inactiveIcon: Icons.home_outlined,
                onTap: () => selectedIndex = 0,
              ),
              EcoBottomNavItem(
                label: 'Tareas',
                activeIcon: Icons.assignment,
                inactiveIcon: Icons.assignment_outlined,
                badgeCount: 3,
                onTap: () => selectedIndex = 1,
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.text('Inicio'), findsOneWidget);
    expect(find.text('Tareas'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);

    await tester.tap(find.text('Tareas'));
    expect(selectedIndex, 1);
  });
}

