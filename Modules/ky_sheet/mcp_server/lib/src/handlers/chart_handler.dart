/// Handler for chart operations

import 'package:ky_sheet/ky_sheet.dart';
import '../ky_sheet_mcp_server.dart';

class ChartHandler {
  final KySheetMCPServer server;

  ChartHandler(this.server);

  /// Create a new chart
  Future<Map<String, dynamic>> createChart(Map<String, dynamic> params) async {
    final workbook = server.getActiveWorkbook();
    if (workbook == null) {
      return {'success': false, 'error': 'No active workbook'};
    }

    final sheetName = params['sheet_name'] as String?;
    final chartType = params['chart_type'] as String?;
    final dataRange = params['data_range'] as String?;
    final title = params['title'] as String?;
    final position = params['position'] as Map<String, dynamic>?;

    if (sheetName == null || chartType == null || dataRange == null) {
      return {'success': false, 'error': 'sheet_name, chart_type, and data_range are required'};
    }

    try {
      final sheet = workbook.sheets.firstWhere(
        (s) => s.name == sheetName,
        orElse: () => throw Exception('Sheet not found'),
      );

      // Parse chart type
      final parsedChartType = _parseChartType(chartType);
      
      // Parse data range (e.g., "A1:B10")
      final rangeInfo = _parseRange(dataRange);
      
      // Create chart
      final chart = Chart(
        type: parsedChartType,
        dataRange: rangeInfo,
        title: title ?? '',
      );

      // Set position if provided
      if (position != null) {
        chart.position = ChartPosition(
          row: position['row'] as int? ?? 1,
          column: position['column'] as int? ?? 1,
          width: (position['width'] as num?)?.toDouble() ?? 400.0,
          height: (position['height'] as num?)?.toDouble() ?? 300.0,
        );
      }

      sheet.charts.add(chart);

      return {
        'success': true,
        'chart_id': chart.id,
        'chart_type': chartType,
        'data_range': dataRange,
        'title': title,
        'message': 'Chart created successfully',
      };
    } catch (e) {
      return {'success': false, 'error': 'Failed to create chart: $e'};
    }
  }

  /// Update an existing chart
  Future<Map<String, dynamic>> updateChart(Map<String, dynamic> params) async {
    final workbook = server.getActiveWorkbook();
    if (workbook == null) {
      return {'success': false, 'error': 'No active workbook'};
    }

    final sheetName = params['sheet_name'] as String?;
    final chartId = params['chart_id'] as String?;
    final updates = params['updates'] as Map<String, dynamic>?;

    if (sheetName == null || chartId == null || updates == null) {
      return {'success': false, 'error': 'sheet_name, chart_id, and updates are required'};
    }

    try {
      final sheet = workbook.sheets.firstWhere(
        (s) => s.name == sheetName,
        orElse: () => throw Exception('Sheet not found'),
      );

      final chart = sheet.charts.firstWhere(
        (c) => c.id == chartId,
        orElse: () => throw Exception('Chart not found'),
      );

      // Apply updates
      if (updates.containsKey('title')) {
        chart.title = updates['title'] as String;
      }
      if (updates.containsKey('data_range')) {
        chart.dataRange = _parseRange(updates['data_range'] as String);
      }
      if (updates.containsKey('chart_type')) {
        chart.type = _parseChartType(updates['chart_type'] as String);
      }
      if (updates.containsKey('position')) {
        final pos = updates['position'] as Map<String, dynamic>;
        chart.position = ChartPosition(
          row: pos['row'] as int? ?? chart.position.row,
          column: pos['column'] as int? ?? chart.position.column,
          width: (pos['width'] as num?)?.toDouble() ?? chart.position.width,
          height: (pos['height'] as num?)?.toDouble() ?? chart.position.height,
        );
      }
      if (updates.containsKey('show_legend')) {
        chart.showLegend = updates['show_legend'] as bool;
      }
      if (updates.containsKey('show_title')) {
        chart.showTitle = updates['show_title'] as bool;
      }

      return {
        'success': true,
        'chart_id': chartId,
        'message': 'Chart updated successfully',
      };
    } catch (e) {
      return {'success': false, 'error': 'Failed to update chart: $e'};
    }
  }

  /// Delete a chart
  Future<Map<String, dynamic>> deleteChart(Map<String, dynamic> params) async {
    final workbook = server.getActiveWorkbook();
    if (workbook == null) {
      return {'success': false, 'error': 'No active workbook'};
    }

    final sheetName = params['sheet_name'] as String?;
    final chartId = params['chart_id'] as String?;

    if (sheetName == null || chartId == null) {
      return {'success': false, 'error': 'sheet_name and chart_id are required'};
    }

    try {
      final sheet = workbook.sheets.firstWhere(
        (s) => s.name == sheetName,
        orElse: () => throw Exception('Sheet not found'),
      );

      final initialCount = sheet.charts.length;
      sheet.charts.removeWhere((c) => c.id == chartId);

      if (sheet.charts.length == initialCount) {
        return {'success': false, 'error': 'Chart not found'};
      }

      return {
        'success': true,
        'chart_id': chartId,
        'message': 'Chart deleted successfully',
      };
    } catch (e) {
      return {'success': false, 'error': 'Failed to delete chart: $e'};
    }
  }

