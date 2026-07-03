import 'package:flutter/material.dart';

/// Renders a mode-aware icon toggle for document app-bar command clusters.
class DocumentToolbarToggleButton extends StatelessWidget {
  final bool active;
  final IconData activeIcon;
  final IconData inactiveIcon;
  final String tooltip;
  final VoidCallback? onPressed;

  const DocumentToolbarToggleButton({
    super.key,
    required this.active,
    required this.activeIcon,
    required this.inactiveIcon,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return IconButton(
      isSelected: active,
      selectedIcon: Icon(activeIcon),
      icon: Icon(inactiveIcon),
      tooltip: tooltip,
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          if (!active || states.contains(WidgetState.disabled)) return null;
          return colorScheme.primaryContainer.withValues(alpha: 0.78);
        }),
        foregroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return colorScheme.onSurface.withValues(alpha: 0.38);
          }
          if (active) return colorScheme.onPrimaryContainer;
          return colorScheme.onSurfaceVariant;
        }),
      ),
      onPressed: onPressed,
    );
  }
}
