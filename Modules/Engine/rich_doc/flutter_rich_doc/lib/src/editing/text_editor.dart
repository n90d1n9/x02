/// Editable view of a single inline text run.
///
/// HONEST SCOPE NOTE: a production rich editor spanning multiple
/// text-node children per block (so marks render as contiguous rich
/// spans within one visually-continuous line, and selection can cross
/// node boundaries) needs a custom `TextInputClient` /
/// `RenderEditable` — that's genuinely the hardest, highest-effort part
/// of building an editor like this, which is exactly why Quill /
/// ProseMirror / Lexical each took real time on it. This file is the
/// simplified interim: one `TextField` per text node, diffed into
/// `insert_text`/`delete_text`, with Enter intercepted for
/// `split_block`. It proves the full Command round trip end-to-end and
/// is the seam to replace with a custom `TextInputClient` later — none
/// of the state/model/rendering layers need to change when you do,
/// since they only know about `Command`s and `DocumentTree`, never
/// about how a keystroke became one.
library rich_doc_text_editor;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../model/commands.dart';
import '../model/document_tree.dart';
import '../state/document_controller.dart';
import 'text_diff.dart';

class TextNodeEditor extends ConsumerStatefulWidget {
  final TextNode node;
  const TextNodeEditor({super.key, required this.node});

  @override
  ConsumerState<TextNodeEditor> createState() => _TextNodeEditorState();
}

class _TextNodeEditorState extends ConsumerState<TextNodeEditor> {
  late final TextEditingController _controller;
  late String _lastKnownText;

  @override
  void initState() {
    super.initState();
    _lastKnownText = widget.node.text;
    _controller = TextEditingController(text: _lastKnownText)..addListener(_onChanged);
  }

  @override
  void didUpdateWidget(covariant TextNodeEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Rust is the source of truth. If the node's text changed for a
    // reason other than this field's own edits (undo/redo, an agent
    // edit, a remote collaborator), resync without re-triggering
    // _onChanged and without fighting the user's live cursor position.
    if (widget.node.text != _lastKnownText && widget.node.text != _controller.text) {
      _lastKnownText = widget.node.text;
      final offset = widget.node.text.length;
      _controller.value = TextEditingValue(text: widget.node.text, selection: TextSelection.collapsed(offset: offset));
    }
  }

  void _onChanged() {
    final edit = diffText(_lastKnownText, _controller.text);
    if (edit == null) return;
    _lastKnownText = _controller.text;

    final ops = <Command>[
      if (edit.deleteCount > 0)
        Command.op(DeleteTextOp(node: widget.node.id, start: edit.start, end: edit.start + edit.deleteCount)),
      if (edit.insert.isNotEmpty) Command.op(InsertTextOp(node: widget.node.id, offset: edit.start, text: edit.insert)),
    ];
    if (ops.isEmpty) return;
    ref.read(documentControllerProvider.notifier).apply(CommandBatch(ops, reason: 'typing'));
  }

  KeyEventResult _handleKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent || event.logicalKey != LogicalKeyboardKey.enter) {
      return KeyEventResult.ignored;
    }
    final offset = _controller.selection.baseOffset.clamp(0, _controller.text.length);
    ref.read(documentControllerProvider.notifier).apply(
      CommandBatch([Command.op(SplitBlockOp(node: widget.node.id, offset: offset))], reason: 'enter key'),
    );
    return KeyEventResult.handled;
  }

  @override
  void dispose() {
    _controller.removeListener(_onChanged);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      onKeyEvent: _handleKey,
      child: TextField(
        controller: _controller,
        decoration: const InputDecoration.collapsed(hintText: ''),
        maxLines: null,
        style: styleForMarks(widget.node.marks, DefaultTextStyle.of(context).style),
      ),
    );
  }
}

TextStyle styleForMarks(List<Mark> marks, TextStyle base) {
  var style = base;
  for (final mark in marks) {
    style = switch (mark) {
      BoldMark() => style.copyWith(fontWeight: FontWeight.bold),
      ItalicMark() => style.copyWith(fontStyle: FontStyle.italic),
      UnderlineMark() => style.copyWith(decoration: TextDecoration.underline),
      StrikeMark() => style.copyWith(decoration: TextDecoration.lineThrough),
      CodeMark() => style.copyWith(fontFamily: 'monospace', backgroundColor: const Color(0x22000000)),
      LinkMark() => style.copyWith(color: Colors.blue, decoration: TextDecoration.underline),
      CustomMark() => style,
    };
  }
  return style;
}
