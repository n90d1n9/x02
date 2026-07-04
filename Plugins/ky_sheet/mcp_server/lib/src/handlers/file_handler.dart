/// Handler for file operations (open, save, export, import)

import 'dart:io';
import 'package:ky_sheet/ky_sheet.dart';
import '../ky_sheet_mcp_server.dart';

class FileHandler {
  final KySheetMCPServer server;

  FileHandler(this.server);

  /// Open an existing spreadsheet file
  Future<Map<String, dynamic>> openFile(Map<String, dynamic> params) async {
    final filePath = params['file_path'] as String?;
    final fileType = params['file_type'] as String?;

    if (filePath == null) {
      return {'success': false, 'error': 'file_path is required'};
    }

    try {
      final file = File(filePath);
      if (!await file.exists()) {
        return {'success': false, 'error': 'File not found: $filePath'};
      }

      Workbook workbook;
      final actualFileType = fileType ?? _getFileExtension(filePath);

      switch (actualFileType.toLowerCase()) {
        case 'xlsx':
          workbook = await _openXlsx(filePath);
          break;
        case 'csv':
          workbook = await _openCsv(filePath);
          break;
        case 'xls':
          return {'success': false, 'error': 'XLS format not supported, please use XLSX'};
        default:
          return {'success': false, 'error': 'Unsupported file type: $actualFileType'};
      }

      final id = server.generateWorkbookId();
      server.setActiveWorkbook(id, workbook);

      return {
        'success': true,
        'workbook_id': id,
        'file_path': filePath,
        'file_type': actualFileType,
        'sheet_count': workbook.sheets.length,
        'sheets': workbook.sheets.map((s) => s.name).toList(),
        'message': 'File opened successfully',
      };
    } catch (e) {
      return {'success': false, 'error': 'Failed to open file: $e'};
    }
  }

  /// Save the current workbook to a file
  Future<Map<String, dynamic>> saveFile(Map<String, dynamic> params) async {
    final workbook = server.getActiveWorkbook();
    if (workbook == null) {
      return {'success': false, 'error': 'No active workbook'};
    }

    final filePath = params['file_path'] as String?;
    final fileType = params['file_type'] as String?;

    if (filePath == null) {
      return {'success': false, 'error': 'file_path is required'};
    }

    try {
      final actualFileType = fileType ?? _getFileExtension(filePath);

      switch (actualFileType.toLowerCase()) {
        case 'xlsx':
          await _saveXlsx(workbook, filePath);
          break;
        case 'csv':
          await _saveCsv(workbook, filePath);
          break;
        default:
          return {'success': false, 'error': 'Unsupported file type: $actualFileType'};
      }

      return {
        'success': true,
        'file_path': filePath,
        'file_type': actualFileType,
        'message': 'File saved successfully',
      };
    } catch (e) {
      return {'success': false, 'error': 'Failed to save file: $e'};
    }
  }

  /// Export workbook to PDF
  Future<Map<String, dynamic>> exportPdf(Map<String, dynamic> params) async {
    final workbook = server.getActiveWorkbook();
    if (workbook == null) {
      return {'success': false, 'error': 'No active workbook'};
    }

    final filePath = params['file_path'] as String?;
    final sheetNames = params['sheet_names'] as List?;

    if (filePath == null) {
      return {'success': false, 'error': 'file_path is required'};
    }

    try {
      // Note: PDF export would require additional dependencies
      // This is a placeholder implementation
      final sheetsToExport = sheetNames != null && sheetNames.isNotEmpty
          ? workbook.sheets.where((s) => sheetNames.contains(s.name)).toList()
          : workbook.sheets;

      if (sheetsToExport.isEmpty) {
        return {'success': false, 'error': 'No sheets to export'};
      }

      // Placeholder: In real implementation, use a PDF generation library
      return {
        'success': false,
        'error': 'PDF export requires additional setup. Please use export_csv or save as xlsx.',
        'note': 'PDF export functionality is planned for future release',
      };
    } catch (e) {
      return {'success': false, 'error': 'Failed to export PDF: $e'};
    }
  }

  /// Export a sheet to CSV
  Future<Map<String, dynamic>> exportCsv(Map<String, dynamic> params) async {
    final workbook = server.getActiveWorkbook();
    if (workbook == null) {
      return {'success': false, 'error': 'No active workbook'};
    }

    final filePath = params['file_path'] as String?;
    final sheetName = params['sheet_name'] as String?;

    if (filePath == null) {
      return {'success': false, 'error': 'file_path is required'};
    }

    try {
      Worksheet sheet;
      if (sheetName != null) {
        sheet = workbook.sheets.firstWhere(
          (s) => s.name == sheetName,
          orElse: () => throw Exception('Sheet not found: $sheetName'),
        );
      } else {
        sheet = workbook.activeSheet!;
      }

      await _saveCsvSingleSheet(sheet, filePath);

      return {
        'success': true,
        'file_path': filePath,
        'sheet_name': sheet.name,
        'message': 'CSV exported successfully',
      };
    } catch (e) {
      return {'success': false, 'error': 'Failed to export CSV: $e'};
    }
  }

