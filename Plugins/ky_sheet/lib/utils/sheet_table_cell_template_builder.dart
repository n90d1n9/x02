import '../model/cell/cell_address.dart';
import '../model/cell/cell_data.dart';
import '../model/cell/cell_style.dart';
import 'sheet_formula_reference.dart';

/// Builds blank table cells that inherit reusable formatting and formulas.
class SheetTableCellTemplateBuilder {
  const SheetTableCellTemplateBuilder._();

  /// Returns a blank cell with style and validation copied from a source cell.
  static CellData inheritMetadata({
    required CellData source,
    CellData? current,
  }) {
    return (current ?? CellData()).copyWith(
      style: source.style,
      validation: source.validation,
    );
  }

  /// Returns a blank cell with metadata and a shifted calculated-column formula.
  static CellData inheritMetadataAndFormula({
    required CellData source,
    required CellAddress sourceAddress,
    required CellAddress targetAddress,
    CellData? current,
  }) {
    final inherited = inheritMetadata(source: source, current: current);
    final formula = source.formula?.trim();
    if (formula == null || formula.isEmpty) return inherited;

    return inherited.copyWith(
      value: '',
      formula: SheetFormulaReference.shiftFormula(
        formula,
        rowDelta: targetAddress.row - sourceAddress.row,
        colDelta: targetAddress.col - sourceAddress.col,
      ),
    );
  }

  /// Whether a source cell carries a formula reusable by table appends.
  static bool hasFormulaTemplate(CellData cell) {
    return cell.formula?.trim().isNotEmpty ?? false;
  }

  /// Whether a source cell carries formatting, validation, or formula metadata.
  static bool hasRowTemplate(CellData cell) {
    return hasTemplateMetadata(cell) || hasFormulaTemplate(cell);
  }

  /// Whether a source cell carries reusable table formatting metadata.
  static bool hasTemplateMetadata(CellData cell) {
    return hasCustomStyle(cell.style) || cell.validation != null;
  }

  /// Whether the style differs from the default spreadsheet cell style.
  static bool hasCustomStyle(CellStyle style) {
    const defaultStyle = CellStyle();
    return style.bold != defaultStyle.bold ||
        style.italic != defaultStyle.italic ||
        style.underline != defaultStyle.underline ||
        style.backgroundColor != defaultStyle.backgroundColor ||
        style.textColor != defaultStyle.textColor ||
        style.align != defaultStyle.align ||
        style.fontSize != defaultStyle.fontSize ||
        style.fontFamily != defaultStyle.fontFamily ||
        style.borders != defaultStyle.borders ||
        style.wrapText != defaultStyle.wrapText ||
        style.numberFormat != defaultStyle.numberFormat ||
        style.borderTop != defaultStyle.borderTop ||
        style.borderBottom != defaultStyle.borderBottom ||
        style.borderLeft != defaultStyle.borderLeft ||
        style.borderRight != defaultStyle.borderRight;
  }
}
