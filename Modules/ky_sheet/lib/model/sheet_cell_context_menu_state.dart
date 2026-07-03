import 'cell/cell_address.dart';

/// Presentation state used to build cell context menu commands.
class SheetCellContextMenuState {
  const SheetCellContextMenuState({
    this.hasColumnFilter = false,
    this.columnFilterDetail = 'No active filter',
    this.canFreezePanesHere = true,
    this.hasFreezePane = false,
    this.canFindThisValue = false,
  });

  /// Builds menu state from the clicked cell and current spreadsheet context.
  factory SheetCellContextMenuState.forCell({
    required CellAddress clickedCell,
    required bool hasColumnFilter,
    required String columnFilterDetail,
    required bool hasFreezePane,
    required bool canFindThisValue,
  }) {
    return SheetCellContextMenuState(
      hasColumnFilter: hasColumnFilter,
      columnFilterDetail: columnFilterDetail,
      canFreezePanesHere: clickedCell.row > 0 || clickedCell.col > 0,
      hasFreezePane: hasFreezePane,
      canFindThisValue: canFindThisValue,
    );
  }

  final bool hasColumnFilter;
  final String columnFilterDetail;
  final bool canFreezePanesHere;
  final bool hasFreezePane;
  final bool canFindThisValue;

  /// Returns this state with selected fields replaced for focused menu tests.
  SheetCellContextMenuState copyWith({
    bool? hasColumnFilter,
    String? columnFilterDetail,
    bool? canFreezePanesHere,
    bool? hasFreezePane,
    bool? canFindThisValue,
  }) {
    return SheetCellContextMenuState(
      hasColumnFilter: hasColumnFilter ?? this.hasColumnFilter,
      columnFilterDetail: columnFilterDetail ?? this.columnFilterDetail,
      canFreezePanesHere: canFreezePanesHere ?? this.canFreezePanesHere,
      hasFreezePane: hasFreezePane ?? this.hasFreezePane,
      canFindThisValue: canFindThisValue ?? this.canFindThisValue,
    );
  }
}
