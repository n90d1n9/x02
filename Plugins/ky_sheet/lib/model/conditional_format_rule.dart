import 'package:flutter/material.dart';

import 'cell/cell_address.dart';
import 'cell/cell_selection.dart';

enum ConditionalFormatCondition {
  greaterThan,
  lessThan,
  equalTo,
  containsText,
  notEmpty,
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
  });

  final String id;
  final CellSelection selection;
  final ConditionalFormatCondition condition;
  final String operand;
  final Color backgroundColor;
  final Color textColor;
  final bool bold;

  String get label {
    final conditionLabel = switch (condition) {
      ConditionalFormatCondition.greaterThan => '> $operand',
      ConditionalFormatCondition.lessThan => '< $operand',
      ConditionalFormatCondition.equalTo => '= $operand',
      ConditionalFormatCondition.containsText => 'contains "$operand"',
      ConditionalFormatCondition.notEmpty => 'not empty',
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
  };

  factory ConditionalFormatRule.fromJson(Map<String, dynamic> json) {
    final selectionJson = json['selection'] as Map<String, dynamic>;
    final start = CellAddress.fromJson(
      Map<String, dynamic>.from(selectionJson['start']),
    );
    final endJson = selectionJson['end'];

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
    );
  }
}
