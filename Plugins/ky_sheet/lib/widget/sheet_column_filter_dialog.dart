import 'package:flutter/material.dart';

import '../model/cell/cell_address.dart';
import '../model/sheet_filter_rule.dart';
import '../theme/ky_sheet_theme.dart';
import 'sheet_column_filter_quick_actions.dart';
import 'sheet_column_filter_state_summary.dart';
import 'sheet_filter_rule_editor.dart';
import 'sheet_filter_value_checklist.dart';

enum SheetColumnFilterDialogAction {
  applyFilter,
  clearFilter,
  clearSort,
  sortAscending,
  sortDescending,
}

/// Result returned when a column sort/filter dialog action is selected.
class SheetColumnFilterDialogResult {
  const SheetColumnFilterDialogResult.apply(this.rule)
    : action = SheetColumnFilterDialogAction.applyFilter;
  const SheetColumnFilterDialogResult.clear()
    : action = SheetColumnFilterDialogAction.clearFilter,
      rule = null;
  const SheetColumnFilterDialogResult.clearSort()
    : action = SheetColumnFilterDialogAction.clearSort,
      rule = null;
  const SheetColumnFilterDialogResult.sortAscending()
    : action = SheetColumnFilterDialogAction.sortAscending,
      rule = null;
  const SheetColumnFilterDialogResult.sortDescending()
    : action = SheetColumnFilterDialogAction.sortDescending,
      rule = null;

  final SheetFilterRule? rule;
  final SheetColumnFilterDialogAction action;

  bool get clear => action == SheetColumnFilterDialogAction.clearFilter;
}

/// Combined sort, condition-filter, and checklist-filter dialog for a column.
class SheetColumnFilterDialog extends StatefulWidget {
  const SheetColumnFilterDialog({
    super.key,
    required this.column,
    this.titleText,
    this.scopeDescription,
    this.initialValue = '',
    this.initialRule,
    this.values = const [],
    this.isSorted = false,
    this.sortAscending = true,
  });

  final int column;
  final String? titleText;
  final String? scopeDescription;
  final String initialValue;
  final SheetFilterRule? initialRule;
  final List<String> values;
  final bool isSorted;
  final bool sortAscending;

  @override
  State<SheetColumnFilterDialog> createState() =>
      _SheetColumnFilterDialogState();
}

/// Owns dialog-local filter editing controllers and checklist selection.
class _SheetColumnFilterDialogState extends State<SheetColumnFilterDialog> {
  late final TextEditingController _textController;
  late final TextEditingController _searchController;
  late final FocusNode _conditionFocusNode;
  late final List<String> _values;
  late final Set<String> _selectedValues;
  late final bool _hasActiveFilter;
  late final String? _initialFilterDescription;
  late SheetFilterOperator _operator;

  @override
  void initState() {
    super.initState();
    final initialRule =
        widget.initialRule ?? SheetFilterRule.contains(widget.initialValue);
    final initialValues = initialRule.operator == SheetFilterOperator.oneOf
        ? initialRule.valueList
        : const <String>[];
    final isConditionRule = initialRule.operator != SheetFilterOperator.oneOf;

    _values = _normalizeValues([...widget.values, ...initialValues]);
    _selectedValues = initialRule.operator == SheetFilterOperator.oneOf
        ? _normalizeValues(initialValues).toSet()
        : _values.toSet();
    _hasActiveFilter = initialRule.isActive;
    _initialFilterDescription = _hasActiveFilter
        ? initialRule.description
        : null;
    _operator = isConditionRule
        ? initialRule.operator
        : SheetFilterOperator.contains;
    _textController = TextEditingController(
      text: isConditionRule && initialRule.operator.requiresValue
          ? initialRule.value
          : '',
    );
    _searchController = TextEditingController();
    _conditionFocusNode = FocusNode(debugLabel: 'KySheetColumnFilterCondition');
  }

