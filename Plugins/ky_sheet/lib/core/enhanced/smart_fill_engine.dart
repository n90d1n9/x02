import 'dart:math' as math;

import '../../model/cell/cell_address.dart';
import '../../model/cell/cell_data.dart';
import '../../model/workbook_sheet.dart';

/// Smart Fill Engine - Advanced auto-fill capabilities similar to Excel's Flash Fill
/// Supports:
/// - Pattern recognition (numbers, dates, text patterns)
/// - Series generation (linear, growth, date, auto-fill)
/// - Custom pattern learning from examples
/// - AI-assisted fill suggestions
class SmartFillEngine {
  SmartFillEngine();

  /// Fill a range with smart pattern detection
  List<CellData> fillRange({
    required WorkbookSheet sheet,
    required CellAddress startAddress,
    required CellAddress endAddress,
    required FillDirection direction,
    FillType? fillType,
    int? stepValue,
    double? growthFactor,
    DateTime? stopDate,
  }) {
    final results = <CellData>[];

    // Get source data from the starting cell(s)
    final sourceData = _getSourceData(sheet, startAddress, direction);

    // Detect or use specified fill type
    final detectedType = fillType ?? _detectFillType(sourceData);

    switch (detectedType) {
      case FillType.linearSeries:
        return _fillLinearSeries(
          sourceData,
          startAddress,
          endAddress,
          direction,
          stepValue: stepValue,
        );
      case FillType.growthSeries:
        return _fillGrowthSeries(
          sourceData,
          startAddress,
          endAddress,
          direction,
          growthFactor: growthFactor,
        );
      case FillType.dateSeries:
        return _fillDateSeries(
          sourceData,
          startAddress,
          endAddress,
          direction,
          stepValue: stepValue,
          stopDate: stopDate,
        );
      case FillType.autoFill:
        return _fillAutoPattern(
          sourceData,
          startAddress,
          endAddress,
          direction,
        );
      case FillType.flashFill:
        return _fillFlashFill(
          sourceData,
          startAddress,
          endAddress,
          direction,
        );
    }
  }

  /// Detect the appropriate fill type based on source data
  FillType _detectFillType(List<CellData> sourceData) {
    if (sourceData.isEmpty) return FillType.autoFill;

    // Check if all values are numbers
    final numbers = sourceData
        .map((d) => double.tryParse(d.value))
        .where((n) => n != null)
        .toList();

    if (numbers.length == sourceData.length && numbers.isNotEmpty) {
      // Check for linear pattern
      if (_isLinearSequence(numbers.cast<double>())) {
        return FillType.linearSeries;
      }
      // Check for growth pattern
      if (_isGrowthSequence(numbers.cast<double>())) {
        return FillType.growthSeries;
      }
    }

    // Check for date pattern
    final dates = sourceData
        .map((d) => _tryParseDate(d.value))
        .where((d) => d != null)
        .toList();

    if (dates.length == sourceData.length && dates.isNotEmpty) {
      return FillType.dateSeries;
    }

    // Check for text pattern that could be flash fill
    if (sourceData.any((d) => d.value.contains(RegExp(r'[A-Za-z]')))) {
      return FillType.flashFill;
    }

    return FillType.autoFill;
  }

  /// Check if numbers form a linear sequence
  bool _isLinearSequence(List<double> numbers) {
    if (numbers.length < 2) return false;

    final diff = numbers[1] - numbers[0];
    for (var i = 2; i < numbers.length; i++) {
      if ((numbers[i] - numbers[i - 1] - diff).abs() > 0.0001) {
        return false;
      }
    }
    return true;
  }

  /// Check if numbers form a growth sequence
  bool _isGrowthSequence(List<double> numbers) {
    if (numbers.length < 2 || numbers.any((n) => n == 0)) return false;

    final ratio = numbers[1] / numbers[0];
    for (var i = 2; i < numbers.length; i++) {
      if ((numbers[i] / numbers[i - 1] - ratio).abs() > 0.0001) {
        return false;
      }
    }
    return true;
  }

