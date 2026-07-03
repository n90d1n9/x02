import 'package:flutter/material.dart';

import '../model/sheet_table_outline.dart';

/// Paint-only overlay for the active structured-table frame inside the grid.
class SheetTableOutlineOverlay extends StatelessWidget {
  const SheetTableOutlineOverlay({
    super.key,
    required this.outline,
    required this.color,
    this.width = 2,
  });

  /// Stable test key for the active table's top outline edge.
  static const topEdgeKey = ValueKey<String>(
    'ky-sheet-active-table-outline-top',
  );

  /// Stable test key for the active table's right outline edge.
  static const rightEdgeKey = ValueKey<String>(
    'ky-sheet-active-table-outline-right',
  );

  /// Stable test key for the active table's bottom outline edge.
  static const bottomEdgeKey = ValueKey<String>(
    'ky-sheet-active-table-outline-bottom',
  );

  /// Stable test key for the active table's left outline edge.
  static const leftEdgeKey = ValueKey<String>(
    'ky-sheet-active-table-outline-left',
  );

  /// Cell edges that should be highlighted.
  final SheetTableCellOutline outline;

  /// Accent color borrowed from the active table style.
  final Color color;

  /// Thickness of the painted outline edges.
  final double width;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: [
          if (outline.top)
            Positioned(
              key: topEdgeKey,
              top: 0,
              left: 0,
              right: 0,
              height: width,
              child: ColoredBox(color: color),
            ),
          if (outline.right)
            Positioned(
              key: rightEdgeKey,
              top: 0,
              right: 0,
              bottom: 0,
              width: width,
              child: ColoredBox(color: color),
            ),
          if (outline.bottom)
            Positioned(
              key: bottomEdgeKey,
              left: 0,
              right: 0,
              bottom: 0,
              height: width,
              child: ColoredBox(color: color),
            ),
          if (outline.left)
            Positioned(
              key: leftEdgeKey,
              top: 0,
              left: 0,
              bottom: 0,
              width: width,
              child: ColoredBox(color: color),
            ),
        ],
      ),
    );
  }
}
