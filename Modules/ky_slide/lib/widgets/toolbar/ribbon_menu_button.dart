import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

/// Generic popup menu trigger styled for compact ribbon command groups.
class RibbonMenuButton<T> extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final bool enabled;
  final bool compact;
  final ValueChanged<T> onSelected;
  final PopupMenuItemBuilder<T> itemBuilder;

  const RibbonMenuButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.enabled,
    required this.onSelected,
    required this.itemBuilder,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final side = compact ? 40.0 : 48.0;

    return Semantics(
      button: true,
      enabled: enabled,
      label: tooltip,
      child: PopupMenuButton<T>(
        enabled: enabled,
        tooltip: tooltip,
        color: const Color(0xFF1E293B),
        elevation: 12,
        offset: Offset(0, compact ? 36 : 42),
        padding: EdgeInsets.zero,
        onSelected: onSelected,
        itemBuilder: itemBuilder,
        icon: AnimatedContainer(
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
    );
  }
}

@Preview(name: 'Ribbon menu button', size: Size(160, 96))
Widget ribbonMenuButtonPreview() {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    home: Scaffold(
      backgroundColor: const Color(0xFF1E293B),
      body: Center(
        child: RibbonMenuButton<String>(
          icon: Icons.center_focus_strong,
          tooltip: 'Arrange selected',
          enabled: true,
          onSelected: (_) {},
          itemBuilder: (context) => const [
            PopupMenuItem(
              value: 'center',
              child: Text(
                'Center on slide',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
