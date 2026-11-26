import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_names.dart';

class AdminBackButton extends StatelessWidget {
  const AdminBackButton({
    super.key,
    this.fallbackRoute = RouteNames.adminDashboard,
  });

  final String fallbackRoute;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF0F172A)),
      tooltip: MaterialLocalizations.of(context).backButtonTooltip,
      onPressed: () {
        final router = GoRouter.maybeOf(context);
        if (router == null) {
          Navigator.of(context).maybePop();
        } else if (router.canPop()) {
          router.pop();
        } else {
          router.go(fallbackRoute);
        }
      },
    );
  }
}
