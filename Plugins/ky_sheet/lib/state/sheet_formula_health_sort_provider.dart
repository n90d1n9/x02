import 'package:flutter_riverpod/legacy.dart';

import '../model/sheet_formula_issue_sort.dart';

final sheetFormulaHealthSortModeProvider =
    StateProvider<SheetFormulaIssueSortMode>(
      (ref) => SheetFormulaIssueSortMode.cell,
    );
