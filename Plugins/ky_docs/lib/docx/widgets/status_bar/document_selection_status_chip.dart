import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;

import 'document_selection_status.dart';
import 'document_status_popover.dart';
import 'document_status_chip.dart';

/// Listens to editor selection changes and displays selected text metrics.
class DocumentSelectionStatusChip extends StatefulWidget {
  static const chipKey = ValueKey('document-selection-status-chip');
  static const menuKey = ValueKey('document-selection-status-menu');

  final quill.QuillController controller;

  const DocumentSelectionStatusChip({super.key, required this.controller});

  @override
  State<DocumentSelectionStatusChip> createState() =>
      _DocumentSelectionStatusChipState();
}

/// Keeps selected-text metrics synchronized with the editor controller.
class _DocumentSelectionStatusChipState
    extends State<DocumentSelectionStatusChip> {
  late DocumentSelectionStatus _status;

  @override
  void initState() {
    super.initState();
    _status = _currentStatus();
    widget.controller.addListener(_handleControllerChanged);
  }

  @override
  void didUpdateWidget(DocumentSelectionStatusChip oldWidget) {
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
    if (!_status.hasSelection) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: PopupMenuButton<void>(
        tooltip: 'Show selection details',
        itemBuilder: (context) => [
          PopupMenuItem<void>(
            enabled: false,
            padding: EdgeInsets.zero,
            child: _SelectionStatusMenu(status: _status),
          ),
        ],
        child: DocumentStatusChip(
          key: DocumentSelectionStatusChip.chipKey,
          icon: Icons.select_all_outlined,
          label: _status.label,
          tooltip: _status.tooltip,
        ),
      ),
    );
  }

  DocumentSelectionStatus _currentStatus() {
    return DocumentSelectionStatus.fromSelection(
      text: widget.controller.document.toPlainText(),
      selection: widget.controller.selection,
    );
  }

  void _handleControllerChanged() {
    final nextStatus = _currentStatus();
    if (nextStatus.characterCount == _status.characterCount &&
        nextStatus.wordCount == _status.wordCount &&
        nextStatus.lineCount == _status.lineCount &&
        nextStatus.paragraphCount == _status.paragraphCount) {
      return;
    }

    setState(() => _status = nextStatus);
  }
}

/// Renders selected-text metrics inside the status chip popover.
class _SelectionStatusMenu extends StatelessWidget {
  final DocumentSelectionStatus status;

  const _SelectionStatusMenu({required this.status});

  @override
  Widget build(BuildContext context) {
    return DocumentStatusPopover(
      contentKey: DocumentSelectionStatusChip.menuKey,
      icon: Icons.select_all_outlined,
      title: 'Selection details',
      subtitle: status.tooltip,
      width: 260,
      children: [
        DocumentStatusPopoverMetricLine(
          icon: Icons.subject,
          label: 'Words',
          value: status.wordCountLabel,
        ),
        DocumentStatusPopoverMetricLine(
          icon: Icons.text_fields,
          label: 'Characters',
          value: status.characterCountLabel,
        ),
        DocumentStatusPopoverMetricLine(
          icon: Icons.notes_outlined,
          label: 'Lines',
          value: status.lineCountLabel,
        ),
        DocumentStatusPopoverMetricLine(
          icon: Icons.format_align_left,
          label: 'Paragraphs',
          value: status.paragraphCountLabel,
        ),
      ],
    );
  }
}
