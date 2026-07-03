import 'package:uuid/uuid.dart';

class DocumentTable {
  final String id;
  final int rows;
  final int columns;
  final List<List<String>> data;
  final bool hasHeader;
  const DocumentTable({
    required this.id,
    required this.rows,
    required this.columns,
    required this.data,
    this.hasHeader = true,
  });

  DocumentTable copyWith({
    String? id,
    int? rows,
    int? columns,
    List<List<String>>? data,
    bool? hasHeader,
  }) {
    return DocumentTable(
      id: id ?? this.id,
      rows: rows ?? this.rows,
      columns: columns ?? this.columns,
      data: data ?? this.data,
      hasHeader: hasHeader ?? this.hasHeader,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'rows': rows,
    'columns': columns,
    'data': data,
    'hasHeader': hasHeader,
  };
  factory DocumentTable.fromJson(Map<String, dynamic> json) => DocumentTable(
    id: json['id'],
    rows: json['rows'],
    columns: json['columns'],
    data: List<List<String>>.from(
      json['data'].map((row) => List<String>.from(row)),
    ),
    hasHeader: json['hasHeader'] ?? true,
  );
  factory DocumentTable.empty(int rows, int columns) {
    return DocumentTable(
      id: const Uuid().v4(),
      rows: rows,
      columns: columns,
      data: List.generate(rows, (_) => List.generate(columns, (_) => '')),
      hasHeader: true,
    );
  }
}
