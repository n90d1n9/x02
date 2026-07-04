/// Pivot Field definitions for ky_sheet pivot tables.
/// 
/// Fields define how data is organized and calculated in a pivot table.
library pivot_field;

/// Areas where a pivot field can be placed
enum FieldArea {
  /// Row labels area
  rows,
  
  /// Column labels area
  columns,
  
  /// Values/data area
  values,
  
  /// Filter/page area
  filters,
}

/// Types of aggregation for value fields
enum AggregationType {
  /// Sum of values
  sum,
  
  /// Count of values
  count,
  
  /// Average of values
  average,
  
  /// Maximum value
  max,
  
  /// Minimum value
  min,
  
  /// Product of values
  product,
  
  /// Count of non-blank cells
  countA,
  
  /// Standard deviation (sample)
  stdev,
  
  /// Standard deviation (population)
  stdevP,
  
  /// Variance (sample)
  var,
  
  /// Variance (population)
  varP,
}

/// Custom calculations for value fields
enum CustomCalculation {
  /// No custom calculation
  none,
  
  /// Difference from base value
  differenceFrom,
  
  /// Percentage of base value
  percentOf,
  
  /// Percentage difference from base
  percentDifferenceFrom,
  
  /// Running total in
  runningTotalIn,
  
  /// Percentage of row total
  percentOfRowTotal,
  
  /// Percentage of column total
  percentOfColumnTotal,
  
  /// Percentage of grand total
  percentOfGrandTotal,
  
  /// Index calculation
  index,
}

/// Position for subtotals
enum SubtotalPosition {
  /// Show subtotals at the top of groups
  top,
  
  /// Show subtotals at the bottom of groups
  bottom,
  
  /// Don't show subtotals
  none,
}

/// Type of subtotal calculation
enum SubtotalType {
  /// Automatic (usually sum or count)
  automatic,
  
  /// Sum
  sum,
  
  /// Count
  count,
  
  /// Average
  average,
  
  /// Maximum
  max,
  
  /// Minimum
  min,
  
  /// Product
  product,
  
  /// Standard deviation
  stdev,
  
  /// Variance
  var,
}

/// Report layout styles
enum ReportLayout {
  /// Compact form (Excel default)
  compact,
  
  /// Outline form
  outline,
  
  /// Tabular form
  tabular,
}

/// Represents a field in a pivot table
class PivotField {
  /// Name of the field (must match source data column header)
  final String name;
  
  /// Custom display name for the field
  String? caption;
  
  /// Area where this field is placed
  FieldArea area = FieldArea.filters;
  
  /// Aggregation type for value fields
  AggregationType aggregation = AggregationType.sum;
  
  /// Custom calculation to apply
  CustomCalculation? customCalculation;
  
  /// Base field for custom calculations
  String? calculationBaseField;
  
  /// Base item for custom calculations
  String? calculationBaseItem;
  
  /// Subtotal type for row/column fields
  SubtotalType subtotal = SubtotalType.automatic;
  
  /// Whether to show subtotals for this field
  bool showSubtotal = true;
  
  /// Number format for display
  String? numberFormat;
  
  /// Sort order for this field
  FieldSortOrder sortOrder = FieldSortOrder.none;
  
  /// Field to sort by (if different from this field)
  String? sortByField;
  
  /// Whether this field is visible
  bool isVisible = true;
  
  /// Specific items to include (null means all)
  List<dynamic>? includedItems;
  
  /// Specific items to exclude
  List<dynamic>? excludedItems;
  
  /// Label filters for this field
  List<LabelFilter> labelFilters = [];
  
  /// Value filters for this field
  List<ValueFilter> valueFilters = [];
  
  /// Grouping configuration for date/numeric fields
  FieldGrouping? grouping;
  
  /// Create a new pivot field
  PivotField({
    required this.name,
    this.caption,
    this.area = FieldArea.filters,
    this.aggregation = AggregationType.sum,
    this.customCalculation,
    this.subtotal = SubtotalType.automatic,
    this.showSubtotal = true,
    this.numberFormat,
    this.sortOrder = FieldSortOrder.none,
  });
  
  /// Set aggregation type (fluent interface)
  PivotField withAggregation(AggregationType type) {
    aggregation = type;
    return this;
  }
  
