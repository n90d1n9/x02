import 'package:flutter/material.dart';

import '../model/sheet_filter_rule.dart';
import '../theme/ky_sheet_theme.dart';

class SheetFilterRuleEditor extends StatelessWidget {
  const SheetFilterRuleEditor({
    super.key,
    required this.operator,
    required this.valueController,
    required this.focusNode,
    required this.enabled,
    required this.onOperatorChanged,
    required this.onSubmitted,
  });

  final SheetFilterOperator operator;
  final TextEditingController valueController;
  final FocusNode focusNode;
  final bool enabled;
  final ValueChanged<SheetFilterOperator> onOperatorChanged;
  final VoidCallback onSubmitted;

  @override
  Widget build(BuildContext context) {
    final operatorOptions = [
      for (final option in SheetFilterOperator.values)
        if (option != SheetFilterOperator.oneOf) option,
    ];
    final effectiveOperator = operatorOptions.contains(operator)
        ? operator
        : SheetFilterOperator.contains;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DropdownButtonFormField<SheetFilterOperator>(
          key: const ValueKey('ky-sheet-filter-operator'),
          initialValue: effectiveOperator,
          isExpanded: true,
          decoration: _inputDecoration(label: 'Condition'),
          items: [
            for (final option in operatorOptions)
              DropdownMenuItem(value: option, child: Text(option.label)),
          ],
          onChanged: enabled
              ? (value) {
                  if (value != null) onOperatorChanged(value);
                }
              : null,
        ),
        const SizedBox(height: 10),
        TextField(
          key: const ValueKey('ky-sheet-filter-value'),
          controller: valueController,
          focusNode: focusNode,
          enabled: enabled && effectiveOperator.requiresValue,
          decoration: _inputDecoration(
            label: 'Value',
            hintText: effectiveOperator.requiresValue
                ? 'Type value'
                : 'No value needed',
            prefixIcon: const Icon(Icons.search, size: 18),
          ),
          onSubmitted: (_) => onSubmitted(),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    String? hintText,
    Widget? prefixIcon,
  }) {
    return InputDecoration(
      isDense: true,
      labelText: label,
      hintText: hintText,
      prefixIcon: prefixIcon,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: KySheetColors.gridLine),
      ),
    );
  }
}
