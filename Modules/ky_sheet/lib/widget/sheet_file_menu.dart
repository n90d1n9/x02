import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../service/kyo_xlsx_reader.dart';
import '../state/spreadsheet_provider.dart';
import '../state/workbook_provider.dart';
import '../theme/ky_sheet_theme.dart';

/// File menu widget providing Excel-like File menu functionality
class SheetFileMenu extends ConsumerWidget {
  const SheetFileMenu({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PopupMenuButton<String>(
      icon: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.menu, color: KySheetColors.text),
          SizedBox(width: 4),
          Text(
            'File',
            style: TextStyle(
              color: KySheetColors.text,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
      offset: Offset(0, 40),
      onSelected: (value) => _handleMenuSelection(context, ref, value),
      itemBuilder: (context) => [
        _buildMenuItem(
          Icons.insert_drive_file,
          'New Workbook',
          'new_workbook',
          shortcut: 'Ctrl+N',
        ),
        _buildMenuItem(
          Icons.folder_open,
          'Open...',
          'open',
          shortcut: 'Ctrl+O',
        ),
        const PopupMenuDivider(),
        _buildMenuItem(Icons.save, 'Save', 'save', shortcut: 'Ctrl+S'),
        _buildMenuItem(
          Icons.save_as,
          'Save As...',
          'save_as',
          shortcut: 'Ctrl+Shift+S',
        ),
        const PopupMenuDivider(),
        _buildMenuItem(
          Icons.upload_file,
          'Import',
          'import',
          submenu: [
            _buildSubMenuItem('Excel Workbook (.xlsx)', 'import_xlsx'),
            _buildSubMenuItem('CSV File (.csv)', 'import_csv'),
            _buildSubMenuItem('JSON Workbook (.json)', 'import_json'),
          ],
        ),
        _buildMenuItem(
          Icons.download,
          'Export / Download As',
          'export',
          submenu: [
            _buildSubMenuItem('Excel Workbook (.xlsx)', 'export_xlsx'),
            _buildSubMenuItem('CSV File (.csv)', 'export_csv'),
            _buildSubMenuItem('JSON Workbook (.json)', 'export_json'),
            _buildSubMenuItem(
              'Sheet Engine JSON (.sheet-engine.json)',
              'export_xlsx_reader',
            ),
          ],
        ),
        const PopupMenuDivider(),
        _buildMenuItem(Icons.print, 'Print...', 'print', shortcut: 'Ctrl+P'),
        _buildMenuItem(Icons.share, 'Share', 'share'),
        const PopupMenuDivider(),
        _buildMenuItem(Icons.info_outline, 'Workbook Info', 'info'),
        _buildMenuItem(Icons.settings, 'Options', 'options'),
      ],
    );
  }

  PopupMenuItem<String> _buildMenuItem(
    IconData icon,
    String label,
    String value, {
    String? shortcut,
    List<PopupMenuItem<String>>? submenu,
  }) {
    return PopupMenuItem<String>(
      value: value,
      enabled: submenu == null,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20, color: KySheetColors.text),
          SizedBox(width: 12),
          Expanded(
            child: Text(label, style: TextStyle(color: KySheetColors.text)),
          ),
          if (shortcut != null)
            Padding(
              padding: EdgeInsets.only(left: 16),
              child: Text(
                shortcut,
                style: TextStyle(color: KySheetColors.mutedText, fontSize: 12),
              ),
            ),
          if (submenu != null) ...[
            SizedBox(width: 8),
            Icon(Icons.chevron_right, size: 16, color: KySheetColors.mutedText),
          ],
        ],
      ),
      // Note: For submenu support, we'd need a custom menu implementation
      // This is a simplified version - in production you'd use a more sophisticated menu system
    );
  }

  PopupMenuItem<String> _buildSubMenuItem(String label, String value) {
    return PopupMenuItem<String>(
      value: value,
      child: Text(label, style: TextStyle(color: KySheetColors.text)),
    );
  }

  Future<void> _handleMenuSelection(
    BuildContext context,
    WidgetRef ref,
    String value,
  ) async {
    switch (value) {
      case 'new_workbook':
        await _showNewWorkbookDialog(context, ref);
        break;
      case 'open':
        await _openFile(context, ref);
        break;
      case 'save':
        await _saveFile(context, ref);
        break;
      case 'save_as':
        await _saveAsFile(context, ref);
        break;
      case 'import_xlsx':
      case 'import_csv':
      case 'import_json':
        await _importFile(context, ref, value.split('_').last);
        break;
      case 'export_xlsx':
      case 'export_csv':
      case 'export_json':
      case 'export_xlsx_reader':
        await _exportFile(context, ref, value.replaceFirst('export_', ''));
        break;
      case 'print':
        _showSnackBar(context, 'Print functionality coming soon');
        break;
      case 'share':
        _showSnackBar(context, 'Share functionality coming soon');
        break;
      case 'info':
        await _showWorkbookInfo(context, ref);
        break;
      case 'options':
        _showSnackBar(context, 'Options dialog coming soon');
        break;
    }
  }

  Future<void> _showNewWorkbookDialog(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('New Workbook'),
        content: Text(
          'Create a new workbook? Any unsaved changes will be lost.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Create New'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      ref.read(workbookProvider.notifier).createNewWorkbook();
      _showSnackBar(context, 'New workbook created');
    }
  }

  Future<void> _openFile(BuildContext context, WidgetRef ref) async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls', 'csv', 'json', 'sheet-engine.json'],
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final extension = result.files.single.extension?.toLowerCase();

        if (extension == 'xlsx' || extension == 'xls') {
          // Use high-performance parser-xlsx parser for large files
          // Falls back to package:excel if FFI library not available
          try {
            await ref
                .read(spreadsheetProvider.notifier)
                .importFromExcelBytesKyo(file.path);
            _showSnackBar(
              context,
              'Excel file opened successfully (parser-xlsx)',
            );
          } catch (e) {
            // Fallback to package:excel
            final bytes = await file.readAsBytes();
            ref.read(spreadsheetProvider.notifier).importFromExcelBytes(bytes);
            _showSnackBar(context, 'Excel file opened successfully');
          }
        } else if (extension == 'csv') {
          final content = await file.readAsString();
          ref.read(spreadsheetProvider.notifier).importFromCSV(content);
          _showSnackBar(context, 'CSV file opened successfully');
        } else if (extension == 'json') {
          final content = await file.readAsString();
          final data = Map<String, dynamic>.from(jsonDecode(content));
          ref.read(workbookProvider.notifier).importFromAnyJson(data);
          _showSnackBar(context, 'Workbook JSON opened successfully');
        } else if (extension == 'sheet-engine.json') {
          final content = await file.readAsString();
          final data = Map<String, dynamic>.from(jsonDecode(content));
          ref.read(workbookProvider.notifier).importFromSheetEngineJson(data);
          _showSnackBar(context, 'Sheet Engine workbook opened successfully');
        }
      }
    } catch (e) {
      if (context.mounted) {
        _showSnackBar(context, 'Open failed: $e', isError: true);
      }
    }
  }

  Future<void> _saveFile(BuildContext context, WidgetRef ref) async {
    // Try to save to current file path if available
    final workbookState = ref.read(workbookProvider);
    final currentPath = workbookState.currentFilePath;

    if (currentPath != null) {
      await _performSave(context, ref, currentPath);
    } else {
      await _saveAsFile(context, ref);
    }
  }

  Future<void> _saveAsFile(BuildContext context, WidgetRef ref) async {
    try {
      final directory = await getApplicationDocumentsDirectory();

      final fileName = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Save As'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Enter file name:'),
              SizedBox(height: 8),
              TextField(
                decoration: InputDecoration(
                  hintText: 'workbook.xlsx',
                  border: OutlineInputBorder(),
                ),
                autofocus: true,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                // Get text from field - simplified for demo
                Navigator.pop(
                  context,
                  'workbook_${DateTime.now().millisecondsSinceEpoch}.xlsx',
                );
              },
              child: Text('Save'),
            ),
          ],
        ),
      );

      if (fileName != null && context.mounted) {
        final filePath = '${directory.path}/$fileName';
        await _performSave(context, ref, filePath);
      }
    } catch (e) {
      if (context.mounted) {
        _showSnackBar(context, 'Save failed: $e', isError: true);
      }
    }
  }

  Future<void> _performSave(
    BuildContext context,
    WidgetRef ref,
    String filePath,
  ) async {
    final extension = filePath.split('.').last.toLowerCase();

    if (extension == 'xlsx') {
      final excel = ref.read(spreadsheetProvider.notifier).exportToExcel();
      final bytes = excel.encode();
      if (bytes != null) {
        await File(filePath).writeAsBytes(bytes);
        ref.read(workbookProvider.notifier).setCurrentFilePath(filePath);
        _showSnackBar(context, 'Saved to $filePath');
      }
    } else if (extension == 'json') {
      final data = ref.read(workbookProvider.notifier).exportToJson();
      await File(filePath).writeAsString(jsonEncode(data));
      ref.read(workbookProvider.notifier).setCurrentFilePath(filePath);
      _showSnackBar(context, 'Saved to $filePath');
    } else if (extension == 'sheet-engine.json') {
      final data = ref
          .read(workbookProvider.notifier)
          .exportToSheetEngineJson();
      await File(filePath).writeAsString(jsonEncode(data));
      ref.read(workbookProvider.notifier).setCurrentFilePath(filePath);
      _showSnackBar(context, 'Saved to $filePath');
    } else {
      _showSnackBar(
        context,
        'Unsupported file format: $extension',
        isError: true,
      );
    }
  }

  Future<void> _importFile(
    BuildContext context,
    WidgetRef ref,
    String format,
  ) async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: format == 'xlsx'
            ? ['xlsx', 'xls']
            : format == 'csv'
            ? ['csv']
            : ['json'],
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);

        if (format == 'xlsx') {
          // Use high-performance parser-xlsx parser for large files
          try {
            await ref
                .read(spreadsheetProvider.notifier)
                .importFromExcelBytesKyo(file.path);
            _showSnackBar(
              context,
              'Excel file imported successfully (parser-xlsx)',
            );
          } catch (e) {
            // Fallback to package:excel
            final bytes = await file.readAsBytes();
            ref.read(spreadsheetProvider.notifier).importFromExcelBytes(bytes);
            _showSnackBar(context, 'Excel file imported successfully');
          }
        } else if (format == 'csv') {
          final content = await file.readAsString();
          ref.read(spreadsheetProvider.notifier).importFromCSV(content);
          _showSnackBar(context, 'CSV file imported successfully');
        } else if (format == 'json') {
          final content = await file.readAsString();
          final data = Map<String, dynamic>.from(jsonDecode(content));
          ref.read(workbookProvider.notifier).importFromAnyJson(data);
          _showSnackBar(context, 'Workbook JSON imported successfully');
        }
      }
    } catch (e) {
      if (context.mounted) {
        _showSnackBar(context, 'Import failed: $e', isError: true);
      }
    }
  }

  Future<void> _exportFile(
    BuildContext context,
    WidgetRef ref,
    String format,
  ) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final extension = format == 'xlsx_reader' ? 'sheet-engine.json' : format;
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
      } else if (format == 'xlsx_reader') {
        final data = ref
            .read(workbookProvider.notifier)
            .exportToSheetEngineJson();
        await File(filePath).writeAsString(jsonEncode(data));
      }

      if (context.mounted) {
        _showSnackBar(context, 'Exported to $filePath');
      }
    } catch (e) {
      if (context.mounted) {
        _showSnackBar(context, 'Export failed: $e', isError: true);
      }
    }
  }

  Future<void> _showWorkbookInfo(BuildContext context, WidgetRef ref) async {
    final workbook = ref.read(workbookProvider);
    final sheetCount = workbook.sheets.length;
    final totalCells = workbook.totalCellCount;

    if (!context.mounted) return;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Workbook Information'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _infoRow('Name:', workbook.name ?? 'Untitled'),
            _infoRow('Sheets:', '$sheetCount'),
            _infoRow('Total Cells:', '$totalCells'),
            _infoRow('Current Path:', workbook.currentFilePath ?? 'Not saved'),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  void _showSnackBar(
    BuildContext context,
    String message, {
    bool isError = false,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : null,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
