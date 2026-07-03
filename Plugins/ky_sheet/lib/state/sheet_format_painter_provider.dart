import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../model/cell/cell_selection.dart';
import '../model/sheet_format_snapshot.dart';
import 'spreadsheet_provider.dart';

final sheetFormatPainterSnapshotProvider = StateProvider<SheetFormatSnapshot?>(
  (ref) => null,
);

final sheetFormatPainterControllerProvider = Provider((ref) {
  return SheetFormatPainterController(ref);
});

class SheetFormatPainterController {
  const SheetFormatPainterController(this.ref);

  final Ref ref;

  bool get isActive => ref.read(sheetFormatPainterSnapshotProvider) != null;

  void start(CellSelection selection) {
    final snapshot = SheetFormatSnapshot.fromSelection(
      selection: selection,
      cells: ref.read(spreadsheetProvider),
    );
    ref.read(sheetFormatPainterSnapshotProvider.notifier).state = snapshot;
  }

  void cancel() {
    ref.read(sheetFormatPainterSnapshotProvider.notifier).state = null;
  }

  bool applyTo(CellSelection selection) {
    final snapshot = ref.read(sheetFormatPainterSnapshotProvider);
    if (snapshot == null) return false;

    ref
        .read(spreadsheetProvider.notifier)
        .updateCells(
          selection.getCells(),
          (address, current) =>
              current.copyWith(style: snapshot.styleFor(address, selection)),
          description: 'Paint formatting',
          recalculate: false,
        );
    cancel();
    return true;
  }
}
