<<<<<<< HEAD:Modules/ky_sheet/lib/model/sheet_pivot_table.dart
import 'package:flutter/material.dart';

=======
>>>>>>> fdcc93050a737f18cc3ba965abd1229d5f2a24f1:Plugins/ky_sheet/lib/model/sheet_pivot_table.dart
import 'cell/cell_address.dart';
import 'cell/cell_selection.dart';
import 'sheet_table.dart';

/// Aggregation functions supported by Ky Sheet pivot tables.
enum PivotAggregation {
  sum,
  count,
  average,
  min,
  max,
  product,
  countNumbers,
  distinctCount,
}

/// Extension providing user-facing labels for aggregation functions.
extension PivotAggregationLabel on PivotAggregation {
  String get label {
    return switch (this) {
      PivotAggregation.sum => 'Sum',
      PivotAggregation.count => 'Count',
      PivotAggregation.average => 'Average',
      PivotAggregation.min => 'Min',
      PivotAggregation.max => 'Max',
      PivotAggregation.product => 'Product',
      PivotAggregation.countNumbers => 'Count Numbers',
      PivotAggregation.distinctCount => 'Distinct Count',
    };
  }

  String get shortLabel {
    return switch (this) {
      PivotAggregation.sum => 'Σ',
      PivotAggregation.count => '#',
      PivotAggregation.average => 'Avg',
      PivotAggregation.min => 'Min',
      PivotAggregation.max => 'Max',
      PivotAggregation.product => '×',
      PivotAggregation.countNumbers => '#Num',
      PivotAggregation.distinctCount => 'D#',
    };
  }
}

/// Layout orientation for pivot table fields.
enum PivotArea {
  rows,
  columns,
<<<<<<< HEAD:Modules/ky_sheet/lib/model/sheet_pivot_table.dart
  data, // Renamed from 'values' since 'values' is a reserved name in enums
=======
  values,
>>>>>>> fdcc93050a737f18cc3ba965abd1229d5f2a24f1:Plugins/ky_sheet/lib/model/sheet_pivot_table.dart
  filters,
}

/// Extension providing user-facing labels for pivot areas.
extension PivotAreaLabel on PivotArea {
  String get label {
    return switch (this) {
      PivotArea.rows => 'Rows',
      PivotArea.columns => 'Columns',
<<<<<<< HEAD:Modules/ky_sheet/lib/model/sheet_pivot_table.dart
      PivotArea.data => 'Values',
=======
      PivotArea.values => 'Values',
>>>>>>> fdcc93050a737f18cc3ba965abd1229d5f2a24f1:Plugins/ky_sheet/lib/model/sheet_pivot_table.dart
      PivotArea.filters => 'Filters',
    };
  }

  IconData get icon {
    return switch (this) {
      PivotArea.rows => Icons.view_list,
      PivotArea.columns => Icons.view_column,
<<<<<<< HEAD:Modules/ky_sheet/lib/model/sheet_pivot_table.dart
      PivotArea.data => Icons.bar_chart,
=======
      PivotArea.values => Icons.bar_chart,
>>>>>>> fdcc93050a737f18cc3ba965abd1229d5f2a24f1:Plugins/ky_sheet/lib/model/sheet_pivot_table.dart
      PivotArea.filters => Icons.filter_list,
    };
  }
}

/// Configuration for a single field in a pivot table.
class PivotField {
  const PivotField({
    required this.sourceColumn,
    required this.area,
    this.aggregation,
    this.showAsPercentage = false,
    this.showAsDifference = false,
    this.baseField,
    this.customName,
  });

  /// Source column name from the data source.
  final String sourceColumn;

  /// Area where this field is placed (rows, columns, values, filters).
  final PivotArea area;

  /// Aggregation function for values area fields.
  final PivotAggregation? aggregation;

  /// Whether to show value as percentage of total/parent.
  final bool showAsPercentage;

  /// Whether to show value as difference from base.
  final bool showAsDifference;

  /// Base field for difference/percentage calculations.
  final String? baseField;

