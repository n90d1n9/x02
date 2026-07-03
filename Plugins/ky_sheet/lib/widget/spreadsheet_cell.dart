import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../model/cell/cell_address.dart';
import '../model/cell/cell_data.dart';
import '../model/cell/cell_selection.dart';
import '../model/cell/cell_style.dart';
import '../model/sheet_table.dart';
import '../state/sheet_active_table_provider.dart';
import '../state/sheet_formula_preview_provider.dart';
import '../state/sheet_table_provider.dart';
import '../state/spreadsheet_provider.dart';
import '../theme/ky_sheet_theme.dart';
import '../utils/sheet_cell_formatter.dart';
import '../utils/sheet_conditional_format_evaluator.dart';
import '../utils/sheet_formula_error_status.dart';
import '../utils/sheet_table_badge_resolver.dart';
import '../utils/sheet_table_corner_action_resolver.dart';
import '../utils/sheet_table_outline_resolver.dart';
import '../utils/sheet_table_style_resolver.dart';
import '../utils/sheet_validation_status.dart';
import 'inline_cell_editor.dart';
import 'sheet_cell_metadata_badges.dart';
import 'sheet_table_corner_action_button.dart';
import 'sheet_table_corner_badge.dart';
import 'sheet_table_header_action_button.dart';
import 'sheet_table_outline_overlay.dart';
import 'sheet_table_total_action_button.dart';
import 'sheet_validation_dropdown_button.dart';

/// Interactive grid cell renderer for sheet values, metadata, and overlays.
class SpreadsheetCell extends ConsumerWidget {
  final CellAddress address;
  final double width;
  final double height;
  final VoidCallback? onSelected;
  final void Function(CellAddress address)? onEditRequested;
  final void Function(
    CellAddress address,
    String value,
    CellEditCommitIntent intent,
  )?
  onEditCommitted;
  final VoidCallback? onEditCanceled;
  final GestureDragStartCallback? onFillDragStart;
  final GestureDragUpdateCallback? onFillDragUpdate;
  final GestureDragEndCallback? onFillDragEnd;
  final GestureTapDownCallback? onSecondaryTapDown;

