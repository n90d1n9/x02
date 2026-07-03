import 'package:flutter/material.dart';

import 'sidebar_action_card.dart';

class SidebarCommandButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isEnabled;
  final VoidCallback onPressed;
  final Color accentColor;
  final double height;
  final double iconSize;
  final double fontSize;

  const SidebarCommandButton({
    super.key,
    required this.icon,
    required this.label,
    required this.isEnabled,
    required this.onPressed,
    this.accentColor = Colors.white,
    this.height = 38,
    this.iconSize = 16,
    this.fontSize = 11,
  });

  @override
  Widget build(BuildContext context) {
    final color = isEnabled ? Colors.white : Colors.white38;

    return SidebarActionCard(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      accentColor: accentColor,
      onPressed: isEnabled ? onPressed : null,
      semanticsLabel: label,
      backgroundColor: isEnabled
          ? Colors.white.withValues(alpha: 0.08)
          : Colors.white.withValues(alpha: 0.035),
      borderColor: Colors.white.withValues(alpha: 0.08),
      child: SizedBox(
        height: height,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: iconSize, color: color),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: color,
                  fontSize: fontSize,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
