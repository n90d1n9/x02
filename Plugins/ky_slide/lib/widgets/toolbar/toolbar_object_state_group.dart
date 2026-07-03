import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

import 'ribbon_icon_button.dart';
import 'ribbon_toggle_button.dart';

/// Contextual ribbon group for selected-object visibility, lock, and inspector.
class ToolbarObjectStateGroup extends StatelessWidget {
  final bool isVisible;
  final bool isLocked;
  final VoidCallback onToggleVisibility;
  final VoidCallback onToggleLocked;
  final VoidCallback onOpenInspector;
  final bool compact;
  final Color accentColor;

  const ToolbarObjectStateGroup({
    super.key,
    required this.isVisible,
    required this.isLocked,
    required this.onToggleVisibility,
    required this.onToggleLocked,
    required this.onOpenInspector,
    this.compact = false,
    this.accentColor = const Color(0xFF38BDF8),
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        RibbonToggleButton(
          activeIcon: Icons.visibility_outlined,
          inactiveIcon: Icons.visibility_off_outlined,
          tooltip: isVisible ? 'Hide Object' : 'Show Object',
          isActive: isVisible,
          onPressed: onToggleVisibility,
          compact: compact,
          accentColor: accentColor,
        ),
        RibbonToggleButton(
          activeIcon: Icons.lock_outline,
          inactiveIcon: Icons.lock_open_outlined,
          tooltip: isLocked ? 'Unlock Object' : 'Lock Object',
          isActive: isLocked,
          onPressed: onToggleLocked,
          compact: compact,
          accentColor: accentColor,
        ),
        RibbonIconButton(
          icon: Icons.tune_outlined,
          tooltip: 'Open Inspector',
          onPressed: onOpenInspector,
          compact: compact,
        ),
      ],
    );
  }
}

@Preview(name: 'Toolbar object state group', size: Size(190, 88))
Widget toolbarObjectStateGroupPreview() {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    home: Scaffold(
      backgroundColor: const Color(0xFF1E293B),
      body: Center(
        child: ToolbarObjectStateGroup(
          isVisible: true,
          isLocked: false,
          onToggleVisibility: () {},
          onToggleLocked: () {},
          onOpenInspector: () {},
        ),
      ),
    ),
  );
}
