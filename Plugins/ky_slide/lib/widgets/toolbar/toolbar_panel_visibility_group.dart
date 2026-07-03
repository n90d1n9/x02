import 'package:flutter/material.dart';

import 'ribbon_toggle_button.dart';

/// View ribbon group for showing and hiding editor side panels.
class ToolbarPanelVisibilityGroup extends StatelessWidget {
  final bool showSlideNavigator;
  final bool showInspector;
  final VoidCallback onToggleSlideNavigator;
  final VoidCallback onToggleInspector;
  final bool compact;

  const ToolbarPanelVisibilityGroup({
    super.key,
    required this.showSlideNavigator,
    required this.showInspector,
    required this.onToggleSlideNavigator,
    required this.onToggleInspector,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        RibbonToggleButton(
          activeIcon: Icons.view_sidebar_outlined,
          inactiveIcon: Icons.view_sidebar,
          tooltip: 'Toggle Slide Navigator',
          isActive: showSlideNavigator,
          onPressed: onToggleSlideNavigator,
          compact: compact,
        ),
        RibbonToggleButton(
          activeIcon: Icons.tune_outlined,
          inactiveIcon: Icons.space_dashboard_outlined,
          tooltip: 'Toggle Inspector',
          isActive: showInspector,
          onPressed: onToggleInspector,
          compact: compact,
        ),
      ],
    );
  }
}
