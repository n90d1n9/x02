/// Conditional Formatting Rule Models
<<<<<<< HEAD:Modules/ky_sheet/lib/model/conditional_formatting_rule.dart
///
=======
/// 
>>>>>>> fdcc93050a737f18cc3ba965abd1229d5f2a24f1:Plugins/ky_sheet/lib/model/conditional_formatting_rule.dart
/// Defines the data structures for conditional formatting rules similar to Excel/GSheet.
/// Supports various rule types: cell value, formula, top/bottom, data bars, color scales, icon sets.

import 'dart:convert';
import 'package:flutter/material.dart';

/// Types of conditional formatting rules
enum ConditionalFormattingRuleType {
<<<<<<< HEAD:Modules/ky_sheet/lib/model/conditional_formatting_rule.dart
  cellValue, // Based on cell value comparison
  formula, // Based on custom formula evaluation
  topBottom, // Top/Bottom N items or percentage
  dataBar, // Gradient or solid fill data bars
  colorScale, // 2 or 3 color gradient scale
  iconSet, // Directional arrows, traffic lights, etc.
  duplicateValues, // Highlight duplicate or unique values
  textContains, // Text contains specific string
  dateOccurring, // Dates occurring in specific period
  blankErrors, // Cells that are blank or contain errors
=======
  cellValue,        // Based on cell value comparison
  formula,          // Based on custom formula evaluation
  topBottom,        // Top/Bottom N items or percentage
  dataBar,          // Gradient or solid fill data bars
  colorScale,       // 2 or 3 color gradient scale
  iconSet,          // Directional arrows, traffic lights, etc.
  duplicateValues,  // Highlight duplicate or unique values
  textContains,     // Text contains specific string
  dateOccurring,    // Dates occurring in specific period
  blankErrors,      // Cells that are blank or contain errors
>>>>>>> fdcc93050a737f18cc3ba965abd1229d5f2a24f1:Plugins/ky_sheet/lib/model/conditional_formatting_rule.dart
}

/// Comparison operators for cell value rules
enum ComparisonOperator {
  between,
  notBetween,
  equal,
  notEqual,
  greaterThan,
  lessThan,
  greaterThanOrEqual,
  lessThanOrEqual,
}

/// Position for top/bottom rules
<<<<<<< HEAD:Modules/ky_sheet/lib/model/conditional_formatting_rule.dart
enum TopBottomPosition { top, bottom }

/// Type for top/bottom rules (items or percentage)
enum TopBottomType { items, percent }

/// Data bar direction
enum DataBarDirection { leftToRight, rightToLeft }
=======
enum TopBottomPosition {
  top,
  bottom,
}

/// Type for top/bottom rules (items or percentage)
enum TopBottomType {
  items,
  percent,
}

/// Data bar direction
enum DataBarDirection {
  leftToRight,
  rightToLeft,
}
>>>>>>> fdcc93050a737f18cc3ba965abd1229d5f2a24f1:Plugins/ky_sheet/lib/model/conditional_formatting_rule.dart

/// Icon set types
enum IconSetType {
  threeArrows,
  threeArrowsColored,
  fourArrows,
  fourArrowsColored,
  fiveArrows,
  fiveArrowsColored,
  threeTrafficLights,
  threeTrafficLightsRimmed,
  fourTrafficLights,
  fiveRating,
  fourRating,
  threeSymbols,
  threeSymbolsCircled,
}

/// Base class for conditional formatting rules
abstract class ConditionalFormattingRule {
  final String id;
  final ConditionalFormattingRuleType type;
<<<<<<< HEAD:Modules/ky_sheet/lib/model/conditional_formatting_rule.dart
  final bool? stopIfTrue; // If true, stop processing further rules
=======
  final String? stopIfTrue; // If true, stop processing further rules
>>>>>>> fdcc93050a737f18cc3ba965abd1229d5f2a24f1:Plugins/ky_sheet/lib/model/conditional_formatting_rule.dart
  final Color? fillColor;
  final Color? fontColor;
  final FontWeight? fontWeight;
  final FontStyle? fontStyle;
  final bool? underline;
  final bool? strikethrough;
  final String? priority; // Higher priority rules apply first

  ConditionalFormattingRule({
    required this.id,
    required this.type,
    this.stopIfTrue = false,
    this.fillColor,
    this.fontColor,
    this.fontWeight,
    this.fontStyle,
    this.underline,
    this.strikethrough,
    this.priority,
  });

  /// Evaluate if the rule applies to a given cell value
  bool evaluate(dynamic cellValue, EvaluationContext context);

  /// Apply formatting to a cell style
  CellStyle applyFormat(CellStyle style);

  /// Serialize rule to JSON
  Map<String, dynamic> toJson();

