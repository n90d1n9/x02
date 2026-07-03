/// Pivot Calculator for ky_sheet pivot tables.
/// 
/// Performs aggregations and calculations for pivot table data.
library pivot_calculator;

import 'dart:math' as math;
import 'pivot_cache.dart';
import 'pivot_field.dart';
import 'pivot_layout.dart';

/// Calculates pivot table values based on layout and cached data
class PivotCalculator {
  /// Source data cache
  final PivotCache _cache;
  
  /// Last calculation timestamp
  DateTime? _lastCalculated;
  
  /// Create a new pivot calculator
  PivotCalculator(this._cache);
  
  /// Get last calculation time
  DateTime? get lastCalculated => _lastCalculated;
  
  /// Calculate pivot table values based on layout
  PivotResult calculate(PivotLayout layout) {
    if (!layout.isValid) {
      throw StateError('Pivot layout must have at least one value field');
    }
    
    // Get filtered data
    var filteredData = _getFilteredData(layout);
    
    // Build row and column structures
    var rowStructure = _buildRowStructure(filteredData, layout);
    var columnStructure = _buildColumnStructure(filteredData, layout);
    
    // Calculate data cells
    var dataCells = _calculateDataCells(
      filteredData,
      layout,
      rowStructure,
      columnStructure,
    );
    
    // Calculate grand totals
    var rowGrandTotals = layout.showRowGrandTotals
        ? _calculateRowGrandTotals(dataCells, layout)
        : null;
    var columnGrandTotals = layout.showColumnGrandTotals
        ? _calculateColumnGrandTotals(dataCells, layout)
        : null;
    
    _lastCalculated = DateTime.now();
    
    return PivotResult(
      columnHeaders: columnStructure.headers,
      rowHeaders: rowStructure.headers,
      data: dataCells,
      rowHeaderWidth: rowStructure.width,
      columnHeaderHeight: columnStructure.height,
      rowGrandTotals: rowGrandTotals,
      columnGrandTotals: columnGrandTotals,
    );
  }
  
  /// Get result (alias for calculate)
  PivotResult getResult(PivotLayout layout) {
    return calculate(layout);
  }
  
  /// Apply filters from layout to get filtered dataset
  List<List<dynamic>> _getFilteredData(PivotLayout layout) {
    var includeFilters = <String, List<dynamic>>{};
    var excludeFilters = <String, List<dynamic>>{};
    
    // Process filter fields
    for (var fieldName in layout.filterFields) {
      var filter = layout.getActiveFilter(fieldName);
      if (filter != null && filter.isNotEmpty) {
        includeFilters[fieldName] = filter;
      }
    }
    
    // Process field-level filters
    for (var field in layout.fields.values) {
      if (field.includedItems != null && field.includedItems!.isNotEmpty) {
        includeFilters[field.name] = field.includedItems!;
      }
      if (field.excludedItems != null && field.excludedItems!.isNotEmpty) {
        excludeFilters[field.name] = field.excludedItems!;
      }
    }
    
    return _cache.getFilteredData(
      includeFilters: includeFilters.isEmpty ? null : includeFilters,
      excludeFilters: excludeFilters.isEmpty ? null : excludeFilters,
    );
  }
  
  /// Build row header structure
  _RowStructure _buildRowStructure(
    List<List<dynamic>> data,
    PivotLayout layout,
  ) {
    var rowFieldNames = layout.rowFields;
    if (rowFieldNames.isEmpty) {
      return _RowStructure(headers: [[]], width: 0);
    }
    
    // Get field indices
    var fieldIndices = <int>[];
    for (var name in rowFieldNames) {
      var index = _cache.getFieldIndex(name);
      if (index != null) {
        fieldIndices.add(index);
      }
    }
    
    // Group data by row fields
    var groups = _groupData(data, fieldIndices, layout);
    
    // Build headers
    var headers = <List<dynamic>>[];
    var width = rowFieldNames.length;
    
    // Create header rows based on unique combinations
    var seen = <String>{};
    var uniqueRows = <List<dynamic>>[];
    
    for (var entry in groups.entries) {
      var key = entry.key;
      if (!seen.contains(key)) {
        seen.add(key);
        uniqueRows.add(key);
      }
    }
    
    // Format headers for display
    for (var i = 0; i < width; i++) {
      var headerRow = <dynamic>[];
      for (var rowKey in uniqueRows) {
        if (i < rowKey.length) {
          headerRow.add(rowKey[i]);
        } else {
          headerRow.add(null);
        }
      }
      headers.add(headerRow);
    }
    
    return _RowStructure(headers: headers, width: width);
  }
  
