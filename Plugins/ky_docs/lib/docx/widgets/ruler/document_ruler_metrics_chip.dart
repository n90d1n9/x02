import 'package:flutter/material.dart';

import '../../models/page_margin_preset.dart';
import '../../models/page_orientation.dart';
import '../../models/page_settings.dart';
import '../../models/page_size.dart';

/// Shows a compact page-size and margin summary beside the print ruler.
class DocumentRulerMetricsChip extends StatelessWidget {
  static const chipKey = ValueKey('document-ruler-metrics-chip');
  static const settingsButtonKey = ValueKey(
    'document-ruler-metrics-settings-button',
  );
  static const optionPrefixKey = 'document-ruler-margin-preset-option';

  final PageSettings pageSettings;
  final ValueChanged<EdgeInsets>? onMarginsChanged;
  final VoidCallback? onPressed;

  const DocumentRulerMetricsChip({
    super.key,
    required this.pageSettings,
    this.onMarginsChanged,
    this.onPressed,
  });

  static Key optionKey(DocumentPageMarginPreset preset) {
    return Key('$optionPrefixKey-${preset.name}');
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final summary = _DocumentRulerMetricsSummary.fromSettings(pageSettings);
    final selectedPreset = DocumentPageMarginPresetMatcher.match(
      pageSettings.margins,
    );
    final canChangeMargins = onMarginsChanged != null;
    final canOpenSettings = onPressed != null;
    final tooltip = canChangeMargins
        ? '${summary.tooltip}. Choose margin preset'
        : '${summary.tooltip} - locked';

    return Row(
      children: [
        Expanded(
          child: PopupMenuButton<DocumentPageMarginPreset>(
            key: chipKey,
            enabled: canChangeMargins,
            tooltip: tooltip,
            initialValue: selectedPreset,
            onSelected: (preset) => onMarginsChanged?.call(preset.margins),
            itemBuilder: (context) => [
              for (final preset in DocumentPageMarginPreset.values)
                PopupMenuItem(
                  key: optionKey(preset),
                  value: preset,
                  child: _MarginPresetMenuItem(
                    preset: preset,
                    selected: preset == selectedPreset,
                  ),
                ),
            ],
            child: _RulerMetricsChipBody(
              enabled: canChangeMargins,
              icon: pageSettings.orientation.icon,
              label: summary.label,
              trailingIcon: Icons.arrow_drop_down,
            ),
          ),
        ),
        if (canOpenSettings) ...[
          const SizedBox(width: 4),
          Tooltip(
            message: 'Open page settings',
            child: IconButton(
              key: settingsButtonKey,
              onPressed: onPressed,
              icon: const Icon(Icons.tune),
              style: IconButton.styleFrom(
                minimumSize: const Size.square(28),
                padding: EdgeInsets.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
                backgroundColor: colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.62,
                ),
                foregroundColor: colorScheme.onSurfaceVariant,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                  side: BorderSide(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.72),
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// Paints the compact ruler metrics button body used by the preset menu.
class _RulerMetricsChipBody extends StatelessWidget {
  final bool enabled;
  final IconData icon;
  final String label;
  final IconData trailingIcon;

  const _RulerMetricsChipBody({
    required this.enabled,
    required this.icon,
    required this.label,
    required this.trailingIcon,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Semantics(
      button: true,
      enabled: enabled,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.62),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: colorScheme.outlineVariant.withValues(alpha: 0.72),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Opacity(
            opacity: enabled ? 1 : 0.58,
            child: Row(
              children: [
                Icon(icon, size: 15, color: colorScheme.onSurfaceVariant),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(width: 2),
                Icon(
                  trailingIcon,
                  size: 16,
                  color: colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Renders one selectable page margin preset in the ruler menu.
class _MarginPresetMenuItem extends StatelessWidget {
  final DocumentPageMarginPreset preset;
  final bool selected;

  const _MarginPresetMenuItem({required this.preset, required this.selected});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final foreground = selected ? colorScheme.primary : colorScheme.onSurface;

    return Row(
      children: [
        Icon(
          selected ? Icons.check_circle : Icons.crop_free,
          color: foreground,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                preset.label,
                style: TextStyle(
                  color: foreground,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w700,
                ),
              ),
              Text(
                preset.description,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Formats page metrics for compact ruler chrome and accessibility labels.
class _DocumentRulerMetricsSummary {
  final String label;
  final String tooltip;

  const _DocumentRulerMetricsSummary({
    required this.label,
    required this.tooltip,
  });

  factory _DocumentRulerMetricsSummary.fromSettings(PageSettings settings) {
    final pageLabel = settings.pageSize.shortLabel;
    final orientationLabel = settings.orientation.label.toLowerCase();
    final margins = settings.margins;
    final marginLabel = _compactMarginLabel(margins);
    final tooltip =
        '${settings.pageSize.label} $orientationLabel, '
        'margins top ${_formatPoints(margins.top)}, '
        'right ${_formatPoints(margins.right)}, '
        'bottom ${_formatPoints(margins.bottom)}, '
        'left ${_formatPoints(margins.left)}';

    return _DocumentRulerMetricsSummary(
      label: '$pageLabel · $marginLabel',
      tooltip: tooltip,
    );
  }

  static String _compactMarginLabel(EdgeInsets margins) {
    final values = [margins.left, margins.top, margins.right, margins.bottom];
    final allEqual = values.every((value) => (value - margins.left).abs() < 1);
    if (allEqual) return '${_formatPoints(margins.left)} margins';

    final horizontalEqual = (margins.left - margins.right).abs() < 1;
    final verticalEqual = (margins.top - margins.bottom).abs() < 1;
    if (horizontalEqual && verticalEqual) {
      return 'H ${_formatPoints(margins.left)} · V ${_formatPoints(margins.top)}';
    }

    return 'Custom margins';
  }

  static String _formatPoints(double points) {
    final inches = points / 72;
    final rounded = (inches * 10).round() / 10;
    if ((rounded - rounded.round()).abs() < 0.01) {
      return '${rounded.round()} in';
    }
    return '$rounded in';
  }
}
