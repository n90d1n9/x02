import 'package:flutter/material.dart';

import '../model/workbook_sheet.dart';
import '../theme/ky_sheet_theme.dart';
import 'sheet_tab_action_menu.dart';
import 'sheet_tab_inline_rename_field.dart';

/// Interactive workbook sheet tab with selection, rename, and sheet actions.
class SheetTab extends StatelessWidget {
  const SheetTab({
    super.key,
    required this.sheet,
    required this.active,
    required this.canMoveLeft,
    required this.canMoveRight,
    required this.canDelete,
    required this.canHide,
    this.renaming = false,
    required this.onSelected,
    required this.onRename,
    this.onRenameCommit,
    this.onRenameCancel,
    required this.onDuplicate,
    required this.onMoveLeft,
    required this.onMoveRight,
    required this.onColor,
    required this.onHide,
    required this.onDelete,
  });

  /// Workbook sheet represented by this tab.
  final WorkbookSheet sheet;

  /// Whether this tab is the active workbook sheet.
  final bool active;

  /// Whether the sheet can move one position toward the start.
  final bool canMoveLeft;

  /// Whether the sheet can move one position toward the end.
  final bool canMoveRight;

  /// Whether the sheet can be deleted from the workbook.
  final bool canDelete;

  /// Whether the sheet can be hidden from the tab strip.
  final bool canHide;

  /// Whether this tab is currently editing its sheet name inline.
  final bool renaming;

  /// Called when the tab is selected.
  final VoidCallback onSelected;

  /// Called when the tab rename affordance is invoked.
  final VoidCallback onRename;

  /// Called when an inline sheet rename is committed.
  final ValueChanged<String>? onRenameCommit;

  /// Called when an inline sheet rename is cancelled.
  final VoidCallback? onRenameCancel;

  /// Called when the sheet should be duplicated.
  final VoidCallback onDuplicate;

  /// Called when the sheet should move one position left.
  final VoidCallback onMoveLeft;

  /// Called when the sheet should move one position right.
  final VoidCallback onMoveRight;

  /// Called when the sheet tab color should be changed.
  final VoidCallback onColor;

  /// Called when the sheet should be hidden from visible navigation.
  final VoidCallback onHide;

  /// Called when the sheet should be deleted.
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final tabColor = sheet.tabColor;
    final baseBackground = active
        ? KySheetColors.accentSoft
        : KySheetColors.surfaceMuted;
    final backgroundColor = tabColor == null
        ? baseBackground
        : Color.alphaBlend(
            tabColor.withAlpha(active ? 34 : 22),
            baseBackground,
          );
    final borderColor = active
        ? tabColor ?? KySheetColors.accent
        : tabColor?.withAlpha(180) ?? KySheetColors.gridLineStrong;
    final tooltip = renaming
        ? 'Rename ${sheet.name}'
        : active
        ? '${sheet.name} active. Double tap to rename. Right-click for actions'
        : 'Switch to ${sheet.name}. Right-click for actions';
    final menuCallbacks = SheetTabActionMenuCallbacks(
      onRename: onRename,
      onDuplicate: onDuplicate,
      onMoveLeft: onMoveLeft,
      onMoveRight: onMoveRight,
      onColor: onColor,
      onHide: onHide,
      onDelete: onDelete,
    );

    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: Tooltip(
        message: tooltip,
        waitDuration: const Duration(milliseconds: 500),
        child: GestureDetector(
          onSecondaryTapDown: renaming
              ? null
              : (details) => showSheetTabActionContextMenu(
                  context: context,
                  globalPosition: details.globalPosition,
                  tabColor: tabColor,
                  canMoveLeft: canMoveLeft,
                  canMoveRight: canMoveRight,
                  canDelete: canDelete,
                  canHide: canHide,
                  callbacks: menuCallbacks,
                ),
          child: Material(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              height: 32,
              constraints: BoxConstraints(
                minWidth: renaming ? 136 : 104,
                maxWidth: renaming ? 220 : 180,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: borderColor),
              ),
              child: Stack(
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: renaming
                            ? Padding(
                                padding: const EdgeInsets.only(
                                  left: 6,
                                  right: 6,
                                ),
                                child: SheetTabInlineRenameField(
                                  sheetId: sheet.id,
                                  initialName: sheet.name,
                                  onCommit: onRenameCommit ?? (_) {},
                                  onCancel: onRenameCancel ?? () {},
                                ),
                              )
                            : InkWell(
                                onTap: onSelected,
                                onDoubleTap: onRename,
                                borderRadius: const BorderRadius.horizontal(
                                  left: Radius.circular(8),
                                ),
                                child: SizedBox(
                                  height: 32,
                                  child: Padding(
                                    padding: const EdgeInsets.only(
                                      left: 10,
                                      right: 4,
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.table_chart_outlined,
                                          size: 16,
                                          color: active
                                              ? KySheetColors.accent
                                              : KySheetColors.mutedText,
                                        ),
                                        const SizedBox(width: 7),
                                        Flexible(
                                          child: Text(
                                            sheet.name,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              color: active
                                                  ? KySheetColors.accent
                                                  : KySheetColors.text,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                      ),
                      if (!renaming)
                        SheetTabActionMenuButton(
                          sheetId: sheet.id,
                          tabColor: tabColor,
                          canMoveLeft: canMoveLeft,
                          canMoveRight: canMoveRight,
                          canDelete: canDelete,
                          canHide: canHide,
                          callbacks: menuCallbacks,
                        ),
                    ],
                  ),
                  if (tabColor != null)
                    Positioned(
                      left: 8,
                      right: renaming ? 8 : 34,
                      bottom: 2,
                      child: Container(
                        key: ValueKey(
                          'ky-sheet-tab-color-indicator-${sheet.id}',
                        ),
                        height: 3,
                        decoration: BoxDecoration(
                          color: tabColor,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
