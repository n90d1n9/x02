import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

import '../../models/sidebar_menu_item.dart';
import 'ribbon_command_button.dart';

/// Ribbon group for opening frequently used editor sidebar panels.
class ToolbarSidebarPanelsGroup extends StatelessWidget {
  final ValueChanged<SidebarMenuItem> onOpenPanel;
  final bool compact;

  const ToolbarSidebarPanelsGroup({
    super.key,
    required this.onOpenPanel,
    this.compact = false,
  });

  static const List<_SidebarPanelShortcut> _shortcuts = [
    _SidebarPanelShortcut(
      item: SidebarMenuItem.design,
      icon: Icons.auto_awesome,
      label: 'Design',
      tooltip: 'Open Design panel',
    ),
    _SidebarPanelShortcut(
      item: SidebarMenuItem.layers,
      icon: Icons.layers,
      label: 'Layers',
      tooltip: 'Open Layers panel',
    ),
    _SidebarPanelShortcut(
      item: SidebarMenuItem.arrange,
      icon: Icons.center_focus_strong,
      label: 'Arrange',
      tooltip: 'Open Arrange panel',
    ),
    _SidebarPanelShortcut(
      item: SidebarMenuItem.history,
      icon: Icons.history,
      label: 'History',
      tooltip: 'Open History panel',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final shortcut in _shortcuts)
          RibbonCommandButton(
            icon: shortcut.icon,
            label: shortcut.label,
            tooltip: shortcut.tooltip,
            compact: compact,
            onPressed: () => onOpenPanel(shortcut.item),
          ),
      ],
    );
  }
}

/// Static sidebar panel shortcut metadata used by the ribbon.
class _SidebarPanelShortcut {
  final SidebarMenuItem item;
  final IconData icon;
  final String label;
  final String tooltip;

  const _SidebarPanelShortcut({
    required this.item,
    required this.icon,
    required this.label,
    required this.tooltip,
  });
}

@Preview(name: 'Toolbar sidebar panels group', size: Size(320, 96))
Widget toolbarSidebarPanelsGroupPreview() {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    home: Scaffold(
      backgroundColor: const Color(0xFF1E293B),
      body: Center(child: ToolbarSidebarPanelsGroup(onOpenPanel: (_) {})),
    ),
  );
}
