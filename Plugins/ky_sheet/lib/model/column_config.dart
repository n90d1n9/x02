class ColumnConfig {
  final int index;
  final double width;
  final bool hidden;

  ColumnConfig({required this.index, this.width = 100, this.hidden = false});

  ColumnConfig copyWith({int? index, double? width, bool? hidden}) =>
      ColumnConfig(
        index: index ?? this.index,
        width: width ?? this.width,
        hidden: hidden ?? this.hidden,
      );

  Map<String, dynamic> toJson() => {
    'index': index,
    'width': width,
    'hidden': hidden,
  };

  factory ColumnConfig.fromJson(Map<String, dynamic> json) => ColumnConfig(
    index: json['index'],
    width: (json['width'] as num?)?.toDouble() ?? 100,
    hidden: json['hidden'] ?? false,
  );
}
