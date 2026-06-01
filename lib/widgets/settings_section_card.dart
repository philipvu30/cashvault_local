import 'package:flutter/material.dart';

import 'app_card.dart';

class SettingsSectionCard extends StatelessWidget {
  const SettingsSectionCard({
    super.key,
    required this.title,
    this.subtitle,
    required this.child,
  });

  final String title;
  final String? subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      title: title,
      subtitle: subtitle,
      child: child,
    );
  }
}
