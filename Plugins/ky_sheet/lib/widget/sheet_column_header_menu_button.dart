import 'package:flutter/material.dart';

import '../theme/ky_sheet_theme.dart';

enum SheetColumnHeaderAction {
  sortAscending,
  sortDescending,
  filter,
  clearFilter,
  openSidebar,
  insertLeft,
  insertRight,
  deleteColumn,
  hideColumn,
  unhideAdjacentColumns,
  autoFitColumn,
}

enum SheetRowHeaderAction {
  insertAbove,
  insertBelow,
  deleteRow,
  hideRow,
  unhideAdjacentRows,
  autoFitRow,
}

class SheetColumnHeaderMenuButton extends StatelessWidget {
  const SheetColumnHeaderMenuButton({
    super.key,
    required this.hasFilter,
    required this.isSorted,
    required this.sortAscending,
    required this.onSelected,
    this.canUnhideAdjacent = false,
    this.filterDescription,
  });

  final bool hasFilter;
  final bool isSorted;
  final bool sortAscending;
  final ValueChanged<SheetColumnHeaderAction> onSelected;
  final bool canUnhideAdjacent;
  final String? filterDescription;

  @override
  Widget build(BuildContext context) {
    final active = hasFilter || isSorted;
    final tooltip = _tooltipText();
    final icon = hasFilter
        ? Icons.filter_alt
        : (isSorted
              ? (sortAscending ? Icons.arrow_upward : Icons.arrow_downward)
              : Icons.more_horiz);

    return PopupMenuButton<SheetColumnHeaderAction>(
      tooltip: tooltip,
      onSelected: onSelected,
      offset: const Offset(0, 30),
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: SheetColumnHeaderAction.insertLeft,
          child: _HeaderMenuItem(
            icon: Icons.add_box_outlined,
            label: 'Insert column left',
          ),
        ),
        const PopupMenuItem(
          value: SheetColumnHeaderAction.insertRight,
          child: _HeaderMenuItem(
            icon: Icons.add_box,
            label: 'Insert column right',
          ),
        ),
        const PopupMenuItem(
          value: SheetColumnHeaderAction.deleteColumn,
          child: _HeaderMenuItem(
            icon: Icons.delete_outline,
            label: 'Delete column',
          ),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem(
          value: SheetColumnHeaderAction.hideColumn,
          child: _HeaderMenuItem(
            icon: Icons.visibility_off_outlined,
            label: 'Hide column',
          ),
        ),
        PopupMenuItem(
          value: SheetColumnHeaderAction.unhideAdjacentColumns,
          enabled: canUnhideAdjacent,
          child: const _HeaderMenuItem(
            icon: Icons.visibility_outlined,
            label: 'Unhide adjacent columns',
          ),
        ),
        const PopupMenuItem(
          value: SheetColumnHeaderAction.autoFitColumn,
          child: _HeaderMenuItem(
            icon: Icons.fit_screen,
            label: 'Auto-fit column',
          ),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem(
          value: SheetColumnHeaderAction.sortAscending,
          child: _HeaderMenuItem(icon: Icons.arrow_upward, label: 'Sort A-Z'),
        ),
        const PopupMenuItem(
          value: SheetColumnHeaderAction.sortDescending,
          child: _HeaderMenuItem(icon: Icons.arrow_downward, label: 'Sort Z-A'),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem(
          value: SheetColumnHeaderAction.filter,
          child: _HeaderMenuItem(
            icon: Icons.filter_alt_outlined,
            label: 'Sort & filter',
          ),
        ),
        PopupMenuItem(
          value: SheetColumnHeaderAction.clearFilter,
          enabled: hasFilter,
          child: const _HeaderMenuItem(
            icon: Icons.filter_alt_off,
            label: 'Clear filter',
          ),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem(
          value: SheetColumnHeaderAction.openSidebar,
          child: _HeaderMenuItem(icon: Icons.tune, label: 'Open Sort & Filter'),
        ),
      ],
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          width: 24,
          height: 24,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: active ? KySheetColors.accent : KySheetColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: active
                  ? KySheetColors.accent
                  : KySheetColors.gridLineStrong,
            ),
          ),
          child: Icon(
            icon,
            size: 14,
            color: active ? Colors.white : KySheetColors.mutedText,
          ),
        ),
      ),
    );
  }

  String _tooltipText() {
    final details = <String>[];
    if (isSorted) {
      details.add(sortAscending ? 'Sorted A-Z' : 'Sorted Z-A');
    }
    if (hasFilter) {
      final description = filterDescription?.trim();
      details.add(
        description == null || description.isEmpty
            ? 'Filtered'
            : 'Filter: $description',
      );
    }

    if (details.isEmpty) return 'Column Menu';
    return details.join('\n');
  }
}

class SheetRowHeaderMenuButton extends StatelessWidget {
  const SheetRowHeaderMenuButton({
    super.key,
    required this.onSelected,
    this.canUnhideAdjacent = false,
  });

  final ValueChanged<SheetRowHeaderAction> onSelected;
  final bool canUnhideAdjacent;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<SheetRowHeaderAction>(
      tooltip: 'Row Menu',
      onSelected: onSelected,
      offset: const Offset(0, 30),
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: SheetRowHeaderAction.insertAbove,
          child: _HeaderMenuItem(
            icon: Icons.add_box_outlined,
            label: 'Insert row above',
          ),
        ),
        const PopupMenuItem(
          value: SheetRowHeaderAction.insertBelow,
          child: _HeaderMenuItem(
            icon: Icons.add_box,
            label: 'Insert row below',
          ),
        ),
        const PopupMenuItem(
          value: SheetRowHeaderAction.deleteRow,
          child: _HeaderMenuItem(
            icon: Icons.delete_outline,
            label: 'Delete row',
          ),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem(
          value: SheetRowHeaderAction.hideRow,
          child: _HeaderMenuItem(
            icon: Icons.visibility_off_outlined,
            label: 'Hide row',
          ),
        ),
        PopupMenuItem(
          value: SheetRowHeaderAction.unhideAdjacentRows,
          enabled: canUnhideAdjacent,
          child: const _HeaderMenuItem(
            icon: Icons.visibility_outlined,
            label: 'Unhide adjacent rows',
          ),
        ),
        const PopupMenuItem(
          value: SheetRowHeaderAction.autoFitRow,
          child: _HeaderMenuItem(icon: Icons.fit_screen, label: 'Auto-fit row'),
        ),
      ],
      child: Tooltip(
        message: 'Row Menu',
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: Container(
            width: 24,
            height: 24,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: KySheetColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: KySheetColors.gridLineStrong),
            ),
            child: const Icon(
              Icons.more_horiz,
              size: 14,
              color: KySheetColors.mutedText,
            ),
          ),
        ),
      ),
    );
  }
}

class _HeaderMenuItem extends StatelessWidget {
  const _HeaderMenuItem({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18),
        const SizedBox(width: 10),
        Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
      ],
    );
  }
}
