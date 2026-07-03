import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;

import 'document_status_chip.dart';
import 'document_status_popover.dart';
import 'document_text_style_status.dart';

/// Displays the current cursor or selection style in the document status bar.
class DocumentTextStyleStatusChip extends StatefulWidget {
  static const chipKey = ValueKey('document-text-style-status-chip');
  static const menuKey = ValueKey('document-text-style-status-menu');

  final quill.QuillController controller;

  const DocumentTextStyleStatusChip({super.key, required this.controller});

  @override
  State<DocumentTextStyleStatusChip> createState() =>
      _DocumentTextStyleStatusChipState();
}

/// Keeps the visible text-style summary synchronized with the editor.
class _DocumentTextStyleStatusChipState
    extends State<DocumentTextStyleStatusChip> {
  late DocumentTextStyleStatus _status;

  @override
  void initState() {
    super.initState();
    _status = _currentStatus();
    widget.controller.addListener(_handleControllerChanged);
  }

  @override
  void didUpdateWidget(DocumentTextStyleStatusChip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller == widget.controller) return;

    oldWidget.controller.removeListener(_handleControllerChanged);
    _status = _currentStatus();
    widget.controller.addListener(_handleControllerChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_handleControllerChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<void>(
      tooltip: 'Show text style details',
      itemBuilder: (context) => [
        PopupMenuItem<void>(
          enabled: false,
          padding: EdgeInsets.zero,
          child: _TextStyleStatusMenu(status: _status),
        ),
      ],
      child: DocumentStatusChip(
        key: DocumentTextStyleStatusChip.chipKey,
        icon: Icons.format_shapes_outlined,
        label: _status.label,
        tooltip: _status.tooltip,
      ),
    );
  }

  DocumentTextStyleStatus _currentStatus() {
    return DocumentTextStyleStatus.fromController(
      controller: widget.controller,
    );
  }

  void _handleControllerChanged() {
    final nextStatus = _currentStatus();
    if (nextStatus.label == _status.label) return;

    setState(() => _status = nextStatus);
  }
}

/// Renders paragraph and inline-formatting details for the status popover.
class _TextStyleStatusMenu extends StatelessWidget {
  final DocumentTextStyleStatus status;

  const _TextStyleStatusMenu({required this.status});

  @override
  Widget build(BuildContext context) {
    return DocumentStatusPopover(
      contentKey: DocumentTextStyleStatusChip.menuKey,
      icon: Icons.format_shapes_outlined,
      title: 'Text style',
      subtitle: status.tooltip,
      width: 280,
      children: [
        DocumentStatusPopoverMetricLine(
          icon: Icons.format_paint_outlined,
          label: 'Paragraph',
          value: status.paragraphStyle,
        ),
        DocumentStatusPopoverMetricLine(
          icon: Icons.format_bold,
          label: 'Inline marks',
          value: status.inlineSummary,
        ),
      ],
    );
  }
}