  /// Set custom calculation (fluent interface)
  PivotField withCustomCalculation(
    CustomCalculation calc, {
    String? baseField,
    String? baseItem,
  }) {
    customCalculation = calc;
    calculationBaseField = baseField;
    calculationBaseItem = baseItem;
    return this;
  }
  
  /// Set number format (fluent interface)
  PivotField withNumberFormat(String format) {
    numberFormat = format;
    return this;
  }
  
  /// Set area (fluent interface)
  PivotField withArea(FieldArea fieldArea) {
    area = fieldArea;
    return this;
  }
  
  /// Apply a label filter
  void addLabelFilter(LabelFilter filter) {
    labelFilters.add(filter);
  }
  
  /// Apply a value filter
  void addValueFilter(ValueFilter filter) {
    valueFilters.add(filter);
  }
  
  /// Include specific items
  void includeItems(List<dynamic> items) {
    includedItems = items;
  }
  
  /// Exclude specific items
  void excludeItems(List<dynamic> items) {
    excludedItems = items;
  }
  
  /// Enable date grouping
  void groupByDate(DateGroupInterval interval) {
    grouping = FieldGrouping.date(interval);
  }
  
  /// Enable numeric grouping
  void groupByNumbers({
    required double start,
    required double end,
    required double step,
  }) {
    grouping = FieldGrouping.numeric(start: start, end: end, step: step);
  }
  
  /// Export field configuration to JSON
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'caption': caption,
      'area': area.name,
      'aggregation': aggregation.name,
      'customCalculation': customCalculation?.name,
      'calculationBaseField': calculationBaseField,
      'calculationBaseItem': calculationBaseItem,
      'subtotal': subtotal.name,
      'showSubtotal': showSubtotal,
      'numberFormat': numberFormat,
      'sortOrder': sortOrder.name,
      'sortByField': sortByField,
      'isVisible': isVisible,
      'includedItems': includedItems,
      'excludedItems': excludedItems,
      'labelFilters': labelFilters.map((f) => f.toJson()).toList(),
      'valueFilters': valueFilters.map((f) => f.toJson()).toList(),
      'grouping': grouping?.toJson(),
    };
  }
  
  /// Import field configuration from JSON
  factory PivotField.fromJson(Map<String, dynamic> json) {
    var field = PivotField(
      name: json['name'],
      caption: json['caption'],
      area: FieldArea.values.firstWhere(
        (e) => e.name == json['area'],
        orElse: () => FieldArea.filters,
      ),
      aggregation: AggregationType.values.firstWhere(
        (e) => e.name == json['aggregation'],
        orElse: () => AggregationType.sum,
      ),
      subtotal: SubtotalType.values.firstWhere(
        (e) => e.name == json['subtotal'],
        orElse: () => SubtotalType.automatic,
      ),
      sortOrder: FieldSortOrder.values.firstWhere(
        (e) => e.name == json['sortOrder'],
        orElse: () => FieldSortOrder.none,
      ),
    );
    
    if (json['customCalculation'] != null) {
      field.customCalculation = CustomCalculation.values.firstWhere(
        (e) => e.name == json['customCalculation'],
      );
    }
    
    field.calculationBaseField = json['calculationBaseField'];
    field.calculationBaseItem = json['calculationBaseItem'];
    field.showSubtotal = json['showSubtotal'] ?? true;
    field.numberFormat = json['numberFormat'];
    field.sortByField = json['sortByField'];
    field.isVisible = json['isVisible'] ?? true;
    field.includedItems = json['includedItems'] as List<dynamic>?;
    field.excludedItems = json['excludedItems'] as List<dynamic>?;
    
    if (json['labelFilters'] != null) {
      field.labelFilters = (json['labelFilters'] as List)
          .map((f) => LabelFilter.fromJson(f))
          .toList();
    }
    
    if (json['valueFilters'] != null) {
      field.valueFilters = (json['valueFilters'] as List)
          .map((f) => ValueFilter.fromJson(f))
          .toList();
    }
    
    if (json['grouping'] != null) {
      field.grouping = FieldGrouping.fromJson(json['grouping']);
    }
    
    return field;
  }
}

/// Sort order for pivot fields
enum FieldSortOrder {
  /// No sorting
  none,
  
  /// Ascending order
  ascending,
  
  /// Descending order
  descending,
}

/// Label filter for pivot fields
class LabelFilter {
  /// Type of label filter
  final LabelFilterType type;
  
  /// Value to compare against
  final String value;
  
