import 'package:flutter/material.dart';

/// Describes one selectable tab inside a document side-panel tab strip.
class DocumentPanelTabOption<T> {
  final T value;
  final String keySuffix;
  final String label;
  final IconData icon;
  final int? count;
  final String? tooltip;

  const DocumentPanelTabOption({
    required this.value,
    required this.keySuffix,
    required this.label,
    required this.icon,
    this.count,
    this.tooltip,
  });
}

/// Renders a reusable, horizontally scrolling tab strip for document panels.
class DocumentPanelTabStrip<T> extends StatelessWidget {
  final String keyPrefix;
  final T selectedValue;
  final List<DocumentPanelTabOption<T>> options;
  final ValueChanged<T> onSelected;
  final EdgeInsetsGeometry padding;
  final double spacing;

  const DocumentPanelTabStrip({
    super.key,
    required this.keyPrefix,
    required this.selectedValue,
    required this.options,
    required this.onSelected,
    this.padding = const EdgeInsets.symmetric(horizontal: 16),
    this.spacing = 8,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: padding,
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (var index = 0; index < options.length; index++) ...[
            _DocumentPanelTab<T>(
              key: Key('$keyPrefix-${options[index].keySuffix}'),
              option: options[index],
              selected: selectedValue == options[index].value,
              onSelected: onSelected,
            ),
            if (index < options.length - 1) SizedBox(width: spacing),
          ],
        ],
      ),
    );
  }
}

/// Shows one selectable tab with an optional count badge.
class _DocumentPanelTab<T> extends StatelessWidget {
  final DocumentPanelTabOption<T> option;
  final bool selected;
  final ValueChanged<T> onSelected;

  const _DocumentPanelTab({
    super.key,
    required this.option,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final foreground = selected
        ? colorScheme.onPrimaryContainer
        : colorScheme.onSurfaceVariant;
    final background = selected
        ? colorScheme.primaryContainer.withValues(alpha: 0.78)
        : colorScheme.surfaceContainerHighest.withValues(alpha: 0.36);
    final borderColor = selected
        ? colorScheme.primary.withValues(alpha: 0.28)
        : colorScheme.outlineVariant.withValues(alpha: 0.70);

    final tab = Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: selected ? null : () => onSelected(option.value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(option.icon, size: 16, color: foreground),
              const SizedBox(width: 7),
              Text(
                option.label,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: foreground,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (option.count != null) ...[
                const SizedBox(width: 7),
                _DocumentPanelTabCountBadge(
                  count: option.count!,
                  selected: selected,
                ),
              ],
            ],
          ),
        ),
      ),
    );

    final tooltip = option.tooltip;
    if (tooltip == null) return tab;
    return Tooltip(message: tooltip, child: tab);
  }
}

/// Displays a compact count badge for panel tab options.
class _DocumentPanelTabCountBadge extends StatelessWidget {
  final int count;
  final bool selected;

  const _DocumentPanelTabCountBadge({
    required this.count,
    required this.selected,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final foreground = selected ? colorScheme.onPrimary : colorScheme.primary;
    final background = selected
        ? colorScheme.primary
        : colorScheme.primary.withValues(alpha: 0.10);

    return Container(
      constraints: const BoxConstraints(minWidth: 22),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$count',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: foreground,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}
