import '../../model/cell/cell_address.dart';
import '../../model/cell/cell_data.dart';
import '../../model/cell/cell_validation.dart';
import '../../model/workbook_sheet.dart';

/// Advanced Data Validation Engine
/// Supports:
/// - List validation (dropdown)
/// - Number range validation
/// - Date range validation
/// - Text length validation
/// - Custom formula validation
/// - Input messages and error alerts
/// - Circle invalid data detection
class DataValidationEngine {
  DataValidationEngine();

  final Map<String, CellValidation> _validations = {};
  final Set<CellAddress> _invalidCells = {};

  /// Add validation rule to a cell or range
  void addValidation({
    required WorkbookSheet sheet,
    required CellAddress start,
    CellAddress? end,
    required ValidationType type,
    String? min,
    String? max,
    List<String>? options,
    String? pattern,
    String? errorMessage,
    bool ignoreBlank = true,
    bool showInputMessage = true,
    String? inputTitle,
    String? inputMessage,
    bool showErrorAlert = true,
    String? errorTitle,
  }) {
    final validation = CellValidation(
      type: type,
      min: min,
      max: max,
      options: options,
      pattern: pattern,
      errorMessage: errorMessage,
    );

    // Apply to single cell or range
    if (end == null) {
      _validations[start.toString()] = validation;
    } else {
      for (var row = start.row; row <= end.row; row++) {
        for (var col = start.col; col <= end.col; col++) {
          _validations[CellAddress(row, col).toString()] = validation;
        }
      }
    }

    // Revalidate affected cells
    _revalidateRange(sheet, start, end ?? start);
  }

  /// Remove validation from cell(s)
  void removeValidation({
    required WorkbookSheet sheet,
    required CellAddress start,
    CellAddress? end,
  }) {
    if (end == null) {
      _validations.remove(start.toString());
    } else {
      for (var row = start.row; row <= end.row; row++) {
        for (var col = start.col; col <= end.col; col++) {
          _validations.remove(CellAddress(row, col).toString());
        }
      }
    }

    _revalidateRange(sheet, start, end ?? start);
  }

  /// Validate a cell value
  ValidationResult validateCell(
    WorkbookSheet sheet,
    CellAddress address,
    String value,
  ) {
    final key = address.toString();
    final validation = _validations[key];

    if (validation == null) {
      return ValidationResult(valid: true);
    }

    // TODO: Check ignore blank - need to store ignoreBlank setting per validation
    // if (ignoreBlank && value.isEmpty) {
    //   return ValidationResult(valid: true);
    // }

    final isValid = validation.validate(value);
    
    return ValidationResult(
      valid: isValid,
      errorMessage: isValid ? null : (validation.errorMessage ?? 'Invalid value'),
    );
  }

  /// Get all invalid cells in sheet
  Set<CellAddress> findInvalidCells(WorkbookSheet sheet) {
    _invalidCells.clear();

    for (var row = 0; row < sheet.rowCount; row++) {
      for (var col = 0; col < sheet.columnCount; col++) {
        final address = CellAddress(row, col);
        final cell = sheet.getCell(address);
        
        if (cell != null) {
          final result = validateCell(sheet, address, cell.value);
          if (!result.valid) {
            _invalidCells.add(address);
          }
        }
      }
    }

    return _invalidCells;
  }

  /// Get validation for a cell
  CellValidation? getValidation(CellAddress address) {
    return _validations[address.toString()];
  }

  /// Check if cell has dropdown list
  bool hasDropdown(CellAddress address) {
    final validation = _validations[address.toString()];
    return validation?.type == ValidationType.list;
  }

  /// Get list values for dropdown
  List<String> getListValues(CellAddress address, WorkbookSheet sheet) {
    final validation = _validations[address.toString()];
    if (validation == null || validation.type != ValidationType.list) {
      return [];
    }

    // Return options if provided
    if (validation.options != null && validation.options!.isNotEmpty) {
      return validation.options!;
    }

    return [];
  }

  void _revalidateRange(
    WorkbookSheet sheet,
    CellAddress start,
    CellAddress end,
  ) {
    for (var row = start.row; row <= end.row; row++) {
      for (var col = start.col; col <= end.col; col++) {
        final address = CellAddress(row, col);
        final cell = sheet.getCell(address);
        
        if (cell != null) {
          final result = validateCell(sheet, address, cell.value);
          
          if (result.valid) {
            _invalidCells.remove(address);
          } else {
            _invalidCells.add(address);
          }
        }
      }
    }
  }
}

/// Result of validation check
class ValidationResult {
  ValidationResult({
    required this.valid,
    this.errorMessage,
  });

  final bool valid;
  final String? errorMessage;
}
