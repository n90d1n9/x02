/// Pivot Cache for ky_sheet pivot tables.
/// 
/// Caches and processes source data for efficient pivot table calculations.
library pivot_cache;

import '../../models/worksheet.dart';
import '../../models/range.dart';
import 'pivot_field.dart';

/// Represents cached data from the source range
class PivotCache {
  /// Source worksheet reference
  final Worksheet _sourceSheet;
  
  /// Source data range address
  final String _sourceRange;
  
  /// Cached column headers
  List<String> _headers = [];
  
  /// Cached data rows
  List<List<dynamic>> _data = [];
  
  /// Field index mapping (field name -> column index)
  Map<String, int> _fieldIndexMap = {};
  
  /// Last refresh timestamp
  DateTime? _lastRefreshed;
  
  /// Whether cache is valid
  bool _isValid = false;
  
  /// Create a new pivot cache
  PivotCache(this._sourceSheet, this._sourceRange);
  
  /// Get the headers
  List<String> get headers => List.unmodifiable(_headers);
  
  /// Get the data rows
  List<List<dynamic>> get data => List.unmodifiable(_data);
  
  /// Get field index by name
  int? getFieldIndex(String fieldName) {
    return _fieldIndexMap[fieldName];
  }
  
  /// Get all field names
  List<String> getFieldNames() {
    return List.from(_fieldIndexMap.keys);
  }
  
  /// Get last refresh time
  DateTime? get lastRefreshed => _lastRefreshed;
  
  /// Check if cache is valid
  bool get isValid => _isValid;
  
  /// Get row count
  int get rowCount => _data.length;
  
  /// Get column count
  int get columnCount => _headers.length;
  
  /// Refresh the cache from source data
  void refresh() {
    try {
      final range = RangeAddress.fromString(_sourceRange);
      _loadData(range);
      _isValid = true;
      _lastRefreshed = DateTime.now();
    } catch (e) {
      _isValid = false;
      rethrow;
    }
  }
  
  /// Load data from the source range
  void _loadData(RangeAddress range) {
    _headers.clear();
    _data.clear();
    _fieldIndexMap.clear();
    
    // Read header row
    var headerRow = range.start.row;
    for (var col = range.start.column; col <= range.end.column; col++) {
      var cell = _sourceSheet.cellAt(headerRow, col);
      var headerName = cell.value?.toString() ?? 'Column $col';
      _headers.add(headerName);
      _fieldIndexMap[headerName] = col - range.start.column;
    }
    
    // Read data rows
    for (var row = range.start.row + 1; row <= range.end.row; row++) {
      var rowData = <dynamic>[];
      var hasData = false;
      
      for (var col = range.start.column; col <= range.end.column; col++) {
        var cell = _sourceSheet.cellAt(row, col);
        var value = cell.value;
        rowData.add(value);
        
        if (value != null && value.toString().isNotEmpty) {
          hasData = true;
        }
      }
      
      // Only include rows with data
      if (hasData) {
        _data.add(rowData);
      }
    }
  }
  
  /// Get distinct values for a field
  List<dynamic> getDistinctValues(String fieldName) {
    var index = _fieldIndexMap[fieldName];
    if (index == null || index >= _headers.length) {
      return [];
    }
    
    var values = <dynamic>{};
    for (var row in _data) {
      if (index < row.length) {
        var value = row[index];
        if (value != null && value.toString().isNotEmpty) {
          values.add(value);
        }
      }
    }
    
    return values.toList();
  }
  
  /// Get filtered data based on field filters
  List<List<dynamic>> getFilteredData({
    Map<String, List<dynamic>>? includeFilters,
    Map<String, List<dynamic>>? excludeFilters,
  }) {
    if (includeFilters == null && excludeFilters == null) {
      return _data;
    }
    
    return _data.where((row) {
      // Check include filters
      if (includeFilters != null) {
        for (var entry in includeFilters.entries) {
          var index = _fieldIndexMap[entry.key];
          if (index == null || index >= row.length) continue;
          
          var value = row[index];
          if (!entry.value.contains(value)) {
            return false;
          }
        }
      }
      
      // Check exclude filters
      if (excludeFilters != null) {
        for (var entry in excludeFilters.entries) {
          var index = _fieldIndexMap[entry.key];
          if (index == null || index >= row.length) continue;
          
          var value = row[index];
          if (entry.value.contains(value)) {
            return false;
          }
        }
      }
      
      return true;
    }).toList();
  }
  