  /// List all charts in a sheet
  Future<Map<String, dynamic>> listCharts(Map<String, dynamic> params) async {
    final workbook = server.getActiveWorkbook();
    if (workbook == null) {
      return {'success': false, 'error': 'No active workbook'};
    }

    final sheetName = params['sheet_name'] as String?;

    if (sheetName == null) {
      return {'success': false, 'error': 'sheet_name is required'};
    }

    try {
      final sheet = workbook.sheets.firstWhere(
        (s) => s.name == sheetName,
        orElse: () => throw Exception('Sheet not found'),
      );

      final charts = sheet.charts.map((chart) => {
        'id': chart.id,
        'type': chart.type.toString(),
        'title': chart.title,
        'data_range': _formatRange(chart.dataRange),
        'position': {
          'row': chart.position.row,
          'column': chart.position.column,
          'width': chart.position.width,
          'height': chart.position.height,
        },
        'show_legend': chart.showLegend,
        'show_title': chart.showTitle,
      }).toList();

      return {
        'success': true,
        'sheet_name': sheetName,
        'chart_count': charts.length,
        'charts': charts,
      };
    } catch (e) {
      return {'success': false, 'error': 'Failed to list charts: $e'};
    }
  }

  // Helper methods
  ChartType _parseChartType(String typeString) {
    switch (typeString.toLowerCase()) {
      case 'column':
      case 'bar':
        return ChartType.column;
      case 'line':
        return ChartType.line;
      case 'pie':
        return ChartType.pie;
      case 'area':
        return ChartType.area;
      case 'scatter':
        return ChartType.scatter;
      case 'doughnut':
        return ChartType.doughnut;
      case 'radar':
        return ChartType.radar;
      case 'surface':
        return ChartType.surface;
      case 'bubble':
        return ChartType.bubble;
      case 'stock':
        return ChartType.stock;
      default:
        return ChartType.column;
    }
  }

  DataRange _parseRange(String rangeString) {
    // Parse range string like "A1:B10" or "Sheet1!A1:B10"
    String sheetName = '';
    String rangePart = rangeString;
    
    if (rangeString.contains('!')) {
      final parts = rangeString.split('!');
      sheetName = parts[0];
      rangePart = parts[1];
    }
    
    final cellRefs = rangePart.split(':');
    final startRef = _parseCellReference(cellRefs[0]);
    final endRef = cellRefs.length > 1 
        ? _parseCellReference(cellRefs[1])
        : startRef;
    
    return DataRange(
      sheetName: sheetName,
      startRow: startRef.row,
      startColumn: startRef.column,
      endRow: endRef.row,
      endColumn: endRef.column,
    );
  }

  String _formatRange(DataRange range) {
    final startCell = '${_getColumnLetter(range.startColumn)}${range.startRow}';
    final endCell = '${_getColumnLetter(range.endColumn)}${range.endRow}';
    
    if (range.sheetName.isNotEmpty) {
      return '${range.sheetName}!$startCell:$endCell';
    }
    return '$startCell:$endCell';
  }

  CellReference _parseCellReference(String ref) {
    // Parse cell reference like "A1", "B10", "AA100"
    final regex = RegExp(r'^([A-Za-z]+)(\d+)$');
    final match = regex.firstMatch(ref.trim().toUpperCase());
    
    if (match == null) {
      throw FormatException('Invalid cell reference: $ref');
    }
    
    final colLetters = match.group(1)!;
    final rowNum = int.parse(match.group(2)!);
    
    int colNum = 0;
    for (int i = 0; i < colLetters.length; i++) {
      colNum = colNum * 26 + (colLetters.codeUnitAt(i) - 64);
    }
    
    return CellReference(row: rowNum, column: colNum);
  }

  String _getColumnLetter(int column) {
    if (column < 1) throw ArgumentError('Column must be >= 1');
    
    String result = '';
    int col = column - 1;
    
    while (col >= 0) {
      result = String.fromCharCode((col % 26) + 65) + result;
      col = (col ~/ 26) - 1;
    }
    
    return result;
  }
}

// Supporting classes
class ChartPosition {
  int row;
  int column;
  double width;
  double height;

  ChartPosition({
    this.row = 1,
    this.column = 1,
    this.width = 400.0,
    this.height = 300.0,
  });
}

class DataRange {
  String sheetName;
  int startRow;
  int startColumn;
  int endRow;
  int endColumn;

  DataRange({
    this.sheetName = '',
    required this.startRow,
    required this.startColumn,
    required this.endRow,
    required this.endColumn,
  });
}

class CellReference {
  final int row;
  final int column;

  CellReference({required this.row, required this.column});
}
