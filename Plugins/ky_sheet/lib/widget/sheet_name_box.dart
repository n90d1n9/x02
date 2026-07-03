import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/sheet_navigation_provider.dart';
import '../state/sheet_named_range_provider.dart';
import '../state/spreadsheet_provider.dart';
import '../theme/ky_sheet_theme.dart';
import '../utils/sheet_range_parser.dart';

class SheetNameBox extends ConsumerStatefulWidget {
  const SheetNameBox({super.key, this.maxRows = 200, this.maxColumns = 52});

  final int maxRows;
  final int maxColumns;

  @override
  ConsumerState<SheetNameBox> createState() => _SheetNameBoxState();
}

class _SheetNameBoxState extends ConsumerState<SheetNameBox> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode(debugLabel: 'KySheetNameBox');
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_handleFocusChanged);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChanged);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectionLabel = ref.watch(selectedCellProvider)?.label ?? '';

    if (!_focusNode.hasFocus && _controller.text != selectionLabel) {
      _controller.text = selectionLabel;
      _controller.selection = TextSelection.collapsed(
        offset: selectionLabel.length,
      );
    }

    final borderColor = _hasError
        ? KySheetColors.validationError
        : KySheetColors.gridLineStrong;

    return SizedBox(
      width: 96,
      child: Tooltip(
        message: 'Go to cell, range, or named range',
        child: TextField(
          key: const ValueKey('ky-sheet-name-box-input'),
          controller: _controller,
          focusNode: _focusNode,
          textAlign: TextAlign.center,
          textCapitalization: TextCapitalization.characters,
          textInputAction: TextInputAction.done,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 13,
            color: KySheetColors.text,
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: KySheetColors.surfaceMuted,
            suffixIcon: _hasError
                ? const Icon(
                    Icons.error_outline,
                    size: 16,
                    color: KySheetColors.validationError,
                  )
                : null,
            suffixIconConstraints: const BoxConstraints(
              minWidth: 22,
              minHeight: 20,
            ),
            border: _border(borderColor),
            enabledBorder: _border(borderColor),
            focusedBorder: _border(
              _hasError ? KySheetColors.validationError : KySheetColors.accent,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 8,
            ),
            isDense: true,
          ),
          onChanged: (_) {
            if (_hasError) setState(() => _hasError = false);
          },
          onSubmitted: _submit,
        ),
      ),
    );
  }

  OutlineInputBorder _border(Color color) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: color),
    );
  }

  void _handleFocusChanged() {
    if (_focusNode.hasFocus) {
      _controller.selection = TextSelection(
        baseOffset: 0,
        extentOffset: _controller.text.length,
      );
    } else if (_hasError) {
      setState(() => _hasError = false);
    }
  }

  void _submit(String value) {
    final parsedSelection = SheetRangeParser.parseSelection(
      value,
      maxRows: widget.maxRows,
      maxColumns: widget.maxColumns,
    );
    final namedRange = parsedSelection == null
        ? ref.read(sheetNamedRangesProvider.notifier).findByName(value)
        : null;
    final selection = parsedSelection ?? namedRange?.selection;

    if (selection == null) {
      setState(() => _hasError = true);
      return;
    }

    setState(() => _hasError = false);
    ref.read(sheetNavigationControllerProvider).goTo(selection);
    _controller.text = selection.label;
    _controller.selection = TextSelection.collapsed(
      offset: _controller.text.length,
    );
    _focusNode.unfocus();
  }
}
