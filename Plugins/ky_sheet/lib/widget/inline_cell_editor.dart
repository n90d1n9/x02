import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/ky_sheet_theme.dart';

enum CellEditCommitIntent {
  stay,
  nextRow,
  previousRow,
  nextColumn,
  previousColumn,
}

class InlineCellEditor extends StatefulWidget {
  final String initialValue;
  final double width;
  final double height;
  final TextStyle textStyle;
  final TextAlign textAlign;
  final bool selectAll;
  final void Function(String value, CellEditCommitIntent intent) onCommit;
  final VoidCallback onCancel;

  const InlineCellEditor({
    super.key,
    required this.initialValue,
    required this.width,
    required this.height,
    required this.textStyle,
    required this.textAlign,
    this.selectAll = true,
    required this.onCommit,
    required this.onCancel,
  });

  @override
  State<InlineCellEditor> createState() => _InlineCellEditorState();
}

class _InlineCellEditorState extends State<InlineCellEditor> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  bool _finished = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
    _focusNode = FocusNode(debugLabel: 'KySheetInlineCellEditor');

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _focusNode.requestFocus();
      _controller.selection = widget.selectAll
          ? TextSelection(baseOffset: 0, extentOffset: _controller.text.length)
          : TextSelection.collapsed(offset: _controller.text.length);
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
    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: Focus(
        onKeyEvent: _handleKeyEvent,
        child: TextField(
          controller: _controller,
          focusNode: _focusNode,
          textAlign: widget.textAlign,
          style: widget.textStyle,
          maxLines: 1,
          textInputAction: TextInputAction.done,
          decoration: InputDecoration(
            filled: true,
            fillColor: KySheetColors.surface,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 4,
            ),
            border: _border(KySheetColors.accent, 2),
            enabledBorder: _border(KySheetColors.accent, 2),
            focusedBorder: _border(KySheetColors.accent, 2),
          ),
          onSubmitted: (_) => _commit(CellEditCommitIntent.nextRow),
        ),
      ),
    );
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    final key = event.logicalKey;
    final pressed = HardwareKeyboard.instance.logicalKeysPressed;
    final isShiftPressed =
        pressed.contains(LogicalKeyboardKey.shiftLeft) ||
        pressed.contains(LogicalKeyboardKey.shiftRight);

    if (key == LogicalKeyboardKey.escape) {
      _cancel();
      return KeyEventResult.handled;
    }

    if (key == LogicalKeyboardKey.enter) {
      _commit(
        isShiftPressed
            ? CellEditCommitIntent.previousRow
            : CellEditCommitIntent.nextRow,
      );
      return KeyEventResult.handled;
    }

    if (key == LogicalKeyboardKey.tab) {
      _commit(
        isShiftPressed
            ? CellEditCommitIntent.previousColumn
            : CellEditCommitIntent.nextColumn,
      );
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  OutlineInputBorder _border(Color color, double width) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.zero,
      borderSide: BorderSide(color: color, width: width),
    );
  }

  void _commit(CellEditCommitIntent intent) {
    if (_finished) return;
    _finished = true;
    widget.onCommit(_controller.text, intent);
  }

  void _cancel() {
    if (_finished) return;
    _finished = true;
    widget.onCancel();
  }
}