  /// Build column header structure
  _ColumnStructure _buildColumnStructure(
    List<List<dynamic>> data,
    PivotLayout layout,
  ) {
    var colFieldNames = layout.columnFields;
    if (colFieldNames.isEmpty) {
      return _ColumnStructure(headers: [[]], height: 0);
    }
    
    // Get field indices
    var fieldIndices = <int>[];
    for (var name in colFieldNames) {
      var index = _cache.getFieldIndex(name);
      if (index != null) {
        fieldIndices.add(index);
      }
    }
    
    // Group data by column fields
    var groups = _groupData(data, fieldIndices, layout);
    
    // Build headers
    var headers = <List<dynamic>>[];
    var height = colFieldNames.length;
    
    // Create unique column combinations
    var seen = <String>{};
    var uniqueCols = <List<dynamic>>[];
    
    for (var entry in groups.entries) {
      var key = entry.key;
      if (!seen.contains(key)) {
        seen.add(key);
        uniqueCols.add(key);
      }
    }
    
    // Format headers for display
    for (var i = 0; i < height; i++) {
      var headerRow = <dynamic>[];
      for (var colKey in uniqueCols) {
        if (i < colKey.length) {
          headerRow.add(colKey[i]);
        } else {
          headerRow.add(null);
        }
      }
      headers.add(headerRow);
    }
    
    return _ColumnStructure(headers: headers, height: height);
  }
  
  /// Group data by specified field indices
  Map<String, Map<List<dynamic>, List<List<dynamic>>>> _groupData(
    List<List<dynamic>> data,
    List<int> fieldIndices,
    PivotLayout layout,
  ) {
    var groups = <String, Map<List<dynamic>, List<List<dynamic>>>>{};
    
    for (var row in data) {
      // Extract key values
      var keyValues = <dynamic>[];
      for (var index in fieldIndices) {
        if (index < row.length) {
          keyValues.add(row[index]);
        } else {
          keyValues.add(null);
        }
      }
      
      // Create string key for grouping
      var key = keyValues.map((v) => v?.toString() ?? '').join('|');
      
      groups.putIfAbsent(key, () => []).add(row);
    }
    
    return groups;
  }
  
  /// Calculate all data cells
  List<List<PivotValue>> _calculateDataCells(
    List<List<dynamic>> data,
    PivotLayout layout,
    _RowStructure rowStructure,
    _ColumnStructure columnStructure,
  ) {
    var result = <List<PivotValue>>[];
    var valueFields = layout.getValueFields();
    
    // For each row combination
    // (simplified - in full implementation would iterate through row groups)
    var rowData = <PivotValue>[];
    
    // For each column combination
    for (var colIdx = 0; colIdx < (columnStructure.headers.isNotEmpty ? columnStructure.headers[0].length : 1); colIdx++) {
      // For each value field
      for (var valueField in valueFields) {
        var value = _aggregateValue(
          data,
          valueField,
          layout,
        );
        rowData.add(value);
      }
    }
    
    if (rowData.isNotEmpty) {
      result.add(rowData);
    }
    
    return result;
  }
  