  /// Get grouped data by a field
  Map<dynamic, List<List<dynamic>>> groupByField(
    String fieldName, {
    FieldGrouping? grouping,
  }) {
    var index = _fieldIndexMap[fieldName];
    if (index == null) {
      return {};
    }
    
    var groups = <dynamic, List<List<dynamic>>>{};
    
    for (var row in _data) {
      if (index >= row.length) continue;
      
      var key = row[index];
      
      // Apply grouping if specified
      if (grouping != null) {
        key = _applyGrouping(key, grouping);
      }
      
      if (key == null) continue;
      
      groups.putIfAbsent(key, () => []).add(row);
    }
    
    return groups;
  }
  
  /// Apply grouping to a value
  dynamic _applyGrouping(dynamic value, FieldGrouping grouping) {
    if (value == null) return null;
    
    if (grouping.type == GroupingType.date && value is DateTime) {
      switch (grouping.dateInterval) {
        case DateGroupInterval.years:
          return DateTime(value.year);
        case DateGroupInterval.quarters:
          return '${value.year}-Q${(value.month - 1) ~/ 3 + 1}';
        case DateGroupInterval.months:
          return DateTime(value.year, value.month);
        case DateGroupInterval.days:
          return DateTime(value.year, value.month, value.day);
        case DateGroupInterval.hours:
          return value.hour;
        case DateGroupInterval.minutes:
          return value.minute;
        case DateGroupInterval.seconds:
          return value.second;
        case null:
          return value;
      }
    } else if (grouping.type == GroupingType.numeric && value is num) {
      if (grouping.start != null && grouping.step != null) {
        var bucket = ((value - grouping.start!) / grouping.step!).floor();
        var groupStart = grouping.start! + bucket * grouping.step!;
        return '$groupStart-${groupStart + grouping.step!}';
      }
      return value;
    }
    
    return value;
  }
  
  /// Get numeric values for a field
  List<num> getNumericValues(String fieldName) {
    var index = _fieldIndexMap[fieldName];
    if (index == null) {
      return [];
    }
    
    var values = <num>[];
    for (var row in _data) {
      if (index < row.length) {
        var value = row[index];
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
    
    return values;
  }
  
  /// Get date values for a field
  List<DateTime> getDateValues(String fieldName) {
    var index = _fieldIndexMap[fieldName];
    if (index == null) {
      return [];
    }
    
    var values = <DateTime>[];
    for (var row in _data) {
      if (index < row.length) {
        var value = row[index];
        if (value is DateTime) {
          values.add(value);
        } else if (value != null) {
          var parsed = DateTime.tryParse(value.toString());
          if (parsed != null) {
            values.add(parsed);
          }
        }
      }
    }
    
    return values;
  }
  
  /// Export cache to JSON
  Map<String, dynamic> toJson() {
    return {
      'sourceRange': _sourceRange,
      'headers': _headers,
      'data': _data,
      'fieldIndexMap': _fieldIndexMap,
      'lastRefreshed': _lastRefreshed?.toIso8601String(),
      'isValid': _isValid,
    };
  }
  
  /// Import cache from JSON
  factory PivotCache.fromJson(
    Map<String, dynamic> json,
    Worksheet sourceSheet,
  ) {
    var cache = PivotCache(sourceSheet, json['sourceRange']);
    cache._headers = List<String>.from(json['headers'] ?? []);
    cache._data = List<List<dynamic>>.from(
      (json['data'] as List?)?.map((e) => List<dynamic>.from(e)) ?? [],
    );
    cache._fieldIndexMap = Map<String, int>.from(json['fieldIndexMap'] ?? {});
    
    if (json['lastRefreshed'] != null) {
      cache._lastRefreshed = DateTime.parse(json['lastRefreshed']);
    }
    cache._isValid = json['isValid'] ?? false;
    
    return cache;
  }
}
