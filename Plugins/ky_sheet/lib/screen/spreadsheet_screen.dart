import 'dart:convert';
import 'dart:io';

import 'package:excel/excel.dart' as excel_lib;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../model/sheet_command.dart';
import '../state/sheet_command_palette_provider.dart';
import '../state/sheet_find_replace_provider.dart';
import '../state/sheet_sidebar_provider.dart';
import '../state/spreadsheet_provider.dart';
import '../state/workbook_provider.dart';
import '../theme/ky_sheet_theme.dart';
import '../widget/formula_bar.dart';
import '../widget/quick_action_sheet.dart';
import '../widget/sheet_command_palette_dialog.dart';
import '../widget/sheet_sidebar.dart';
import '../widget/sheet_tabs_bar.dart';
import '../widget/sheet_workbook_shortcuts.dart';
import '../widget/spreadsheet_grid.dart';
import '../widget/status_bar.dart';
import '../widget/toolbar_widget.dart';
import '../utils/sheet_command_catalog.dart';

class SpreadsheetScreen extends ConsumerStatefulWidget {
  const SpreadsheetScreen({super.key});

  @override
  ConsumerState<SpreadsheetScreen> createState() => _SpreadsheetScreenState();
}

class _SpreadsheetScreenState extends ConsumerState<SpreadsheetScreen> {
  final _horizontalController = ScrollController();
  final _verticalController = ScrollController();

