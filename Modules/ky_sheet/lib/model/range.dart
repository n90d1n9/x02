/// Represents a range of cells
class Range {
  final int startRow;
  final int startCol;
  final int endRow;
  final int endCol;

  Range({
    required this.startRow,
    required this.startCol,
    required this.endRow,
    required this.endCol,
  });
}
