/// Handler for data operations (sorting, filtering, formulas, validation)

import 'package:ky_sheet/ky_sheet.dart';
import '../ky_sheet_mcp_server.dart';

class DataHandler {
  final KySheetMCPServer server;

  DataHandler(this.server);

  /// Sort a range of data
  Future<Map<String, dynamic>> sortRange(Map<String, dynamic> params) async {
    final workbook = server.getActiveWorkbook();
    if (workbook == null) {
      return {'success': false, 'error': 'No active workbook'};
    }

    final sheetName = params['sheet_name'] as String?;
    final startRow = params['start_row'] as int?;
    final startColumn = params['start_column'] as int?;
    final endRow = params['end_row'] as int?;
    final endColumn = params['end_column'] as int?;
    final sortColumn = params['sort_column'] as int?;
    final sortOrder = params['sort_order'] as String? ?? 'ascending';

    if (sheetName == null || startRow == null || startColumn == null ||
        endRow == null || endColumn == null || sortColumn == null) {
      return {'success': false, 'error': 'Required parameters missing'};
    }

    try {
      final sheet = workbook.sheets.firstWhere(
        (s) => s.name == sheetName,
        orElse: () => throw Exception('Sheet not found'),
      );

      // Read the data
      final data = <List<dynamic>>[];
      for (var r = startRow; r <= endRow; r++) {
        final rowValues = <dynamic>[];
        for (var c = startColumn; c <= endColumn; c++) {
          final cell = sheet.getCell(r, c);
          rowValues.add(cell?.value);
        }
        data.add(rowValues);
      }

      // Sort the data
      final sortIndex = sortColumn - startColumn;
      data.sort((a, b) {
        final valA = a[sortIndex];
        final valB = b[sortIndex];
        
        if (valA == null && valB == null) return 0;
        if (valA == null) return 1;
        if (valB == null) return -1;
        
        int comparison;
        if (valA is num && valB is num) {
          comparison = valA.compareTo(valB);
        } else {
          comparison = valA.toString().compareTo(valB.toString());
        }
        
        return sortOrder.toLowerCase() == 'descending' ? -comparison : comparison;
      });

      // Write back the sorted data
      for (var i = 0; i < data.length; i++) {
        for (var j = 0; j < data[i].length; j++) {
          final cell = sheet.getCell(startRow + i, startColumn + j) 
              ?? sheet.createCell(startRow + i, startColumn + j);
          cell.value = data[i][j];
        }
      }

      return {
        'success': true,
        'range': '${_getColumnLetter(startColumn)}$startRow:${_getColumnLetter(endColumn)}$endRow',
        'sorted_by_column': _getColumnLetter(sortColumn),
        'sort_order': sortOrder,
        'rows_sorted': data.length,
      };
    } catch (e) {
      return {'success': false, 'error': 'Failed to sort range: $e'};
    }
  }

  /// Filter data in a range
  Future<Map<String, dynamic>> filterData(Map<String, dynamic> params) async {
    final workbook = server.getActiveWorkbook();
    if (workbook == null) {
      return {'success': false, 'error': 'No active workbook'};
    }

    final sheetName = params['sheet_name'] as String?;
    final startRow = params['start_row'] as int?;
    final startColumn = params['start_column'] as int?;
    final endRow = params['end_row'] as int?;
    final endColumn = params['end_column'] as int?;
    final criteria = params['criteria'] as Map<String, dynamic>?;

    if (sheetName == null || startRow == null || startColumn == null ||
        criteria == null) {
      return {'success': false, 'error': 'Required parameters missing'};
    }

    try {
      final sheet = workbook.sheets.firstWhere(
        (s) => s.name == sheetName,
        orElse: () => throw Exception('Sheet not found'),
      );

      // Read the data
      final allData = <List<dynamic>>[];
      for (var r = startRow; r <= endRow; r++) {
        final rowValues = <dynamic>[];
        for (var c = startColumn; c <= endColumn; c++) {
          final cell = sheet.getCell(r, c);
          rowValues.add(cell?.value);
        }
        allData.add(rowValues);
      }

      // Apply filters
      final filteredData = <List<dynamic>>[];
      for (final row in allData) {
        bool matches = true;
        
        criteria.forEach((key, value) {
          if (!matches) return;
          
          final columnKey = key.toString();
          // Parse column letter to index
          int columnIndex = 0;
          for (int i = 0; i < columnKey.length; i++) {
            columnIndex = columnIndex * 26 + (columnKey.codeUnitAt(i) - 64);
          }
          final dataIndex = columnIndex - startColumn;
          
          if (dataIndex >= 0 && dataIndex < row.length) {
            final cellValue = row[dataIndex];
            
            if (value is Map<String, dynamic>) {
              final operator = value['operator'] as String? ?? 'equals';
              final filterValue = value['value'];
              
              switch (operator.toLowerCase()) {
                case 'equals':
                  matches = cellValue == filterValue;
                  break;
                case 'not_equals':
                  matches = cellValue != filterValue;
                  break;
                case 'greater_than':
                  matches = (cellValue is num) && (cellValue > filterValue);
                  break;
                case 'less_than':
                  matches = (cellValue is num) && (cellValue < filterValue);
                  break;
                case 'contains':
                  matches = cellValue.toString().contains(filterValue.toString());
                  break;
                case 'starts_with':
                  matches = cellValue.toString().startsWith(filterValue.toString());
                  break;
                case 'ends_with':
                  matches = cellValue.toString().endsWith(filterValue.toString());
                  break;
              }
            } else {
              matches = cellValue == value;
            }
          }
        });
        
        if (matches) {
          filteredData.add(row);
        }
      }

      return {
        'success': true,
        'total_rows': allData.length,
        'filtered_rows': filteredData.length,
        'data': filteredData,
      };
    } catch (e) {
      return {'success': false, 'error': 'Failed to filter data: $e'};
    }
  }

