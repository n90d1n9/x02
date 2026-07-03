import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/sheet_engine_operation_provider.dart';
import '../state/spreadsheet_provider.dart';
import '../theme/ky_sheet_theme.dart';
import '../utils/sheet_engine_operation_payload_parser.dart';
import '../utils/sheet_engine_operation_replayer.dart';
import 'sheet_engine_operation_import_dialog.dart';
import 'sheet_sidebar_panel_surface.dart';

/// Sidebar panel for inspecting and replaying Waraq sheet engine operations.
class SheetEngineOperationPanel extends ConsumerWidget {
  const SheetEngineOperationPanel({super.key, this.onClose});

  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final log = ref.watch(sheetEngineOperationLogProvider);
    final operations = log.operations.reversed.take(20).toList();

    return SheetSidebarPanelSurface(
      icon: Icons.hub_outlined,
      title: 'Waraq Operations',
      subtitle: 'Sheet engine sync log',
      trailing: SheetSidebarPanelCountBadge(count: log.operations.length),
      width: 336,
      onClose: onClose,
      child: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          _OperationSummary(log: log),
          const SizedBox(height: 12),
          _OperationActions(
            canCopy: log.operations.isNotEmpty,
            canClear: log.operations.isNotEmpty,
            onApply: () => _showApplyDialog(context, ref),
            onCopy: () => _copyLog(context, log),
            onClear: () =>
                ref.read(sheetEngineOperationLogProvider.notifier).clear(),
          ),
          const SizedBox(height: 14),
          if (operations.isEmpty)
            const _EmptyLog()
          else ...[
            const _SectionTitle(title: 'Recent Operations'),
            const SizedBox(height: 8),
            for (final operation in operations) ...[
              _OperationTile(operation: operation),
              const SizedBox(height: 8),
            ],
          ],
        ],
      ),
    );
  }

  Future<void> _copyLog(
    BuildContext context,
    SheetEngineOperationLogState log,
  ) async {
    final messenger = ScaffoldMessenger.maybeOf(context);
    final text = const JsonEncoder.withIndent('  ').convert(log.toJson());
    await Clipboard.setData(ClipboardData(text: text));
    messenger?.showSnackBar(
      SnackBar(
        content: Text(
          'Copied ${log.operations.length} Waraq ${log.operations.length == 1 ? 'operation' : 'operations'}',
        ),
        duration: const Duration(milliseconds: 1600),
      ),
    );
  }

  Future<void> _showApplyDialog(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.maybeOf(context);
    final expectedDocumentId = ref
        .read(sheetEngineOperationLogProvider)
        .documentId;
    final payload = await showDialog<SheetEngineOperationPayload>(
      context: context,
      builder: (context) => SheetEngineOperationImportDialog(
        expectedDocumentId: expectedDocumentId,
      ),
    );
    if (payload == null) return;

    final sheet = ref.read(spreadsheetProvider.notifier);
    final result = switch (payload.kind) {
      SheetEngineOperationPayloadKind.edit =>
        sheet.applySheetEngineEditWithResult(payload.edit),
      SheetEngineOperationPayloadKind.operation =>
        sheet.applySheetEngineOperationWithResult(payload.operation!),
      SheetEngineOperationPayloadKind.operationLog =>
        sheet.applySheetEngineOperationLogWithResult(payload.operationLog!),
    };

    messenger?.showSnackBar(
      SnackBar(
        content: Text(_formatApplyMessage(result)),
        duration: const Duration(milliseconds: 1600),
      ),
    );
  }

  String _formatApplyMessage(SheetEngineOperationReplayResult result) {
    final applied = result.appliedEditCount;
    final appliedLabel = applied == 1 ? 'edit' : 'edits';
    if (!result.hasSkippedOperations) {
      return 'Applied $applied Waraq $appliedLabel';
    }

    final skipped = result.skippedOperationCount;
    final skippedLabel = skipped == 1 ? 'operation' : 'operations';
    return 'Applied $applied Waraq $appliedLabel, skipped $skipped $skippedLabel';
  }
}

/// Summary card for the active Waraq operation log metadata.
class _OperationSummary extends StatelessWidget {
  const _OperationSummary({required this.log});

  final SheetEngineOperationLogState log;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: KySheetColors.surfaceMuted,
        border: Border.all(color: KySheetColors.gridLine),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          children: [
            Row(
              children: [
                _SummaryMetric(
                  label: 'Ops',
                  value: log.operations.length.toString(),
                ),
                const SizedBox(width: 8),
                _SummaryMetric(
                  label: 'Next',
                  value: log.nextSequence.toString(),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _MetadataRow(label: 'Document', value: log.documentId),
            const SizedBox(height: 6),
            _MetadataRow(label: 'Actor', value: log.actorId),
          ],
        ),
      ),
    );
  }
}

