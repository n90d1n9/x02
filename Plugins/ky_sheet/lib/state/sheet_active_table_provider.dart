import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../model/sheet_table.dart';
import 'sheet_table_provider.dart';
import 'spreadsheet_provider.dart';

/// Resolves the structured table containing the active selection anchor.
final activeSheetTableProvider = Provider<SheetTable?>((ref) {
  final selection = ref.watch(selectedCellProvider);
  if (selection == null) return null;

  final address = selection.start;
  final tables = ref.watch(sheetTablesProvider);
  for (final table in tables.reversed) {
    if (table.contains(address)) return table;
  }

  return null;
});