  /// Create rule from JSON
  factory ConditionalFormattingRule.fromJson(Map<String, dynamic> json) {
    final typeStr = json['type'] as String;
    final type = ConditionalFormattingRuleType.values.firstWhere(
      (e) => e.name == typeStr,
      orElse: () => ConditionalFormattingRuleType.cellValue,
    );

    switch (type) {
      case ConditionalFormattingRuleType.cellValue:
        return CellValueRule.fromJson(json);
      case ConditionalFormattingRuleType.formula:
        return FormulaRule.fromJson(json);
      case ConditionalFormattingRuleType.topBottom:
        return TopBottomRule.fromJson(json);
      case ConditionalFormattingRuleType.dataBar:
        return DataBarRule.fromJson(json);
      case ConditionalFormattingRuleType.colorScale:
        return ColorScaleRule.fromJson(json);
      case ConditionalFormattingRuleType.iconSet:
        return IconSetRule.fromJson(json);
      case ConditionalFormattingRuleType.duplicateValues:
        return DuplicateValueRule.fromJson(json);
      case ConditionalFormattingRuleType.textContains:
        return TextContainsRule.fromJson(json);
      case ConditionalFormattingRuleType.dateOccurring:
        return DateOccurringRule.fromJson(json);
      case ConditionalFormattingRuleType.blankErrors:
        return BlankErrorRule.fromJson(json);
    }
  }
}

/// Context for rule evaluation
class EvaluationContext {
  final dynamic cellValue;
  final String cellAddress;
  final String sheetName;
  final List<dynamic>? rangeValues; // All values in the formatted range
  final int? rank; // Rank of current value in range
  final int? totalCount; // Total count of values in range
<<<<<<< HEAD:Modules/ky_sheet/lib/model/conditional_formatting_rule.dart
  final Function(String address)?
  getCellValue; // Function to get other cell values
=======
  final Function(String address)? getCellValue; // Function to get other cell values
>>>>>>> fdcc93050a737f18cc3ba965abd1229d5f2a24f1:Plugins/ky_sheet/lib/model/conditional_formatting_rule.dart

  EvaluationContext({
    required this.cellValue,
    required this.cellAddress,
    required this.sheetName,
    this.rangeValues,
    this.rank,
    this.totalCount,
    this.getCellValue,
  });
}

/// Simple cell style for formatting
class CellStyle {
  Color? fillColor;
  Color? fontColor;
  FontWeight? fontWeight;
  FontStyle? fontStyle;
  bool? underline;
  bool? strikethrough;
  String? numberFormat;
  double? fontSize;
  String? fontFamily;

  CellStyle({
    this.fillColor,
    this.fontColor,
    this.fontWeight,
    this.fontStyle,
    this.underline,
    this.strikethrough,
    this.numberFormat,
    this.fontSize,
    this.fontFamily,
  });

  CellStyle copyWith({
    Color? fillColor,
    Color? fontColor,
    FontWeight? fontWeight,
    FontStyle? fontStyle,
    bool? underline,
    bool? strikethrough,
    String? numberFormat,
    double? fontSize,
    String? fontFamily,
  }) {
    return CellStyle(
      fillColor: fillColor ?? this.fillColor,
      fontColor: fontColor ?? this.fontColor,
      fontWeight: fontWeight ?? this.fontWeight,
      fontStyle: fontStyle ?? this.fontStyle,
      underline: underline ?? this.underline,
      strikethrough: strikethrough ?? this.strikethrough,
      numberFormat: numberFormat ?? this.numberFormat,
      fontSize: fontSize ?? this.fontSize,
      fontFamily: fontFamily ?? this.fontFamily,
    );
  }
}

/// Rule based on cell value comparison
class CellValueRule extends ConditionalFormattingRule {
  final ComparisonOperator operator;
  final dynamic formula1; // Can be a value or formula string
  final dynamic formula2; // For between/notBetween operators

  CellValueRule({
    required String id,
    required this.operator,
    required this.formula1,
    this.formula2,
    Color? fillColor,
    Color? fontColor,
    FontWeight? fontWeight,
    bool? stopIfTrue,
  }) : super(
<<<<<<< HEAD:Modules/ky_sheet/lib/model/conditional_formatting_rule.dart
         id: id,
         type: ConditionalFormattingRuleType.cellValue,
         fillColor: fillColor,
         fontColor: fontColor,
         fontWeight: fontWeight,
         stopIfTrue: stopIfTrue,
       );
=======
          id: id,
          type: ConditionalFormattingRuleType.cellValue,
          fillColor: fillColor,
          fontColor: fontColor,
          fontWeight: fontWeight,
          stopIfTrue: stopIfTrue,
        );
