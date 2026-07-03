import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

/// Reusable icon toggle for ribbon view and panel controls.
class RibbonToggleButton extends StatelessWidget {
  final IconData activeIcon;
  final IconData inactiveIcon;
  final String tooltip;
  final bool isActive;
  final VoidCallback? onPressed;
  final bool compact;
  final Color accentColor;

  const RibbonToggleButton({
    super.key,
    required this.activeIcon,
    required this.inactiveIcon,
    required this.tooltip,
    required this.isActive,
    required this.onPressed,
    this.compact = false,
    this.accentColor = const Color(0xFF6366F1),
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    final side = compact ? 40.0 : 48.0;
    final iconColor = enabled
        ? (isActive ? accentColor : Colors.white60)
        : Colors.white24;
    final borderColor = enabled
        ? (isActive
              ? accentColor.withValues(alpha: 0.42)
              : Colors.white.withValues(alpha: 0.08))
        : Colors.white.withValues(alpha: 0.05);
    final backgroundColor = enabled
        ? (isActive
              ? accentColor.withValues(alpha: 0.14)
              : Colors.white.withValues(alpha: 0.035))
        : Colors.white.withValues(alpha: 0.02);

    return Semantics(
      button: true,
      enabled: enabled,
      toggled: isActive,
      label: tooltip,
      child: Tooltip(
        message: tooltip,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 3),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            child: InkWell(
              onTap: onPressed,
              borderRadius: BorderRadius.circular(8),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 140),
                curve: Curves.easeOutCubic,
                width: side,
                height: side,
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: borderColor),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Icon(
                      isActive ? activeIcon : inactiveIcon,
                      color: iconColor,
                      size: compact ? 19 : 21,
                    ),
                    Positioned(
                      bottom: 6,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 140),
                        width: isActive ? 16 : 0,
                        height: 2,
                        decoration: BoxDecoration(
                          color: accentColor,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

@Preview(name: 'Ribbon toggle button', size: Size(120, 88))
Widget ribbonToggleButtonPreview() {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    home: Scaffold(
      backgroundColor: const Color(0xFF1E293B),
      body: Center(
        child: RibbonToggleButton(
          activeIcon: Icons.grid_on,
          inactiveIcon: Icons.grid_off,
          tooltip: 'Toggle Grid',
          isActive: true,
          onPressed: () {},
        ),
      ),
    ),
  );
}