  DateTime? _tryParseDate(String value) {
    // Try common date formats
    final formats = [
      RegExp(r'^\d{4}-\d{2}-\d{2}$'), // YYYY-MM-DD
      RegExp(r'^\d{2}/\d{2}/\d{4}$'), // MM/DD/YYYY
      RegExp(r'^\d{2}-\d{2}-\d{4}$'), // DD-MM-YYYY
    ];

    if (!formats.any((f) => f.hasMatch(value))) return null;

    try {
      return DateTime.parse(value);
    } catch (_) {
      return null;
    }
  }

  List<CellData> _getSourceData(
    WorkbookSheet sheet,
    CellAddress startAddress,
    FillDirection direction,
  ) {
    final source = <CellData>[];

    // Get 1-2 cells in the opposite direction of fill to detect pattern
    switch (direction) {
      case FillDirection.down:
        for (var row = math.max(0, startAddress.row - 2);
            row < startAddress.row;
            row++) {
          final cell = sheet.getCell(CellAddress(row, startAddress.col));
          if (cell != null) source.add(cell);
        }
        break;
      case FillDirection.right:
        for (var col = math.max(0, startAddress.col - 2);
            col < startAddress.col;
            col++) {
          final cell = sheet.getCell(CellAddress(startAddress.row, col));
          if (cell != null) source.add(cell);
        }
        break;
      case FillDirection.up:
        for (var row = startAddress.row + 1;
            row <= math.min(startAddress.row + 2, sheet.rowCount - 1);
            row++) {
          final cell = sheet.getCell(CellAddress(row, startAddress.col));
          if (cell != null) source.add(cell);
        }
        break;
      case FillDirection.left:
        for (var col = startAddress.col + 1;
            col <= math.min(startAddress.col + 2, sheet.columnCount - 1);
            col++) {
          final cell = sheet.getCell(CellAddress(startAddress.row, col));
          if (cell != null) source.add(cell);
        }
        break;
    }

    return source;
  }

  List<CellData> _fillLinearSeries(
    List<CellData> sourceData,
    CellAddress startAddress,
    CellAddress endAddress,
    FillDirection direction, {
    int? stepValue,
  }) {
    final results = <CellData>[];

    // Calculate step from source data or use provided value
    double step = stepValue?.toDouble() ?? 1.0;
    if (sourceData.length >= 2) {
      final first = double.tryParse(sourceData.first.value) ?? 0;
      final second = double.tryParse(sourceData.last.value) ?? first + step;
      step = second - first;
    }

    final startValue = double.tryParse(sourceData.lastOrNull?.value ?? '0') ?? 0;

    var count = 0;
    _iterateRange(startAddress, endAddress, direction, (address, index) {
      final newValue = startValue + (step * index);
      results.add(CellData(value: newValue.toString()));
      count++;
    });

    return results;
  }

  List<CellData> _fillGrowthSeries(
    List<CellData> sourceData,
    CellAddress startAddress,
    CellAddress endAddress,
    FillDirection direction, {
    double? growthFactor,
  }) {
    final results = <CellData>[];

    // Calculate growth factor from source data or use provided value
    double factor = growthFactor ?? 2.0;
    if (sourceData.length >= 2) {
      final first = double.tryParse(sourceData.first.value) ?? 1;
      final second = double.tryParse(sourceData.last.value) ?? first * factor;
      if (first != 0) factor = second / first;
    }

    final startValue = double.tryParse(sourceData.lastOrNull?.value ?? '1') ?? 1;

    _iterateRange(startAddress, endAddress, direction, (address, index) {
      final newValue = startValue * math.pow(factor, index);
      results.add(CellData(value: newValue.toString()));
    });

    return results;
  }

  List<CellData> _fillDateSeries(
    List<CellData> sourceData,
    CellAddress startAddress,
    CellAddress endAddress,
    FillDirection direction, {
    int? stepValue,
    DateTime? stopDate,
  }) {
    final results = <CellData>[];

    // Default to daily increment
    int daysStep = stepValue ?? 1;

    DateTime startDate;
    if (sourceData.isNotEmpty) {
      final parsed = _tryParseDate(sourceData.last.value);
      startDate = parsed ?? DateTime.now();
    } else {
      startDate = DateTime.now();
    }

    _iterateRange(startAddress, endAddress, direction, (address, index) {
      final newDate = startDate.add(Duration(days: daysStep * index));
      
      // Check stop date
      if (stopDate != null && newDate.isAfter(stopDate)) {
        return;
      }
      
      results.add(CellData(value: _formatDate(newDate)));
    });

    return results;
  }

