import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

import '../../models/component_arrange_action.dart';

/// Compact arrange menu for aligning the selected object from the canvas.
class SelectionContextArrangeMenu extends StatelessWidget {
  final Color accentColor;
  final bool enabled;
  final ValueChanged<ComponentArrangeAction> onSelected;

  const SelectionContextArrangeMenu({
    super.key,
    required this.accentColor,
    required this.enabled,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final color = enabled ? accentColor : Colors.white24;

    return PopupMenuButton<ComponentArrangeAction>(
      tooltip: enabled ? 'Align selected object' : 'Unlock object to align',
      enabled: enabled,
      color: const Color(0xFF111827),
      elevation: 10,
      offset: const Offset(0, 34),
      onSelected: onSelected,
      itemBuilder: (context) => const [
        PopupMenuItem(
          value: ComponentArrangeAction.centerOnSlide,
          child: _SelectionContextArrangeItem(
            icon: Icons.center_focus_strong,
            label: 'Center on slide',
          ),
        ),
        PopupMenuDivider(height: 8),
        PopupMenuItem(
          value: ComponentArrangeAction.alignHorizontalCenter,
          child: _SelectionContextArrangeItem(
            icon: Icons.format_align_center,
            label: 'Center horizontally',
          ),
        ),
        PopupMenuItem(
          value: ComponentArrangeAction.alignVerticalCenter,
          child: _SelectionContextArrangeItem(
            icon: Icons.vertical_align_center,
            label: 'Center vertically',
          ),
        ),
        PopupMenuDivider(height: 8),
        PopupMenuItem(
          value: ComponentArrangeAction.alignLeft,
          child: _SelectionContextArrangeItem(
            icon: Icons.format_align_left,
            label: 'Align left',
          ),
        ),
        PopupMenuItem(
          value: ComponentArrangeAction.alignRight,
          child: _SelectionContextArrangeItem(
            icon: Icons.format_align_right,
            label: 'Align right',
          ),
        ),
        PopupMenuItem(
          value: ComponentArrangeAction.alignTop,
          child: _SelectionContextArrangeItem(
            icon: Icons.vertical_align_top,
            label: 'Align top',
          ),
        ),
        PopupMenuItem(
          value: ComponentArrangeAction.alignBottom,
          child: _SelectionContextArrangeItem(
            icon: Icons.vertical_align_bottom,
            label: 'Align bottom',
          ),
        ),
        PopupMenuDivider(height: 8),
        PopupMenuItem(
          value: ComponentArrangeAction.rotateLeft,
          child: _SelectionContextArrangeItem(
            icon: Icons.rotate_left,
            label: 'Rotate left 90',
          ),
        ),
        PopupMenuItem(
          value: ComponentArrangeAction.rotateRight,
          child: _SelectionContextArrangeItem(
            icon: Icons.rotate_right,
            label: 'Rotate right 90',
          ),
        ),
        PopupMenuDivider(height: 8),
        PopupMenuItem(
          value: ComponentArrangeAction.snapToGrid,
          child: _SelectionContextArrangeItem(
            icon: Icons.grid_on,
            label: 'Snap to grid',
          ),
        ),
      ],
      child: SizedBox(
        width: 30,
        height: 30,
        child: Icon(Icons.align_horizontal_center, size: 17, color: color),
      ),
    );
  }
}

/// Icon and label row used by the selected-object arrange popup.
class _SelectionContextArrangeItem extends StatelessWidget {
  final IconData icon;
  final String label;

  const _SelectionContextArrangeItem({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 17, color: Colors.white70),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 0,
            ),
          ),
        ),
      ],
    );
  }
}

@Preview(name: 'Selection context arrange menu', size: Size(180, 96))
Widget selectionContextArrangeMenuPreview() {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    home: Scaffold(
      backgroundColor: const Color(0xFF101114),
      body: Center(
        child: SelectionContextArrangeMenu(
          accentColor: const Color(0xFF38BDF8),
          enabled: true,
          onSelected: (_) {},
        ),
      ),
    ),
  );
}
