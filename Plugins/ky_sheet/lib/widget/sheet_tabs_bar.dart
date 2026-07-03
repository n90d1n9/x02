import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../model/workbook_sheet.dart';
import '../state/sheet_recent_sheet_provider.dart';
import '../state/workbook_provider.dart';
import '../theme/ky_sheet_theme.dart';
import 'sheet_delete_sheet_dialog.dart';
import 'sheet_tab.dart';
import 'sheet_tab_color_dialog.dart';
import 'sheet_tab_reorder_target.dart';
import 'sheet_tabs_navigator_button.dart';
import 'sheet_tabs_overflow_scroller.dart';

/// Bottom workbook tab strip for switching, adding, and managing sheets.
class SheetTabsBar extends ConsumerStatefulWidget {
  const SheetTabsBar({super.key});

  @override
  ConsumerState<SheetTabsBar> createState() => _SheetTabsBarState();
}

/// Coordinates workbook tab state, actions, and active-tab visibility.
class _SheetTabsBarState extends ConsumerState<SheetTabsBar> {
  final _scrollController = ScrollController();
  final Map<String, GlobalKey> _tabVisibilityKeys = {};
  String? _lastActiveSheetId;
  String? _renamingSheetId;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final workbook = ref.watch(workbookProvider);
    final recentSheetIds = ref.watch(recentWorkbookSheetIdsProvider);
    final controller = ref.read(workbookProvider.notifier);
    final visibleSheets = workbook.visibleSheets;
    _syncTabVisibilityKeys(visibleSheets);
    _scheduleActiveTabVisibility(workbook.activeSheetId);

