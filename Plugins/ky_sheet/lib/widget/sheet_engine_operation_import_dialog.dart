import 'package:flutter/material.dart';

import '../theme/ky_sheet_theme.dart';
import '../utils/sheet_engine_operation_payload_parser.dart';

class SheetEngineOperationImportDialog extends StatefulWidget {
  const SheetEngineOperationImportDialog({super.key, this.expectedDocumentId});

  final String? expectedDocumentId;

  @override
  State<SheetEngineOperationImportDialog> createState() =>
      _SheetEngineOperationImportDialogState();
}

class _SheetEngineOperationImportDialogState
    extends State<SheetEngineOperationImportDialog> {
  final _controller = TextEditingController();
  String? _errorText;
  SheetEngineOperationPayloadSummary? _summary;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.hub_outlined, color: KySheetColors.accent, size: 20),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Apply Waraq Operations',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 540,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              key: const ValueKey('ky-sheet-operations-import-input'),
              controller: _controller,
              autofocus: true,
              minLines: 8,
              maxLines: 10,
              onChanged: _updatePreview,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
              decoration: InputDecoration(
                labelText: 'JSON payload',
                alignLabelWithHint: true,
                border: const OutlineInputBorder(),
                errorText: _errorText,
              ),
            ),
            const SizedBox(height: 12),
            _PayloadPreview(summary: _summary),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          key: const ValueKey('ky-sheet-operations-import-apply'),
          onPressed: _apply,
          icon: const Icon(Icons.playlist_add_check, size: 18),
          label: const Text('Apply'),
        ),
      ],
    );
  }

  void _apply() {
    try {
      final payload = SheetEngineOperationPayloadParser.parseText(
        _controller.text,
      );
      Navigator.of(context).pop(payload);
    } on FormatException catch (error) {
      setState(() => _errorText = error.message);
    } catch (_) {
      setState(() => _errorText = 'Invalid JSON payload');
    }
  }

  void _updatePreview(String value) {
    if (value.trim().isEmpty) {
      setState(() {
        _errorText = null;
        _summary = null;
      });
      return;
    }

    try {
      final summary = SheetEngineOperationPayloadParser.summarizeText(
        value,
        expectedDocumentId: widget.expectedDocumentId,
      );
      setState(() {
        _errorText = null;
        _summary = summary;
      });
    } on FormatException catch (error) {
      setState(() {
        _errorText = error.message;
        _summary = null;
      });
    } catch (_) {
      setState(() {
        _errorText = 'Invalid JSON payload';
        _summary = null;
      });
    }
  }
}

class _PayloadPreview extends StatelessWidget {
  const _PayloadPreview({required this.summary});

  final SheetEngineOperationPayloadSummary? summary;

  @override
  Widget build(BuildContext context) {
    final summary = this.summary;
    if (summary == null) {
      return DecoratedBox(
        decoration: BoxDecoration(
          color: KySheetColors.surfaceMuted,
          border: Border.all(color: KySheetColors.gridLine),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Padding(
          padding: EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(
                Icons.info_outline,
                color: KySheetColors.mutedText,
                size: 18,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Payload preview will appear here',
                  style: TextStyle(
                    color: KySheetColors.mutedText,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        color: KySheetColors.accentSoft,
        border: Border.all(color: KySheetColors.gridLine),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          children: [
            Row(
              children: [
                _PreviewMetric(
                  key: const ValueKey('ky-sheet-operations-import-kind'),
                  label: 'Payload',
                  value: summary.kindLabel,
                ),
                const SizedBox(width: 8),
                _PreviewMetric(
                  key: const ValueKey('ky-sheet-operations-import-count'),
                  label: 'Ops',
                  value: summary.operationCount.toString(),
                ),
                const SizedBox(width: 8),
                _PreviewMetric(
                  key: const ValueKey('ky-sheet-operations-import-matching'),
                  label: 'Matching',
                  value: summary.matchingOperationCount.toString(),
                ),
                const SizedBox(width: 8),
                _PreviewMetric(
                  key: const ValueKey('ky-sheet-operations-import-skipped'),
                  label: 'Skipped',
                  value: summary.skippedOperationCount.toString(),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Text(
                  'Targets',
                  style: TextStyle(
                    color: KySheetColors.mutedText,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    summary.targetDocumentsLabel,
                    key: const ValueKey('ky-sheet-operations-import-targets'),
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: KySheetColors.text,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PreviewMetric extends StatelessWidget {
  const _PreviewMetric({super.key, required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: KySheetColors.mutedText,
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: KySheetColors.text,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}