  /// Second value for between filters
  final String? value2;
  
  /// Create a label filter
  const LabelFilter({
    required this.type,
    required this.value,
    this.value2,
  });
  
  /// Equals filter
  const LabelFilter.equals(String val)
      : this(type: LabelFilterType.equals, value: val);
  
  /// Not equals filter
  const LabelFilter.notEquals(String val)
      : this(type: LabelFilterType.notEquals, value: val);
  
  /// Begins with filter
  const LabelFilter.beginsWith(String val)
      : this(type: LabelFilterType.beginsWith, value: val);
  
  /// Ends with filter
  const LabelFilter.endsWith(String val)
      : this(type: LabelFilterType.endsWith, value: val);
  
  /// Contains filter
  const LabelFilter.contains(String val)
      : this(type: LabelFilterType.contains, value: val);
  
  /// Does not contain filter
  const LabelFilter.doesNotContain(String val)
      : this(type: LabelFilterType.doesNotContain, value: val);
  
  /// Between filter
  const LabelFilter.between(String val1, String val2)
      : this(type: LabelFilterType.between, value: val1, value2: val2);
  
  /// Export to JSON
  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'value': value,
      'value2': value2,
    };
  }
  
  /// Import from JSON
  factory LabelFilter.fromJson(Map<String, dynamic> json) {
    return LabelFilter(
      type: LabelFilterType.values.firstWhere(
        (e) => e.name == json['type'],
      ),
      value: json['value'],
      value2: json['value2'],
    );
  }
}

/// Types of label filters
enum LabelFilterType {
  equals,
  notEquals,
  beginsWith,
  endsWith,
  contains,
  doesNotContain,
  between,
}

/// Value filter for pivot fields
class ValueFilter {
  /// Type of value filter
  final ValueFilterType type;
  
  /// Data field to filter on
  final String dataField;
  
  /// Value to compare against
  final num value;
  
  /// Second value for between filters
  final num? value2;
  
  /// Create a value filter
  const ValueFilter({
    required this.type,
    required this.dataField,
    required this.value,
    this.value2,
  });
  
  /// Export to JSON
  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'dataField': dataField,
      'value': value,
      'value2': value2,
    };
  }
  
  /// Import from JSON
  factory ValueFilter.fromJson(Map<String, dynamic> json) {
    return ValueFilter(
      type: ValueFilterType.values.firstWhere(
        (e) => e.name == json['type'],
      ),
      dataField: json['dataField'],
      value: json['value'],
      value2: json['value2'],
    );
  }
}

/// Types of value filters
enum ValueFilterType {
  equals,
  notEquals,
  greaterThan,
  lessThan,
  between,
  topN,
  bottomN,
  aboveAverage,
  belowAverage,
}

/// Grouping configuration for pivot fields
class FieldGrouping {
  /// Type of grouping
  final GroupingType type;
  
  /// Date interval (for date grouping)
  final DateGroupInterval? dateInterval;
  
  /// Start value (for numeric grouping)
  final double? start;
  
  /// End value (for numeric grouping)
  final double? end;
  
  /// Step size (for numeric grouping)
  final double? step;
  
  /// Create date grouping
  const FieldGrouping.date(this.dateInterval)
      : type = GroupingType.date,
        start = null,
        end = null,
        step = null;
  
  /// Create numeric grouping
  const FieldGrouping.numeric({
    required this.start,
    required this.end,
    required this.step,
  })  : type = GroupingType.numeric,
        dateInterval = null;
  
  /// Export to JSON
  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'dateInterval': dateInterval?.name,
      'start': start,
      'end': end,
      'step': step,
    };
  }
  
  /// Import from JSON
  factory FieldGrouping.fromJson(Map<String, dynamic> json) {
    var type = GroupingType.values.firstWhere(
      (e) => e.name == json['type'],
    );
    
    if (type == GroupingType.date) {
      return FieldGrouping.date(
        DateGroupInterval.values.firstWhere(
          (e) => e.name == json['dateInterval'],
        ),
      );
    } else {
      return FieldGrouping.numeric(
        start: json['start'],
        end: json['end'],
        step: json['step'],
      );
    }
  }
}

/// Types of grouping
enum GroupingType {
  date,
  numeric,
}

/// Date grouping intervals
enum DateGroupInterval {
  seconds,
  minutes,
  hours,
  days,
  months,
  quarters,
  years,
}
