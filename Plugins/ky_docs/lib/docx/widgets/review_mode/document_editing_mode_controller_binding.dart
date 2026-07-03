import 'package:flutter/widgets.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;

import '../../models/document_editing_mode.dart';

/// Synchronizes document editing modes with the underlying Quill controller.
class DocumentEditingModeControllerBinding extends StatefulWidget {
  final quill.QuillController controller;
  final DocumentEditingMode mode;
  final Widget child;

  const DocumentEditingModeControllerBinding({
    super.key,
    required this.controller,
    required this.mode,
    required this.child,
  });

  @override
  State<DocumentEditingModeControllerBinding> createState() =>
      _DocumentEditingModeControllerBindingState();
}

class _DocumentEditingModeControllerBindingState
    extends State<DocumentEditingModeControllerBinding> {
  late bool _previousReadOnly;

  @override
  void initState() {
    super.initState();
    _previousReadOnly = widget.controller.readOnly;
    _syncController();
  }

  @override
  void didUpdateWidget(DocumentEditingModeControllerBinding oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.controller != widget.controller) {
      _restoreController(oldWidget.controller);
      _previousReadOnly = widget.controller.readOnly;
    }

    _syncController();
  }

  @override
  void dispose() {
    _restoreController(widget.controller);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }

  void _syncController() {
    final nextReadOnly = widget.mode.isReadOnly;
    if (widget.controller.readOnly == nextReadOnly) return;
    widget.controller.readOnly = nextReadOnly;
  }

  void _restoreController(quill.QuillController controller) {
    if (controller.readOnly == _previousReadOnly) return;
    controller.readOnly = _previousReadOnly;
  }
}
