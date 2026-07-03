import 'package:flutter/material.dart';

import '../model/sheet_cell_context_menu_state.dart';
import '../model/sheet_shortcut.dart';
import '../theme/ky_sheet_theme.dart';
import 'sheet_menu_section_label.dart';
import 'sheet_shortcut_hint.dart';

/// Actions exposed by the spreadsheet cell context menu.
enum SheetCellContextAction {
  edit,
  copy,
  cut,
  paste,
  clearContents,
  clearFormatting,
  insertRowAbove,
  insertRowBelow,
  insertColumnLeft,
  insertColumnRight,
  deleteRow,
  deleteColumn,
  sortAscending,
  sortDescending,
  keepOnlyValue,
  excludeValue,
  clearColumnFilter,
  findThisValue,
  openSortFilter,
  openInspector,
  openDataValidation,
  freezePanesHere,
  unfreezePanes,
  openChartBuilder,
  openConditionalFormat,
}

/// Builds the shared right-click menu entries for spreadsheet cells.
class SheetCellContextMenu {
  const SheetCellContextMenu._();

  static const double _itemHeight = 32;
  static const double _sectionHeight = 28;

  static List<PopupMenuEntry<SheetCellContextAction>> items({
    SheetCellContextMenuState state = const SheetCellContextMenuState(),
  }) {
    return [
      _section('Cell'),
      _item(
        value: SheetCellContextAction.edit,
        icon: Icons.edit,
        label: 'Edit cell',
        shortcut: SheetShortcutLabels.editCell,
      ),
      _item(
        value: SheetCellContextAction.openInspector,
        icon: Icons.info_outline,
        label: 'Inspect Cell',
      ),
      _item(
        value: SheetCellContextAction.freezePanesHere,
        enabled: state.canFreezePanesHere,
        icon: Icons.my_location,
        label: 'Freeze Panes Here',
        detail: state.canFreezePanesHere ? null : 'Top-left cell selected',
      ),
      _item(
        value: SheetCellContextAction.unfreezePanes,
        enabled: state.hasFreezePane,
        icon: Icons.lock_open,
        label: 'Unfreeze Panes',
        detail: state.hasFreezePane ? null : 'No frozen panes',
      ),
      const PopupMenuDivider(),
      _section('Sort & Find'),
      _item(
        value: SheetCellContextAction.sortAscending,
        icon: Icons.arrow_upward,
        label: 'Sort A to Z',
      ),
      _item(
        value: SheetCellContextAction.sortDescending,
        icon: Icons.arrow_downward,
        label: 'Sort Z to A',
      ),
      _item(
        value: SheetCellContextAction.openSortFilter,
        icon: Icons.tune,
        label: 'Open Sort & Filter',
      ),
      _item(
        value: SheetCellContextAction.findThisValue,
        enabled: state.canFindThisValue,
        icon: Icons.search,
        label: 'Find This Value',
        detail: state.canFindThisValue ? null : 'Empty cell',
        shortcut: SheetShortcutLabels.findReplace,
      ),
      const PopupMenuDivider(),
      _section('Filter'),
      _item(
        value: SheetCellContextAction.keepOnlyValue,
        icon: Icons.filter_alt,
        label: 'Keep Only This Value',
      ),
      _item(
        value: SheetCellContextAction.excludeValue,
        icon: Icons.filter_alt_off_outlined,
        label: 'Exclude This Value',
      ),
      _item(
        value: SheetCellContextAction.clearColumnFilter,
        enabled: state.hasColumnFilter,
        icon: Icons.filter_alt_off,
        label: 'Clear Column Filter',
        detail: state.columnFilterDetail,
      ),
      const PopupMenuDivider(),
      _section('Analyze'),
      _item(
        value: SheetCellContextAction.openDataValidation,
        icon: Icons.rule,
        label: 'Data Validation',
      ),
      _item(
        value: SheetCellContextAction.openChartBuilder,
        icon: Icons.insert_chart_outlined,
        label: 'Chart Builder',
      ),
      _item(
        value: SheetCellContextAction.openConditionalFormat,
        icon: Icons.format_color_fill,
        label: 'Conditional Formatting',
      ),
      const PopupMenuDivider(),
      _section('Clipboard'),
      _item(
        value: SheetCellContextAction.copy,
        icon: Icons.content_copy,
        label: 'Copy',
        shortcut: SheetShortcutLabels.copy,
      ),
      _item(
        value: SheetCellContextAction.cut,
        icon: Icons.content_cut,
        label: 'Cut',
        shortcut: SheetShortcutLabels.cut,
      ),
      _item(
        value: SheetCellContextAction.paste,
        icon: Icons.content_paste,
        label: 'Paste',
        shortcut: SheetShortcutLabels.paste,
      ),
      const PopupMenuDivider(),
      _section('Clear'),
      _item(
        value: SheetCellContextAction.clearContents,
        icon: Icons.backspace_outlined,
        label: 'Clear',
        shortcut: SheetShortcutLabels.clearSelection,
      ),
      _item(
        value: SheetCellContextAction.clearFormatting,
        icon: Icons.format_clear,
        label: 'Clear formatting',
      ),
      const PopupMenuDivider(),
      _section('Insert'),
      _item(
        value: SheetCellContextAction.insertRowAbove,
        icon: Icons.vertical_align_top,
        label: 'Insert row above',
      ),
      _item(
        value: SheetCellContextAction.insertRowBelow,
        icon: Icons.vertical_align_bottom,
        label: 'Insert row below',
      ),
      _item(
        value: SheetCellContextAction.insertColumnLeft,
        icon: Icons.align_horizontal_left,
        label: 'Insert column left',
      ),
      _item(
        value: SheetCellContextAction.insertColumnRight,
        icon: Icons.align_horizontal_right,
        label: 'Insert column right',
      ),
      const PopupMenuDivider(),
      _section('Delete'),
      _item(
        value: SheetCellContextAction.deleteRow,
        icon: Icons.table_rows,
        label: 'Delete row',
        destructive: true,
      ),
      _item(
        value: SheetCellContextAction.deleteColumn,
        icon: Icons.view_column_outlined,
        label: 'Delete column',
        destructive: true,
      ),
    ];
  }

