import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../model/cell/cell_address.dart';
import '../model/cell/cell_data.dart';
import '../model/sheet_cleanup.dart';
import '../state/spreadsheet_provider.dart';
import '../theme/ky_sheet_theme.dart';
import '../utils/sheet_cleanup_engine.dart';
import 'sheet_sidebar_panel_surface.dart';

/// Sidebar panel for previewing and applying cleanup operations to selections.
class SheetDataCleanupPanel extends ConsumerStatefulWidget {
  const SheetDataCleanupPanel({super.key, this.onClose});

  final VoidCallback? onClose;

  @override
  ConsumerState<SheetDataCleanupPanel> createState() =>
      _SheetDataCleanupPanelState();
}

/// State holder for the selected cleanup operation.
class _SheetDataCleanupPanelState extends ConsumerState<SheetDataCleanupPanel> {
  SheetCleanupOperation _operation = SheetCleanupOperation.trimWhitespace;

  @override
  Widget build(BuildContext context) {
    final selection = ref.watch(selectedCellProvider);
    final cells = ref.watch(spreadsheetProvider);
    final plan = selection == null
        ? null
        : SheetCleanupEngine.buildPlan(
            operation: _operation,
            selection: selection,
            cells: cells,
          );

    return SheetSidebarPanelSurface(
      icon: Icons.cleaning_services_outlined,
      title: 'Data Cleanup',
      subtitle: 'Clean selected data',
      trailing: SheetSidebarPanelLabelBadge(label: selection?.label ?? 'None'),
      onClose: widget.onClose,
      child: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          _CleanupSummary(plan: plan),
          const SizedBox(height: 12),
          DropdownButtonFormField<SheetCleanupOperation>(
            key: const ValueKey('ky-sheet-cleanup-operation'),
            initialValue: _operation,
            isExpanded: true,
            decoration: InputDecoration(
              isDense: true,
              labelText: 'Operation',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            items: [
              for (final operation in SheetCleanupOperation.values)
                DropdownMenuItem(
                  value: operation,
                  child: Text(operation.label),
                ),
            ],
            onChanged: (value) {
              if (value != null) {
                setState(() => _operation = value);
              }
            },
          ),
          const SizedBox(height: 12),
          _OperationGrid(
            selected: _operation,
            onSelected: (operation) {
              setState(() => _operation = operation);
            },
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            key: const ValueKey('ky-sheet-cleanup-apply'),
            onPressed: plan?.hasChanges ?? false
                ? () => _applyPlan(plan!)
                : null,
            icon: const Icon(Icons.auto_fix_high, size: 18),
            label: const Text('Apply Cleanup'),
          ),
          const SizedBox(height: 16),
          _CleanupPreview(plan: plan),
        ],
      ),
    );
  }

  void _applyPlan(SheetCleanupPlan plan) {
    ref
        .read(spreadsheetProvider.notifier)
        .replaceCells(plan.replacements, description: plan.operation.label);
  }
}

/// Summary card for scanned cells, planned changes, and affected rows.
class _CleanupSummary extends StatelessWidget {
  const _CleanupSummary({required this.plan});

  final SheetCleanupPlan? plan;

  @override
  Widget build(BuildContext context) {
    final scanned = plan?.scannedCellCount ?? 0;
    final changed = plan?.changedCellCount ?? 0;
    final rows = plan?.affectedRowCount ?? 0;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: KySheetColors.surfaceMuted,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: KySheetColors.gridLine),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            _CleanupStat(label: 'Scanned', value: scanned.toString()),
            const SizedBox(width: 8),
            _CleanupStat(label: 'Changes', value: changed.toString()),
            const SizedBox(width: 8),
            _CleanupStat(label: 'Rows', value: rows.toString()),
          ],
        ),
      ),
    );
  }
}

/// Compact cleanup metric used by the summary card.
class _CleanupStat extends StatelessWidget {
  const _CleanupStat({required this.label, required this.value});

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
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: KySheetColors.text,
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

/// Quick operation picker for common cleanup transformations.
class _OperationGrid extends StatelessWidget {
  const _OperationGrid({required this.selected, required this.onSelected});

  final SheetCleanupOperation selected;
  final ValueChanged<SheetCleanupOperation> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final operation in SheetCleanupOperation.values)
          ChoiceChip(
            label: Text(operation.label),
            avatar: Icon(_iconFor(operation), size: 16),
            selected: selected == operation,
            onSelected: (_) => onSelected(operation),
            visualDensity: VisualDensity.compact,
          ),
      ],
    );
  }

  IconData _iconFor(SheetCleanupOperation operation) {
    return switch (operation) {
      SheetCleanupOperation.trimWhitespace => Icons.space_bar,
      SheetCleanupOperation.normalizeWhitespace => Icons.compress,
      SheetCleanupOperation.uppercase => Icons.keyboard_capslock,
      SheetCleanupOperation.lowercase => Icons.text_fields,
      SheetCleanupOperation.titleCase => Icons.title,
      SheetCleanupOperation.clearDuplicateRows => Icons.playlist_remove,
    };
  }
}

/// Preview list for the pending cleanup changes.
class _CleanupPreview extends StatelessWidget {
  const _CleanupPreview({required this.plan});

  final SheetCleanupPlan? plan;

  @override
  Widget build(BuildContext context) {
    if (plan == null) {
      return const _MutedMessage(label: 'No selection');
    }

    if (!plan!.hasChanges) {
      return const _MutedMessage(label: 'No cleanup changes');
    }

    final entries = plan!.replacements.entries.toList()
      ..sort((left, right) {
        final rowCompare = left.key.row.compareTo(right.key.row);
        return rowCompare == 0
            ? left.key.col.compareTo(right.key.col)
            : rowCompare;
      });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Preview',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        for (final entry in entries.take(8)) ...[
          _PreviewTile(address: entry.key, cell: entry.value),
          const SizedBox(height: 8),
        ],
        if (entries.length > 8)
          _MutedMessage(label: '${entries.length - 8} more changes'),
      ],
    );
  }
}

/// Single cell replacement preview row.
class _PreviewTile extends StatelessWidget {
  const _PreviewTile({required this.address, required this.cell});

  final CellAddress address;
  final CellData? cell;

  @override
  Widget build(BuildContext context) {
    final value = cell?.value;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: KySheetColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: KySheetColors.gridLine),
      ),
      child: Row(
        children: [
          Text(
            address.label,
            style: const TextStyle(
              color: KySheetColors.accent,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              value == null || value.isEmpty ? 'Clear' : value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

/// Muted message card for empty cleanup states.
class _MutedMessage extends StatelessWidget {
  const _MutedMessage({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: KySheetColors.surfaceMuted,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: KySheetColors.gridLine),
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: KySheetColors.mutedText,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
