import 'package:flutter_riverpod/legacy.dart';

import '../model/cell/cell_selection.dart';
import '../model/sheet_named_range.dart';

final sheetNamedRangesProvider =
    StateNotifierProvider<SheetNamedRangeNotifier, List<SheetNamedRange>>(
      (ref) => SheetNamedRangeNotifier(),
    );

class SheetNamedRangeNotifier extends StateNotifier<List<SheetNamedRange>> {
  SheetNamedRangeNotifier([List<SheetNamedRange>? initial])
    : super(_sorted(initial ?? const []));

  SheetNamedRange save({
    required String name,
    required CellSelection selection,
  }) {
    final normalizedName = SheetNamedRange.normalizeName(name);
    if (!SheetNamedRange.isValidName(normalizedName)) {
      throw ArgumentError.value(name, 'name', 'Invalid named range name');
    }

    final existing = findByName(normalizedName);
    final next = SheetNamedRange(
      id: existing?.id ?? _nextId(),
      name: normalizedName,
      selection: selection,
    );

    state = _sorted([
      for (final range in state)
        if (range.id != next.id) range,
      next,
    ]);

    return next;
  }

  void replaceAll(Iterable<SheetNamedRange> ranges) {
    final seenNames = <String>{};
    state = _sorted([
      for (final range in ranges)
        if (SheetNamedRange.isValidName(range.name) &&
            seenNames.add(range.normalizedName))
          range.copyWith(name: SheetNamedRange.normalizeName(range.name)),
    ]);
  }

  void remove(String id) {
    state = [
      for (final range in state)
        if (range.id != id) range,
    ];
  }

  SheetNamedRange? findByName(String name) {
    final normalizedName = SheetNamedRange.normalizeName(name).toLowerCase();
    for (final range in state) {
      if (range.normalizedName == normalizedName) return range;
    }
    return null;
  }

  static List<SheetNamedRange> _sorted(Iterable<SheetNamedRange> ranges) {
    return [...ranges]
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  }

  String _nextId() {
    return 'named-range-${DateTime.now().microsecondsSinceEpoch}';
  }
}
