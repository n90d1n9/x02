import 'package:flutter/material.dart';

import '../theme/ky_sheet_theme.dart';

class SheetColumnFilterStateSummary extends StatelessWidget {
  const SheetColumnFilterStateSummary({
    super.key,
    required this.isSorted,
    required this.sortAscending,
    this.filterDescription,
  });

  final bool isSorted;
  final bool sortAscending;
  final String? filterDescription;

  @override
  Widget build(BuildContext context) {
    final filterText = filterDescription?.trim();
    final hasFilter = filterText != null && filterText.isNotEmpty;

    return Container(
      key: const ValueKey('ky-sheet-column-filter-state-summary'),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: KySheetColors.accentSoft,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: KySheetColors.gridLine),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, size: 17, color: KySheetColors.accent),
          const SizedBox(width: 8),
          Expanded(
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                if (isSorted)
                  _StatePill(
                    key: const ValueKey('ky-sheet-column-filter-state-sort'),
                    icon: sortAscending
                        ? Icons.arrow_upward
                        : Icons.arrow_downward,
                    label: sortAscending ? 'Sorted A-Z' : 'Sorted Z-A',
                  ),
                if (hasFilter)
                  _StatePill(
                    key: const ValueKey('ky-sheet-column-filter-state-filter'),
                    icon: Icons.filter_alt,
                    label: filterText,
                  ),
                if (!isSorted && !hasFilter)
                  const Text(
                    'No active sort or filter',
                    style: TextStyle(
                      color: KySheetColors.mutedText,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatePill extends StatelessWidget {
  const _StatePill({super.key, required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 168),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: KySheetColors.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: KySheetColors.gridLineStrong),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: KySheetColors.accent),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
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
    );
  }
}