>>>>>>> fdcc93050a737f18cc3ba965abd1229d5f2a24f1:Plugins/ky_sheet/lib/model/conditional_formatting_rule.dart

  @override
  bool evaluate(dynamic cellValue, EvaluationContext context) {
    final num? val1 = _toNumber(cellValue);
    final num? val2 = _toNumber(formula1);
    final num? val3 = formula2 != null ? _toNumber(formula2) : null;

    if (val1 == null || val2 == null) return false;

    switch (operator) {
      case ComparisonOperator.between:
        return val3 != null && val1 >= val2 && val1 <= val3;
      case ComparisonOperator.notBetween:
        return val3 != null && (val1 < val2 || val1 > val3);
      case ComparisonOperator.equal:
        return val1 == val2;
      case ComparisonOperator.notEqual:
        return val1 != val2;
      case ComparisonOperator.greaterThan:
        return val1 > val2;
      case ComparisonOperator.lessThan:
        return val1 < val2;
      case ComparisonOperator.greaterThanOrEqual:
        return val1 >= val2;
      case ComparisonOperator.lessThanOrEqual:
        return val1 <= val2;
    }
  }

  num? _toNumber(dynamic value) {
    if (value is num) return value;
    if (value is String) {
      try {
        return num.parse(value);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  @override
  CellStyle applyFormat(CellStyle style) {
    return style.copyWith(
      fillColor: fillColor,
      fontColor: fontColor,
      fontWeight: fontWeight,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'operator': operator.name,
      'formula1': formula1,
      'formula2': formula2,
      'fillColor': fillColor?.value.toRadixString(16),
      'fontColor': fontColor?.value.toRadixString(16),
      'fontWeight': fontWeight?.index,
      'stopIfTrue': stopIfTrue,
      'priority': priority,
    };
  }

  factory CellValueRule.fromJson(Map<String, dynamic> json) {
    return CellValueRule(
      id: json['id'] as String,
      operator: ComparisonOperator.values.firstWhere(
        (e) => e.name == json['operator'],
        orElse: () => ComparisonOperator.equal,
      ),
      formula1: json['formula1'],
      formula2: json['formula2'],
      fillColor: json['fillColor'] != null
          ? Color(int.parse(json['fillColor'], radix: 16))
          : null,
      fontColor: json['fontColor'] != null
          ? Color(int.parse(json['fontColor'], radix: 16))
          : null,
      fontWeight: json['fontWeight'] != null
          ? FontWeight.values[json['fontWeight'] as int]
          : null,
      stopIfTrue: json['stopIfTrue'] as bool?,
    );
  }
}

/// Rule based on custom formula
class FormulaRule extends ConditionalFormattingRule {
  final String formula; // Formula string (e.g., "=A1>B1", "=MOD(ROW(),2)=0")

  FormulaRule({
    required String id,
    required this.formula,
    Color? fillColor,
    Color? fontColor,
    FontWeight? fontWeight,
    bool? stopIfTrue,
  }) : super(
<<<<<<< HEAD:Modules/ky_sheet/lib/model/conditional_formatting_rule.dart
         id: id,
         type: ConditionalFormattingRuleType.formula,
         fillColor: fillColor,
         fontColor: fontColor,
         fontWeight: fontWeight,
         stopIfTrue: stopIfTrue,
       );
=======
          id: id,
          type: ConditionalFormattingRuleType.formula,
          fillColor: fillColor,
          fontColor: fontColor,
          fontWeight: fontWeight,
          stopIfTrue: stopIfTrue,
        );
>>>>>>> fdcc93050a737f18cc3ba965abd1229d5f2a24f1:Plugins/ky_sheet/lib/model/conditional_formatting_rule.dart

  @override
  bool evaluate(dynamic cellValue, EvaluationContext context) {
    // Formula evaluation requires integration with the sheet engine's formula parser
    // This is a placeholder - actual implementation would call the formula engine
    try {
      // Remove leading '=' if present
<<<<<<< HEAD:Modules/ky_sheet/lib/model/conditional_formatting_rule.dart
      final cleanFormula = formula.startsWith('=')
          ? formula.substring(1)
          : formula;

      // TODO: Integrate with xlsx_reader formula evaluator
      // For now, return false as placeholder
      // In production: return context.formulaEngine.evaluate(cleanFormula, context.cellAddress);

=======
      final cleanFormula = formula.startsWith('=') ? formula.substring(1) : formula;
      
      // TODO: Integrate with sheet_engine formula evaluator
      // For now, return false as placeholder
      // In production: return context.formulaEngine.evaluate(cleanFormula, context.cellAddress);
      
>>>>>>> fdcc93050a737f18cc3ba965abd1229d5f2a24f1:Plugins/ky_sheet/lib/model/conditional_formatting_rule.dart
      return false;
    } catch (e) {
      return false;
    }
  }

  @override
  CellStyle applyFormat(CellStyle style) {
    return style.copyWith(
      fillColor: fillColor,
      fontColor: fontColor,
      fontWeight: fontWeight,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'formula': formula,
      'fillColor': fillColor?.value.toRadixString(16),
      'fontColor': fontColor?.value.toRadixString(16),
      'fontWeight': fontWeight?.index,
      'stopIfTrue': stopIfTrue,
      'priority': priority,
    };
  }

  factory FormulaRule.fromJson(Map<String, dynamic> json) {
    return FormulaRule(
      id: json['id'] as String,
      formula: json['formula'] as String,
      fillColor: json['fillColor'] != null
          ? Color(int.parse(json['fillColor'], radix: 16))
          : null,
      fontColor: json['fontColor'] != null
          ? Color(int.parse(json['fontColor'], radix: 16))
          : null,
      fontWeight: json['fontWeight'] != null
          ? FontWeight.values[json['fontWeight'] as int]
          : null,
      stopIfTrue: json['stopIfTrue'] as bool?,
    );
  }
}

/// Rule for top/bottom N items or percentage
class TopBottomRule extends ConditionalFormattingRule {
  final TopBottomPosition position;
  final TopBottomType rankType;
  final int rankValue; // N items or N percent

  TopBottomRule({
    required String id,
    required this.position,
    required this.rankType,
    required this.rankValue,
    Color? fillColor,
    Color? fontColor,
    FontWeight? fontWeight,
    bool? stopIfTrue,
  }) : super(
<<<<<<< HEAD:Modules/ky_sheet/lib/model/conditional_formatting_rule.dart
         id: id,
         type: ConditionalFormattingRuleType.topBottom,
         fillColor: fillColor,
         fontColor: fontColor,
         fontWeight: fontWeight,
         stopIfTrue: stopIfTrue,
       );
=======
          id: id,
          type: ConditionalFormattingRuleType.topBottom,
          fillColor: fillColor,
          fontColor: fontColor,
          fontWeight: fontWeight,
          stopIfTrue: stopIfTrue,
        );
>>>>>>> fdcc93050a737f18cc3ba965abd1229d5f2a24f1:Plugins/ky_sheet/lib/model/conditional_formatting_rule.dart

  @override
  bool evaluate(dynamic cellValue, EvaluationContext context) {
    if (context.rank == null || context.totalCount == null) return false;

    final threshold = rankType == TopBottomType.items
        ? rankValue
        : (context.totalCount! * rankValue / 100).ceil();

    if (position == TopBottomPosition.top) {
      return context.rank! <= threshold;
    } else {
      return context.rank! > (context.totalCount! - threshold);
    }
  }

  @override
  CellStyle applyFormat(CellStyle style) {
    return style.copyWith(
      fillColor: fillColor,
      fontColor: fontColor,
      fontWeight: fontWeight,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'position': position.name,
      'rankType': rankType.name,
      'rankValue': rankValue,
      'fillColor': fillColor?.value.toRadixString(16),
      'fontColor': fontColor?.value.toRadixString(16),
      'fontWeight': fontWeight?.index,
      'stopIfTrue': stopIfTrue,
      'priority': priority,
    };
  }

  factory TopBottomRule.fromJson(Map<String, dynamic> json) {
    return TopBottomRule(
      id: json['id'] as String,
      position: TopBottomPosition.values.firstWhere(
        (e) => e.name == json['position'],
        orElse: () => TopBottomPosition.top,
      ),
      rankType: TopBottomType.values.firstWhere(
        (e) => e.name == json['rankType'],
        orElse: () => TopBottomType.items,
      ),
      rankValue: json['rankValue'] as int,
      fillColor: json['fillColor'] != null
          ? Color(int.parse(json['fillColor'], radix: 16))
          : null,
      fontColor: json['fontColor'] != null
          ? Color(int.parse(json['fontColor'], radix: 16))
          : null,
      fontWeight: json['fontWeight'] != null
          ? FontWeight.values[json['fontWeight'] as int]
          : null,
      stopIfTrue: json['stopIfTrue'] as bool?,
    );
  }
}

