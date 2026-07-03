/// Common models used across MCP server handlers

/// Represents a cell reference in a spreadsheet
class CellPosition {
  final int row;
  final int column;

  const CellPosition({required this.row, required this.column});

  String get address {
    return '${_getColumnLetter(column)}$row';
  }

  static String _getColumnLetter(int column) {
    if (column < 1) throw ArgumentError('Column must be >= 1');
    
    String result = '';
    int col = column - 1;
    
    while (col >= 0) {
      result = String.fromCharCode((col % 26) + 65) + result;
      col = (col ~/ 26) - 1;
    }
    
    return result;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CellPosition &&
          runtimeType == other.runtimeType &&
          row == other.row &&
          column == other.column;

  @override
  int get hashCode => row.hashCode ^ column.hashCode;
}

/// Represents a range of cells
class CellRange {
  final int startRow;
  final int startColumn;
  final int endRow;
  final int endColumn;

  const CellRange({
    required this.startRow,
    required this.startColumn,
    required this.endRow,
    required this.endColumn,
  });

  String get address {
    return '${CellPosition(row: startRow, column: startColumn).address}:'
        '${CellPosition(row: endRow, column: endColumn).address}';
  }

  int get rowCount => endRow - startRow + 1;
  int get columnCount => endColumn - startColumn + 1;
  int get totalCells => rowCount * columnCount;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CellRange &&
          runtimeType == other.runtimeType &&
          startRow == other.startRow &&
          startColumn == other.startColumn &&
          endRow == other.endRow &&
          endColumn == other.endColumn;

  @override
  int get hashCode =>
      startRow.hashCode ^ startColumn.hashCode ^ endRow.hashCode ^ endColumn.hashCode;
}

/// Response format for MCP tool calls
class ToolResponse {
  final bool success;
  final String? error;
  final Map<String, dynamic>? data;
  final String? message;

  ToolResponse({
    required this.success,
    this.error,
    this.data,
    this.message,
  });

  Map<String, dynamic> toJson() {
    final result = <String, dynamic>{'success': success};
    
    if (!success && error != null) {
      result['error'] = error;
    }
    
    if (data != null) {
      result.addAll(data!);
    }
    
    if (message != null) {
      result['message'] = message;
    }
    
    return result;
  }

  factory ToolResponse.success(Map<String, dynamic>? data, [String? message]) {
    return ToolResponse(success: true, data: data, message: message);
  }

  factory ToolResponse.failure(String error) {
    return ToolResponse(success: false, error: error);
  }
}

/// Format configuration for cells
class FormatConfig {
  bool? bold;
  bool? italic;
  bool? underline;
  double? fontSize;
  String? fontFamily;
  String? foregroundColor;
  String? backgroundColor;
  String? horizontalAlignment;
  String? verticalAlignment;
  String? numberFormat;
  BorderConfig? border;

  FormatConfig({
    this.bold,
    this.italic,
    this.underline,
    this.fontSize,
    this.fontFamily,
    this.foregroundColor,
    this.backgroundColor,
    this.horizontalAlignment,
    this.verticalAlignment,
    this.numberFormat,
    this.border,
  });

  factory FormatConfig.fromJson(Map<String, dynamic> json) {
    return FormatConfig(
      bold: json['bold'] as bool?,
      italic: json['italic'] as bool?,
      underline: json['underline'] as bool?,
      fontSize: (json['font_size'] as num?)?.toDouble(),
      fontFamily: json['font_family'] as String?,
      foregroundColor: json['foreground_color'] as String?,
      backgroundColor: json['background_color'] as String?,
      horizontalAlignment: json['horizontal_alignment'] as String?,
      verticalAlignment: json['vertical_alignment'] as String?,
      numberFormat: json['number_format'] as String?,
      border: json['border'] != null 
          ? BorderConfig.fromJson(json['border'] as Map<String, dynamic>)
          : null,
    );
  }
}

/// Border configuration
class BorderConfig {
  BorderSideConfig? top;
  BorderSideConfig? bottom;
  BorderSideConfig? left;
  BorderSideConfig? right;

  BorderConfig({this.top, this.bottom, this.left, this.right});

  factory BorderConfig.fromJson(Map<String, dynamic> json) {
    return BorderConfig(
      top: json['top'] != null 
          ? BorderSideConfig.fromJson(json['top'] as Map<String, dynamic>)
          : null,
      bottom: json['bottom'] != null 
          ? BorderSideConfig.fromJson(json['bottom'] as Map<String, dynamic>)
          : null,
      left: json['left'] != null 
          ? BorderSideConfig.fromJson(json['left'] as Map<String, dynamic>)
          : null,
      right: json['right'] != null 
          ? BorderSideConfig.fromJson(json['right'] as Map<String, dynamic>)
          : null,
    );
  }
}

/// Border side configuration
class BorderSideConfig {
  String? color;
  double? width;
  String? style;

  BorderSideConfig({this.color, this.width, this.style});

  factory BorderSideConfig.fromJson(Map<String, dynamic> json) {
    return BorderSideConfig(
      color: json['color'] as String?,
      width: (json['width'] as num?)?.toDouble(),
      style: json['style'] as String?,
    );
  }
}

/// Chart configuration
class ChartConfig {
  String type;
  String dataRange;
  String? title;
  Map<String, dynamic>? position;
  bool? showLegend;
  bool? showTitle;

  ChartConfig({
    required this.type,
    required this.dataRange,
    this.title,
    this.position,
    this.showLegend,
    this.showTitle,
  });

  factory ChartConfig.fromJson(Map<String, dynamic> json) {
    return ChartConfig(
      type: json['chart_type'] as String,
      dataRange: json['data_range'] as String,
      title: json['title'] as String?,
      position: json['position'] as Map<String, dynamic>?,
      showLegend: json['show_legend'] as bool?,
      showTitle: json['show_title'] as bool?,
    );
  }
}

/// Sort configuration
class SortConfig {
  int sortColumn;
  String sortOrder;

  SortConfig({
    required this.sortColumn,
    this.sortOrder = 'ascending',
  });
}

/// Filter criteria
class FilterCriteria {
  final String column;
  final String operator;
  final dynamic value;

  FilterCriteria({
    required this.column,
    this.operator = 'equals',
    required this.value,
  });
}

/// Validation configuration
class ValidationConfig {
  final String type;
  final Map<String, dynamic>? criteria;

  ValidationConfig({
    required this.type,
    this.criteria,
  });
}
