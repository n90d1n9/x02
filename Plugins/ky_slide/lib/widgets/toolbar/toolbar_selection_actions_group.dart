import 'package:flutter/material.dart';

import '../../models/component_arrange_action.dart';
import 'arrange_menu_button.dart';
import 'ribbon_icon_button.dart';

/// Ribbon group for arranging or deleting the selected component.
class ToolbarSelectionActionsGroup extends StatelessWidget {
  final bool hasSelection;
  final ValueChanged<ComponentArrangeAction> onArrangeSelected;
  final VoidCallback onDeleteSelected;
  final bool compact;

  const ToolbarSelectionActionsGroup({
    super.key,
    required this.hasSelection,
    required this.onArrangeSelected,
    required this.onDeleteSelected,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ArrangeMenuButton(
          enabled: hasSelection,
          onSelected: onArrangeSelected,
          compact: compact,
        ),
        const VerticalDivider(),
        RibbonIconButton(
          icon: Icons.delete,
          tooltip: 'Delete (Del)',
          onPressed: hasSelection ? onDeleteSelected : null,
          compact: compact,
        ),
      ],
    );
  }
}