/// Data Bar Rule (visual representation in cell)
class DataBarRule extends ConditionalFormattingRule {
  final DataBarDirection direction;
  final Color? barColor;
  final bool showValue;
  final bool gradient;
  final dynamic? minValue;
  final dynamic? maxValue;

  DataBarRule({
    required String id,
    this.direction = DataBarDirection.leftToRight,
    this.barColor,
    this.showValue = true,
    this.gradient = true,
    this.minValue,
    this.maxValue,
    Color? fillColor,
    bool? stopIfTrue,
  }) : super(
<<<<<<< HEAD:Modules/ky_sheet/lib/model/conditional_formatting_rule.dart
         id: id,
         type: ConditionalFormattingRuleType.dataBar,
         fillColor: fillColor,
         stopIfTrue: stopIfTrue,
       );
=======
          id: id,
          type: ConditionalFormattingRuleType.dataBar,
          fillColor: fillColor,
          stopIfTrue: stopIfTrue,
        );
>>>>>>> fdcc93050a737f18cc3ba965abd1229d5f2a24f1:Plugins/ky_sheet/lib/model/conditional_formatting_rule.dart

  @override
  bool evaluate(dynamic cellValue, EvaluationContext context) {
    // Data bars always "apply" but render differently based on value
    return cellValue is num;
  }

  @override
  CellStyle applyFormat(CellStyle style) {
    // Data bars are rendered separately, not as cell style
    return style;
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'direction': direction.name,
      'barColor': barColor?.value.toRadixString(16),
      'showValue': showValue,
      'gradient': gradient,
      'minValue': minValue,
      'maxValue': maxValue,
      'stopIfTrue': stopIfTrue,
      'priority': priority,
    };
  }

  factory DataBarRule.fromJson(Map<String, dynamic> json) {
    return DataBarRule(
      id: json['id'] as String,
      direction: DataBarDirection.values.firstWhere(
        (e) => e.name == json['direction'],
        orElse: () => DataBarDirection.leftToRight,
      ),
      barColor: json['barColor'] != null
          ? Color(int.parse(json['barColor'], radix: 16))
          : null,
      showValue: json['showValue'] as bool? ?? true,
      gradient: json['gradient'] as bool? ?? true,
      minValue: json['minValue'],
      maxValue: json['maxValue'],
      stopIfTrue: json['stopIfTrue'] as bool?,
    );
  }
}

