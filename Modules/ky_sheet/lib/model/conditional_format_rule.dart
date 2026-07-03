import 'package:flutter/material.dart';

import 'cell/cell_address.dart';
import 'cell/cell_selection.dart';
import 'range.dart';

enum ConditionalFormatCondition {
  greaterThan,
  lessThan,
  equalTo,
  containsText,
  notEmpty,
  between,
  dateOccurring,
  duplicateValues,
  aboveAverage,
  belowAverage,
  topItems,
  bottomItems,
  topPercent,
  bottomPercent,
}

enum ConditionalFormatIconSet {
  directionalArrows,
  trafficLights,
  ratingStars,
  emoticons,
}

enum ConditionalFormatType {
  cellHighlight,
  dataBar,
  colorScale,
  iconSet,
}

class ConditionalFormatRule {
  const ConditionalFormatRule({
    required this.id,
    required this.selection,
    required this.condition,
    this.operand = '',
    required this.backgroundColor,
    required this.textColor,
    this.bold = true,
    this.type = ConditionalFormatType.cellHighlight,
    this.gradient = false,
    this.colors = const [],
    this.iconSet,
  });

  factory ConditionalFormatRule.dataBar({
    required Color color,
    required bool gradient,
    required Range range,
    String? id,
  }) {
    return ConditionalFormatRule(
      id: id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      selection: CellSelection.fromRange(range),
      condition: ConditionalFormatCondition.greaterThan,
      backgroundColor: color,
      textColor: Colors.transparent,
      type: ConditionalFormatType.dataBar,
      gradient: gradient,
      colors: [color],
    );
  }

  factory ConditionalFormatRule.colorScale({
    required List<Color> colors,
    required Range range,
    String? id,
  }) {
    return ConditionalFormatRule(
      id: id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      selection: CellSelection.fromRange(range),
      condition: ConditionalFormatCondition.greaterThan,
      backgroundColor: colors.first,
      textColor: Colors.transparent,
      type: ConditionalFormatType.colorScale,
      colors: colors,
    );
  }

  factory ConditionalFormatRule.iconSet({
    required ConditionalFormatIconSet iconSet,
    required Range range,
    String? id,
  }) {
    return ConditionalFormatRule(
      id: id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      selection: CellSelection.fromRange(range),
      condition: ConditionalFormatCondition.greaterThan,
      backgroundColor: Colors.transparent,
      textColor: Colors.transparent,
      type: ConditionalFormatType.iconSet,
      iconSet: iconSet,
    );
  }

  final String id;
  final CellSelection selection;
  final ConditionalFormatCondition condition;
  final String operand;
  final Color backgroundColor;
  final Color textColor;
  final bool bold;
  final ConditionalFormatType type;
  final bool gradient;
  final List<Color> colors;
  final ConditionalFormatIconSet? iconSet;

  Range toRange() => selection.toRange();

  String get label {
    if (type == ConditionalFormatType.dataBar) {
      return 'Data Bar (${gradient ? "Gradient" : "Solid"})';
    }
    if (type == ConditionalFormatType.colorScale) {
      return 'Color Scale (${colors.length} colors)';
    }
    if (type == ConditionalFormatType.iconSet) {
      return 'Icon Set (${iconSet?.name ?? "Custom"})';
    }
    
    final conditionLabel = switch (condition) {
      ConditionalFormatCondition.greaterThan => '> $operand',
      ConditionalFormatCondition.lessThan => '< $operand',
      ConditionalFormatCondition.equalTo => '= $operand',
      ConditionalFormatCondition.containsText => 'contains "$operand"',
      ConditionalFormatCondition.notEmpty => 'not empty',
      ConditionalFormatCondition.between => 'between $operand',
      ConditionalFormatCondition.dateOccurring => 'date occurring',
      ConditionalFormatCondition.duplicateValues => 'duplicate values',
      ConditionalFormatCondition.aboveAverage => 'above average',
      ConditionalFormatCondition.belowAverage => 'below average',
      ConditionalFormatCondition.topItems => 'top items',
      ConditionalFormatCondition.bottomItems => 'bottom items',
      ConditionalFormatCondition.topPercent => 'top percent',
      ConditionalFormatCondition.bottomPercent => 'bottom percent',
    };
    return '${selection.label} • $conditionLabel';
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'selection': {
      'start': selection.start.toJson(),
      if (selection.end != null) 'end': selection.end!.toJson(),
    },
    'condition': condition.name,
    'operand': operand,
    'backgroundColor': backgroundColor.toARGB32(),
    'textColor': textColor.toARGB32(),
    'bold': bold,
    'type': type.name,
    'gradient': gradient,
    'colors': colors.map((c) => c.toARGB32()).toList(),
    if (iconSet != null) 'iconSet': iconSet!.name,
  };

  factory ConditionalFormatRule.fromJson(Map<String, dynamic> json) {
    final selectionJson = json['selection'] as Map<String, dynamic>;
    final start = CellAddress.fromJson(
      Map<String, dynamic>.from(selectionJson['start']),
    );
    final endJson = selectionJson['end'];

    final colorsJson = json['colors'] as List<dynamic>?;
    final colors = colorsJson
            ?.map((c) => Color(c as int))
            .toList() ??
        [];

    return ConditionalFormatRule(
      id: json['id'],
      selection: CellSelection(
        start,
        endJson == null
            ? null
            : CellAddress.fromJson(Map<String, dynamic>.from(endJson)),
      ),
      condition: ConditionalFormatCondition.values.byName(json['condition']),
      operand: json['operand'] ?? '',
      backgroundColor: Color(json['backgroundColor']),
      textColor: Color(json['textColor']),
      bold: json['bold'] ?? true,
      type: ConditionalFormatType.values.byName(json['type'] ?? 'cellHighlight'),
      gradient: json['gradient'] ?? false,
      colors: colors,
      iconSet: json['iconSet'] != null
          ? ConditionalFormatIconSet.values.byName(json['iconSet'])
          : null,
    );
  }
}
