import 'package:flutter_riverpod/legacy.dart';

import '../model/workbook_sheet.dart';

/// Recent workbook sheet ids visited during the current editing session.
final recentWorkbookSheetIdsProvider =
    StateNotifierProvider<RecentWorkbookSheetNotifier, List<String>>(
      (ref) => RecentWorkbookSheetNotifier(),
    );

/// Tracks recently visited workbook sheets and resolves them against a workbook.
class RecentWorkbookSheetNotifier extends StateNotifier<List<String>> {
  RecentWorkbookSheetNotifier() : super(const []);

  static const maxRecentSheets = 4;

  /// Records a workbook sheet visit newest-first without duplicates.
  void record(String sheetId) {
    final normalizedId = sheetId.trim();
    if (normalizedId.isEmpty) return;

    state = [
      normalizedId,
      for (final id in state)
        if (id != normalizedId) id,
    ].take(maxRecentSheets).toList();
  }

  /// Removes a sheet id when the sheet no longer belongs to the workbook.
  void remove(String sheetId) {
    state = [
      for (final id in state)
        if (id != sheetId) id,
    ];
  }

  /// Drops recent ids that are no longer present in the workbook.
  void retain(Iterable<String> sheetIds) {
    final allowedIds = sheetIds.toSet();
    state = [
      for (final id in state)
        if (allowedIds.contains(id)) id,
    ];
  }

  /// Resolves recent ids to visible workbook sheets in recent order.
  List<WorkbookSheet> resolve({
    required Iterable<WorkbookSheet> sheets,
    String? activeSheetId,
  }) {
    final sheetsById = {for (final sheet in sheets) sheet.id: sheet};

    return [
      for (final id in state)
        if (id != activeSheetId &&
            sheetsById[id] != null &&
            !sheetsById[id]!.hidden)
          sheetsById[id]!,
    ];
  }

  /// Clears the recent sheet history.
  void clear() {
    state = const [];
  }
}
