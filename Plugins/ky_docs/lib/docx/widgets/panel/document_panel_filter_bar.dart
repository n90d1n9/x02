import 'package:flutter/material.dart';

/// Describes one counted filter option for document panel filter bars.
class DocumentPanelFilterOption<T> {
  final T value;
  final String keySuffix;
  final String label;
  final int count;
  final String? tooltip;

  const DocumentPanelFilterOption({
    required this.value,
    required this.keySuffix,
    required this.label,
    required this.count,
    this.tooltip,
  });
}

/// Renders a reusable horizontal row of counted filter chips for panels.
class DocumentPanelFilterBar<T> extends StatelessWidget {
  final String keyPrefix;
  final T selectedValue;
  final List<DocumentPanelFilterOption<T>> options;
  final ValueChanged<T> onSelected;
  final EdgeInsetsGeometry padding;
  final double spacing;

  const DocumentPanelFilterBar({
    super.key,
    required this.keyPrefix,
    required this.selectedValue,
    required this.options,
    required this.onSelected,
    this.padding = EdgeInsets.zero,
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
            _PanelFilterChip<T>(
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

/// Shows one selectable counted filter chip.
class _PanelFilterChip<T> extends StatelessWidget {
  final DocumentPanelFilterOption<T> option;
  final bool selected;
  final ValueChanged<T> onSelected;

  const _PanelFilterChip({
    super.key,
    required this.option,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final chip = ChoiceChip(
      label: Text('${option.label} ${option.count}'),
      selected: selected,
      onSelected: (_) => onSelected(option.value),
      labelStyle: TextStyle(
        color: selected ? colorScheme.onSecondaryContainer : null,
        fontSize: 12,
        fontWeight: FontWeight.w700,
      ),
      selectedColor: colorScheme.secondaryContainer,
      backgroundColor: colorScheme.surface.withValues(alpha: 0.72),
      side: BorderSide(
        color: selected
            ? colorScheme.secondary.withValues(alpha: 0.26)
            : colorScheme.outlineVariant.withValues(alpha: 0.7),
      ),
      visualDensity: VisualDensity.compact,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    );

    final tooltip = option.tooltip;
    if (tooltip == null) return chip;
    return Tooltip(message: tooltip, child: chip);
  }
}
