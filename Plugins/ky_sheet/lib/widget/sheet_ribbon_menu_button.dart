import 'package:flutter/material.dart';

import 'tool_popup_button.dart';

class SheetRibbonMenuAction {
  const SheetRibbonMenuAction({required this.label, this.onSelected});

  final String label;
  final VoidCallback? onSelected;

  bool get enabled => onSelected != null;
}

class SheetRibbonMenuButton extends StatelessWidget {
  const SheetRibbonMenuButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.actions,
  });

  final IconData icon;
  final String tooltip;
  final List<SheetRibbonMenuAction> actions;

  @override
  Widget build(BuildContext context) {
    return ToolPopupButton<SheetRibbonMenuAction>(
      icon: icon,
      tooltip: tooltip,
      enabled: actions.any((action) => action.enabled),
      onSelected: (action) => action.onSelected?.call(),
      itemBuilder: (context) => [
        for (final action in actions)
          PopupMenuItem(
            value: action,
            enabled: action.enabled,
            child: Text(action.label),
          ),
      ],
    );
  }
}