  List<CellData> _fillAutoPattern(
    List<CellData> sourceData,
    CellAddress startAddress,
    CellAddress endAddress,
    FillDirection direction,
  ) {
    final results = <CellData>[];

    if (sourceData.isEmpty) {
      _iterateRange(startAddress, endAddress, direction, (address, index) {
        results.add(CellData(value: ''));
      });
      return results;
    }

    // Simple pattern: repeat or continue based on content
    final pattern = sourceData.map((d) => d.value).toList();
    
    _iterateRange(startAddress, endAddress, direction, (address, index) {
      final value = pattern[index % pattern.length];
      results.add(CellData(value: value));
    });

    return results;
  }

  List<CellData> _fillFlashFill(
    List<CellData> sourceData,
    CellAddress startAddress,
    CellAddress endAddress,
    FillDirection direction,
  ) {
    final results = <CellData>[];

    // Flash Fill attempts to recognize patterns in text
    // Examples: extracting first names, formatting phone numbers, etc.
    
    if (sourceData.isEmpty) {
      _iterateRange(startAddress, endAddress, direction, (address, index) {
        results.add(CellData(value: ''));
      });
      return results;
    }

    // Analyze pattern in source data
    final pattern = _analyzeTextPattern(sourceData);
    
    _iterateRange(startAddress, endAddress, direction, (address, index) {
      // Apply detected pattern
      final value = pattern.isNotEmpty ? pattern[index % pattern.length] : '';
      results.add(CellData(value: value));
    });

    return results;
  }

  List<String> _analyzeTextPattern(List<CellData> sourceData) {
    // Simplified pattern analysis
    // In production, this would use ML or more sophisticated algorithms
    
    final patterns = <String>[];
    
    for (final data in sourceData) {
      final value = data.value;
      
      // Detect common patterns
      if (value.contains('@')) {
        // Email pattern - extract domain
        final parts = value.split('@');
        if (parts.length == 2) {
          patterns.add(parts[1]);
        }
      } else if (RegExp(r'\d').hasMatch(value)) {
        // Extract numbers
        final numbers = value.replaceAll(RegExp(r'\D'), '');
        patterns.add(numbers);
      } else {
        patterns.add(value);
      }
    }
    
    return patterns;
  }

  void _iterateRange(
    CellAddress start,
    CellAddress end,
    FillDirection direction,
    void Function(CellAddress address, int index) callback,
  ) {
    var index = 0;

    switch (direction) {
      case FillDirection.down:
        for (var row = start.row; row <= end.row; row++) {
          callback(CellAddress(row, start.col), index++);
        }
        break;
      case FillDirection.right:
        for (var col = start.col; col <= end.col; col++) {
          callback(CellAddress(start.row, col), index++);
        }
        break;
      case FillDirection.up:
        for (var row = start.row; row >= end.row; row--) {
          callback(CellAddress(row, start.col), index++);
        }
        break;
      case FillDirection.left:
        for (var col = start.col; col >= end.col; col--) {
          callback(CellAddress(start.row, col), index++);
        }
        break;
    }
  }

  String _formatDate(DateTime date) {
    // Format as YYYY-MM-DD by default
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}

/// Direction for fill operations
enum FillDirection {
  down,
  right,
  up,
  left,
}

/// Type of fill operation
enum FillType {
  /// Copy values without pattern
  autoFill,
  
  /// Linear series (1, 2, 3, 4...)
  linearSeries,
  
  /// Growth series (2, 4, 8, 16...)
  growthSeries,
  
  /// Date series (Jan 1, Jan 2, Jan 3...)
  dateSeries,
  
  /// AI-powered pattern recognition (Flash Fill)
  flashFill,
}