/// Color Scale Rule (2 or 3 color gradient)
class ColorScaleRule extends ConditionalFormattingRule {
  final List<ColorScalePoint> points;

<<<<<<< HEAD:Modules/ky_sheet/lib/model/conditional_formatting_rule.dart
  ColorScaleRule({required String id, required this.points, bool? stopIfTrue})
    : super(
        id: id,
        type: ConditionalFormattingRuleType.colorScale,
        stopIfTrue: stopIfTrue,
      );
=======
  ColorScaleRule({
    required String id,
    required this.points,
    bool? stopIfTrue,
  }) : super(
          id: id,
          type: ConditionalFormattingRuleType.colorScale,
          stopIfTrue: stopIfTrue,
        );
>>>>>>> fdcc93050a737f18cc3ba965abd1229d5f2a24f1:Plugins/ky_sheet/lib/model/conditional_formatting_rule.dart

  @override
  bool evaluate(dynamic cellValue, EvaluationContext context) {
    return cellValue is num;
  }

  @override
  CellStyle applyFormat(CellStyle style) {
    // Color scales are computed per-cell based on position in range
    return style;
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'points': points.map((p) => p.toJson()).toList(),
      'stopIfTrue': stopIfTrue,
      'priority': priority,
    };
  }

  factory ColorScaleRule.fromJson(Map<String, dynamic> json) {
    final pointsJson = json['points'] as List;
    return ColorScaleRule(
      id: json['id'] as String,
      points: pointsJson.map((p) => ColorScalePoint.fromJson(p)).toList(),
      stopIfTrue: json['stopIfTrue'] as bool?,
    );
  }
}

/// Point in a color scale
class ColorScalePoint {
  final int index; // 0, 1, or 2
<<<<<<< HEAD:Modules/ky_sheet/lib/model/conditional_formatting_rule.dart
  final String
  type; // min, max, percentile, number, percent, formula, percentil
=======
  final String type; // min, max, percentile, number, percent, formula, percentil
>>>>>>> fdcc93050a737f18cc3ba965abd1229d5f2a24f1:Plugins/ky_sheet/lib/model/conditional_formatting_rule.dart
  final dynamic value;
  final Color color;

  ColorScalePoint({
    required this.index,
    required this.type,
    this.value,
    required this.color,
  });

  Map<String, dynamic> toJson() {
    return {
      'index': index,
      'type': type,
      'value': value,
      'color': color.value.toRadixString(16),
    };
  }

  factory ColorScalePoint.fromJson(Map<String, dynamic> json) {
    return ColorScalePoint(
      index: json['index'] as int,
      type: json['type'] as String,
      value: json['value'],
      color: Color(int.parse(json['color'], radix: 16)),
    );
  }
}

/// Icon Set Rule
class IconSetRule extends ConditionalFormattingRule {
  final IconSetType iconSet;
  final bool reverse;
  final bool showIconOnly;
  final List<IconSetPoint> points;

  IconSetRule({
    required String id,
    required this.iconSet,
    this.reverse = false,
    this.showIconOnly = false,
    required this.points,
    bool? stopIfTrue,
  }) : super(
<<<<<<< HEAD:Modules/ky_sheet/lib/model/conditional_formatting_rule.dart
         id: id,
         type: ConditionalFormattingRuleType.iconSet,
         stopIfTrue: stopIfTrue,
       );
=======
          id: id,
          type: ConditionalFormattingRuleType.iconSet,
          stopIfTrue: stopIfTrue,
        );
