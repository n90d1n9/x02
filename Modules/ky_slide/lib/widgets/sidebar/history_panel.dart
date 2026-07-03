import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/history_entry.dart';
import '../../states/history_provider.dart';
import '../../states/presentation_provider.dart';
import 'history_action_card.dart';
import 'sidebar_command_button.dart';
import 'sidebar_empty_state.dart';
import 'sidebar_section.dart';

class HistoryPanel extends ConsumerWidget {
  const HistoryPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(historyProvider);
    final theme = ref.watch(presentationProvider).theme;
    final actions = _recentActions(history);

    return SidebarSection(
      title: 'History',
      subtitle: 'Recent editor actions and recovery controls.',
      icon: Icons.history,
      gradientColors: [theme.primaryColor, theme.secondaryColor],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _HistoryControls(
            undoLabel: history.undoLabel,
            redoLabel: history.redoLabel,
            canUndo: history.canUndo,
            canRedo: history.canRedo,
            onUndo: () => ref.read(historyProvider.notifier).undo(),
            onRedo: () => ref.read(historyProvider.notifier).redo(),
          ),
          const SizedBox(height: 12),
          if (actions.isEmpty)
            const SidebarEmptyState(message: 'No actions yet')
          else
            Column(
              children: actions.map((action) {
                final isCurrent = action.index == history.currentIndex;
                return HistoryActionCard(
                  entry: action.entry,
                  isCurrent: isCurrent,
                  isFuture: action.index > history.currentIndex,
                  onSelected: isCurrent
                      ? null
                      : () => ref
                            .read(historyProvider.notifier)
                            .jumpTo(action.index),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  List<({HistoryEntry entry, int index})> _recentActions(HistoryState history) {
    return history.entries.indexed
        .where((item) => item.$2.label != null && item.$2.label!.isNotEmpty)
        .map((item) => (index: item.$1, entry: item.$2))
        .toList()
        .reversed
        .take(8)
        .toList();
  }
}

class _HistoryControls extends StatelessWidget {
  final String? undoLabel;
  final String? redoLabel;
  final bool canUndo;
  final bool canRedo;
  final VoidCallback onUndo;
  final VoidCallback onRedo;

  const _HistoryControls({
    required this.undoLabel,
    required this.redoLabel,
    required this.canUndo,
    required this.canRedo,
    required this.onUndo,
    required this.onRedo,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: SidebarCommandButton(
            icon: Icons.undo,
            label: undoLabel ?? 'Undo',
            isEnabled: canUndo,
            onPressed: onUndo,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: SidebarCommandButton(
            icon: Icons.redo,
            label: redoLabel ?? 'Redo',
            isEnabled: canRedo,
            onPressed: onRedo,
          ),
        ),
      ],
    );
  }
}