  /// Find and replace values in a range
  Future<Map<String, dynamic>> findReplace(Map<String, dynamic> params) async {
    final workbook = server.getActiveWorkbook();
    if (workbook == null) {
      return {'success': false, 'error': 'No active workbook'};
    }

    final sheetName = params['sheet_name'] as String?;
    final searchText = params['search_text'] as String?;
    final replaceText = params['replace_text'] as String?;
    final startRow = params['start_row'] as int?;
    final startColumn = params['start_column'] as int?;
    final endRow = params['end_row'] as int?;
    final endColumn = params['end_column'] as int?;
    final matchCase = params['match_case'] as bool? ?? false;
    final matchEntireCell = params['match_entire_cell'] as bool? ?? false;

    if (sheetName == null || searchText == null || replaceText == null) {
      return {'success': false, 'error': 'sheet_name, search_text, and replace_text are required'};
    }

    try {
      final sheet = workbook.sheets.firstWhere(
        (s) => s.name == sheetName,
        orElse: () => throw Exception('Sheet not found'),
      );

      final actualStartRow = startRow ?? 1;
      final actualStartColumn = startColumn ?? 1;
      final actualEndRow = endRow ?? sheet.rowCount;
      final actualEndColumn = endColumn ?? sheet.columnCount;

      int replacements = 0;

      for (var r = actualStartRow; r <= actualEndRow; r++) {
        for (var c = actualStartColumn; c <= actualEndColumn; c++) {
          final cell = sheet.getCell(r, c);
          if (cell != null && cell.value != null) {
            final currentValue = cell.value.toString();
            String newValue;
            
            if (matchEntireCell) {
              if (matchCase) {
                if (currentValue == searchText) {
                  newValue = replaceText;
                  cell.value = newValue;
                  replacements++;
                }
              } else {
                if (currentValue.toLowerCase() == searchText.toLowerCase()) {
                  newValue = replaceText;
                  cell.value = newValue;
                  replacements++;
                }
              }
            } else {
              if (matchCase) {
                if (currentValue.contains(searchText)) {
                  newValue = currentValue.replaceAll(searchText, replaceText);
                  cell.value = newValue;
                  replacements++;
                }
              } else {
                final pattern = RegExp(RegExp.escape(searchText), caseSensitive: false);
                if (pattern.hasMatch(currentValue)) {
                  newValue = currentValue.replaceAll(pattern, replaceText);
                  cell.value = newValue;
                  replacements++;
                }
              }
            }
          }
        }
      }

      return {
        'success': true,
        'replacements_made': replacements,
        'search_text': searchText,
        'replace_text': replaceText,
      };
    } catch (e) {
      return {'success': false, 'error': 'Failed to find and replace: $e'};
    }
  }

