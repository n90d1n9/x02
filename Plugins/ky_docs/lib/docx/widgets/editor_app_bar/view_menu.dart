import 'package:flutter/material.dart';

import '../../models/page_layout.dart';

class DocumentViewMenu extends StatelessWidget {
  final PageLayout currentLayout;
  final bool showOutline;
  final bool showPageNavigator;
  final ValueChanged<PageLayout> onSetPageLayout;
  final VoidCallback onToggleOutline;
  final VoidCallback onTogglePageNavigator;

  const DocumentViewMenu({
    super.key,
    required this.currentLayout,
    required this.showOutline,
    required this.showPageNavigator,
    required this.onSetPageLayout,
    required this.onToggleOutline,
    required this.onTogglePageNavigator,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.view_sidebar),
      tooltip: 'View',
      onSelected: (value) {
        if (value == 'print') {
          onSetPageLayout(PageLayout.print);
        } else if (value == 'web') {
          onSetPageLayout(PageLayout.web);
        } else if (value == 'pages') {
          onTogglePageNavigator();
        } else if (value == 'outline') {
          onToggleOutline();
        }
      },
      itemBuilder: (context) => [
        _layoutMenuItem(
          value: 'print',
          selected: currentLayout == PageLayout.print,
          label: 'Print Layout',
        ),
        _layoutMenuItem(
          value: 'web',
          selected: currentLayout == PageLayout.web,
          label: 'Web Layout',
        ),
        const PopupMenuDivider(),
        _layoutMenuItem(
          value: 'pages',
          selected: showPageNavigator,
          label: 'Page Navigator',
        ),
        _layoutMenuItem(
          value: 'outline',
          selected: showOutline,
          label: 'Outline',
        ),
      ],
    );
  }

  PopupMenuItem<String> _layoutMenuItem({
    required String value,
    required bool selected,
    required String label,
  }) {
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(
            selected ? Icons.check_box : Icons.check_box_outline_blank,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(label),
        ],
      ),
    );
  }
}
