import 'package:flutter/material.dart';

import '../design/app_colors.dart';

// Chip de estado con fondo suave, ícono opcional y texto (nunca solo color).
class StatusChip extends StatelessWidget {
  final String text;
  final Color color;
  final Color container;
  final IconData? icon;

  const StatusChip(
    this.text, {
    super.key,
    this.color = AppColors.success,
    this.container = AppColors.successContainer,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: container, borderRadius: BorderRadius.circular(999)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, size: 14, color: color), const SizedBox(width: 4)],
          Text(text, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }
}