    return Container(
      height: 44,
      decoration: const BoxDecoration(
        color: KySheetColors.surface,
        border: Border(
          top: BorderSide(color: KySheetColors.gridLine),
          bottom: BorderSide(color: KySheetColors.gridLine),
        ),
      ),
      child: Row(
        children: [
          const SizedBox(width: 10),
          SheetTabsNavigatorButton(
            sheets: workbook.sheets,
            activeSheetId: workbook.activeSheetId,
            recentSheetIds: recentSheetIds,
            onSelected: controller.switchToSheet,
            onUnhide: (sheetId) =>
                controller.unhideSheet(sheetId, makeActive: true),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: SheetTabsOverflowScroller(
              controller: _scrollController,
              child: Row(
                children: [
                  for (final sheet in visibleSheets)
                    KeyedSubtree(
                      key: ValueKey('ky-sheet-tab-${sheet.id}'),
                      child: SheetTabReorderTarget(
                        sheet: sheet,
                        active: sheet.id == workbook.activeSheetId,
                        enabled:
                            visibleSheets.length > 1 &&
                            _renamingSheetId == null,
                        onDropped: (draggedSheetId, edge) =>
                            controller.moveSheetToVisibleIndex(
                              draggedSheetId,
                              _visibleIndexForDrop(
                                visibleSheets: visibleSheets,
                                draggedSheetId: draggedSheetId,
                                targetSheet: sheet,
                                edge: edge,
                              ),
                            ),
                        child: KeyedSubtree(
                          key: _tabVisibilityKeys[sheet.id],
                          child: SheetTab(
                            sheet: sheet,
                            active: sheet.id == workbook.activeSheetId,
                            canMoveLeft: visibleSheets.indexOf(sheet) > 0,
                            canMoveRight:
                                visibleSheets.indexOf(sheet) <
                                visibleSheets.length - 1,
                            canDelete: visibleSheets.length > 1,
                            canHide: visibleSheets.length > 1,
                            renaming: _renamingSheetId == sheet.id,
                            onSelected: () =>
                                controller.switchToSheet(sheet.id),
                            onRename: () => _startRenameSheet(sheet.id),
                            onRenameCommit: (name) =>
                                _commitRenameSheet(controller, sheet.id, name),
                            onRenameCancel: _cancelRenameSheet,
                            onDuplicate: () =>
                                controller.duplicateSheet(sheet.id),
                            onMoveLeft: () =>
                                controller.moveSheet(sheet.id, -1),
                            onMoveRight: () =>
                                controller.moveSheet(sheet.id, 1),
                            onColor: () =>
                                _chooseTabColor(context, controller, sheet),
                            onHide: () => controller.hideSheet(sheet.id),
                            onDelete: () =>
                                _confirmDeleteSheet(context, controller, sheet),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          Tooltip(
            message: 'Add Sheet',
            child: IconButton.filledTonal(
              onPressed: controller.addSheet,
              icon: const Icon(Icons.add, size: 18),
              style: IconButton.styleFrom(
                minimumSize: const Size.square(32),
                padding: EdgeInsets.zero,
                backgroundColor: KySheetColors.accentSoft,
                foregroundColor: KySheetColors.accent,
              ),
            ),
          ),
          const SizedBox(width: 10),
        ],
      ),
    );
  }

  void _syncTabVisibilityKeys(List<WorkbookSheet> sheets) {
    final sheetIds = sheets.map((sheet) => sheet.id).toSet();
    _tabVisibilityKeys.removeWhere((sheetId, _) => !sheetIds.contains(sheetId));
    if (_renamingSheetId != null && !sheetIds.contains(_renamingSheetId)) {
      _renamingSheetId = null;
    }

    for (final sheet in sheets) {
      _tabVisibilityKeys.putIfAbsent(sheet.id, GlobalKey.new);
    }
  }

  void _scheduleActiveTabVisibility(String activeSheetId) {
    if (_lastActiveSheetId == activeSheetId) return;
    _lastActiveSheetId = activeSheetId;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final tabContext = _tabVisibilityKeys[activeSheetId]?.currentContext;
      if (tabContext == null) return;

      Scrollable.ensureVisible(
        tabContext,
        alignment: 0.5,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
      );
    });
  }

  void _startRenameSheet(String sheetId) {
    if (_renamingSheetId == sheetId) return;

    setState(() {
      _renamingSheetId = sheetId;
    });
  }

  void _commitRenameSheet(
    WorkbookNotifier controller,
    String sheetId,
    String name,
  ) {
    setState(() {
      _renamingSheetId = null;
    });
    controller.renameSheet(sheetId, name);
  }

  void _cancelRenameSheet() {
    if (_renamingSheetId == null) return;

    setState(() {
      _renamingSheetId = null;
    });
  }

  int _visibleIndexForDrop({
    required List<WorkbookSheet> visibleSheets,
    required String draggedSheetId,
    required WorkbookSheet targetSheet,
    required SheetTabReorderEdge edge,
  }) {
    final sourceIndex = visibleSheets.indexWhere(
      (sheet) => sheet.id == draggedSheetId,
    );
    final targetIndex = visibleSheets.indexWhere(
      (sheet) => sheet.id == targetSheet.id,
    );
    if (sourceIndex == -1 || targetIndex == -1) return targetIndex;

    var insertionIndex = edge == SheetTabReorderEdge.before
        ? targetIndex
        : targetIndex + 1;
    if (sourceIndex < insertionIndex) {
      insertionIndex -= 1;
    }

    if (insertionIndex < 0) return 0;
    if (insertionIndex >= visibleSheets.length) {
      return visibleSheets.length - 1;
    }
    return insertionIndex;
  }

  Future<void> _confirmDeleteSheet(
    BuildContext context,
    WorkbookNotifier controller,
    WorkbookSheet sheet,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => SheetDeleteSheetDialog(sheetName: sheet.name),
    );

    if (confirmed ?? false) {
      controller.deleteSheet(sheet.id);
    }
  }

  Future<void> _chooseTabColor(
    BuildContext context,
    WorkbookNotifier controller,
    WorkbookSheet sheet,
  ) async {
    final selection = await showDialog<SheetTabColorSelection>(
      context: context,
      builder: (context) => SheetTabColorDialog(
        sheetName: sheet.name,
        currentColor: sheet.tabColor,
      ),
    );

    if (selection == null) return;
    controller.setSheetTabColor(sheet.id, selection.color);
  }
}
