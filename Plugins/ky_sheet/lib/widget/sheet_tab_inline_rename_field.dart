import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/ky_sheet_theme.dart';

/// Inline text field used to rename a workbook sheet tab in place.
class SheetTabInlineRenameField extends StatefulWidget {
  const SheetTabInlineRenameField({
    super.key,
    required this.sheetId,
    required this.initialName,
    required this.onCommit,
    required this.onCancel,
  });

  /// Stable sheet id used for the rename field key.
  final String sheetId;

  /// Name shown when inline rename starts.
  final String initialName;

  /// Called when the user commits the inline rename.
  final ValueChanged<String> onCommit;

  /// Called when the user cancels the inline rename.
  final VoidCallback onCancel;

  @override
  State<SheetTabInlineRenameField> createState() =>
      _SheetTabInlineRenameFieldState();
}

/// Owns inline rename focus, selection, and keyboard behavior.
class _SheetTabInlineRenameFieldState extends State<SheetTabInlineRenameField> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  bool _finished = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialName);
    _focusNode = FocusNode(debugLabel: 'KySheetTabInlineRename');

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _focusNode.requestFocus();
      _controller.selection = TextSelection(
        baseOffset: 0,
        extentOffset: _controller.text.length,
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      onFocusChange: (focused) {
        if (!focused) _commit();
      },
      onKeyEvent: _handleKeyEvent,
      child: TextField(
        key: ValueKey('ky-sheet-tab-rename-${widget.sheetId}'),
        controller: _controller,
        focusNode: _focusNode,
        maxLines: 1,
        textInputAction: TextInputAction.done,
        style: const TextStyle(
          color: KySheetColors.text,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
        decoration: InputDecoration(
          filled: true,
          fillColor: KySheetColors.surface,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 6,
          ),
          border: _border(KySheetColors.accent, 2),
          enabledBorder: _border(KySheetColors.accent, 2),
          focusedBorder: _border(KySheetColors.accent, 2),
        ),
        onSubmitted: (_) => _commit(),
      ),
    );
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    if (event.logicalKey == LogicalKeyboardKey.escape) {
      _cancel();
      return KeyEventResult.handled;
    }

    if (event.logicalKey == LogicalKeyboardKey.enter) {
      _commit();
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  OutlineInputBorder _border(Color color, double width) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(7),
      borderSide: BorderSide(color: color, width: width),
    );
  }

  void _commit() {
    if (_finished) return;
    _finished = true;
    widget.onCommit(_controller.text);
  }

  void _cancel() {
    if (_finished) return;
    _finished = true;
    widget.onCancel();
  }
}
