import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;

import '../../models/document_editing_mode.dart';
import 'document_selection_toolbar.dart';
import 'document_selection_toolbar_policy.dart';

/// Listens to the editor selection and shows contextual selection actions.
class DocumentSelectionToolbarHost extends StatefulWidget {
  final quill.QuillController controller;
  final Widget child;
  final DocumentEditingMode editingMode;
  final bool aiProcessing;
  final VoidCallback? onOpenComments;
  final Future<void> Function()? onImproveSelection;
  final VoidCallback? onOpenTrackChanges;
  final VoidCallback? onRequestEditorFocus;

  const DocumentSelectionToolbarHost({
    super.key,
    required this.controller,
    required this.child,
    this.editingMode = DocumentEditingMode.editing,
    this.aiProcessing = false,
    this.onOpenComments,
    this.onImproveSelection,
    this.onOpenTrackChanges,
    this.onRequestEditorFocus,
  });

  @override
  State<DocumentSelectionToolbarHost> createState() =>
      _DocumentSelectionToolbarHostState();
}

/// Tracks selection changes and bridges toolbar callbacks to editor commands.
class _DocumentSelectionToolbarHostState
    extends State<DocumentSelectionToolbarHost> {
  static final _clearableFormattingAttributes = <quill.Attribute>[
    quill.Attribute.bold,
    quill.Attribute.italic,
    quill.Attribute.underline,
    quill.Attribute.strikeThrough,
    quill.Attribute.inlineCode,
    quill.Attribute.link,
    quill.Attribute.color,
    quill.Attribute.background,
    quill.Attribute.font,
    quill.Attribute.size,
    quill.Attribute.script,
    quill.Attribute.header,
    quill.Attribute.blockQuote,
    quill.Attribute.codeBlock,
    quill.Attribute.list,
    quill.Attribute.indent,
    quill.Attribute.align,
    quill.Attribute.direction,
    quill.Attribute.lineHeight,
  ];

  late TextSelection _selection;

  @override
  void initState() {
    super.initState();
    _selection = widget.controller.selection;
    widget.controller.addListener(_handleControllerChanged);
  }

  @override
  void didUpdateWidget(DocumentSelectionToolbarHost oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller == widget.controller) return;

    oldWidget.controller.removeListener(_handleControllerChanged);
    _selection = widget.controller.selection;
    widget.controller.addListener(_handleControllerChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_handleControllerChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasSelection = _hasSelection;
    final policy = DocumentSelectionToolbarPolicy(
      editingMode: widget.editingMode,
    );

    return Column(
      children: [
        DocumentSelectionToolbar(
          visible: hasSelection,
          selectedCharacterCount: _selectedCharacterCount,
          editingMode: widget.editingMode,
          boldActive: _attributeIsActive(quill.Attribute.bold.key),
          italicActive: _attributeIsActive(quill.Attribute.italic.key),
          underlineActive: _attributeIsActive(quill.Attribute.underline.key),
          quoteActive: _attributeIsActive(quill.Attribute.blockQuote.key),
          aiProcessing: widget.aiProcessing,
          onCopy: hasSelection ? _copySelection : null,
          onBold: hasSelection && policy.showsFormattingActions
              ? () => _toggleAttribute(quill.Attribute.bold)
              : null,
          onItalic: hasSelection && policy.showsFormattingActions
              ? () => _toggleAttribute(quill.Attribute.italic)
              : null,
          onUnderline: hasSelection && policy.showsFormattingActions
              ? () => _toggleAttribute(quill.Attribute.underline)
              : null,
          onQuote: hasSelection && policy.showsFormattingActions
              ? () => _toggleAttribute(quill.Attribute.blockQuote)
              : null,
          onClearFormatting: hasSelection && policy.showsFormattingActions
              ? _clearSelectionFormatting
              : null,
          onComment: policy.showsReviewActions ? widget.onOpenComments : null,
          onImprove:
              !policy.showsReviewActions || widget.onImproveSelection == null
              ? null
              : () => _runImproveSelection(),
          onSuggestChange: policy.showsReviewActions
              ? widget.onOpenTrackChanges
              : null,
        ),
        Expanded(child: widget.child),
      ],
    );
  }

  bool get _hasSelection {
    return _selection.isValid && !_selection.isCollapsed;
  }

  int get _selectedCharacterCount {
    if (!_hasSelection) return 0;
    return _selection.end - _selection.start;
  }

  bool _attributeIsActive(String key) {
    if (!_hasSelection) return false;
    return widget.controller.getSelectionStyle().attributes.containsKey(key);
  }

  void _toggleAttribute(quill.Attribute attribute) {
    final nextAttribute = _attributeIsActive(attribute.key)
        ? quill.Attribute.clone(attribute, null)
        : attribute;
    widget.controller.formatSelection(nextAttribute);
    widget.onRequestEditorFocus?.call();
  }

  void _clearSelectionFormatting() {
    for (final attribute in _clearableFormattingAttributes) {
      widget.controller.formatSelection(quill.Attribute.clone(attribute, null));
    }
    widget.onRequestEditorFocus?.call();
  }

  Future<void> _runImproveSelection() async {
    await widget.onImproveSelection?.call();
    widget.onRequestEditorFocus?.call();
  }

  Future<void> _copySelection() async {
    final text = _selectedText;
    if (text.isEmpty) return;

    await Clipboard.setData(ClipboardData(text: text));
    widget.onRequestEditorFocus?.call();
  }

  String get _selectedText {
    final text = widget.controller.document.toPlainText();
    final start = _selection.start.clamp(0, text.length).toInt();
    final end = _selection.end.clamp(0, text.length).toInt();
    if (end <= start) return '';

    return text.substring(start, end);
  }

  void _handleControllerChanged() {
    setState(() => _selection = widget.controller.selection);
  }
}
