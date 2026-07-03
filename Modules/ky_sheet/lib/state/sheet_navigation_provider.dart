import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../model/cell/cell_selection.dart';
import 'sheet_formula_preview_provider.dart';
import 'spreadsheet_provider.dart';

final sheetNavigationControllerProvider = Provider((ref) {
  return SheetNavigationController(ref);
});

final sheetNavigationRequestProvider = StateProvider<SheetNavigationRequest?>(
  (ref) => null,
);

class SheetNavigationController {
  const SheetNavigationController(this.ref);

  final Ref ref;

  void goTo(CellSelection selection, {bool clearFormulaPreview = true}) {
    ref.read(editingCellProvider.notifier).state = null;
    ref.read(editingCellDraftProvider.notifier).state = null;
    if (clearFormulaPreview) {
      ref.read(formulaReferencePreviewProvider.notifier).state = const [];
      ref.read(formulaReferencePreviewContextProvider.notifier).state = null;
    }
    ref.read(selectedCellProvider.notifier).state = selection;
    ref.read(sheetNavigationRequestProvider.notifier).state =
        SheetNavigationRequest(selection);
  }
}

class SheetNavigationRequest {
  const SheetNavigationRequest(this.selection);

  final CellSelection selection;
}
