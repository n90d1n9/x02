/// Pivot Layout for ky_sheet pivot tables.
/// 
/// Manages the arrangement and configuration of fields in a pivot table.
library pivot_layout;

import 'pivot_field.dart';

/// Represents the layout configuration of a pivot table
class PivotLayout {
  /// All fields in the pivot table
  final Map<String, PivotField> _fields = {};
  
  /// Fields in the row area (in order)
  final List<String> _rowFields = [];
  
  /// Fields in the column area (in order)
  final List<String> _columnFields = [];
  
  /// Fields in the values area (in order)
  final List<String> _valueFields = [];
  
  /// Fields in the filter area (in order)
  final List<String> _filterFields = [];
  
  /// Active filters for each field
  final Map<String, List<dynamic>> _activeFilters = {};
  
  /// Create a new pivot layout
  PivotLayout();
  
  /// Get all fields
  Map<String, PivotField> get fields => Map.unmodifiable(_fields);
  
  /// Get row fields
  List<String> get rowFields => List.unmodifiable(_rowFields);
  
  /// Get column fields
  List<String> get columnFields => List.unmodifiable(_columnFields);
  
  /// Get value fields
  List<String> get valueFields => List.unmodifiable(_valueFields);
  
  /// Get filter fields
  List<String> get filterFields => List.unmodifiable(_filterFields);
  
  /// Get a specific field by name
  PivotField? getField(String name) {
    return _fields[name];
  }
  
  /// Add or update a field
  void addField(PivotField field) {
    _fields[field.name] = field;
    
    // Remove from all areas first
    _rowFields.remove(field.name);
    _columnFields.remove(field.name);
    _valueFields.remove(field.name);
    _filterFields.remove(field.name);
    
    // Add to appropriate area based on field.area
    switch (field.area) {
      case FieldArea.rows:
        _rowFields.add(field.name);
        break;
      case FieldArea.columns:
        _columnFields.add(field.name);
        break;
      case FieldArea.values:
        _valueFields.add(field.name);
        break;
      case FieldArea.filters:
        _filterFields.add(field.name);
        break;
    }
  }
  
  /// Remove a field by name
  void removeField(String fieldName) {
    _fields.remove(fieldName);
    _rowFields.remove(fieldName);
    _columnFields.remove(fieldName);
    _valueFields.remove(fieldName);
    _filterFields.remove(fieldName);
    _activeFilters.remove(fieldName);
  }
  
  /// Move a field to a different area
  void moveField(String fieldName, FieldArea newArea) {
    var field = _fields[fieldName];
    if (field == null) return;
    
    field.area = newArea;
    addField(field);
  }
  
  /// Set filter for a field
  void setFieldFilter(String fieldName, List<dynamic> visibleItems) {
    if (visibleItems.isEmpty) {
      _activeFilters.remove(fieldName);
    } else {
      _activeFilters[fieldName] = visibleItems;
    }
  }
  
  /// Get active filter for a field
  List<dynamic>? getActiveFilter(String fieldName) {
    return _activeFilters[fieldName];
  }
  
  /// Clear all filters
  void clearAllFilters() {
    _activeFilters.clear();
  }
  
  /// Reorder fields in an area
  void reorderFields(FieldArea area, List<String> newOrder) {
    List<String> targetList;
    switch (area) {
      case FieldArea.rows:
        targetList = _rowFields;
        break;
      case FieldArea.columns:
        targetList = _columnFields;
        break;
      case FieldArea.values:
        targetList = _valueFields;
        break;
      case FieldArea.filters:
        targetList = _filterFields;
        break;
    }
    
    // Validate that all fields exist
    for (var name in newOrder) {
      if (!_fields.containsKey(name)) {
        throw ArgumentError('Field $name does not exist');
      }
    }
    
    targetList.clear();
    targetList.addAll(newOrder);
  }
  
  /// Get field count in an area
  int getFieldCount(FieldArea area) {
    switch (area) {
      case FieldArea.rows:
        return _rowFields.length;
      case FieldArea.columns:
        return _columnFields.length;
      case FieldArea.values:
        return _valueFields.length;
      case FieldArea.filters:
        return _filterFields.length;
    }
  }
  
  /// Check if layout is valid (has at least one value field)
  bool get isValid => _valueFields.isNotEmpty;
  
  /// Get all value fields as PivotField objects
  List<PivotField> getValueFields() {
    return _valueFields.map((name) => _fields[name]!).toList();
  }
  
  /// Get all row fields as PivotField objects
  List<PivotField> getRowFields() {
    return _rowFields.map((name) => _fields[name]!).toList();
  }
  
