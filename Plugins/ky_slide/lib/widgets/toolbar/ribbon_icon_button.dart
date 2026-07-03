import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

/// Reusable icon-only command button for compact ribbon actions.
class RibbonIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final bool compact;

  const RibbonIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    final side = compact ? 40.0 : 48.0;

    return Semantics(
      button: true,
      enabled: enabled,
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
                  color: enabled
                      ? Colors.white.withValues(alpha: 0.045)
                      : Colors.white.withValues(alpha: 0.02),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: enabled
                        ? Colors.white.withValues(alpha: 0.09)
                        : Colors.white.withValues(alpha: 0.05),
                  ),
                ),
                child: Icon(
                  icon,
                  color: enabled ? Colors.white60 : Colors.white24,
                  size: compact ? 19 : 21,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

@Preview(name: 'Ribbon icon button', size: Size(120, 88))
Widget ribbonIconButtonPreview() {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    home: Scaffold(
      backgroundColor: const Color(0xFF1E293B),
      body: Center(
        child: RibbonIconButton(
          icon: Icons.add_to_photos_outlined,
          tooltip: 'New Slide',
          onPressed: () {},
        ),
      ),
    ),
  );
}
