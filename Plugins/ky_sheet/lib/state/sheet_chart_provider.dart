import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../model/sheet_chart.dart';
import '../utils/sheet_chart_data_builder.dart';
import 'spreadsheet_provider.dart';

final sheetChartSpecProvider = StateProvider<SheetChartSpec>(
  (ref) => const SheetChartSpec(),
);

final sheetChartDataProvider = Provider<SheetChartData>((ref) {
  return SheetChartDataBuilder.build(
    selection: ref.watch(selectedCellProvider),
    cells: ref.watch(spreadsheetProvider),
    spec: ref.watch(sheetChartSpecProvider),
  );
});
