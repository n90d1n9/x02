import 'package:flutter/material.dart';

import '../../models/component_arrange_action.dart';
import 'ribbon_menu_button.dart';

/// Popup command for aligning selected slide components.
class ArrangeMenuButton extends StatelessWidget {
  final bool enabled;
  final ValueChanged<ComponentArrangeAction> onSelected;
  final bool compact;

  const ArrangeMenuButton({
    super.key,
    required this.enabled,
    required this.onSelected,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return RibbonMenuButton<ComponentArrangeAction>(
      icon: Icons.center_focus_strong,
      enabled: enabled,
      tooltip: enabled ? 'Arrange selected' : 'Select a component to arrange',
      compact: compact,
      onSelected: onSelected,
      itemBuilder: (context) => [
        _item(
          ComponentArrangeAction.centerOnSlide,
          Icons.center_focus_strong,
          'Center on slide',
        ),
        _item(
          ComponentArrangeAction.alignHorizontalCenter,
          Icons.format_align_center,
          'Center horizontally',
        ),
        _item(
          ComponentArrangeAction.alignVerticalCenter,
          Icons.vertical_align_center,
          'Center vertically',
        ),
        const PopupMenuDivider(),
        _item(
          ComponentArrangeAction.alignLeft,
          Icons.format_align_left,
          'Left',
        ),
        _item(
          ComponentArrangeAction.alignRight,
          Icons.format_align_right,
          'Right',
        ),
        _item(ComponentArrangeAction.alignTop, Icons.vertical_align_top, 'Top'),
        _item(
          ComponentArrangeAction.alignBottom,
          Icons.vertical_align_bottom,
          'Bottom',
        ),
        const PopupMenuDivider(),
        _item(
          ComponentArrangeAction.rotateLeft,
          Icons.rotate_left,
          'Rotate left 90',
        ),
        _item(
          ComponentArrangeAction.rotateRight,
          Icons.rotate_right,
          'Rotate right 90',
        ),
        const PopupMenuDivider(),
        _item(ComponentArrangeAction.snapToGrid, Icons.grid_on, 'Snap to grid'),
      ],
    );
  }

  PopupMenuEntry<ComponentArrangeAction> _item(
    ComponentArrangeAction action,
    IconData icon,
    String label,
  ) {
    return PopupMenuItem(
      value: action,
      child: Row(
        children: [
          Icon(icon, color: Colors.white70, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
