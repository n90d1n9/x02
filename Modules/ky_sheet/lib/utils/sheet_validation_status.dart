import '../model/cell/cell_data.dart';
import '../model/cell/cell_validation.dart';

class SheetValidationStatus {
  const SheetValidationStatus({
    required this.hasValidation,
    required this.isValid,
    required this.description,
    this.errorMessage,
    this.options = const [],
  });

  final bool hasValidation;
  final bool isValid;
  final String description;
  final String? errorMessage;
  final List<String> options;

  bool get isInvalid => hasValidation && !isValid;

  bool get hasListOptions => options.isNotEmpty;

  String get tooltip {
    if (!hasValidation) return '';
    if (isValid) return description;
    return errorMessage ?? 'Value must match: $description';
  }

  factory SheetValidationStatus.fromCell(CellData cellData) {
    final validation = cellData.validation;
    if (validation == null || validation.type == ValidationType.none) {
      return const SheetValidationStatus(
        hasValidation: false,
        isValid: true,
        description: '',
      );
    }

    return SheetValidationStatus(
      hasValidation: true,
      isValid: validation.validate(cellData.value),
      description: validation.toString(),
      errorMessage: validation.errorMessage,
      options: validation.type == ValidationType.list
          ? validation.options ?? const []
          : const [],
    );
  }
}
