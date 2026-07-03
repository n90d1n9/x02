import 'cell/cell_address.dart';
import 'cell/cell_selection.dart';

class SheetNamedRange {
  const SheetNamedRange({
    required this.id,
    required this.name,
    required this.selection,
  });

  final String id;
  final String name;
  final CellSelection selection;

  String get normalizedName => normalizeName(name).toLowerCase();

  String get label => '${name.trim()} - ${selection.label}';

  SheetNamedRange copyWith({
    String? id,
    String? name,
    CellSelection? selection,
  }) {
    return SheetNamedRange(
      id: id ?? this.id,
      name: name ?? this.name,
      selection: selection ?? this.selection,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'selection': _selectionToJson(selection),
  };

  factory SheetNamedRange.fromJson(Map<String, dynamic> json) {
    final name = json['name']?.toString() ?? '';
    final selectionJson = Map<String, dynamic>.from(json['selection'] as Map);
    final start = CellAddress.fromJson(
      Map<String, dynamic>.from(selectionJson['start']),
    );
    final endJson = selectionJson['end'];

    return SheetNamedRange(
      id: json['id']?.toString() ?? 'named-range-${name.toLowerCase()}',
      name: name,
      selection: CellSelection(
        start,
        endJson == null
            ? null
            : CellAddress.fromJson(Map<String, dynamic>.from(endJson)),
      ),
    );
  }

  static String normalizeName(String input) {
    return input.trim().replaceAll(RegExp(r'\s+'), '_');
  }

  static bool isValidName(String input) {
    final name = normalizeName(input);
    if (name.isEmpty) return false;
    if (!_namePattern.hasMatch(name)) return false;
    return !_cellReferencePattern.hasMatch(name);
  }

  static Map<String, dynamic> _selectionToJson(CellSelection selection) => {
    'start': selection.start.toJson(),
    if (selection.end != null) 'end': selection.end!.toJson(),
  };

  static final _namePattern = RegExp(r'^[A-Za-z_][A-Za-z0-9_.]*$');
  static final _cellReferencePattern = RegExp(r'^\$?[A-Za-z]+\$?[1-9][0-9]*$');
}
