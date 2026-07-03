import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;

import 'blank_document_starter_panel.dart';
import 'document_starter_template.dart';

/// Overlays starter options while the editor document has no meaningful text.
class BlankDocumentStarterHost extends StatefulWidget {
  final quill.QuillController controller;
  final Widget child;
  final DocumentStarterTemplateApplier applier;
  final VoidCallback? onRequestEditorFocus;

  const BlankDocumentStarterHost({
    super.key,
    required this.controller,
    required this.child,
    this.applier = const DocumentStarterTemplateApplier(),
    this.onRequestEditorFocus,
  });

  @override
  State<BlankDocumentStarterHost> createState() =>
      _BlankDocumentStarterHostState();
}

class _BlankDocumentStarterHostState extends State<BlankDocumentStarterHost> {
  var _dismissed = false;
  late bool _blank;

  @override
  void initState() {
    super.initState();
    _blank = _documentIsBlank();
    widget.controller.addListener(_handleControllerChanged);
  }

  @override
  void didUpdateWidget(BlankDocumentStarterHost oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller == widget.controller) return;

    oldWidget.controller.removeListener(_handleControllerChanged);
    _dismissed = false;
    _blank = _documentIsBlank();
    widget.controller.addListener(_handleControllerChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_handleControllerChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(child: widget.child),
        if (_blank && !_dismissed)
          Positioned(
            top: 18,
            left: 24,
            right: 24,
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: BlankDocumentStarterPanel(
                  onTemplateSelected: _applyTemplate,
                  onDismiss: () => setState(() => _dismissed = true),
                ),
              ),
            ),
          ),
      ],
    );
  }

  void _applyTemplate(DocumentStarterTemplate template) {
    widget.applier.apply(insertContent: _insertContent, template: template);
    widget.onRequestEditorFocus?.call();
  }

  void _insertContent(String content) {
    widget.controller.replaceText(
      0,
      _editableDocumentLength,
      content,
      TextSelection.collapsed(offset: content.length),
    );
  }

  int get _editableDocumentLength {
    final length = widget.controller.document.length - 1;
    return length < 0 ? 0 : length;
  }

  bool _documentIsBlank() {
    return widget.controller.document.toPlainText().trim().isEmpty;
  }

  void _handleControllerChanged() {
    final nextBlank = _documentIsBlank();
    if (nextBlank == _blank) return;
    setState(() {
      _blank = nextBlank;
      if (!nextBlank) _dismissed = false;
    });
  }
}