/// Numeric metric shown inside the operation summary card.
class _SummaryMetric extends StatelessWidget {
  const _SummaryMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: KySheetColors.surface,
          border: Border.all(color: KySheetColors.gridLine),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding: const EdgeInsets.all(10),
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
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  color: KySheetColors.text,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Label and value row for operation log metadata.
class _MetadataRow extends StatelessWidget {
  const _MetadataRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 72,
          child: Text(
            label,
            style: const TextStyle(
              color: KySheetColors.mutedText,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
          ),
        ),
      ],
    );
  }
}

/// Action row for applying, copying, and clearing operation logs.
class _OperationActions extends StatelessWidget {
  const _OperationActions({
    required this.canCopy,
    required this.canClear,
    required this.onApply,
    required this.onCopy,
    required this.onClear,
  });

  final bool canCopy;
  final bool canClear;
  final VoidCallback onApply;
  final VoidCallback onCopy;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: FilledButton.tonalIcon(
            key: const ValueKey('ky-sheet-operations-apply'),
            onPressed: onApply,
            icon: const Icon(Icons.playlist_add_check, size: 17),
            label: const Text('Apply'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: FilledButton.tonalIcon(
            key: const ValueKey('ky-sheet-operations-copy'),
            onPressed: canCopy ? onCopy : null,
            icon: const Icon(Icons.content_copy, size: 17),
            label: const Text('Copy Log'),
          ),
        ),
        const SizedBox(width: 8),
        IconButton.filledTonal(
          key: const ValueKey('ky-sheet-operations-clear'),
          onPressed: canClear ? onClear : null,
          icon: const Icon(Icons.clear_all, size: 18),
          tooltip: 'Clear Operations',
        ),
      ],
    );
  }
}

/// Section heading used above recent operation lists.
class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
    );
  }
}

/// Recent operation preview tile for a Waraq operation envelope.
class _OperationTile extends StatelessWidget {
  const _OperationTile({required this.operation});

  final Map<String, dynamic> operation;

  @override
  Widget build(BuildContext context) {
    final edit = _editMap(operation['edit']);
    final editKind = _editKind(operation['edit']);
    final position = _positionLabel(edit);
    final rawContent = _rawContent(edit);
    final sequence = operation['sequence']?.toString() ?? '-';

    return DecoratedBox(
      decoration: BoxDecoration(
        color: KySheetColors.surface,
        border: Border.all(color: KySheetColors.gridLine),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _OperationBadge(label: '#$sequence'),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    editKind,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: KySheetColors.text,
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                if (position != null)
                  Text(
                    position,
                    style: const TextStyle(
                      color: KySheetColors.mutedText,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
              ],
            ),
            if (rawContent != null) ...[
              const SizedBox(height: 8),
              Text(
                rawContent,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: KySheetColors.mutedText,
                  fontFamily: 'monospace',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Map<String, dynamic>? _editMap(dynamic edit) {
    if (edit is! Map || edit.isEmpty) return null;
    final entry = edit.entries.first;
    if (entry.value is! Map) return null;
    return Map<String, dynamic>.from(entry.value as Map);
  }

  String _editKind(dynamic edit) {
    if (edit is String) return edit;
    if (edit is Map && edit.isNotEmpty) return edit.keys.first.toString();
    return 'Unknown';
  }

  String? _positionLabel(Map<String, dynamic>? edit) {
    final position = edit?['position'];
    if (position is! Map) return null;
    final col = position['col'];
    final row = position['row'];
    if (col == null || row == null) return null;
    return 'R${(row as num).toInt() + 1} C${(col as num).toInt() + 1}';
  }

  String? _rawContent(Map<String, dynamic>? edit) {
    final raw = edit?['raw_content']?.toString();
    if (raw == null || raw.isEmpty) return null;
    return raw;
  }
}

/// Compact sequence badge for recent operation tiles.
class _OperationBadge extends StatelessWidget {
  const _OperationBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: KySheetColors.accentSoft,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Text(
          label,
          style: const TextStyle(
            color: KySheetColors.accent,
            fontSize: 11,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

/// Empty state shown before any Waraq operations are recorded.
class _EmptyLog extends StatelessWidget {
  const _EmptyLog();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: KySheetColors.surfaceMuted,
        border: Border.all(color: KySheetColors.gridLine),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Padding(
        padding: EdgeInsets.all(18),
        child: Column(
          children: [
            Icon(Icons.hub_outlined, color: KySheetColors.mutedText),
            SizedBox(height: 8),
            Text(
              'No Waraq operations yet',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: KySheetColors.mutedText,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
