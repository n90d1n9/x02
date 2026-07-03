import 'package:flutter/material.dart';

import '../model/sheet_formula_issue_code_info.dart';
import '../theme/ky_sheet_theme.dart';

class SheetFormulaIssueFilterBar extends StatelessWidget {
  const SheetFormulaIssueFilterBar({
    super.key,
    required this.counts,
    required this.activeCode,
    required this.onChanged,
  });

  final Map<String, int> counts;
  final String? activeCode;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final entries = counts.entries.toList()
      ..sort((left, right) => left.key.compareTo(right.key));

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        for (final entry in entries)
          _IssueCodeFilterChip(
            code: entry.key,
            count: entry.value,
            selected: activeCode == entry.key,
            onSelected: () =>
                onChanged(activeCode == entry.key ? null : entry.key),
          ),
        if (activeCode != null)
          IconButton.filledTonal(
            key: const ValueKey('ky-sheet-formula-health-filter-clear'),
            constraints: const BoxConstraints.tightFor(width: 32, height: 32),
            padding: EdgeInsets.zero,
            iconSize: 16,
            tooltip: 'Clear Formula Health Filter',
            onPressed: () => onChanged(null),
            icon: const Icon(Icons.filter_alt_off_outlined),
          ),
      ],
    );
  }
}

class _IssueCodeFilterChip extends StatelessWidget {
  const _IssueCodeFilterChip({
    required this.code,
    required this.count,
    required this.selected,
    required this.onSelected,
  });

  final String code;
  final int count;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    final info = SheetFormulaIssueCodeCatalog.describe(code);

    return Tooltip(
      message: '${info.label} (${info.code}). ${info.description}',
      child: FilterChip(
        key: ValueKey('ky-sheet-formula-health-filter-$code'),
        selected: selected,
        label: Text('${info.shortLabel} $count'),
        onSelected: (_) => onSelected(),
        selectedColor: KySheetColors.validationSoft,
        checkmarkColor: KySheetColors.validationError,
        side: BorderSide(
          color: selected
              ? KySheetColors.validationError
              : KySheetColors.gridLine,
        ),
        labelStyle: TextStyle(
          color: selected ? KySheetColors.validationError : KySheetColors.text,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}
