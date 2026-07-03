import 'package:flutter/material.dart';

import '../../models/sidebar_menu_item.dart';

class SidebarMenu extends StatelessWidget {
  final SidebarMenuItem selectedItem;
  final ValueChanged<SidebarMenuItem> onSelected;
  final Color accentColor;

  const SidebarMenu({
    super.key,
    required this.selectedItem,
    required this.onSelected,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: SidebarMenuItem.values.map((item) {
          return Expanded(
            child: _SidebarMenuButton(
              item: item,
              isSelected: item == selectedItem,
              accentColor: accentColor,
              onPressed: () => onSelected(item),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _SidebarMenuButton extends StatelessWidget {
  final SidebarMenuItem item;
  final bool isSelected;
  final Color accentColor;
  final VoidCallback onPressed;

  const _SidebarMenuButton({
    required this.item,
    required this.isSelected,
    required this.accentColor,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: item.tooltip,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(7),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(7),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 4),
            decoration: BoxDecoration(
              color: isSelected
                  ? accentColor.withValues(alpha: 0.18)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(7),
              border: Border.all(
                color: isSelected
                    ? accentColor.withValues(alpha: 0.42)
                    : Colors.transparent,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  item.icon,
                  size: 17,
                  color: isSelected ? Colors.white : Colors.white60,
                ),
                const SizedBox(height: 4),
                Text(
                  item.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.white60,
                    fontSize: 10,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

extension _SidebarMenuItemView on SidebarMenuItem {
  String get label {
    switch (this) {
      case SidebarMenuItem.slides:
        return 'Slides';
      case SidebarMenuItem.design:
        return 'Design';
      case SidebarMenuItem.outline:
        return 'Outline';
      case SidebarMenuItem.layers:
        return 'Layers';
      case SidebarMenuItem.arrange:
        return 'Arrange';
      case SidebarMenuItem.history:
        return 'History';
      case SidebarMenuItem.files:
        return 'File';
    }
  }

  String get tooltip {
    switch (this) {
      case SidebarMenuItem.slides:
        return 'Slides and slide actions';
      case SidebarMenuItem.design:
        return 'Design Assist templates';
      case SidebarMenuItem.outline:
        return 'Presentation outline';
      case SidebarMenuItem.layers:
        return 'Object layers';
      case SidebarMenuItem.arrange:
        return 'Align, rotate, and layer order';
      case SidebarMenuItem.history:
        return 'Undo and redo history';
      case SidebarMenuItem.files:
        return 'Import and export presentations';
    }
  }

  IconData get icon {
    switch (this) {
      case SidebarMenuItem.slides:
        return Icons.view_carousel_outlined;
      case SidebarMenuItem.design:
        return Icons.auto_awesome;
      case SidebarMenuItem.outline:
        return Icons.format_list_bulleted;
      case SidebarMenuItem.layers:
        return Icons.layers_outlined;
      case SidebarMenuItem.arrange:
        return Icons.center_focus_strong;
      case SidebarMenuItem.history:
        return Icons.history;
      case SidebarMenuItem.files:
        return Icons.folder_open_outlined;
    }
  }
}