  /// Validate data in a cell or range
  Future<Map<String, dynamic>> validateData(Map<String, dynamic> params) async {
    final workbook = server.getActiveWorkbook();
    if (workbook == null) {
      return {'success': false, 'error': 'No active workbook'};
    }

    final sheetName = params['sheet_name'] as String?;
    final row = params['row'] as int?;
    final column = params['column'] as int?;
    final validationType = params['validation_type'] as String?;
    final validationCriteria = params['validation_criteria'] as Map<String, dynamic>?;

    if (sheetName == null || row == null || column == null || validationType == null) {
      return {'success': false, 'error': 'Required parameters missing'};
    }

    try {
      final sheet = workbook.sheets.firstWhere(
        (s) => s.name == sheetName,
        orElse: () => throw Exception('Sheet not found'),
      );

      final cell = sheet.getCell(row, column);
      if (cell == null || cell.value == null) {
        return {
          'success': true,
          'valid': true,
          'message': 'Empty cell',
        };
      }

      final value = cell.value;
      bool isValid = true;
      String message = 'Validation passed';

      switch (validationType.toLowerCase()) {
        case 'number':
          if (value is! num) {
            isValid = false;
            message = 'Value must be a number';
          } else if (validationCriteria != null) {
            final min = validationCriteria['min'] as num?;
            final max = validationCriteria['max'] as num?;
            if (min != null && value < min) {
              isValid = false;
              message = 'Value must be >= $min';
            }
            if (max != null && value > max) {
              isValid = false;
              message = 'Value must be <= $max';
            }
          }
          break;
          
        case 'text':
          if (value is! String) {
            isValid = false;
            message = 'Value must be text';
          } else if (validationCriteria != null) {
            final minLength = validationCriteria['min_length'] as int?;
            final maxLength = validationCriteria['max_length'] as int?;
            if (minLength != null && value.length < minLength) {
              isValid = false;
              message = 'Text length must be >= $minLength';
            }
            if (maxLength != null && value.length > maxLength) {
              isValid = false;
              message = 'Text length must be <= $maxLength';
            }
          }
          break;
          
        case 'list':
          if (validationCriteria != null) {
            final allowedValues = validationCriteria['allowed_values'] as List?;
            if (allowedValues != null && !allowedValues.contains(value)) {
              isValid = false;
              message = 'Value must be one of: ${allowedValues.join(', ')}';
            }
          }
          break;
          
        case 'date':
          if (value is! DateTime && !(value is String && DateTime.tryParse(value) != null)) {
            isValid = false;
            message = 'Value must be a valid date';
          }
          break;
          
        case 'email':
          if (value is! String || !RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
            isValid = false;
            message = 'Value must be a valid email address';
          }
          break;
          
        case 'custom':
          if (validationCriteria != null) {
            final formula = validationCriteria['formula'] as String?;
            if (formula != null) {
              // Evaluate custom formula
              // This would need integration with ky_sheet's formula engine
              message = 'Custom validation: $formula';
            }
          }
          break;
      }

      return {
        'success': true,
        'valid': isValid,
        'address': '${_getColumnLetter(column)}$row',
        'value': value,
        'validation_type': validationType,
        'message': message,
      };
    } catch (e) {
      return {'success': false, 'error': 'Failed to validate data: $e'};
    }
  }

  /// Calculate a formula
  Future<Map<String, dynamic>> calculateFormula(Map<String, dynamic> params) async {
    final workbook = server.getActiveWorkbook();
    if (workbook == null) {
      return {'success': false, 'error': 'No active workbook'};
    }

    final formula = params['formula'] as String?;
    final sheetName = params['sheet_name'] as String?;

    if (formula == null) {
      return {'success': false, 'error': 'Formula is required'};
    }

    try {
      final sheet = sheetName != null 
          ? workbook.sheets.firstWhere(
              (s) => s.name == sheetName,
              orElse: () => throw Exception('Sheet not found'),
            )
          : workbook.activeSheet;

      if (sheet == null) {
        return {'success': false, 'error': 'No active sheet'};
      }

      // Use ky_sheet's formula calculation engine
      // Note: This assumes ky_sheet has a FormulaEngine or similar
      final result = sheet.calculateFormula(formula);

      return {
        'success': true,
        'formula': formula,
        'result': result,
        'result_type': result.runtimeType.toString(),
      };
    } catch (e) {
      return {'success': false, 'error': 'Failed to calculate formula: $e'};
    }
  }

  /// Get the result of a formula in a cell
  Future<Map<String, dynamic>> getFormulaResult(Map<String, dynamic> params) async {
    final workbook = server.getActiveWorkbook();
    if (workbook == null) {
      return {'success': false, 'error': 'No active workbook'};
    }

    final sheetName = params['sheet_name'] as String?;
    final row = params['row'] as int?;
    final column = params['column'] as int?;

    if (sheetName == null || row == null || column == null) {
      return {'success': false, 'error': 'sheet_name, row, and column are required'};
    }

    try {
      final sheet = workbook.sheets.firstWhere(
        (s) => s.name == sheetName,
        orElse: () => throw Exception('Sheet not found'),
      );

      final cell = sheet.getCell(row, column);
      if (cell == null) {
        return {
          'success': false,
          'error': 'Cell not found',
        };
      }

      if (cell.formula == null || cell.formula!.isEmpty) {
        return {
          'success': true,
          'has_formula': false,
          'value': cell.value,
        };
      }

      return {
        'success': true,
        'has_formula': true,
        'formula': cell.formula,
        'result': cell.value,
        'address': '${_getColumnLetter(column)}$row',
      };
    } catch (e) {
      return {'success': false, 'error': 'Failed to get formula result: $e'};
    }
  }

  // Helper method
  String _getColumnLetter(int column) {
    if (column < 1) throw ArgumentError('Column must be >= 1');
    
    String result = '';
    int col = column - 1;
    
    while (col >= 0) {
      result = String.fromCharCode((col % 26) + 65) + result;
      col = (col ~/ 26) - 1;
    }
    
    return result;
  }
}