  @override
  void dispose() {
    _horizontalController.dispose();
    _verticalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final zoom = ref.watch(zoomLevelProvider);
    final canUndo = ref.watch(undoStackProvider).isNotEmpty;
    final canRedo = ref.watch(redoStackProvider).isNotEmpty;

    return SheetWorkbookShortcuts(
      onOpenFindReplace: _showSearchDialog,
      onOpenReplace: _showReplaceDialog,
      onOpenSortFilter: _showSortFilterPanel,
      onOpenCommandPalette: _showCommandPalette,
      onOpenShortcuts: _showShortcutsPanel,
      onCloseActivePanel: _closeActiveSidebarPanel,
      onPreviousSheet: () =>
          ref.read(workbookProvider.notifier).switchToAdjacentVisibleSheet(-1),
      onNextSheet: () =>
          ref.read(workbookProvider.notifier).switchToAdjacentVisibleSheet(1),
      child: Scaffold(
        backgroundColor: KySheetColors.canvas,
        appBar: AppBar(
          titleSpacing: 16,
          backgroundColor: KySheetColors.surface,
          foregroundColor: KySheetColors.text,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          title: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.table_chart_outlined, color: KySheetColors.accent),
              SizedBox(width: 10),
              Text(
                'Ky Sheet',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.undo),
              onPressed: canUndo ? _undo : null,
              tooltip: 'Undo (Ctrl+Z)',
            ),
            IconButton(
              icon: const Icon(Icons.redo),
              onPressed: canRedo ? _redo : null,
              tooltip: 'Redo (Ctrl+Y)',
            ),
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: _showSearchDialog,
              tooltip: 'Find & Replace (Ctrl+F)',
            ),
            IconButton(
              key: const ValueKey('ky-sheet-command-palette-button'),
              icon: const Icon(Icons.manage_search),
              onPressed: _showCommandPalette,
              tooltip: 'Command Palette (Ctrl+K)',
            ),
            const VerticalDivider(),
            IconButton(
              icon: const Icon(Icons.upload_file),
              onPressed: _importFile,
              tooltip: 'Import (XLSX, CSV, JSON)',
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.download),
              tooltip: 'Export',
              onSelected: _exportFile,
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'xlsx',
                  child: Text('Export as XLSX'),
                ),
                const PopupMenuItem(value: 'csv', child: Text('Export as CSV')),
                const PopupMenuItem(
                  value: 'json',
                  child: Text('Export as JSON'),
                ),
                const PopupMenuItem(
                  value: 'sheet_engine_json',
                  child: Text('Export for Waraq sheet_engine'),
                ),
              ],
            ),
            const VerticalDivider(),
            IconButton(
              icon: const Icon(Icons.zoom_in),
              onPressed: () => _changeZoom(0.1),
              tooltip: 'Zoom In',
            ),
            Container(
              width: 58,
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(vertical: 6),
              decoration: BoxDecoration(
                color: KySheetColors.surfaceMuted,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${(zoom * 100).toInt()}%',
                style: const TextStyle(
                  fontSize: 12,
                  color: KySheetColors.mutedText,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.zoom_out),
              onPressed: () => _changeZoom(-0.1),
              tooltip: 'Zoom Out',
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: Row(
          children: [
            Expanded(
              child: Column(
                children: [
                  const ToolbarWidget(),
                  const FormulaBar(),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: SpreadsheetGrid(
                          horizontalController: _horizontalController,
                          verticalController: _verticalController,
                        ),
                      ),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.fromLTRB(12, 0, 12, 0),
                    child: SheetTabsBar(),
                  ),
                  const Padding(
                    padding: EdgeInsets.fromLTRB(12, 0, 12, 10),
                    child: StatusBar(),
                  ),
                ],
              ),
            ),
            const SheetSidebar(),
          ],
        ),
        floatingActionButton: FloatingActionButton.small(
          backgroundColor: KySheetColors.accent,
          foregroundColor: Colors.white,
          onPressed: _showQuickActions,
          tooltip: 'Quick Actions',
          child: const Icon(Icons.more_vert),
        ),
      ),
    );
  }

  void _changeZoom(double delta) {
    final current = ref.read(zoomLevelProvider);
    final newZoom = (current + delta).clamp(0.5, 2.0);
    ref.read(zoomLevelProvider.notifier).state = newZoom;
  }

  void _undo() {
    ref.read(spreadsheetProvider.notifier).undo();
  }

  void _redo() {
    ref.read(spreadsheetProvider.notifier).redo();
  }

  Future<void> _importFile() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls', 'csv', 'json'],
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final extension = result.files.single.extension?.toLowerCase();

        if (extension == 'xlsx' || extension == 'xls') {
          final bytes = await file.readAsBytes();
          final excel = excel_lib.Excel.decodeBytes(bytes);
          ref.read(spreadsheetProvider.notifier).importFromExcel(excel);
          _showSnackBar('Excel file imported successfully');
        } else if (extension == 'csv') {
          final content = await file.readAsString();
          ref.read(spreadsheetProvider.notifier).importFromCSV(content);
          _showSnackBar('CSV file imported successfully');
        } else if (extension == 'json') {
          final content = await file.readAsString();
          final data = Map<String, dynamic>.from(jsonDecode(content));
          ref.read(workbookProvider.notifier).importFromAnyJson(data);
          _showSnackBar('Workbook JSON imported successfully');
        }
      }
    } catch (e) {
      _showSnackBar('Import failed: $e', isError: true);
    }
  }

  Future<void> _exportFile(String format) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final extension = format == 'sheet_engine_json'
          ? 'sheet-engine.json'
          : format;
      final fileName = 'spreadsheet_$timestamp.$extension';
      final filePath = '${directory.path}/$fileName';

      if (format == 'xlsx') {
        final excel = ref.read(spreadsheetProvider.notifier).exportToExcel();
        final bytes = excel.encode();
        if (bytes != null) {
          await File(filePath).writeAsBytes(bytes);
        }
      } else if (format == 'csv') {
        final csv = ref.read(spreadsheetProvider.notifier).exportToCSV();
        await File(filePath).writeAsString(csv);
      } else if (format == 'json') {
        final data = ref.read(workbookProvider.notifier).exportToJson();
        await File(filePath).writeAsString(jsonEncode(data));
      } else if (format == 'sheet_engine_json') {
        final data = ref
            .read(workbookProvider.notifier)
            .exportToSheetEngineJson();
        await File(filePath).writeAsString(jsonEncode(data));
      }

      _showSnackBar('Exported to $filePath');
    } catch (e) {
      _showSnackBar('Export failed: $e', isError: true);
    }
  }

  void _showSearchDialog() {
    ref.read(findReplaceFocusTargetProvider.notifier).state =
        SheetFindReplaceFocusTarget.find;
    ref.read(activeSidebarPanelProvider.notifier).state =
        SheetSidebarPanel.findReplace;
  }

  void _showReplaceDialog() {
    ref.read(findReplaceFocusTargetProvider.notifier).state =
        SheetFindReplaceFocusTarget.replace;
    ref.read(activeSidebarPanelProvider.notifier).state =
        SheetSidebarPanel.findReplace;
  }

  void _showSortFilterPanel() {
    ref.read(activeSidebarPanelProvider.notifier).state =
        SheetSidebarPanel.sortFilter;
  }

  void _showShortcutsPanel() {
    ref.read(activeSidebarPanelProvider.notifier).state =
        SheetSidebarPanel.shortcuts;
  }

  bool _closeActiveSidebarPanel() {
    final activePanel = ref.read(activeSidebarPanelProvider);
    if (activePanel == null) return false;

    ref.read(activeSidebarPanelProvider.notifier).state = null;
    return true;
  }

  Future<void> _showCommandPalette() async {
    final recentCommands = ref
        .read(recentSheetCommandIdsProvider.notifier)
        .resolve(SheetCommandCatalog.all);
    final command = await showDialog<SheetCommand>(
      context: context,
      builder: (context) => SheetCommandPaletteDialog(
        recentCommands: recentCommands,
        availability: SheetCommandAvailability(
          disabledReasons: _commandDisabledReasons(),
        ),
      ),
    );
    if (!mounted || command == null) return;
    ref.read(recentSheetCommandIdsProvider.notifier).record(command);
    _runCommand(command);
  }

  Map<String, String> _commandDisabledReasons() {
    return {
      if (ref.read(undoStackProvider).isEmpty) 'edit.undo': 'Nothing to undo',
      if (ref.read(redoStackProvider).isEmpty) 'edit.redo': 'Nothing to redo',
    };
  }

  void _runCommand(SheetCommand command) {
    switch (command.action) {
      case SheetCommandAction.openSidebarPanel:
        final panel = command.sidebarPanel;
        if (panel != null) {
          ref.read(activeSidebarPanelProvider.notifier).state = panel;
        }
      case SheetCommandAction.undo:
        _undo();
      case SheetCommandAction.redo:
        _redo();
      case SheetCommandAction.zoomIn:
        _changeZoom(0.1);
      case SheetCommandAction.zoomOut:
        _changeZoom(-0.1);
      case SheetCommandAction.quickActions:
        _showQuickActions();
    }
  }

  void _showQuickActions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => const QuickActionsSheet(),
    );
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : null,
      ),
    );
  }
}