  /// Custom display name for the field.
  final String? customName;

  /// Display name for the field.
  String get displayName => customName ?? sourceColumn;

  /// Creates a copy with selectively updated properties.
  PivotField copyWith({
    String? sourceColumn,
    PivotArea? area,
    PivotAggregation? aggregation,
    bool? showAsPercentage,
    bool? showAsDifference,
    String? baseField,
    String? customName,
  }) {
    return PivotField(
      sourceColumn: sourceColumn ?? this.sourceColumn,
      area: area ?? this.area,
      aggregation: aggregation ?? this.aggregation,
      showAsPercentage: showAsPercentage ?? this.showAsPercentage,
      showAsDifference: showAsDifference ?? this.showAsDifference,
      baseField: baseField ?? this.baseField,
      customName: customName ?? this.customName,
    );
  }

  /// Serializes the field for persistence.
  Map<String, dynamic> toJson() {
    return {
      'sourceColumn': sourceColumn,
      'area': area.name,
      'aggregation': aggregation?.name,
      'showAsPercentage': showAsPercentage,
      'showAsDifference': showAsDifference,
      'baseField': baseField,
      'customName': customName,
    };
  }

  /// Deserializes the field from persistence.
  factory PivotField.fromJson(Map<String, dynamic> json) {
    return PivotField(
      sourceColumn: json['sourceColumn']?.toString() ?? '',
      area: PivotArea.values.firstWhere(
        (a) => a.name == json['area'],
        orElse: () => PivotArea.rows,
      ),
      aggregation: json['aggregation'] != null
          ? PivotAggregation.values.firstWhere(
              (a) => a.name == json['aggregation'],
              orElse: () => PivotAggregation.sum,
            )
          : null,
      showAsPercentage: json['showAsPercentage'] as bool? ?? false,
      showAsDifference: json['showAsDifference'] as bool? ?? false,
      baseField: json['baseField']?.toString(),
      customName: json['customName']?.toString(),
    );
  }
}

/// Metadata for a pivot table in Ky Sheet.
class SheetPivotTable {
  const SheetPivotTable({
    required this.id,
    required this.name,
    required this.sourceSelection,
    required this.fields,
    this.targetCell,
    this.styleId = SheetTableStyleId.prism,
    this.showGrandTotalsRows = true,
    this.showGrandTotalsColumns = true,
    this.showSubtotals = true,
    this.compactLayout = true,
  });

  /// Stable pivot table id for persistence and operations.
  final String id;

  /// User-facing pivot table name.
  final String name;

  /// Source data range for the pivot table.
  final CellSelection sourceSelection;

  /// Fields configured for the pivot table.
  final List<PivotField> fields;

  /// Top-left cell where the pivot table is rendered.
  final CellAddress? targetCell;

  /// Visual style applied to the pivot table.
  final SheetTableStyleId styleId;

  /// Whether to show grand totals for rows.
  final bool showGrandTotalsRows;

  /// Whether to show grand totals for columns.
  final bool showGrandTotalsColumns;

  /// Whether to show subtotals for row groups.
  final bool showSubtotals;

  /// Whether to use compact layout (nested row labels).
  final bool compactLayout;

  /// Gets fields in a specific area.
  List<PivotField> getFieldsByArea(PivotArea area) {
    return fields.where((f) => f.area == area).toList();
  }

  /// Gets row fields.
  List<PivotField> get rowFields => getFieldsByArea(PivotArea.rows);

  /// Gets column fields.
  List<PivotField> get columnFields => getFieldsByArea(PivotArea.columns);

  /// Gets value fields.
<<<<<<< HEAD:Modules/ky_sheet/lib/model/sheet_pivot_table.dart
  List<PivotField> get valueFields => getFieldsByArea(PivotArea.data);
=======
  List<PivotField> get valueFields => getFieldsByArea(PivotArea.values);
>>>>>>> fdcc93050a737f18cc3ba965abd1229d5f2a24f1:Plugins/ky_sheet/lib/model/sheet_pivot_table.dart

