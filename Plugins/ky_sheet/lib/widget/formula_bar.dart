import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart' show StateController;

import '../model/cell/cell_selection.dart';
import '../model/sheet_formula_suggestion.dart';
import '../state/sheet_formula_preview_provider.dart';
import '../state/sheet_named_range_provider.dart';
import '../state/spreadsheet_provider.dart';
import '../theme/ky_sheet_theme.dart';
import '../utils/sheet_formula_autocomplete.dart';
import '../utils/sheet_formula_reference.dart';
import 'formula_suggestion_panel.dart';
import 'sheet_formula_bar_actions.dart';
import 'sheet_name_box.dart';

class FormulaBar extends ConsumerStatefulWidget {
  const FormulaBar({super.key, this.maxRows = 200, this.maxColumns = 52});

  final int maxRows;
  final int maxColumns;

  @override
  ConsumerState<FormulaBar> createState() => _FormulaBarState();
}

class _FormulaBarState extends ConsumerState<FormulaBar> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  late final StateController<List<CellSelection>> _referencePreviewNotifier;
  late final StateController<SheetFormulaPreviewContext?>
  _referencePreviewContextNotifier;

  @override
  void initState() {
    super.initState();
    _referencePreviewNotifier = ref.read(
      formulaReferencePreviewProvider.notifier,
    );
    _referencePreviewContextNotifier = ref.read(
      formulaReferencePreviewContextProvider.notifier,
    );
    _focusNode.addListener(_handleFocusChanged);
  }

  @override
  void dispose() {
    try {
      _referencePreviewNotifier.state = const [];
      _referencePreviewContextNotifier.state = null;
    } on StateError {
      // ProviderScope may already be gone in widget tests or host teardown.
    }
    _focusNode.removeListener(_handleFocusChanged);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selection = ref.watch(selectedCellProvider);
    final data = ref.watch(spreadsheetProvider);
    final namedRanges = ref.watch(sheetNamedRangesProvider);

    final cellData = selection != null ? data[selection.start] : null;
    final displayValue = cellData?.formula ?? cellData?.value ?? '';
    final suggestions = _focusNode.hasFocus
        ? SheetFormulaAutocomplete.suggestions(
            _controller.text,
            caretOffset: _effectiveCursorOffset(),
            namedRanges: namedRanges,
          )
        : const <SheetFormulaSuggestion>[];

    if (_controller.text != displayValue && !_focusNode.hasFocus) {
      _controller.text = displayValue;
      _controller.selection = TextSelection.collapsed(
        offset: displayValue.length,
      );
    }
    final isDirty = _controller.text != displayValue;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: const BoxDecoration(
        color: KySheetColors.surface,
        border: Border(bottom: BorderSide(color: KySheetColors.gridLine)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              SheetNameBox(
                maxRows: widget.maxRows,
                maxColumns: widget.maxColumns,
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.functions,
                size: 18,
                color: KySheetColors.formula,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  key: const ValueKey('ky-sheet-formula-input'),
                  controller: _controller,
                  focusNode: _focusNode,
                  decoration: InputDecoration(
                    hintText: 'Enter value or formula (e.g., =SUM(A1:A10))',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(
                        color: KySheetColors.gridLine,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(
                        color: KySheetColors.gridLine,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: KySheetColors.accent),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    isDense: true,
                  ),
                  onChanged: (_) {
                    _syncReferencePreview();
                    setState(() {});
                  },
                  onSubmitted: (_) => _commitEdit(selection),
                ),
              ),
              const SizedBox(width: 8),
              SheetFormulaBarActions(
                canCancel: isDirty,
                canCommit: selection != null && isDirty,
                onCancel: () => _cancelEdit(displayValue),
                onCommit: () => _commitEdit(selection),
              ),
            ],
          ),
          if (suggestions.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 130, top: 8),
              child: SizedBox(
                width: double.infinity,
                child: FormulaSuggestionPanel(
                  suggestions: suggestions,
                  onSelected: _insertSuggestion,
                ),
              ),
            ),
        ],
      ),
    );
  }

  int _effectiveCursorOffset() {
    final selection = _controller.selection;
    return selection.isValid ? selection.baseOffset : _controller.text.length;
  }

  void _insertSuggestion(SheetFormulaSuggestion suggestion) {
    final insertion = SheetFormulaAutocomplete.applySuggestion(
      _controller.text,
      suggestion,
      caretOffset: _effectiveCursorOffset(),
    );
    _controller.value = TextEditingValue(
      text: insertion.text,
      selection: TextSelection.collapsed(offset: insertion.caretOffset),
    );
    _focusNode.requestFocus();
    _syncReferencePreview();
    setState(() {});
  }

  void _handleFocusChanged() {
    if (_focusNode.hasFocus) {
      _syncReferencePreview();
    } else {
      _clearReferencePreview();
    }
    if (mounted) setState(() {});
  }

  void _syncReferencePreview() {
    final previews = SheetFormulaReference.referencedSelections(
      _controller.text,
      namedRanges: ref.read(sheetNamedRangesProvider),
    );
    _referencePreviewNotifier.state = previews;
    _referencePreviewContextNotifier.state = previews.isEmpty
        ? null
        : SheetFormulaPreviewContext(
            source: SheetFormulaPreviewSource.formulaEdit,
            originLabel: ref.read(selectedCellProvider)?.label,
            targetCount: previews.length,
          );
  }

  void _clearReferencePreview() {
    _referencePreviewNotifier.state = const [];
    _referencePreviewContextNotifier.state = null;
  }

  void _commitEdit(CellSelection? selection) {
    if (selection == null) return;

    ref
        .read(spreadsheetProvider.notifier)
        .updateCellValue(selection.start, _controller.text);
    _focusNode.unfocus();
    _clearReferencePreview();
    if (mounted) setState(() {});
  }

  void _cancelEdit(String displayValue) {
    _controller.value = TextEditingValue(
      text: displayValue,
      selection: TextSelection.collapsed(offset: displayValue.length),
    );
    _focusNode.unfocus();
    _clearReferencePreview();
    if (mounted) setState(() {});
  }
}
