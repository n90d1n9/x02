import 'package:flutter/material.dart';

class SheetColumnFilterQuickActions extends StatelessWidget {
  const SheetColumnFilterQuickActions({
    super.key,
    required this.canClearFilter,
    required this.canClearSort,
    required this.isSorted,
    required this.sortAscending,
    required this.onSortAscending,
    required this.onSortDescending,
    required this.onClearFilter,
    required this.onClearSort,
  });

  final bool canClearFilter;
  final bool canClearSort;
  final bool isSorted;
  final bool sortAscending;
  final VoidCallback onSortAscending;
  final VoidCallback onSortDescending;
  final VoidCallback onClearFilter;
  final VoidCallback onClearSort;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: _SortButton(
            key: const ValueKey('ky-sheet-column-filter-sort-asc'),
            active: isSorted && sortAscending,
            icon: Icons.arrow_upward,
            label: 'A-Z',
            onPressed: onSortAscending,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _SortButton(
            key: const ValueKey('ky-sheet-column-filter-sort-desc'),
            active: isSorted && !sortAscending,
            icon: Icons.arrow_downward,
            label: 'Z-A',
            onPressed: onSortDescending,
          ),
        ),
        const SizedBox(width: 8),
        IconButton.filledTonal(
          key: const ValueKey('ky-sheet-column-filter-clear-sort'),
          onPressed: canClearSort ? onClearSort : null,
          tooltip: 'Clear sort',
          icon: const Icon(Icons.sort_by_alpha, size: 18),
        ),
        const SizedBox(width: 6),
        IconButton.filledTonal(
          key: const ValueKey('ky-sheet-column-filter-clear'),
          onPressed: canClearFilter ? onClearFilter : null,
          tooltip: 'Clear filter',
          icon: const Icon(Icons.filter_alt_off, size: 18),
        ),
      ],
    );
  }
}

class _SortButton extends StatelessWidget {
  const _SortButton({
    super.key,
    required this.active,
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final bool active;
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    if (active) {
      return FilledButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
        label: Text(label),
      );
    }

    return FilledButton.tonalIcon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
    );
  }
}
