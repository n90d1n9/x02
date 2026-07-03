import 'package:flutter/material.dart';

import '../models/page_layout.dart';

class DocumentLayoutSwitcher extends StatelessWidget {
  final PageLayout currentLayout;
  final ValueChanged<PageLayout>? onLayoutSelected;
  final bool showLabel;

  const DocumentLayoutSwitcher({
    super.key,
    required this.currentLayout,
    this.onLayoutSelected,
    this.showLabel = true,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final activeOption = _LayoutSwitcherOption.forLayout(currentLayout);

    return Container(
      height: 30,
      padding: const EdgeInsets.symmetric(horizontal: 3),
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(alpha: 0.72),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.72),
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final option in _LayoutSwitcherOption.values)
            _LayoutSwitchButton(
              option: option,
              selected: option.layout == currentLayout,
              onPressed: onLayoutSelected == null
                  ? null
                  : () => onLayoutSelected!(option.layout),
            ),
          if (showLabel) ...[
            const SizedBox(width: 6),
            Text(
              activeOption.label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 5),
          ],
        ],
      ),
    );
  }
}

class _LayoutSwitchButton extends StatelessWidget {
  final _LayoutSwitcherOption option;
  final bool selected;
  final VoidCallback? onPressed;

  const _LayoutSwitchButton({
    required this.option,
    required this.selected,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final foreground = selected
        ? colorScheme.onPrimaryContainer
        : colorScheme.onSurfaceVariant;

    return Tooltip(
      message: option.label,
      child: Semantics(
        button: true,
        selected: selected,
        label: option.label,
        child: InkWell(
          borderRadius: BorderRadius.circular(6),
          onTap: onPressed,
          child: Container(
            width: 28,
            height: 24,
            decoration: BoxDecoration(
              color: selected ? colorScheme.primaryContainer : null,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(option.icon, size: 15, color: foreground),
          ),
        ),
      ),
    );
  }
}

class _LayoutSwitcherOption {
  final PageLayout layout;
  final IconData icon;
  final String label;

  const _LayoutSwitcherOption({
    required this.layout,
    required this.icon,
    required this.label,
  });

  static const values = [
    _LayoutSwitcherOption(
      layout: PageLayout.print,
      icon: Icons.description_outlined,
      label: 'Print Layout',
    ),
    _LayoutSwitcherOption(
      layout: PageLayout.web,
      icon: Icons.web_asset_outlined,
      label: 'Web Layout',
    ),
    _LayoutSwitcherOption(
      layout: PageLayout.outline,
      icon: Icons.account_tree_outlined,
      label: 'Outline Layout',
    ),
  ];

  static _LayoutSwitcherOption forLayout(PageLayout layout) {
    return values.firstWhere((option) => option.layout == layout);
  }
}
