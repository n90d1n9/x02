import '../../models/workbook.dart';
import '../../models/worksheet.dart';
import '../../models/cell.dart';
import 'pivot_field.dart';
import 'pivot_cache.dart';
import 'pivot_layout.dart';
import 'pivot_calculator.dart';

/// Represents a Pivot Table in the spreadsheet.
/// 
/// Pivot tables allow users to summarize, analyze, explore, and present
/// summary data from large datasets.
class PivotTable {
  /// Unique identifier for this pivot table
  final String id;
  
  /// Reference to the source worksheet
  final Worksheet sourceSheet;
  
  /// Source data range (e.g., "A1:D100")
  final String sourceRange;
  
  /// Cache containing processed source data
  late PivotCache _cache;
  
  /// Layout configuration for the pivot table
  late PivotLayout _layout;
  
  /// Calculator for aggregating data
  late PivotCalculator _calculator;
  
  /// Destination worksheet for the pivot table
  Worksheet? _destinationSheet;
  
  /// Top-left cell where the pivot table starts
  CellAddress? _destinationCell;
  
  /// Whether the pivot table is auto-sized
  bool autoFitColumns = true;
  
  /// Show/hide grand totals for rows
  bool showRowGrandTotals = true;
  
  /// Show/hide grand totals for columns
  bool showColumnGrandTotals = true;
  
  /// Subtotal position (at top or bottom)
  SubtotalPosition subtotalPosition = SubtotalPosition.bottom;
  
  /// Report layout type
  ReportLayout reportLayout = ReportLayout.compact;
  
  /// Create a new pivot table
  PivotTable({
    required this.id,
    required this.sourceSheet,
    required this.sourceRange,
    Workbook? workbook,
  }) {
    _cache = PivotCache(sourceSheet, sourceRange);
    _layout = PivotLayout();
    _calculator = PivotCalculator(_cache);
    
    // Refresh cache initially
    _cache.refresh();
  }
  
  /// Get the pivot cache
  PivotCache get cache => _cache;
  
  /// Get the pivot layout
  PivotLayout get layout => _layout;
  
  /// Get the pivot calculator
  PivotCalculator get calculator => _calculator;
  
  /// Set the destination for the pivot table output
  void setDestination(Worksheet sheet, CellAddress cell) {
    _destinationSheet = sheet;
    _destinationCell = cell;
  }
  
  /// Add a field to the pivot table
  void addField(PivotField field) {
    _layout.addField(field);
  }
  
  /// Remove a field from the pivot table
  void removeField(String fieldName) {
    _layout.removeField(fieldName);
  }
  
  /// Configure row fields
  void setRowFields(List<String> fieldNames, {SubtotalType? subtotal}) {
    for (var name in fieldNames) {
      var field = _layout.getField(name) ?? PivotField(name: name);
      field.area = FieldArea.rows;
      if (subtotal != null) {
        field.subtotal = subtotal;
      }
      _layout.addField(field);
    }
  }
  
  /// Configure column fields
  void setColumnFields(List<String> fieldNames, {SubtotalType? subtotal}) {
    for (var name in fieldNames) {
      var field = _layout.getField(name) ?? PivotField(name: name);
      field.area = FieldArea.columns;
      if (subtotal != null) {
        field.subtotal = subtotal;
      }
      _layout.addField(field);
    }
  }
  
  /// Configure data/value fields
  void setDataFields(List<DataFieldConfig> configs) {
    for (var config in configs) {
      var field = _layout.getField(config.fieldName) ?? PivotField(name: config.fieldName);
      field.area = FieldArea.values;
      field.aggregation = config.aggregation;
      field.customCalculation = config.customCalculation;
      field.numberFormat = config.numberFormat;
      _layout.addField(field);
    }
  }
  
  /// Configure filter/page fields
  void setFilterFields(List<String> fieldNames) {
    for (var name in fieldNames) {
      var field = _layout.getField(name) ?? PivotField(name: name);
      field.area = FieldArea.filters;
      _layout.addField(field);
    }
  }
  
  /// Apply a filter to a field
  void filterField(String fieldName, List<dynamic> visibleItems) {
    _layout.setFieldFilter(fieldName, visibleItems);
  }
  
  /// Refresh the pivot table data
  void refresh() {
    _cache.refresh();
    _recalculate();
    _render();
  }
  
  /// Recalculate all values
  void _recalculate() {
    _calculator.calculate(_layout);
  }
  
  /// Render the pivot table to the destination sheet
  void render() {
    _recalculate();
    _render();
  }
  
  /// Internal render implementation
  void _render() {
    if (_destinationSheet == null || _destinationCell == null) {
      return;
    }
    
    final result = _calculator.getResult(_layout);
    var startRow = _destinationCell!.row;
    var startCol = _destinationCell!.column;
    
    // Clear previous output
    _clearPreviousOutput();
    
    // Render headers
    _renderHeaders(startRow, startCol, result);
    
    // Render data
    _renderData(startRow, startCol, result);
    
    // Auto-fit columns if enabled
    if (autoFitColumns) {
      _autoFitColumns(startRow, startCol, result);
    }
  }
  
