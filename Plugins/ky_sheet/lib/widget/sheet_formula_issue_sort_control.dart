import 'package:flutter/material.dart';

import '../model/sheet_formula_issue_sort.dart';

class SheetFormulaIssueSortControl extends StatelessWidget {
  const SheetFormulaIssueSortControl({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final SheetFormulaIssueSortMode value;
  final ValueChanged<SheetFormulaIssueSortMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<SheetFormulaIssueSortMode>(
      key: const ValueKey('ky-sheet-formula-health-sort-control'),
      showSelectedIcon: false,
      style: const ButtonStyle(
        visualDensity: VisualDensity.compact,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      selected: {value},
      segments: const [
        ButtonSegment(
          value: SheetFormulaIssueSortMode.cell,
          icon: Icon(Icons.grid_on_outlined, size: 16),
          label: Text('Cell'),
        ),
        ButtonSegment(
          value: SheetFormulaIssueSortMode.code,
          icon: Icon(Icons.category_outlined, size: 16),
          label: Text('Type'),
        ),
      ],
      onSelectionChanged: (selection) => onChanged(selection.first),
    );
  }
}
