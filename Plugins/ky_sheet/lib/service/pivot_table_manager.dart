import 'package:flutter/material.dart';

import '../model/sheet_pivot_table.dart';
import '../state/toolbar_provider.dart';

/// Manager service for pivot table operations in Ky Sheet.
class PivotTableManager {
  PivotTableManager(this._controller);

  final ToolbarController _controller;

  /// Creates a new pivot table from the selected range.
  SheetPivotTable createPivotTable({
    required String id,
    required String name,
    required CellSelection sourceSelection,
    CellAddress? targetCell,
    List<PivotField> fields = const [],
  }) {
    return SheetPivotTable(
      id: id,
      name: name,
      sourceSelection: sourceSelection,
      fields: fields,
      targetCell: targetCell,
    );
  }

  /// Adds a field to the pivot table.
  SheetPivotTable addField(
    SheetPivotTable pivotTable,
    PivotField field,
  ) {
    return pivotTable.copyWith(
      fields: [...pivotTable.fields, field],
    );
  }

  /// Removes a field from the pivot table.
  SheetPivotTable removeField(
    SheetPivotTable pivotTable,
    int fieldIndex,
  ) {
    if (fieldIndex < 0 || fieldIndex >= pivotTable.fields.length) {
      return pivotTable;
    }

    final fields = List<PivotField>.from(pivotTable.fields);
    fields.removeAt(fieldIndex);

    return pivotTable.copyWith(fields: fields);
  }

  /// Updates a field in the pivot table.
  SheetPivotTable updateField(
    SheetPivotTable pivotTable,
    int fieldIndex,
    PivotField updatedField,
  ) {
    if (fieldIndex < 0 || fieldIndex >= pivotTable.fields.length) {
      return pivotTable;
    }

    final fields = List<PivotField>.from(pivotTable.fields);
    fields[fieldIndex] = updatedField;

    return pivotTable.copyWith(fields: fields);
  }

  /// Moves a field to a different area.
  SheetPivotTable moveFieldToArea(
    SheetPivotTable pivotTable,
    int fieldIndex,
    PivotArea newArea,
  ) {
    if (fieldIndex < 0 || fieldIndex >= pivotTable.fields.length) {
      return pivotTable;
    }

    final field = pivotTable.fields[fieldIndex];
    final updatedField = field.copyWith(area: newArea);

    return updateField(pivotTable, fieldIndex, updatedField);
  }

  /// Reorders fields within an area.
  SheetPivotTable reorderFields(
    SheetPivotTable pivotTable,
    PivotArea area,
    int oldIndex,
    int newIndex,
  ) {
    final areaFields = pivotTable.getFieldsByArea(area);
    if (oldIndex < 0 ||
        oldIndex >= areaFields.length ||
        newIndex < 0 ||
        newIndex > areaFields.length) {
      return pivotTable;
    }

    // Find the actual index in the full fields list
    var actualOldIndex = -1;
    var count = 0;
    for (var i = 0; i < pivotTable.fields.length; i++) {
      if (pivotTable.fields[i].area == area) {
        if (count == oldIndex) {
          actualOldIndex = i;
          break;
        }
        count++;
      }
    }

    if (actualOldIndex == -1) return pivotTable;

    final fields = List<PivotField>.from(pivotTable.fields);
    final field = fields.removeAt(actualOldIndex);

    // Find the new insertion point
    var insertIndex = actualOldIndex;
    count = 0;
    if (newIndex > oldIndex) {
      for (var i = actualOldIndex; i < fields.length; i++) {
        if (fields[i].area == area) {
          count++;
          if (count == newIndex - oldIndex) {
            insertIndex = i + 1;
            break;
          }
        }
      }
    } else {
      for (var i = actualOldIndex - 1; i >= 0; i--) {
        if (fields[i].area == area) {
          count++;
          if (count == oldIndex - newIndex) {
            insertIndex = i + 1;
            break;
          }
        }
      }
    }

    fields.insert(insertIndex, field);

    return pivotTable.copyWith(fields: fields);
  }

  /// Aggregates a value based on the aggregation type.
  dynamic aggregateValue(
    List<dynamic> values,
    PivotAggregation aggregation,
  ) {
    if (values.isEmpty) {
      return aggregation == PivotAggregation.count ? 0 : null;
    }

    switch (aggregation) {
      case PivotAggregation.sum:
        return values.fold<num>(
          0,
          (prev, val) => prev + (_toNum(val) ?? 0),
        );
      case PivotAggregation.count:
        return values.where((v) => v != null && v.toString().isNotEmpty).length;
      case PivotAggregation.average:
        final nums = values.map(_toNum).whereType<num>().toList();
        if (nums.isEmpty) return null;
        return nums.reduce((a, b) => a + b) / nums.length;
      case PivotAggregation.min:
        final nums = values.map(_toNum).whereType<num>().toList();
        if (nums.isEmpty) return null;
        return nums.reduce((a, b) => a < b ? a : b);
      case PivotAggregation.max:
        final nums = values.map(_toNum).whereType<num>().toList();
        if (nums.isEmpty) return null;
        return nums.reduce((a, b) => a > b ? a : b);
      case PivotAggregation.product:
        return values.fold<num>(
          1,
          (prev, val) => prev * (_toNum(val) ?? 1),
        );
      case PivotAggregation.countNumbers:
        return values.where((v) => _toNum(v) != null).length;
      case PivotAggregation.distinctCount:
        return values.toSet().length;
    }
  }

  /// Converts a value to a number.
  num? _toNum(dynamic value) {
    if (value == null) return null;
    if (value is num) return value;
    if (value is String) {
      try {
        return double.parse(value);
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  /// Gets available columns from the source data.
  List<String> getAvailableColumns(CellSelection sourceSelection) {
    // This would need access to the actual sheet data
    // For now, returns placeholder column names
    final columns = <String>[];
    for (var col = sourceSelection.minCol;
        col <= sourceSelection.maxCol;
        col++) {
      columns.add(_columnIndexToName(col));
    }
    return columns;
  }

  /// Converts column index to Excel-style column name.
  String _columnIndexToName(int col) {
    final letters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    var name = '';
    var n = col;
    while (n >= 0) {
      name = letters[n % 26] + name;
      n = (n ~/ 26) - 1;
    }
    return name;
  }

  /// Refreshes the pivot table calculation.
  void refreshPivotTable(SheetPivotTable pivotTable) {
    // Trigger recalculation of the pivot table
    // This would integrate with the sheet engine to update cells
    _controller.notifyListeners();
  }

  /// Exports pivot table configuration to JSON.
  Map<String, dynamic> exportToJson(SheetPivotTable pivotTable) {
    return pivotTable.toJson();
  }

  /// Imports pivot table configuration from JSON.
  SheetPivotTable importFromJson(Map<String, dynamic> json) {
    return SheetPivotTable.fromJson(json);
  }
}
