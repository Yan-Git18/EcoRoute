import 'package:flutter/material.dart';

class AdminFilterCarousel extends StatelessWidget {
  const AdminFilterCarousel({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(spacing: 8, children: children),
    );
  }
}
