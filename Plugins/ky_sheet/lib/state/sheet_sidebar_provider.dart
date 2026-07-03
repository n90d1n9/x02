import 'package:flutter_riverpod/legacy.dart';

enum SheetSidebarPanel {
  cellInspector,
  shortcuts,
  functionLibrary,
  formulaAudit,
  formulaHealth,
  goToSpecial,
  history,
  sheetEngineOperations,
  review,
  chartBuilder,
  namedRanges,
  tables,
  dataInsights,
  dataCleanup,
  findReplace,
  sortFilter,
  sheetView,
  conditionalFormat,
  dataValidation,
  performance,
}

final activeSidebarPanelProvider = StateProvider<SheetSidebarPanel?>(
  (ref) => null,
);