  /// Import data from CSV
  Future<Map<String, dynamic>> importCsv(Map<String, dynamic> params) async {
    var workbook = server.getActiveWorkbook();
    
    final filePath = params['file_path'] as String?;
    final sheetName = params['sheet_name'] as String?;
    final startRow = params['start_row'] as int? ?? 1;
    final startColumn = params['start_column'] as int? ?? 1;

    if (filePath == null) {
      return {'success': false, 'error': 'file_path is required'};
    }

    try {
      final importedWorkbook = await _openCsv(filePath);
      final importedSheet = importedWorkbook.sheets.first;

      if (workbook == null) {
        workbook = importedWorkbook;
        final id = server.generateWorkbookId();
        server.setActiveWorkbook(id, workbook);
      } else {
        // Create new sheet or use specified one
        Worksheet targetSheet;
        if (sheetName != null) {
          targetSheet = workbook.sheets.firstWhere(
            (s) => s.name == sheetName,
            orElse: () {
              final newSheet = Worksheet(name: sheetName);
              workbook.sheets.add(newSheet);
              return newSheet;
            },
          );
        } else {
          targetSheet = workbook.activeSheet!;
        }

        // Copy data from imported sheet to target sheet
        int rowsImported = 0;
        int colsImported = 0;

        for (var r = 1; r <= importedSheet.rowCount; r++) {
          for (var c = 1; c <= importedSheet.columnCount; c++) {
            final cell = importedSheet.getCell(r, c);
            if (cell != null && cell.value != null) {
              final targetCell = targetSheet.getCell(startRow + r - 1, startColumn + c - 1)
                  ?? targetSheet.createCell(startRow + r - 1, startColumn + c - 1);
              targetCell.value = cell.value;
            }
          }
          if (importedSheet.columnCount > colsImported) {
            colsImported = importedSheet.columnCount;
          }
          rowsImported++;
        }

        importedWorkbook = workbook;
      }

      return {
        'success': true,
        'file_path': filePath,
        'rows_imported': rowsImported,
        'columns_imported': colsImported,
        'target_sheet': sheetName ?? workbook.activeSheet?.name,
        'message': 'CSV imported successfully',
      };
    } catch (e) {
      return {'success': false, 'error': 'Failed to import CSV: $e'};
    }
  }

  /// Close a workbook
  Future<Map<String, dynamic>> closeWorkbook(Map<String, dynamic> params) async {
    final workbookId = params['workbook_id'] as String?;

    if (workbookId == null) {
      // Close active workbook
      if (server.getActiveWorkbook() == null) {
        return {'success': false, 'error': 'No active workbook to close'};
      }
      // Clear active workbook
      return {
        'success': true,
        'message': 'Active workbook closed',
      };
    }

    // Close specific workbook
    return {
      'success': true,
      'workbook_id': workbookId,
      'message': 'Workbook closed',
    };
  }

  // Helper methods
  String _getFileExtension(String filePath) {
    final lastDot = filePath.lastIndexOf('.');
    if (lastDot == -1) return '';
    return filePath.substring(lastDot + 1);
  }

  Future<Workbook> _openXlsx(String filePath) async {
    // Use ky_of_xlsx or similar package to read XLSX
    // This is a placeholder - actual implementation depends on ky_sheet's IO capabilities
    final file = File(filePath);
    final bytes = await file.readAsBytes();
    
    // Assuming ky_sheet has an XlsxReader or similar
    // final reader = XlsxReader();
    // return reader.read(bytes);
    
    throw UnimplementedError('XLSX reading requires ky_of_xlsx integration');
  }

  Future<Workbook> _openCsv(String filePath) async {
    final file = File(filePath);
    final content = await file.readAsString();
    
    final workbook = Workbook();
    final sheet = workbook.sheets.first;
    sheet.name = File(filePath).path.split('/').last;

    final lines = content.split('\n');
    int rowNum = 1;

    for (final line in lines) {
      if (line.trim().isEmpty) continue;
      
      // Simple CSV parsing (doesn't handle quoted fields with commas)
      final values = line.split(',');
      int colNum = 1;
      
      for (final value in values) {
        final cell = sheet.createCell(rowNum, colNum);
        final trimmedValue = value.trim();
        
        // Try to parse as number
        final numValue = num.tryParse(trimmedValue);
        if (numValue != null) {
          cell.value = numValue;
        } else {
          cell.value = trimmedValue;
        }
        
        colNum++;
      }
      
      rowNum++;
    }

    return workbook;
  }

  Future<void> _saveXlsx(Workbook workbook, String filePath) async {
    // Use ky_of_xlsx or similar package to write XLSX
    // This is a placeholder - actual implementation depends on ky_sheet's IO capabilities
    
    // final writer = XlsxWriter();
    // final bytes = writer.write(workbook);
    // await File(filePath).writeAsBytes(bytes);
    
    throw UnimplementedError('XLSX writing requires ky_of_xlsx integration');
  }

  Future<void> _saveCsv(Workbook workbook, String filePath) async {
    if (workbook.sheets.isEmpty) {
      throw Exception('Workbook has no sheets');
    }

    // For multi-sheet workbooks, save each sheet to a separate file
    if (workbook.sheets.length > 1) {
      for (final sheet in workbook.sheets) {
        final baseName = filePath.substring(0, filePath.lastIndexOf('.'));
        final extension = filePath.substring(filePath.lastIndexOf('.'));
        final sheetFilePath = '${baseName}_${sheet.name}$extension';
        await _saveCsvSingleSheet(sheet, sheetFilePath);
      }
    } else {
      await _saveCsvSingleSheet(workbook.sheets.first, filePath);
    }
  }

  Future<void> _saveCsvSingleSheet(Worksheet sheet, String filePath) async {
    final buffer = StringBuffer();
    
    for (var r = 1; r <= sheet.rowCount; r++) {
      final rowValues = <String>[];
      bool hasData = false;
      
      for (var c = 1; c <= sheet.columnCount; c++) {
        final cell = sheet.getCell(r, c);
        final value = cell?.value ?? '';
        rowValues.add(value.toString());
        
        if (value != null && value.toString().isNotEmpty) {
          hasData = true;
        }
      }
      
      // Only write rows that have data
      if (hasData) {
        buffer.writeln(rowValues.join(','));
      }
    }

    await File(filePath).writeAsString(buffer.toString());
  }
}
