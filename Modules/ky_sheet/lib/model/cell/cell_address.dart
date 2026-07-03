class CellAddress {
  final int row;
  final int col;

  CellAddress(this.row, this.col);

  @override
  bool operator ==(Object other) =>
      other is CellAddress && row == other.row && col == other.col;

  @override
  int get hashCode => Object.hash(row, col);

  String get label => '${colToLabel(col)}${row + 1}';

  static String colToLabel(int col) {
    String label = '';
    int temp = col + 1;
    while (temp > 0) {
      temp--;
      label = String.fromCharCode(65 + (temp % 26)) + label;
      temp ~/= 26;
    }
    return label;
  }

  Map<String, dynamic> toJson() => {'row': row, 'col': col};

  factory CellAddress.fromJson(Map<String, dynamic> json) =>
      CellAddress(json['row'], json['col']);
}