>>>>>>> fdcc93050a737f18cc3ba965abd1229d5f2a24f1:Plugins/ky_sheet/lib/model/conditional_formatting_rule.dart

  @override
  bool evaluate(dynamic cellValue, EvaluationContext context) {
    return cellValue is num;
  }

  @override
  CellStyle applyFormat(CellStyle style) {
    // Icons are rendered separately
    return style;
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'iconSet': iconSet.name,
      'reverse': reverse,
      'showIconOnly': showIconOnly,
      'points': points.map((p) => p.toJson()).toList(),
      'stopIfTrue': stopIfTrue,
      'priority': priority,
    };
  }

  factory IconSetRule.fromJson(Map<String, dynamic> json) {
    final pointsJson = json['points'] as List;
    return IconSetRule(
      id: json['id'] as String,
      iconSet: IconSetType.values.firstWhere(
        (e) => e.name == json['iconSet'],
        orElse: () => IconSetType.threeArrows,
      ),
      reverse: json['reverse'] as bool? ?? false,
      showIconOnly: json['showIconOnly'] as bool? ?? false,
      points: pointsJson.map((p) => IconSetPoint.fromJson(p)).toList(),
      stopIfTrue: json['stopIfTrue'] as bool?,
    );
  }
}

/// Point in an icon set
class IconSetPoint {
  final int index;
  final String type;
  final dynamic value;
  final String? operator;

  IconSetPoint({
    required this.index,
    required this.type,
    this.value,
    this.operator,
  });

  Map<String, dynamic> toJson() {
<<<<<<< HEAD:Modules/ky_sheet/lib/model/conditional_formatting_rule.dart
    return {'index': index, 'type': type, 'value': value, 'operator': operator};
=======
    return {
      'index': index,
      'type': type,
      'value': value,
      'operator': operator,
    };
>>>>>>> fdcc93050a737f18cc3ba965abd1229d5f2a24f1:Plugins/ky_sheet/lib/model/conditional_formatting_rule.dart
  }

  factory IconSetPoint.fromJson(Map<String, dynamic> json) {
    return IconSetPoint(
      index: json['index'] as int,
      type: json['type'] as String,
      value: json['value'],
      operator: json['operator'] as String?,
    );
  }
}

/// Rule for duplicate or unique values
class DuplicateValueRule extends ConditionalFormattingRule {
  final bool highlightDuplicates; // true = duplicates, false = unique

  DuplicateValueRule({
    required String id,
    this.highlightDuplicates = true,
    Color? fillColor,
    Color? fontColor,
    FontWeight? fontWeight,
    bool? stopIfTrue,
  }) : super(
<<<<<<< HEAD:Modules/ky_sheet/lib/model/conditional_formatting_rule.dart
         id: id,
         type: ConditionalFormattingRuleType.duplicateValues,
         fillColor: fillColor,
         fontColor: fontColor,
         fontWeight: fontWeight,
         stopIfTrue: stopIfTrue,
       );
=======
          id: id,
          type: ConditionalFormattingRuleType.duplicateValues,
          fillColor: fillColor,
          fontColor: fontColor,
          fontWeight: fontWeight,
          stopIfTrue: stopIfTrue,
        );
>>>>>>> fdcc93050a737f18cc3ba965abd1229d5f2a24f1:Plugins/ky_sheet/lib/model/conditional_formatting_rule.dart

  @override
  bool evaluate(dynamic cellValue, EvaluationContext context) {
    if (context.rangeValues == null || cellValue == null) return false;

    final count = context.rangeValues!.where((v) => v == cellValue).length;

    return highlightDuplicates ? count > 1 : count == 1;
  }

  @override
  CellStyle applyFormat(CellStyle style) {
    return style.copyWith(
      fillColor: fillColor,
      fontColor: fontColor,
      fontWeight: fontWeight,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'highlightDuplicates': highlightDuplicates,
      'fillColor': fillColor?.value.toRadixString(16),
      'fontColor': fontColor?.value.toRadixString(16),
      'fontWeight': fontWeight?.index,
      'stopIfTrue': stopIfTrue,
      'priority': priority,
    };
  }

  factory DuplicateValueRule.fromJson(Map<String, dynamic> json) {
    return DuplicateValueRule(
      id: json['id'] as String,
      highlightDuplicates: json['highlightDuplicates'] as bool? ?? true,
      fillColor: json['fillColor'] != null
          ? Color(int.parse(json['fillColor'], radix: 16))
          : null,
      fontColor: json['fontColor'] != null
          ? Color(int.parse(json['fontColor'], radix: 16))
          : null,
      fontWeight: json['fontWeight'] != null
          ? FontWeight.values[json['fontWeight'] as int]
          : null,
      stopIfTrue: json['stopIfTrue'] as bool?,
    );
  }
}