  /// Gets filter fields.
  List<PivotField> get filterFields => getFieldsByArea(PivotArea.filters);

  /// Creates a copy with selectively updated properties.
  SheetPivotTable copyWith({
    String? id,
    String? name,
    CellSelection? sourceSelection,
    List<PivotField>? fields,
    CellAddress? targetCell,
    SheetTableStyleId? styleId,
    bool? showGrandTotalsRows,
    bool? showGrandTotalsColumns,
    bool? showSubtotals,
    bool? compactLayout,
  }) {
    return SheetPivotTable(
      id: id ?? this.id,
      name: name ?? this.name,
      sourceSelection: sourceSelection ?? this.sourceSelection,
      fields: fields ?? this.fields,
      targetCell: targetCell ?? this.targetCell,
      styleId: styleId ?? this.styleId,
      showGrandTotalsRows: showGrandTotalsRows ?? this.showGrandTotalsRows,
      showGrandTotalsColumns:
          showGrandTotalsColumns ?? this.showGrandTotalsColumns,
      showSubtotals: showSubtotals ?? this.showSubtotals,
      compactLayout: compactLayout ?? this.compactLayout,
    );
  }

  /// Serializes the pivot table for persistence.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'sourceSelection': {
        'start': sourceSelection.start.toJson(),
        'end': (sourceSelection.end ?? sourceSelection.start).toJson(),
      },
      'fields': fields.map((f) => f.toJson()).toList(),
      'targetCell': targetCell?.toJson(),
      'styleId': styleId.name,
      'showGrandTotalsRows': showGrandTotalsRows,
      'showGrandTotalsColumns': showGrandTotalsColumns,
      'showSubtotals': showSubtotals,
      'compactLayout': compactLayout,
    };
  }

  /// Deserializes the pivot table from persistence.
  factory SheetPivotTable.fromJson(Map<String, dynamic> json) {
    final selectionJson = json['sourceSelection'];
    final selection = selectionJson is Map
        ? Map<String, dynamic>.from(selectionJson)
        : const <String, dynamic>{};
    final startJson = selection['start'];
    final endJson = selection['end'];
    final start = startJson is Map
        ? CellAddress.fromJson(Map<String, dynamic>.from(startJson))
        : CellAddress(0, 0);
    final end = endJson is Map
        ? CellAddress.fromJson(Map<String, dynamic>.from(endJson))
        : start;

    final targetCellJson = json['targetCell'];
    final targetCell = targetCellJson is Map
        ? CellAddress.fromJson(Map<String, dynamic>.from(targetCellJson))
        : null;

    final fieldsJson = json['fields'];
    final fields = fieldsJson is List
        ? fieldsJson
<<<<<<< HEAD:Modules/ky_sheet/lib/model/sheet_pivot_table.dart
              .whereType<Map>()
              .map((f) => PivotField.fromJson(Map<String, dynamic>.from(f)))
              .toList()
=======
            .whereType<Map>()
            .map((f) => PivotField.fromJson(Map<String, dynamic>.from(f)))
            .toList()
>>>>>>> fdcc93050a737f18cc3ba965abd1229d5f2a24f1:Plugins/ky_sheet/lib/model/sheet_pivot_table.dart
        : <PivotField>[];

    return SheetPivotTable(
      id: json['id']?.toString() ?? 'pivot',
      name: json['name']?.toString() ?? 'PivotTable',
      sourceSelection: CellSelection(start, end),
      fields: fields,
      targetCell: targetCell,
      styleId: SheetTableStyleId.values.firstWhere(
        (s) => s.name == json['styleId'],
        orElse: () => SheetTableStyleId.prism,
      ),
      showGrandTotalsRows: json['showGrandTotalsRows'] as bool? ?? true,
      showGrandTotalsColumns: json['showGrandTotalsColumns'] as bool? ?? true,
      showSubtotals: json['showSubtotals'] as bool? ?? true,
      compactLayout: json['compactLayout'] as bool? ?? true,
    );
  }
}
