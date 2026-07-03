import 'package:flutter/material.dart';

import '../model/cell/cell_address.dart';
import '../model/sheet_table.dart';

/// Render-time style overlay for cells inside a structured table.
class SheetTableCellStyle {
  const SheetTableCellStyle({
    this.backgroundColor,
    this.textColor,
    this.bold = false,
  });

  /// Background color supplied by the table style.
  final Color? backgroundColor;

  /// Text color supplied by the table style.
  final Color? textColor;

  /// Whether table semantics make the cell text visually prominent.
  final bool bold;
}

/// Resolves modern Ky Sheet table styling for a cell address.
class SheetTableStyleResolver {
  const SheetTableStyleResolver._();

  /// Returns the table style overlay for a cell, preferring the last table.
  static SheetTableCellStyle? resolve({
    required CellAddress address,
    required List<SheetTable> tables,
  }) {
    for (final table in tables.reversed) {
      if (!table.contains(address)) continue;

      final palette = paletteFor(table.styleId);
      if (table.isHeaderCell(address)) {
        return SheetTableCellStyle(
          backgroundColor: palette.headerBackground,
          textColor: Colors.white,
          bold: true,
        );
      }

      if (table.isTotalsCell(address)) {
        return SheetTableCellStyle(
          backgroundColor: palette.totalBackground,
          textColor: palette.headerBackground,
          bold: true,
        );
      }

      if (table.isBandedBodyCell(address)) {
        return SheetTableCellStyle(backgroundColor: palette.bandBackground);
      }

      return SheetTableCellStyle(backgroundColor: palette.bodyBackground);
    }

    return null;
  }

  /// Returns the reusable color palette for table style previews and cells.
  static SheetTableStylePalette paletteFor(SheetTableStyleId styleId) {
    switch (styleId) {
      case SheetTableStyleId.prism:
        return const SheetTableStylePalette(
          headerBackground: Color(0xFF1D4ED8),
          bodyBackground: Color(0xFFF8FAFC),
          bandBackground: Color(0xFFEFF6FF),
          totalBackground: Color(0xFFDBEAFE),
        );
      case SheetTableStyleId.graphite:
        return const SheetTableStylePalette(
          headerBackground: Color(0xFF334155),
          bodyBackground: Color(0xFFFAFAFA),
          bandBackground: Color(0xFFF1F5F9),
          totalBackground: Color(0xFFE2E8F0),
        );
      case SheetTableStyleId.mint:
        return const SheetTableStylePalette(
          headerBackground: Color(0xFF047857),
          bodyBackground: Color(0xFFF8FAFC),
          bandBackground: Color(0xFFECFDF5),
          totalBackground: Color(0xFFD1FAE5),
        );
    }
  }
}

/// Color tokens for one structured table style family.
class SheetTableStylePalette {
  const SheetTableStylePalette({
    required this.headerBackground,
    required this.bodyBackground,
    required this.bandBackground,
    required this.totalBackground,
  });

  final Color headerBackground;
  final Color bodyBackground;
  final Color bandBackground;
  final Color totalBackground;
}