/// Rule for text containing specific string
class TextContainsRule extends ConditionalFormattingRule {
  final String text;
  final bool caseSensitive;

  TextContainsRule({
    required String id,
    required this.text,
    this.caseSensitive = false,
    Color? fillColor,
    Color? fontColor,
    FontWeight? fontWeight,
    bool? stopIfTrue,
  }) : super(
<<<<<<< HEAD:Modules/ky_sheet/lib/model/conditional_formatting_rule.dart
         id: id,
         type: ConditionalFormattingRuleType.textContains,
         fillColor: fillColor,
         fontColor: fontColor,
         fontWeight: fontWeight,
         stopIfTrue: stopIfTrue,
       );
=======
          id: id,
          type: ConditionalFormattingRuleType.textContains,
          fillColor: fillColor,
          fontColor: fontColor,
          fontWeight: fontWeight,
          stopIfTrue: stopIfTrue,
        );
>>>>>>> fdcc93050a737f18cc3ba965abd1229d5f2a24f1:Plugins/ky_sheet/lib/model/conditional_formatting_rule.dart

  @override
  bool evaluate(dynamic cellValue, EvaluationContext context) {
    if (cellValue == null) return false;

    final cellStr = cellValue.toString();
<<<<<<< HEAD:Modules/ky_sheet/lib/model/conditional_formatting_rule.dart

=======
    
>>>>>>> fdcc93050a737f18cc3ba965abd1229d5f2a24f1:Plugins/ky_sheet/lib/model/conditional_formatting_rule.dart
    if (caseSensitive) {
      return cellStr.contains(text);
    } else {
      return cellStr.toLowerCase().contains(text.toLowerCase());
    }
  }

  @override
  CellStyle applyFormat(CellStyle style) {
    return style.copyWith(
      fillColor: fillColor,
      fontColor: fontColor,
      fontWeight: fontWeight,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'text': text,
      'caseSensitive': caseSensitive,
      'fillColor': fillColor?.value.toRadixString(16),
      'fontColor': fontColor?.value.toRadixString(16),
      'fontWeight': fontWeight?.index,
      'stopIfTrue': stopIfTrue,
      'priority': priority,
    };
  }

  factory TextContainsRule.fromJson(Map<String, dynamic> json) {
    return TextContainsRule(
      id: json['id'] as String,
      text: json['text'] as String,
      caseSensitive: json['caseSensitive'] as bool? ?? false,
      fillColor: json['fillColor'] != null
          ? Color(int.parse(json['fillColor'], radix: 16))
          : null,
      fontColor: json['fontColor'] != null
          ? Color(int.parse(json['fontColor'], radix: 16))
          : null,
      fontWeight: json['fontWeight'] != null
          ? FontWeight.values[json['fontWeight'] as int]
          : null,
      stopIfTrue: json['stopIfTrue'] as bool?,
    );
  }
}

/// Rule for dates occurring in specific period
class DateOccurringRule extends ConditionalFormattingRule {
<<<<<<< HEAD:Modules/ky_sheet/lib/model/conditional_formatting_rule.dart
  final String
  period; // today, yesterday, tomorrow, last7Days, thisMonth, lastMonth, nextMonth, thisWeek, lastWeek, nextWeek, thisYear, lastYear, nextYear
=======
  final String period; // today, yesterday, tomorrow, last7Days, thisMonth, lastMonth, nextMonth, thisWeek, lastWeek, nextWeek, thisYear, lastYear, nextYear
>>>>>>> fdcc93050a737f18cc3ba965abd1229d5f2a24f1:Plugins/ky_sheet/lib/model/conditional_formatting_rule.dart

  DateOccurringRule({
    required String id,
    required this.period,
    Color? fillColor,
    Color? fontColor,
    FontWeight? fontWeight,
    bool? stopIfTrue,
  }) : super(
<<<<<<< HEAD:Modules/ky_sheet/lib/model/conditional_formatting_rule.dart
         id: id,
         type: ConditionalFormattingRuleType.dateOccurring,
         fillColor: fillColor,
         fontColor: fontColor,
         fontWeight: fontWeight,
         stopIfTrue: stopIfTrue,
       );
=======
          id: id,
          type: ConditionalFormattingRuleType.dateOccurring,
          fillColor: fillColor,
          fontColor: fontColor,
          fontWeight: fontWeight,
          stopIfTrue: stopIfTrue,
        );