  @override
  void dispose() {
    _textController.dispose();
    _searchController.dispose();
    _conditionFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final columnLabel = CellAddress.colToLabel(widget.column);
    final titleText = widget.titleText ?? 'Sort & Filter Column $columnLabel';

    return AlertDialog(
      scrollable: true,
      title: _SheetColumnFilterDialogTitle(
        titleText: titleText,
        scopeDescription: widget.scopeDescription,
      ),
      content: SizedBox(
        width: 390,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SheetColumnFilterQuickActions(
              canClearFilter: _hasActiveFilter,
              canClearSort: widget.isSorted,
              isSorted: widget.isSorted,
              sortAscending: widget.sortAscending,
              onSortAscending: () => Navigator.pop(
                context,
                const SheetColumnFilterDialogResult.sortAscending(),
              ),
              onSortDescending: () => Navigator.pop(
                context,
                const SheetColumnFilterDialogResult.sortDescending(),
              ),
              onClearFilter: () => Navigator.pop(
                context,
                const SheetColumnFilterDialogResult.clear(),
              ),
              onClearSort: () => Navigator.pop(
                context,
                const SheetColumnFilterDialogResult.clearSort(),
              ),
            ),
            const SizedBox(height: 10),
            SheetColumnFilterStateSummary(
              isSorted: widget.isSorted,
              sortAscending: widget.sortAscending,
              filterDescription: _initialFilterDescription,
            ),
            const SizedBox(height: 10),
            const Divider(color: KySheetColors.gridLine),
            const SizedBox(height: 10),
            SheetFilterRuleEditor(
              operator: _operator,
              valueController: _textController,
              focusNode: _conditionFocusNode,
              enabled: true,
              onOperatorChanged: _setOperator,
              onSubmitted: _apply,
            ),
            const SizedBox(height: 10),
            const _FilterModeDivider(),
            const SizedBox(height: 10),
            SheetFilterValueChecklist(
              values: _values,
              selectedValues: _selectedValues,
              searchController: _searchController,
              onSearchChanged: (_) => setState(() {}),
              onValueToggled: _toggleValue,
              onSelectValues: (values) => setState(() {
                _selectedValues.addAll(values);
              }),
              onClearValues: (values) => setState(() {
                _selectedValues.removeAll(values);
              }),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _apply, child: const Text('Apply')),
      ],
    );
  }

  void _toggleValue(String value) {
    setState(() {
      if (_selectedValues.contains(value)) {
        _selectedValues.remove(value);
      } else {
        _selectedValues.add(value);
      }
    });
  }

  void _setOperator(SheetFilterOperator operator) {
    setState(() {
      _operator = operator;
      if (!operator.requiresValue) {
        _textController.clear();
        _conditionFocusNode.unfocus();
      }
    });
  }

  void _apply() {
    final text = _textController.text.trim();
    if (!_operator.requiresValue || text.isNotEmpty) {
      Navigator.pop(
        context,
        SheetColumnFilterDialogResult.apply(
          SheetFilterRule(operator: _operator, value: text),
        ),
      );
      return;
    }

    final isValueFilter =
        _values.isNotEmpty && _selectedValues.length != _values.length;
    if (isValueFilter) {
      Navigator.pop(
        context,
        SheetColumnFilterDialogResult.apply(
          SheetFilterRule.oneOf(_selectedValues),
        ),
      );
      return;
    }

    Navigator.pop(context, const SheetColumnFilterDialogResult.clear());
  }

  List<String> _normalizeValues(List<String> values) {
    final normalized = <String>[];
    final seen = <String>{};

    for (final rawValue in values) {
      final value = rawValue.trim();
      if (value.isEmpty) continue;
      final key = value.toLowerCase();
      if (seen.add(key)) normalized.add(value);
    }

    normalized.sort((a, b) {
      final lowerComparison = a.toLowerCase().compareTo(b.toLowerCase());
      return lowerComparison == 0 ? a.compareTo(b) : lowerComparison;
    });
    return normalized;
  }
}

/// Compact title block that can include table-specific filter scope.
class _SheetColumnFilterDialogTitle extends StatelessWidget {
  const _SheetColumnFilterDialogTitle({
    required this.titleText,
    this.scopeDescription,
  });

  final String titleText;
  final String? scopeDescription;

  @override
  Widget build(BuildContext context) {
    final description = scopeDescription?.trim();
    final hasDescription = description != null && description.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(titleText),
        if (hasDescription) ...[
          const SizedBox(height: 6),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.table_rows_outlined,
                size: 15,
                color: KySheetColors.mutedText,
              ),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  description,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: KySheetColors.mutedText,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _FilterModeDivider extends StatelessWidget {
  const _FilterModeDivider();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(child: Divider(color: KySheetColors.gridLine)),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 10),
          child: Text(
            'or choose values',
            style: TextStyle(
              color: KySheetColors.mutedText,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Expanded(child: Divider(color: KySheetColors.gridLine)),
      ],
    );
  }
}
