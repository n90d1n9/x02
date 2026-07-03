import 'package:flutter/material.dart';

/// Renders a reusable labeled slider for document panel and dialog settings.
class DocumentPanelSliderControl extends StatelessWidget {
  final Key? sliderKey;
  final IconData? icon;
  final String label;
  final String valueLabel;
  final String? description;
  final double value;
  final double min;
  final double max;
  final int? divisions;
  final ValueChanged<double> onChanged;
  final EdgeInsetsGeometry padding;
  final String? semanticFormatterSuffix;

  const DocumentPanelSliderControl({
    super.key,
    this.sliderKey,
    this.icon,
    required this.label,
    required this.valueLabel,
    this.description,
    required this.value,
    required this.min,
    required this.max,
    this.divisions,
    required this.onChanged,
    this.padding = EdgeInsets.zero,
    this.semanticFormatterSuffix,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final descriptionText = description?.trim();

    return Padding(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18, color: colorScheme.primary),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          valueLabel,
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                    if (descriptionText != null &&
                        descriptionText.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        descriptionText,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Slider(
            key: sliderKey,
            value: value.clamp(min, max).toDouble(),
            min: min,
            max: max,
            divisions: divisions,
            label: valueLabel,
            semanticFormatterCallback: semanticFormatterSuffix == null
                ? null
                : (value) =>
                      '${value.toStringAsFixed(1)} '
                      '$semanticFormatterSuffix',
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