>>>>>>> fdcc93050a737f18cc3ba965abd1229d5f2a24f1:Plugins/ky_sheet/lib/model/conditional_formatting_rule.dart

  @override
  bool evaluate(dynamic cellValue, EvaluationContext context) {
    if (cellValue == null) return false;

    DateTime date;
    try {
      if (cellValue is DateTime) {
        date = cellValue;
      } else if (cellValue is String) {
        date = DateTime.parse(cellValue);
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    switch (period) {
      case 'today':
        return date.year == today.year &&
            date.month == today.month &&
            date.day == today.day;
      case 'yesterday':
        final yesterday = today.subtract(const Duration(days: 1));
        return date.year == yesterday.year &&
            date.month == yesterday.month &&
            date.day == yesterday.day;
      case 'tomorrow':
        final tomorrow = today.add(const Duration(days: 1));
        return date.year == tomorrow.year &&
            date.month == tomorrow.month &&
            date.day == tomorrow.day;
      case 'last7Days':
        final weekAgo = today.subtract(const Duration(days: 7));
        return date.isAfter(weekAgo) && date.isBefore(today);
      case 'thisMonth':
        return date.year == today.year && date.month == today.month;
      case 'lastMonth':
        final lastMonth = today.month == 1 ? 12 : today.month - 1;
        final lastMonthYear = today.month == 1 ? today.year - 1 : today.year;
        return date.year == lastMonthYear && date.month == lastMonth;
      case 'nextMonth':
        final nextMonth = today.month == 12 ? 1 : today.month + 1;
        final nextMonthYear = today.month == 12 ? today.year + 1 : today.year;
        return date.year == nextMonthYear && date.month == nextMonth;
      default:
        return false;
    }
  }

  @override
  CellStyle applyFormat(CellStyle style) {
    return style.copyWith(
      fillColor: fillColor,
      fontColor: fontColor,
      fontWeight: fontWeight,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'period': period,
      'fillColor': fillColor?.value.toRadixString(16),
      'fontColor': fontColor?.value.toRadixString(16),
      'fontWeight': fontWeight?.index,
      'stopIfTrue': stopIfTrue,
      'priority': priority,
    };
  }

  factory DateOccurringRule.fromJson(Map<String, dynamic> json) {
    return DateOccurringRule(
      id: json['id'] as String,
      period: json['period'] as String,
      fillColor: json['fillColor'] != null
          ? Color(int.parse(json['fillColor'], radix: 16))
          : null,
      fontColor: json['fontColor'] != null
          ? Color(int.parse(json['fontColor'], radix: 16))
          : null,
      fontWeight: json['fontWeight'] != null
          ? FontWeight.values[json['fontWeight'] as int]
          : null,
      stopIfTrue: json['stopIfTrue'] as bool?,
    );
  }
}

/// Rule for blank cells or error cells
class BlankErrorRule extends ConditionalFormattingRule {
  final bool blanks; // true for blanks, false for errors

  BlankErrorRule({
    required String id,
    this.blanks = true,
    Color? fillColor,
    Color? fontColor,
    FontWeight? fontWeight,
    bool? stopIfTrue,
  }) : super(
<<<<<<< HEAD:Modules/ky_sheet/lib/model/conditional_formatting_rule.dart
         id: id,
         type: ConditionalFormattingRuleType.blankErrors,
         fillColor: fillColor,
         fontColor: fontColor,
         fontWeight: fontWeight,
         stopIfTrue: stopIfTrue,
       );
=======
          id: id,
          type: ConditionalFormattingRuleType.blankErrors,
          fillColor: fillColor,
          fontColor: fontColor,
          fontWeight: fontWeight,
          stopIfTrue: stopIfTrue,
        );
>>>>>>> fdcc93050a737f18cc3ba965abd1229d5f2a24f1:Plugins/ky_sheet/lib/model/conditional_formatting_rule.dart

  @override
  bool evaluate(dynamic cellValue, EvaluationContext context) {
    if (blanks) {
      return cellValue == null || cellValue.toString().isEmpty;
    } else {
      // Check for error values (#DIV/0!, #N/A, etc.)
      if (cellValue is String) {
        return cellValue.startsWith('#') && cellValue.endsWith('!');
      }
      return false;
    }
  }

  @override
  CellStyle applyFormat(CellStyle style) {
    return style.copyWith(
      fillColor: fillColor,
      fontColor: fontColor,
      fontWeight: fontWeight,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'blanks': blanks,
      'fillColor': fillColor?.value.toRadixString(16),
      'fontColor': fontColor?.value.toRadixString(16),
      'fontWeight': fontWeight?.index,
      'stopIfTrue': stopIfTrue,
      'priority': priority,
    };
  }

  factory BlankErrorRule.fromJson(Map<String, dynamic> json) {
    return BlankErrorRule(
      id: json['id'] as String,
      blanks: json['blanks'] as bool? ?? true,
      fillColor: json['fillColor'] != null
          ? Color(int.parse(json['fillColor'], radix: 16))
          : null,
      fontColor: json['fontColor'] != null
          ? Color(int.parse(json['fontColor'], radix: 16))
          : null,
      fontWeight: json['fontWeight'] != null
          ? FontWeight.values[json['fontWeight'] as int]
          : null,
      stopIfTrue: json['stopIfTrue'] as bool?,
    );
  }
}
