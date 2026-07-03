/// Edge visibility for the active structured-table frame around a grid cell.
class SheetTableCellOutline {
  const SheetTableCellOutline({
    this.top = false,
    this.right = false,
    this.bottom = false,
    this.left = false,
  });

  /// Whether the top edge of the cell participates in the active table frame.
  final bool top;

  /// Whether the right edge of the cell participates in the active table frame.
  final bool right;

  /// Whether the bottom edge of the cell participates in the active table frame.
  final bool bottom;

  /// Whether the left edge of the cell participates in the active table frame.
  final bool left;

  /// Whether at least one edge should be painted.
  bool get hasVisibleEdge => top || right || bottom || left;
}
