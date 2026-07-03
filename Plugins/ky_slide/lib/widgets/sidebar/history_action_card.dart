import 'package:flutter/material.dart';

import '../../models/history_entry.dart';
import '../../services/history_entry_summary_service.dart';
import 'sidebar_action_card.dart';

class HistoryActionCard extends StatelessWidget {
  final HistoryEntry entry;
  final bool isCurrent;
  final bool isFuture;
  final VoidCallback? onSelected;

  const HistoryActionCard({
    super.key,
    required this.entry,
    required this.isCurrent,
    required this.isFuture,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final label = entry.label ?? 'Editor action';
    final summary = HistoryEntrySummaryService.describe(entry);
    final markerColor = _markerColor;
    final textColor = isFuture ? Colors.white38 : Colors.white;

    return Tooltip(
      message: isCurrent ? 'Current state - $summary' : 'Restore $label',
      waitDuration: const Duration(milliseconds: 450),
      child: SidebarActionCard(
        accentColor: markerColor,
        selected: isCurrent,
        onPressed: onSelected,
        semanticsLabel: isCurrent ? 'Current action: $label' : 'Restore $label',
        backgroundColor: isFuture
            ? Colors.white.withValues(alpha: 0.035)
            : Colors.white.withValues(alpha: 0.045),
        borderColor: isFuture
            ? Colors.white.withValues(alpha: 0.06)
            : Colors.white.withValues(alpha: 0.08),
        child: Row(
          children: [
            _HistoryMarker(color: markerColor),
            const SizedBox(width: 9),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 12,
                      fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    summary,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isFuture ? Colors.white30 : Colors.white54,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 160),
              child: isCurrent
                  ? const Text(
                      'Current',
                      key: ValueKey('current-history-label'),
                      style: TextStyle(
                        color: Color(0xFF86EFAC),
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    )
                  : Icon(
                      Icons.restore,
                      key: ValueKey('restore-history-icon-$label'),
                      size: 14,
                      color: isFuture ? Colors.white30 : Colors.white54,
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Color get _markerColor {
    if (isCurrent) {
      return const Color(0xFF22C55E);
    }
    if (isFuture) {
      return Colors.white30;
    }
    return Colors.white54;
  }
}

class _HistoryMarker extends StatelessWidget {
  final Color color;

  const _HistoryMarker({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