  static PopupMenuItem<SheetCellContextAction> _section(String label) {
    return PopupMenuItem(
      enabled: false,
      height: _sectionHeight,
      child: SheetMenuSectionLabel(
        key: ValueKey('ky-sheet-cell-context-section-$label'),
        label: label,
      ),
    );
  }

  static PopupMenuItem<SheetCellContextAction> _item({
    required SheetCellContextAction value,
    required IconData icon,
    required String label,
    String? detail,
    String? shortcut,
    bool enabled = true,
    bool destructive = false,
  }) {
    return PopupMenuItem(
      value: value,
      enabled: enabled,
      height: _itemHeight,
      child: _ContextMenuItem(
        icon: icon,
        label: label,
        detail: detail,
        shortcut: shortcut,
        destructive: destructive,
      ),
    );
  }
}

/// Compact icon and label row used by cell context menu entries.
class _ContextMenuItem extends StatelessWidget {
  const _ContextMenuItem({
    required this.icon,
    required this.label,
    this.detail,
    this.shortcut,
    this.destructive = false,
  });

  final IconData icon;
  final String label;
  final String? detail;
  final String? shortcut;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final detailText = detail?.trim();
    final hasDetail = detailText != null && detailText.isNotEmpty;
    final shortcutText = shortcut?.trim();
    final hasShortcut = shortcutText != null && shortcutText.isNotEmpty;
    final actionColor = destructive ? KySheetColors.validationError : null;

    return Row(
      crossAxisAlignment: hasDetail
          ? CrossAxisAlignment.start
          : CrossAxisAlignment.center,
      children: [
        Padding(
          padding: EdgeInsets.only(top: hasDetail ? 2 : 0),
          child: Icon(icon, size: 16, color: actionColor),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: actionColor),
                    ),
                  ),
                  if (hasShortcut) ...[
                    const SizedBox(width: 8),
                    SheetShortcutHint(label: shortcutText),
                  ],
                ],
              ),
              if (hasDetail) ...[
                const SizedBox(height: 2),
                Text(
                  detailText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
