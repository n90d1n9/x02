import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../model/cell/cell_selection.dart';
import '../model/sheet_history_entry.dart';
import '../state/sheet_navigation_provider.dart';
import '../state/spreadsheet_provider.dart';
import '../theme/ky_sheet_theme.dart';
import '../utils/sheet_history_summarizer.dart';
import 'sheet_sidebar_panel_surface.dart';

/// Sidebar panel for reviewing and controlling workbook undo/redo history.
class SheetHistoryPanel extends ConsumerWidget {
  const SheetHistoryPanel({super.key, this.onClose});

  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snapshot = SheetHistorySummarizer.summarize(
      undoStack: ref.watch(undoStackProvider),
      redoStack: ref.watch(redoStackProvider),
    );
    final sheet = ref.watch(spreadsheetProvider.notifier);

    return SheetSidebarPanelSurface(
      icon: Icons.history,
      title: 'History',
      subtitle: 'Undo and redo timeline',
      trailing: SheetSidebarPanelCountBadge(
        count: snapshot.undoCount + snapshot.redoCount,
      ),
      onClose: onClose,
      child: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          _HistorySummary(snapshot: snapshot),
          const SizedBox(height: 12),
          _HistoryActions(
            canUndo: snapshot.canUndo,
            canRedo: snapshot.canRedo,
            canClear: !snapshot.isEmpty,
            onUndo: sheet.undo,
            onRedo: sheet.redo,
            onClear: sheet.clearHistory,
          ),
          const SizedBox(height: 16),
          if (snapshot.isEmpty)
            const _EmptyHistory()
          else ...[
            _HistorySection(
              title: 'Undo Timeline',
              entries: snapshot.undoEntries,
              emptyLabel: 'No undo history',
            ),
            const SizedBox(height: 14),
            _HistorySection(
              title: 'Redo Timeline',
              entries: snapshot.redoEntries,
              emptyLabel: 'No redo history',
            ),
          ],
        ],
      ),
    );
  }
}

/// Summary card for undo, redo, and visible history entry counts.
class _HistorySummary extends StatelessWidget {
  const _HistorySummary({required this.snapshot});

  final SheetHistorySnapshot snapshot;

  @override
  Widget build(BuildContext context) {
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
            _HistoryStat(label: 'Undo', value: snapshot.undoCount.toString()),
            const SizedBox(width: 8),
            _HistoryStat(label: 'Redo', value: snapshot.redoCount.toString()),
            const SizedBox(width: 8),
            _HistoryStat(
              label: 'Shown',
              value: (snapshot.undoEntries.length + snapshot.redoEntries.length)
                  .toString(),
            ),
          ],
        ),
      ),
    );
  }
}

/// Compact count metric used by the history summary card.
class _HistoryStat extends StatelessWidget {
  const _HistoryStat({required this.label, required this.value});

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

/// Action row for running undo, redo, and clear history commands.
class _HistoryActions extends StatelessWidget {
  const _HistoryActions({
    required this.canUndo,
    required this.canRedo,
    required this.canClear,
    required this.onUndo,
    required this.onRedo,
    required this.onClear,
  });

  final bool canUndo;
  final bool canRedo;
  final bool canClear;
  final VoidCallback onUndo;
  final VoidCallback onRedo;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: FilledButton.tonalIcon(
            key: const ValueKey('ky-sheet-history-undo'),
            onPressed: canUndo ? onUndo : null,
            icon: const Icon(Icons.undo, size: 18),
            label: const Text('Undo'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: FilledButton.tonalIcon(
            key: const ValueKey('ky-sheet-history-redo'),
            onPressed: canRedo ? onRedo : null,
            icon: const Icon(Icons.redo, size: 18),
            label: const Text('Redo'),
          ),
        ),
        const SizedBox(width: 8),
        IconButton.filledTonal(
          key: const ValueKey('ky-sheet-history-clear'),
          onPressed: canClear ? onClear : null,
          icon: const Icon(Icons.clear_all, size: 18),
          tooltip: 'Clear History',
        ),
      ],
    );
  }
}

/// Timeline section for one history stack.
class _HistorySection extends StatelessWidget {
  const _HistorySection({
    required this.title,
    required this.entries,
    required this.emptyLabel,
  });

  final String title;
  final List<SheetHistoryEntry> entries;
  final String emptyLabel;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        if (entries.isEmpty)
          _MutedMessage(label: emptyLabel)
        else
          for (final entry in entries) ...[
            _HistoryTile(entry: entry),
            const SizedBox(height: 8),
          ],
      ],
    );
  }
}

/// Clickable history entry that can navigate back to its primary cell.
class _HistoryTile extends ConsumerWidget {
  const _HistoryTile({required this.entry});

  final SheetHistoryEntry entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Material(
      color: KySheetColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: KySheetColors.gridLine),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: entry.primaryAddress == null
            ? null
            : () {
                ref
                    .read(sheetNavigationControllerProvider)
                    .goTo(CellSelection.single(entry.primaryAddress!));
              },
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              _StackBadge(entry: entry),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${entry.rangeLabel} - ${entry.detail}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: KySheetColors.mutedText,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              if (entry.isNextAction) ...[
                const SizedBox(width: 8),
                const Icon(Icons.bolt, color: KySheetColors.accent, size: 16),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Visual stack marker for undo and redo history entries.
class _StackBadge extends StatelessWidget {
  const _StackBadge({required this.entry});

  final SheetHistoryEntry entry;

  @override
  Widget build(BuildContext context) {
    final isUndo = entry.stack == SheetHistoryStack.undo;
    return Container(
      width: 38,
      height: 32,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isUndo ? KySheetColors.accentSoft : KySheetColors.surfaceMuted,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isUndo ? KySheetColors.headerActive : KySheetColors.gridLine,
        ),
      ),
      child: Icon(
        isUndo ? Icons.undo : Icons.redo,
        size: 17,
        color: isUndo ? KySheetColors.accent : KySheetColors.mutedText,
      ),
    );
  }
}

/// Empty state shown when there are no undo or redo entries.
class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory();

  @override
  Widget build(BuildContext context) {
    return const _MutedMessage(label: 'No history yet');
  }
}

/// Muted message card used by empty history sections.
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
