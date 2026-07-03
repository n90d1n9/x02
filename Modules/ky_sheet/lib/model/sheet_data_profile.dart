import 'cell/cell_address.dart';

class SheetDataProfile {
  const SheetDataProfile({
    required this.label,
    required this.totalCells,
    required this.filledCells,
    required this.blankCells,
    required this.numericCells,
    required this.textCells,
    required this.formulaCells,
    required this.invalidCells,
    required this.duplicateValueCells,
    required this.sum,
    this.min,
    this.max,
    this.topValues = const [],
    this.histogram = const [],
    this.fromSelection = true,
  });

  final String label;
  final int totalCells;
  final int filledCells;
  final int blankCells;
  final int numericCells;
  final int textCells;
  final int formulaCells;
  final int invalidCells;
  final int duplicateValueCells;
  final double sum;
  final double? min;
  final double? max;
  final List<SheetValueFrequency> topValues;
  final List<SheetNumericBucket> histogram;
  final bool fromSelection;

  bool get hasCells => totalCells > 0;
  bool get hasNumericValues => numericCells > 0;
  bool get hasQualityWarnings => invalidCells > 0 || duplicateValueCells > 0;

  double get fillRate => totalCells == 0 ? 0 : filledCells / totalCells;
  double get numericRate => filledCells == 0 ? 0 : numericCells / filledCells;
  double get formulaRate => filledCells == 0 ? 0 : formulaCells / filledCells;
  double? get average => numericCells == 0 ? null : sum / numericCells;
}

class SheetValueFrequency {
  const SheetValueFrequency({
    required this.value,
    required this.count,
    this.firstAddress,
  });

  final String value;
  final int count;
  final CellAddress? firstAddress;

  double shareOf(int total) => total == 0 ? 0 : count / total;
}

class SheetNumericBucket {
  const SheetNumericBucket({required this.label, required this.count});

  final String label;
  final int count;

  double shareOf(int total) => total == 0 ? 0 : count / total;
}