  /// Get all column fields as PivotField objects
  List<PivotField> getColumnFields() {
    return _columnFields.map((name) => _fields[name]!).toList();
  }
  
  /// Get all filter fields as PivotField objects
  List<PivotField> getFilterFields() {
    return _filterFields.map((name) => _fields[name]!).toList();
  }
  
  /// Export layout to JSON
  Map<String, dynamic> toJson() {
    return {
      'fields': _fields.map((key, value) => MapEntry(key, value.toJson())),
      'rowFields': _rowFields,
      'columnFields': _columnFields,
      'valueFields': _valueFields,
      'filterFields': _filterFields,
      'activeFilters': _activeFilters.map(
        (key, value) => MapEntry(key, List<dynamic>.from(value)),
      ),
    };
  }
  
  /// Import layout from JSON
  factory PivotLayout.fromJson(Map<String, dynamic> json) {
    var layout = PivotLayout();
    
    // Load fields
    if (json['fields'] != null) {
      var fieldsJson = json['fields'] as Map<String, dynamic>;
      fieldsJson.forEach((name, fieldJson) {
        layout._fields[name] = PivotField.fromJson(fieldJson);
      });
    }
    
    // Load area assignments
    if (json['rowFields'] != null) {
      layout._rowFields.addAll(List<String>.from(json['rowFields']));
    }
    if (json['columnFields'] != null) {
      layout._columnFields.addAll(List<String>.from(json['columnFields']));
    }
    if (json['valueFields'] != null) {
      layout._valueFields.addAll(List<String>.from(json['valueFields']));
    }
    if (json['filterFields'] != null) {
      layout._filterFields.addAll(List<String>.from(json['filterFields']));
    }
    
    // Update field areas based on assignments
    for (var name in layout._rowFields) {
      layout._fields[name]?.area = FieldArea.rows;
    }
    for (var name in layout._columnFields) {
      layout._fields[name]?.area = FieldArea.columns;
    }
    for (var name in layout._valueFields) {
      layout._fields[name]?.area = FieldArea.values;
    }
    for (var name in layout._filterFields) {
      layout._fields[name]?.area = FieldArea.filters;
    }
    
    // Load active filters
    if (json['activeFilters'] != null) {
      var filtersJson = json['activeFilters'] as Map<String, dynamic>;
      filtersJson.forEach((key, value) {
        layout._activeFilters[key] = List<dynamic>.from(value);
      });
    }
    
    return layout;
  }
  
  /// Create a copy of this layout
  PivotLayout clone() {
    return PivotLayout.fromJson(toJson());
  }
}

/// Result of pivot table calculation
class PivotResult {
  /// Column headers (multi-level)
  final List<List<dynamic>> columnHeaders;
  
  /// Row headers (multi-level)
  final List<List<dynamic>> rowHeaders;
  
  /// Data values
  final List<List<dynamic>> data;
  
  /// Width of row header section
  final int rowHeaderWidth;
  
  /// Height of column header section
  final int columnHeaderHeight;
  
  /// Grand totals for rows
  final List<dynamic>? rowGrandTotals;
  
  /// Grand totals for columns
  final List<dynamic>? columnGrandTotals;
  
  /// Create a pivot result
  const PivotResult({
    required this.columnHeaders,
    required this.rowHeaders,
    required this.data,
    required this.rowHeaderWidth,
    required this.columnHeaderHeight,
    this.rowGrandTotals,
    this.columnGrandTotals,
  });
}

/// Represents a calculated value in a pivot table
class PivotValue {
  /// Raw numeric value
  final num rawValue;
  
  /// Display formatted value
  final String displayValue;
  
  /// Formula used to calculate (if any)
  final String? formula;
  
  /// Number format string
  final String? numberFormat;
  
  /// Source data references
  final List<String>? sourceReferences;
  
  /// Create a pivot value
  const PivotValue({
    required this.rawValue,
    required this.displayValue,
    this.formula,
    this.numberFormat,
    this.sourceReferences,
  });
  
  /// Create with formatting
  factory PivotValue.formatted(
    num value,
    String format, {
    String? formula,
  }) {
    var display = _formatNumber(value, format);
    return PivotValue(
      rawValue: value,
      displayValue: display,
      formula: formula,
      numberFormat: format,
    );
  }
  
  /// Format a number according to format string
  static String _formatNumber(num value, String format) {
    // Simplified formatting - in production use intl package
    if (format.contains('%')) {
      return '${(value * 100).toStringAsFixed(2)}%';
    } else if (format.contains('.00')) {
      return value.toStringAsFixed(2);
    } else if (format.contains('.0')) {
      return value.toStringAsFixed(1);
    }
    return value.toString();
  }
}