  const SpreadsheetCell({
    super.key,
    required this.address,
    this.width = KySheetMetrics.defaultColumnWidth,
    this.height = KySheetMetrics.defaultRowHeight,
    this.onSelected,
    this.onEditRequested,
    this.onEditCommitted,
    this.onEditCanceled,
    this.onFillDragStart,
    this.onFillDragUpdate,
    this.onFillDragEnd,
    this.onSecondaryTapDown,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(spreadsheetProvider);
    final selection = ref.watch(selectedCellProvider);
    final fillPreview = ref.watch(fillPreviewProvider);
    final formulaReferencePreview = ref.watch(formulaReferencePreviewProvider);
    final editingCell = ref.watch(editingCellProvider);
    final editingDraft = ref.watch(editingCellDraftProvider);
    final conditionalRules = ref.watch(conditionalFormatRulesProvider);
    final tables = ref.watch(sheetTablesProvider);
    final tableCellStyle = SheetTableStyleResolver.resolve(
      address: address,
      tables: tables,
    );
    final headerTable = _headerTableForAddress(address, tables);
    final activeTable = ref.watch(activeSheetTableProvider);
    final activeTableOutline = SheetTableOutlineResolver.resolve(
      address: address,
      activeTable: activeTable,
    );
    final showActiveTableBadge = SheetTableBadgeResolver.shouldShow(
      address: address,
      activeTable: activeTable,
    );
    final showActiveTableCornerAction =
        SheetTableCornerActionResolver.shouldShow(
          address: address,
          activeTable: activeTable,
        );
    final tableStylePalette = activeTable == null
        ? null
        : SheetTableStyleResolver.paletteFor(activeTable.styleId);
    final activeTotalsTable =
        activeTable != null && activeTable.isTotalsCell(address)
        ? activeTable
        : null;
    final hasCellActionButton =
        headerTable != null || activeTotalsTable != null;
    final hasStackedTableActions =
        activeTotalsTable != null && showActiveTableCornerAction;
    final cellActionRightPadding = hasStackedTableActions
        ? 48.0
        : hasCellActionButton
        ? 24.0
        : 0.0;
    final cellData = data[address] ?? CellData();
    final effectiveStyle = SheetConditionalFormatEvaluator.effectiveStyle(
      address: address,
      cellData: cellData,
      rules: conditionalRules,
    );
    final validationStatus = SheetValidationStatus.fromCell(cellData);
    final formulaErrorStatus = SheetFormulaErrorStatus.fromCell(cellData);

    final isSelected = selection?.contains(address) ?? false;
    final isFillPreview = fillPreview?.contains(address) ?? false;
    final isFormulaReference = formulaReferencePreview.any(
      (reference) => reference.contains(address),
    );
    final isRangeStart = selection?.start == address;
    final isFillHandleCell =
        selection != null &&
        selection.maxRow == address.row &&
        selection.maxCol == address.col;
    final isEditing = editingCell == address;

    final hasHyperlink =
        cellData.hyperlink != null && cellData.hyperlink!.isNotEmpty;
    final metadataBadges = SheetCellMetadataBadges(
      comment: cellData.comment,
      hyperlink: cellData.hyperlink,
    );
    final hasFormula = cellData.formula != null && cellData.formula!.isNotEmpty;
    final textStyle = _textStyle(
      cellData,
      effectiveStyle,
      hasHyperlink,
      tableCellStyle,
    );
    final validationRightOffset =
        (validationStatus.hasListOptions ? 26.0 : 2.0) +
        (metadataBadges.count * 15.0);
    final formulaErrorRightOffset =
        validationRightOffset + (validationStatus.isInvalid ? 18.0 : 0.0);

    if (isEditing) {
      return InlineCellEditor(
        initialValue: editingDraft ?? cellData.formula ?? cellData.value,
        width: width,
        height: height,
        textStyle: textStyle,
        textAlign: effectiveStyle.align,
        selectAll: editingDraft == null,
        onCommit: (value, intent) {
          if (onEditCommitted != null) {
            onEditCommitted!(address, value, intent);
            return;
          }
          ref
              .read(spreadsheetProvider.notifier)
              .updateCellValue(address, value);
          ref.read(editingCellProvider.notifier).state = null;
          ref.read(editingCellDraftProvider.notifier).state = null;
        },
        onCancel: () {
          if (onEditCanceled != null) {
            onEditCanceled!();
            return;
          }
          ref.read(editingCellProvider.notifier).state = null;
          ref.read(editingCellDraftProvider.notifier).state = null;
        },
      );
    }

    return GestureDetector(
      onTap: () {
        if (onSelected != null) {
          onSelected!();
        } else {
          ref.read(selectedCellProvider.notifier).state = CellSelection(
            address,
          );
        }
      },
      onDoubleTap: () {
        _requestEdit(ref);
      },
      onSecondaryTapDown: onSecondaryTapDown,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              color: _backgroundColor(
                isSelected: isSelected,
                isFillPreview: isFillPreview,
                isInvalid: validationStatus.isInvalid,
                hasFormulaError: formulaErrorStatus.hasError,
                isFormulaReference: isFormulaReference,
                effectiveStyle: effectiveStyle,
                tableCellStyle: tableCellStyle,
              ),
              border: Border.all(
                color: _borderColor(
                  isRangeStart: isRangeStart,
                  isSelected: isSelected,
                  isFillPreview: isFillPreview,
                  isFormulaReference: isFormulaReference,
                  isInvalid: validationStatus.isInvalid,
                  hasFormulaError: formulaErrorStatus.hasError,
                ),
                width:
                    isRangeStart ||
                        validationStatus.isInvalid ||
                        formulaErrorStatus.hasError ||
                        isFormulaReference
                    ? 2
                    : 1,
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(
                  child: Align(
                    alignment: _getAlignment(effectiveStyle.align),
                    child: Padding(
                      padding: EdgeInsets.only(right: cellActionRightPadding),
                      child: Text(
                        SheetCellFormatter.displayValue(cellData),
                        style: textStyle,
                        overflow: effectiveStyle.wrapText
                            ? TextOverflow.visible
                            : TextOverflow.ellipsis,
                        maxLines: effectiveStyle.wrapText ? null : 1,
                      ),
                    ),
                  ),
                ),
                if (headerTable != null)
                  Positioned(
                    right: -2,
                    top: (height - 20) / 2,
                    child: SheetTableHeaderActionButton(
                      table: headerTable,
                      column: address.col,
                    ),
                  ),
                if (activeTotalsTable != null)
                  Positioned(
                    right: hasStackedTableActions ? 22 : -2,
                    top: (height - 20) / 2,
                    child: SheetTableTotalActionButton(
                      table: activeTotalsTable,
                      column: address.col,
                    ),
                  ),
                if (hasFormula)
                  Positioned(
                    top: 0,
                    left: 0,
                    child: Container(
                      width: 0,
                      height: 0,
                      decoration: const BoxDecoration(
                        border: Border(
                          top: BorderSide(
                            width: 8,
                            color: KySheetColors.formula,
                          ),
                          right: BorderSide(
                            width: 8,
                            color: Colors.transparent,
                          ),
                        ),
                      ),
                    ),
                  ),
                if (!metadataBadges.isEmpty)
                  Positioned(top: 2, right: 2, child: metadataBadges),
                if (validationStatus.hasListOptions)
                  Positioned(
                    right: 2,
                    top: (height - 22) / 2,
                    child: SheetValidationDropdownButton(
                      options: validationStatus.options,
                      onSelected: (value) {
                        ref
                            .read(spreadsheetProvider.notifier)
                            .updateCellValue(address, value);
                      },
                    ),
                  ),
                if (validationStatus.isInvalid)
                  Positioned(
                    right: validationRightOffset,
                    top: 2,
                    child: Tooltip(
                      message: validationStatus.tooltip,
                      child: const Icon(
                        Icons.error,
                        size: 14,
                        color: KySheetColors.validationError,
                      ),
                    ),
                  ),
                if (formulaErrorStatus.hasError)
                  Positioned(
                    right: formulaErrorRightOffset,
                    top: 2,
                    child: Tooltip(
                      message: formulaErrorStatus.tooltip,
                      child: const Icon(
                        Icons.error_outline,
                        size: 14,
                        color: KySheetColors.validationError,
                      ),
                    ),
                  ),
                if (isFillHandleCell &&
                    onFillDragStart != null &&
                    onFillDragUpdate != null &&
                    onFillDragEnd != null)
                  Positioned(
                    right: -6,
                    bottom: -6,
                    child: MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onPanStart: onFillDragStart,
                        onPanUpdate: onFillDragUpdate,
                        onPanEnd: onFillDragEnd,
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: KySheetColors.accent,
                            border: Border.all(
                              color: KySheetColors.surface,
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (activeTableOutline != null && tableStylePalette != null)
            Positioned.fill(
              child: SheetTableOutlineOverlay(
                outline: activeTableOutline,
                color: tableStylePalette.headerBackground,
              ),
            ),
          if (showActiveTableBadge &&
              activeTable != null &&
              tableStylePalette != null)
            Positioned(
              left: 4,
              top: 4,
              child: SheetTableCornerBadge(
                table: activeTable,
                color: tableStylePalette.headerBackground,
                maxWidth: (width - (headerTable == null ? 8 : 38))
                    .clamp(24.0, 92.0)
                    .toDouble(),
              ),
            ),
          if (showActiveTableCornerAction &&
              activeTable != null &&
              tableStylePalette != null)
            Positioned(
              right: -1,
              bottom: -1,
              child: SheetTableCornerActionButton(
                table: activeTable,
                color: tableStylePalette.headerBackground,
              ),
            ),
        ],
      ),
    );
  }

  TextStyle _textStyle(
    CellData cellData,
    CellStyle effectiveStyle,
    bool hasHyperlink,
    SheetTableCellStyle? tableCellStyle,
  ) {
    final hasExplicitTextColor =
        effectiveStyle.textColor != const CellStyle().textColor;

    return KySheetTextStyles.cell.copyWith(
      fontWeight: effectiveStyle.bold || tableCellStyle?.bold == true
          ? FontWeight.bold
          : FontWeight.normal,
      fontStyle: effectiveStyle.italic ? FontStyle.italic : FontStyle.normal,
      decoration: effectiveStyle.underline || hasHyperlink
          ? TextDecoration.underline
          : null,
      decorationColor: hasHyperlink ? KySheetColors.accent : null,
      color: hasHyperlink
          ? KySheetColors.accent
          : hasExplicitTextColor
          ? effectiveStyle.textColor
          : tableCellStyle?.textColor ?? effectiveStyle.textColor,
      fontSize: effectiveStyle.fontSize,
      fontFamily: effectiveStyle.fontFamily,
    );
  }

  Color _backgroundColor({
    required bool isSelected,
    required bool isFillPreview,
    required bool isInvalid,
    required bool hasFormulaError,
    required bool isFormulaReference,
    required CellStyle effectiveStyle,
    required SheetTableCellStyle? tableCellStyle,
  }) {
    if (isSelected) return KySheetColors.accentSoft;
    if (isFillPreview) return KySheetColors.headerActive;
    if (isInvalid || hasFormulaError) return KySheetColors.validationSoft;
    if (effectiveStyle.backgroundColor != null) {
      return effectiveStyle.backgroundColor!;
    }
    if (isFormulaReference) {
      return KySheetColors.formula.withValues(alpha: 0.08);
    }
    return tableCellStyle?.backgroundColor ?? KySheetColors.surface;
  }

  Alignment _getAlignment(TextAlign align) {
    switch (align) {
      case TextAlign.left:
        return Alignment.centerLeft;
      case TextAlign.center:
        return Alignment.center;
      case TextAlign.right:
        return Alignment.centerRight;
      default:
        return Alignment.centerLeft;
    }
  }

  Color _borderColor({
    required bool isRangeStart,
    required bool isSelected,
    required bool isFillPreview,
    required bool isFormulaReference,
    required bool isInvalid,
    required bool hasFormulaError,
  }) {
    if (isRangeStart || isSelected || isFillPreview) {
      return KySheetColors.accent;
    }
    if (isInvalid) return KySheetColors.validationError;
    if (hasFormulaError) return KySheetColors.validationError;
    if (isFormulaReference) return KySheetColors.formula;
    return KySheetColors.gridLine;
  }

  void _requestEdit(WidgetRef ref) {
    if (onEditRequested != null) {
      onEditRequested!(address);
      return;
    }
    ref.read(selectedCellProvider.notifier).state = CellSelection(address);
    ref.read(editingCellDraftProvider.notifier).state = null;
    ref.read(editingCellProvider.notifier).state = address;
  }

  SheetTable? _headerTableForAddress(
    CellAddress address,
    List<SheetTable> tables,
  ) {
    for (final table in tables.reversed) {
      if (table.isHeaderCell(address)) return table;
    }
    return null;
  }
}
