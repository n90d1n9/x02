import 'package:flutter/material.dart';

import 'sidebar_command_button.dart';

class SidebarCommandGridItem {
  final IconData icon;
  final String label;
  final bool isEnabled;
  final VoidCallback onPressed;

  const SidebarCommandGridItem({
    required this.icon,
    required this.label,
    required this.isEnabled,
    required this.onPressed,
  });
}

class SidebarCommandGrid extends StatelessWidget {
  final List<SidebarCommandGridItem> items;
  final Color accentColor;
  final int columns;
  final double columnGap;
  final double rowGap;

  const SidebarCommandGrid({
    super.key,
    required this.items,
    required this.accentColor,
    this.columns = 2,
    this.columnGap = 8,
    this.rowGap = 8,
  }) : assert(columns > 0);

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];

    for (var start = 0; start < items.length; start += columns) {
      final rowItems = items.skip(start).take(columns).toList();
      rows.add(
        _CommandRow(
          items: rowItems,
          columns: columns,
          accentColor: accentColor,
          columnGap: columnGap,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final row in rows.indexed) ...[
          if (row.$1 > 0) SizedBox(height: rowGap),
          row.$2,
        ],
      ],
    );
  }
}

class _CommandRow extends StatelessWidget {
  final List<SidebarCommandGridItem> items;
  final int columns;
  final Color accentColor;
  final double columnGap;

  const _CommandRow({
    required this.items,
    required this.columns,
    required this.accentColor,
    required this.columnGap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var index = 0; index < columns; index++) ...[
          if (index > 0) SizedBox(width: columnGap),
          Expanded(
            child: index < items.length
                ? SidebarCommandButton(
                    icon: items[index].icon,
                    label: items[index].label,
                    isEnabled: items[index].isEnabled,
                    accentColor: accentColor,
                    onPressed: items[index].onPressed,
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ],
    );
  }
}
