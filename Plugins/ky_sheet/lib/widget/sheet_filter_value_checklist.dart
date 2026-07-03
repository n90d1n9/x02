import 'package:flutter/material.dart';

import '../theme/ky_sheet_theme.dart';

class SheetFilterValueChecklist extends StatelessWidget {
  const SheetFilterValueChecklist({
    super.key,
    required this.values,
    required this.selectedValues,
    required this.searchController,
    required this.onSearchChanged,
    required this.onValueToggled,
    required this.onSelectValues,
    required this.onClearValues,
  });

  final List<String> values;
  final Set<String> selectedValues;
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String> onValueToggled;
  final ValueChanged<List<String>> onSelectValues;
  final ValueChanged<List<String>> onClearValues;

  @override
  Widget build(BuildContext context) {
    final query = searchController.text.trim().toLowerCase();
    final visibleValues = [
      for (final value in values)
        if (_displayValue(value).toLowerCase().contains(query)) value,
    ];
    final hasQuery = query.isNotEmpty;
    final canUpdateVisibleValues = visibleValues.isNotEmpty;
    final selectionSummary = hasQuery
        ? '${selectedValues.length} selected, ${visibleValues.length} match${visibleValues.length == 1 ? '' : 'es'}'
        : '${selectedValues.length} of ${values.length} selected';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          key: const ValueKey('ky-sheet-column-filter-search'),
          controller: searchController,
          decoration: const InputDecoration(
            isDense: true,
            labelText: 'Search values',
            prefixIcon: Icon(Icons.search, size: 18),
            border: OutlineInputBorder(),
          ),
          onChanged: onSearchChanged,
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: Text(
                selectionSummary,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: KySheetColors.mutedText,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            TextButton(
              key: const ValueKey('ky-sheet-column-filter-select-all'),
              onPressed: canUpdateVisibleValues
                  ? () => onSelectValues(visibleValues)
                  : null,
              child: Text(hasQuery ? 'Select matches' : 'Select all'),
            ),
            TextButton(
              key: const ValueKey('ky-sheet-column-filter-clear-values'),
              onPressed: canUpdateVisibleValues
                  ? () => onClearValues(visibleValues)
                  : null,
              child: Text(hasQuery ? 'Clear matches' : 'Clear values'),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          height: 126,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: KySheetColors.gridLine),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Material(
              color: KySheetColors.surfaceMuted,
              child: visibleValues.isEmpty
                  ? Center(
                      child: Text(
                        values.isEmpty ? 'No values in column' : 'No matches',
                        style: const TextStyle(
                          color: KySheetColors.mutedText,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      itemCount: visibleValues.length,
                      itemBuilder: (context, index) {
                        final value = visibleValues[index];
                        final sourceIndex = values.indexOf(value);
                        return CheckboxListTile(
                          key: ValueKey(
                            'ky-sheet-column-filter-value-$sourceIndex',
                          ),
                          dense: true,
                          visualDensity: VisualDensity.compact,
                          controlAffinity: ListTileControlAffinity.leading,
                          value: selectedValues.contains(value),
                          title: Text(
                            _displayValue(value),
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          onChanged: (_) => onValueToggled(value),
                        );
                      },
                    ),
            ),
          ),
        ),
      ],
    );
  }

  static String _displayValue(String value) {
    return value.trim().isEmpty ? '(Blanks)' : value;
  }
}
