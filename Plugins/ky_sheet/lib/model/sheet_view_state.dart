import 'cell/cell_address.dart';

class SheetViewStateSummary {
  const SheetViewStateSummary({required this.freezePane, required this.zoom});

  final CellAddress? freezePane;
  final double zoom;

  bool get hasFreeze => freezePane != null;
  bool get hasFrozenRows => (freezePane?.row ?? 0) > 0;
  bool get hasFrozenColumns => (freezePane?.col ?? 0) > 0;

  int get frozenRowCount => freezePane?.row ?? 0;
  int get frozenColumnCount => freezePane?.col ?? 0;

  String get zoomLabel => '${(zoom * 100).round()}%';

  String get freezeLabel {
    if (freezePane == null) return 'None';
    if (frozenRowCount == 1 && frozenColumnCount == 0) return 'First row';
    if (frozenRowCount == 0 && frozenColumnCount == 1) return 'First column';
    if (frozenRowCount == 1 && frozenColumnCount == 1) {
      return 'First row and column';
    }

    final parts = <String>[
      if (hasFrozenRows) '$frozenRowCount row${frozenRowCount == 1 ? '' : 's'}',
      if (hasFrozenColumns)
        '$frozenColumnCount column${frozenColumnCount == 1 ? '' : 's'}',
    ];

    return parts.isEmpty ? 'None' : parts.join(', ');
  }

  String get freezeDetail {
    if (freezePane == null) return 'No frozen panes';
    return 'Freeze before ${freezePane!.label}';
  }
}
