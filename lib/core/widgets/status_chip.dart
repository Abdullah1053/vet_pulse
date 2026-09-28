import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

enum ChipStatusType {
  critical,
  warning,
  success,
  info,
  neutral,
}

class StatusChip extends StatelessWidget {
  final String label;
  final ChipStatusType type;
  final IconData? icon;
  final double fontSize;
  final VoidCallback? onTap;

  const StatusChip({
    super.key,
    required this.label,
    this.type = ChipStatusType.neutral,
    this.icon,
    this.fontSize = 11,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;

    switch (type) {
      case ChipStatusType.critical:
        bg = AppColors.criticalBackground;
        fg = AppColors.critical;
        break;
      case ChipStatusType.warning:
        bg = AppColors.warningBackground;
        fg = AppColors.warning;
        break;
      case ChipStatusType.success:
        bg = AppColors.successBackground;
        fg = AppColors.success;
        break;
      case ChipStatusType.info:
        bg = AppColors.infoBackground;
        fg = AppColors.info;
        break;
      case ChipStatusType.neutral:
        bg = AppColors.border.withValues(alpha: 0.5);
        fg = AppColors.textSecondary;
        break;
    }

    final content = Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: fg.withValues(alpha: 0.2), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: fontSize + 2, color: fg),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              color: fg,
            ),
          ),
        ],
      ),
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: content,
      );
    }
    return content;
  }
}
