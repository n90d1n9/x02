import 'package:flutter/material.dart';

import '../model/cell/cell_address.dart';
import '../theme/ky_sheet_theme.dart';
import 'sheet_column_header_menu_button.dart';

class SheetCornerHeader extends StatelessWidget {
  final double width;
  final double height;
  final VoidCallback onTap;

  const SheetCornerHeader({
    super.key,
    required this.width,
    required this.height,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: width,
          height: height,
          decoration: const BoxDecoration(
            color: KySheetColors.surfaceMuted,
            border: Border(
              right: BorderSide(color: KySheetColors.gridLineStrong),
              bottom: BorderSide(color: KySheetColors.gridLineStrong),
            ),
          ),
          alignment: Alignment.center,
          child: const Icon(
            Icons.select_all,
            size: 16,
            color: KySheetColors.mutedText,
          ),
        ),
      ),
    );
  }
}

class SheetColumnHeader extends StatelessWidget {
  final int column;
  final double width;
  final double height;
  final bool isActive;
  final bool hasFilter;
  final bool isSorted;
  final bool sortAscending;
  final bool canUnhideAdjacent;
  final String? filterDescription;
  final VoidCallback onTap;
  final ValueChanged<SheetColumnHeaderAction>? onMenuAction;
  final ValueChanged<double>? onResize;
  final VoidCallback? onAutoFit;

  const SheetColumnHeader({
    super.key,
    required this.column,
    required this.width,
    required this.height,
    required this.isActive,
    required this.onTap,
    this.hasFilter = false,
    this.isSorted = false,
    this.sortAscending = true,
    this.canUnhideAdjacent = false,
    this.filterDescription,
    this.onMenuAction,
    this.onResize,
    this.onAutoFit,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        children: [
          Positioned.fill(
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onTap,
                child: Container(
                  decoration: BoxDecoration(
                    color: isActive
                        ? KySheetColors.headerActive
                        : KySheetColors.surfaceMuted,
                    border: const Border(
                      right: BorderSide(color: KySheetColors.gridLine),
                      bottom: BorderSide(color: KySheetColors.gridLineStrong),
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    CellAddress.colToLabel(column),
                    style: KySheetTextStyles.header,
                  ),
                ),
              ),
            ),
          ),
          if (onMenuAction != null && width >= 74)
            Positioned(
              right: 12,
              top: (height - 24) / 2,
              child: SheetColumnHeaderMenuButton(
                key: ValueKey('ky-sheet-column-menu-$column'),
                hasFilter: hasFilter,
                isSorted: isSorted,
                sortAscending: sortAscending,
                canUnhideAdjacent: canUnhideAdjacent,
                filterDescription: filterDescription,
                onSelected: onMenuAction!,
              ),
            ),
          Positioned(
            top: 0,
            right: 0,
            bottom: 0,
            width: 8,
            child: MouseRegion(
              cursor: SystemMouseCursors.resizeColumn,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onDoubleTap: onAutoFit,
                onHorizontalDragUpdate: onResize == null
                    ? null
                    : (details) => onResize!(details.delta.dx),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                    width: 2,
                    height: height,
                    color: isActive
                        ? KySheetColors.accent
                        : KySheetColors.gridLineStrong,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SheetRowHeader extends StatelessWidget {
  final int row;
  final double width;
  final double height;
  final bool isActive;
  final bool canUnhideAdjacent;
  final VoidCallback onTap;
  final ValueChanged<SheetRowHeaderAction>? onMenuAction;
  final ValueChanged<double>? onResize;
  final VoidCallback? onAutoFit;

  const SheetRowHeader({
    super.key,
    required this.row,
    required this.width,
    required this.height,
    required this.isActive,
    required this.onTap,
    this.canUnhideAdjacent = false,
    this.onMenuAction,
    this.onResize,
    this.onAutoFit,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        children: [
          Positioned.fill(
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onTap,
                child: Container(
                  decoration: BoxDecoration(
                    color: isActive
                        ? KySheetColors.headerActive
                        : KySheetColors.surfaceMuted,
                    border: const Border(
                      right: BorderSide(color: KySheetColors.gridLineStrong),
                      bottom: BorderSide(color: KySheetColors.gridLine),
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text('${row + 1}', style: KySheetTextStyles.header),
                ),
              ),
            ),
          ),
          if (onMenuAction != null && width >= 48 && height >= 32)
            Positioned(
              right: 4,
              top: (height - 24) / 2,
              child: SheetRowHeaderMenuButton(
                key: ValueKey('ky-sheet-row-menu-$row'),
                canUnhideAdjacent: canUnhideAdjacent,
                onSelected: onMenuAction!,
              ),
            ),
          Positioned(
            right: 0,
            bottom: 0,
            left: 0,
            height: 8,
            child: MouseRegion(
              cursor: SystemMouseCursors.resizeRow,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onDoubleTap: onAutoFit,
                onVerticalDragUpdate: onResize == null
                    ? null
                    : (details) => onResize!(details.delta.dy),
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    width: width,
                    height: 2,
                    color: isActive
                        ? KySheetColors.accent
                        : KySheetColors.gridLineStrong,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
