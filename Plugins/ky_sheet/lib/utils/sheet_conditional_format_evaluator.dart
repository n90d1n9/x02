import '../model/cell/cell_address.dart';
import '../model/cell/cell_data.dart';
import '../model/cell/cell_style.dart';
import '../model/conditional_format_rule.dart';

class SheetConditionalFormatEvaluator {
  const SheetConditionalFormatEvaluator._();

  static CellStyle effectiveStyle({
    required CellAddress address,
    required CellData cellData,
    required Iterable<ConditionalFormatRule> rules,
  }) {
    var style = cellData.style;

    for (final rule in rules) {
      if (!rule.selection.contains(address)) continue;
      if (!_matches(rule, cellData.value)) continue;

      style = style.copyWith(
        backgroundColor: rule.backgroundColor,
        textColor: rule.textColor,
        bold: rule.bold ? true : style.bold,
      );
    }

    return style;
  }

  static bool _matches(ConditionalFormatRule rule, String rawValue) {
    final value = rawValue.trim();

    return switch (rule.condition) {
      ConditionalFormatCondition.greaterThan => _compareNumeric(
        value,
        rule.operand,
        (left, right) => left > right,
      ),
      ConditionalFormatCondition.lessThan => _compareNumeric(
        value,
        rule.operand,
        (left, right) => left < right,
      ),
      ConditionalFormatCondition.equalTo =>
        value.toLowerCase() == rule.operand.trim().toLowerCase(),
      ConditionalFormatCondition.containsText => value.toLowerCase().contains(
        rule.operand.trim().toLowerCase(),
      ),
      ConditionalFormatCondition.notEmpty => value.isNotEmpty,
    };
  }

  static bool _compareNumeric(
    String value,
    String operand,
    bool Function(double left, double right) compare,
  ) {
    final left = double.tryParse(value);
    final right = double.tryParse(operand.trim());
    if (left == null || right == null) return false;
    return compare(left, right);
  }
}