  /// Clear previous pivot table output
  void _clearPreviousOutput() {
    if (_destinationSheet == null || _destinationCell == null) return;
    
    // Get previous size and clear cells
    // Implementation depends on tracking previous dimensions
  }
  
  /// Render pivot table headers
  void _renderHeaders(int startRow, int startCol, PivotResult result) {
    // Render column headers
    for (var i = 0; i < result.columnHeaders.length; i++) {
      for (var j = 0; j < result.columnHeaders[i].length; j++) {
        var cell = _destinationSheet!.cellAt(
          startRow + i,
          startCol + j + result.rowHeaderWidth,
        );
        cell.value = result.columnHeaders[i][j];
        cell.style = cell.style.copyWith(
          fontWeight: FontWeight.bold,
          alignment: Alignment.center,
        );
      }
    }
    
    // Render row headers
    for (var i = 0; i < result.rowHeaders.length; i++) {
      for (var j = 0; j < result.rowHeaders[i].length; j++) {
        var cell = _destinationSheet!.cellAt(
          startRow + i + result.columnHeaderHeight,
          startCol + j,
        );
        cell.value = result.rowHeaders[i][j];
        cell.style = cell.style.copyWith(
          fontWeight: FontWeight.bold,
          alignment: Alignment.left,
        );
      }
    }
  }
  
  /// Render pivot table data cells
  void _renderData(int startRow, int startCol, PivotResult result) {
    for (var i = 0; i < result.data.length; i++) {
      for (var j = 0; j < result.data[i].length; j++) {
        var cell = _destinationSheet!.cellAt(
          startRow + i + result.columnHeaderHeight,
          startCol + j + result.rowHeaderWidth,
        );
        
        var value = result.data[i][j];
        if (value is PivotValue) {
          cell.value = value.rawValue;
          cell.formula = value.formula;
          if (value.numberFormat != null) {
            cell.style = cell.style.copyWith(
              numberFormat: value.numberFormat,
            );
          }
        } else {
          cell.value = value;
        }
      }
    }
  }
  
  /// Auto-fit columns based on content
  void _autoFitColumns(int startRow, int startCol, PivotResult result) {
    final totalCols = result.rowHeaderWidth + result.data[0]?.length ?? 0;
    for (var col = 0; col < totalCols; col++) {
      _destinationSheet?.autoFitColumn(startCol + col);
    }
  }
  
  /// Export pivot table configuration to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sourceSheet': sourceSheet.name,
      'sourceRange': sourceRange,
      'destination': {
        'sheet': _destinationSheet?.name,
        'cell': _destinationCell?.toString(),
      },
      'layout': _layout.toJson(),
      'options': {
        'autoFitColumns': autoFitColumns,
        'showRowGrandTotals': showRowGrandTotals,
        'showColumnGrandTotals': showColumnGrandTotals,
        'subtotalPosition': subtotalPosition.name,
        'reportLayout': reportLayout.name,
      },
    };
  }
  
  /// Import pivot table configuration from JSON
  factory PivotTable.fromJson(
    Map<String, dynamic> json,
    Workbook workbook,
  ) {
    var sourceSheet = workbook.getSheet(json['sourceSheet'])!;
    var pivot = PivotTable(
      id: json['id'],
      sourceSheet: sourceSheet,
      sourceRange: json['sourceRange'],
    );
    
    if (json['destination'] != null) {
      var destSheetName = json['destination']['sheet'];
      var destCellStr = json['destination']['cell'];
      if (destSheetName != null && destCellStr != null) {
        var destSheet = workbook.getSheet(destSheetName);
        if (destSheet != null) {
          pivot.setDestination(destSheet, CellAddress.fromString(destCellStr));
        }
      }
    }
    
    pivot._layout = PivotLayout.fromJson(json['layout']);
    pivot.autoFitColumns = json['options']?['autoFitColumns'] ?? true;
    pivot.showRowGrandTotals = json['options']?['showRowGrandTotals'] ?? true;
    pivot.showColumnGrandTotals = json['options']?['showColumnGrandTotals'] ?? true;
    
    return pivot;
  }
}

/// Configuration for a data field in a pivot table
class DataFieldConfig {
  /// Name of the field
  final String fieldName;
  
  /// Aggregation type (SUM, AVERAGE, COUNT, etc.)
  final AggregationType aggregation;
  
  /// Custom calculation (percent of total, difference from, etc.)
  final CustomCalculation? customCalculation;
  
  /// Number format for display
  final String? numberFormat;
  
  /// Create a data field configuration
  const DataFieldConfig({
    required this.fieldName,
    this.aggregation = AggregationType.sum,
    this.customCalculation,
    this.numberFormat,
  });
  
  /// Create with sum aggregation
  const DataFieldConfig.sum(String fieldName, {String? numberFormat})
      : this(
          fieldName: fieldName,
          aggregation: AggregationType.sum,
          numberFormat: numberFormat,
        );
  
  /// Create with average aggregation
  const DataFieldConfig.average(String fieldName, {String? numberFormat})
      : this(
          fieldName: fieldName,
          aggregation: AggregationType.average,
          numberFormat: numberFormat,
        );
  
  /// Create with count aggregation
  const DataFieldConfig.count(String fieldName)
      : this(
          fieldName: fieldName,
          aggregation: AggregationType.count,
        );
}