  /// Aggregate value for a specific field
  PivotValue _aggregateValue(
    List<List<dynamic>> data,
    PivotField field,
    PivotLayout layout,
  ) {
    var fieldIndex = _cache.getFieldIndex(field.name);
    if (fieldIndex == null) {
      return const PivotValue(rawValue: 0, displayValue: '0');
    }
    
    // Extract values for this field
    var values = <num>[];
    for (var row in data) {
      if (fieldIndex < row.length) {
        var value = row[fieldIndex];
        if (value is num) {
          values.add(value);
        } else if (value != null) {
          var parsed = num.tryParse(value.toString());
          if (parsed != null) {
            values.add(parsed);
          }
        }
      }
    }
    
    // Apply aggregation
    num result = 0;
    switch (field.aggregation) {
      case AggregationType.sum:
        result = values.fold(0, (a, b) => a + b);
        break;
      case AggregationType.count:
        result = values.length.toDouble();
        break;
      case AggregationType.average:
        result = values.isEmpty ? 0 : values.reduce((a, b) => a + b) / values.length;
        break;
      case AggregationType.max:
        result = values.isEmpty ? 0 : values.reduce(math.max);
        break;
      case AggregationType.min:
        result = values.isEmpty ? 0 : values.reduce(math.min);
        break;
      case AggregationType.product:
        result = values.fold(1, (a, b) => a * b);
        break;
      case AggregationType.countA:
        result = data.where((row) => 
          fieldIndex < row.length && row[fieldIndex] != null
        ).length.toDouble();
        break;
      case AggregationType.stdev:
        result = _calculateStdev(values, sample: true);
        break;
      case AggregationType.stdevP:
        result = _calculateStdev(values, sample: false);
        break;
      case AggregationType.var:
        var stdev = _calculateStdev(values, sample: true);
        result = stdev * stdev;
        break;
      case AggregationType.varP:
        var stdev = _calculateStdev(values, sample: false);
        result = stdev * stdev;
        break;
    }
    
    // Apply custom calculation if specified
    if (field.customCalculation != null) {
      result = _applyCustomCalculation(result, field, data, layout);
    }
    
    // Format the result
    var format = field.numberFormat ?? '#,##0.00';
    return PivotValue.formatted(result, format);
  }
  
  /// Calculate standard deviation
  double _calculateStdev(List<num> values, {bool sample = true}) {
    if (values.length < 2) return 0;
    
    var mean = values.reduce((a, b) => a + b) / values.length;
    var variance = values.fold<double>(
      0,
      (sum, value) => sum + math.pow(value - mean, 2) as double,
    );
    
    if (sample) {
      variance /= (values.length - 1);
    } else {
      variance /= values.length;
    }
    
    return math.sqrt(variance);
  }
  
  /// Apply custom calculation
  num _applyCustomCalculation(
    num value,
    PivotField field,
    List<List<dynamic>> data,
    PivotLayout layout,
  ) {
    switch (field.customCalculation) {
      case CustomCalculation.none:
        return value;
      case CustomCalculation.percentOfRowTotal:
        // Would need row total context
        return value;
      case CustomCalculation.percentOfColumnTotal:
        // Would need column total context
        return value;
      case CustomCalculation.percentOfGrandTotal:
        // Would need grand total context
        return value;
      case CustomCalculation.runningTotalIn:
        // Would need running total context
        return value;
      default:
        return value;
    }
  }
  
  /// Calculate row grand totals
  List<dynamic>? _calculateRowGrandTotals(
    List<List<PivotValue>> data,
    PivotLayout layout,
  ) {
    if (data.isEmpty) return null;
    
    var totals = <dynamic>[];
    var numCols = data.first.length;
    
    for (var col = 0; col < numCols; col++) {
      var sum = 0.0;
      for (var row in data) {
        if (col < row.length) {
          sum += row[col].rawValue;
        }
      }
      totals.add(sum);
    }
    
    return totals;
  }
  
  /// Calculate column grand totals
  List<dynamic>? _calculateColumnGrandTotals(
    List<List<PivotValue>> data,
    PivotLayout layout,
  ) {
    if (data.isEmpty) return null;
    
    var totals = <dynamic>[];
    for (var row in data) {
      var sum = 0.0;
      for (var cell in row) {
        sum += cell.rawValue;
      }
      totals.add(sum);
    }
    
    return totals;
  }
}

/// Internal structure for row headers
class _RowStructure {
  final List<List<dynamic>> headers;
  final int width;
  
  const _RowStructure({required this.headers, required this.width});
}

/// Internal structure for column headers
class _ColumnStructure {
  final List<List<dynamic>> headers;
  final int height;
  
  const _ColumnStructure({required this.headers, required this.height});
}
