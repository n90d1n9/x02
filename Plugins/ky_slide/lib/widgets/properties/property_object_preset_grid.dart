import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

import '../../models/object_style_preset.dart';
import '../object_style/object_style_preset_swatch.dart';
import '../object_style/object_style_preset_visuals.dart';

/// Responsive grid of object style presets for the component inspector.
class PropertyObjectPresetGrid extends StatelessWidget {
  final Color accentColor;
  final Color secondaryColor;
  final ObjectStylePreset? selectedPreset;
  final bool enabled;
  final ValueChanged<ObjectStylePreset> onSelected;

  const PropertyObjectPresetGrid({
    super.key,
    required this.accentColor,
    required this.secondaryColor,
    required this.onSelected,
    this.selectedPreset,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth = constraints.maxWidth >= 244
            ? (constraints.maxWidth - 8) / 2
            : constraints.maxWidth;

        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final preset in ObjectStylePreset.values)
              _PropertyObjectPresetButton(
                width: itemWidth,
                enabled: enabled,
                selected: preset == selectedPreset,
                visuals: ObjectStylePresetVisuals.forPreset(
                  preset: preset,
                  accentColor: accentColor,
                  secondaryColor: secondaryColor,
                ),
                onSelected: onSelected,
              ),
          ],
        );
      },
    );
  }
}

/// Tappable inspector preset tile with a stable compact footprint.
class _PropertyObjectPresetButton extends StatelessWidget {
  final double width;
  final bool enabled;
  final bool selected;
  final ObjectStylePresetVisuals visuals;
  final ValueChanged<ObjectStylePreset> onSelected;

  const _PropertyObjectPresetButton({
    required this.width,
    required this.enabled,
    required this.selected,
    required this.visuals,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final foreground = enabled ? Colors.white : Colors.white38;

    return Tooltip(
      message: 'Apply ${visuals.label} preset',
      child: Semantics(
        button: true,
        enabled: enabled,
        selected: selected,
        label: 'Apply ${visuals.label} preset',
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: enabled ? () => onSelected(visuals.preset) : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            width: width,
            height: 42,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: selected && enabled
                  ? const Color(0xFF38BDF8).withValues(alpha: 0.13)
                  : enabled
                  ? Colors.white.withValues(alpha: 0.055)
                  : Colors.white.withValues(alpha: 0.025),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: selected && enabled
                    ? const Color(0xFF38BDF8).withValues(alpha: 0.46)
                    : enabled
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.white.withValues(alpha: 0.045),
              ),
            ),
            child: Row(
              children: [
                ObjectStylePresetSwatch(
                  fillColor: enabled
                      ? visuals.fillColor
                      : visuals.fillColor.withValues(alpha: 0.35),
                  borderColor: enabled
                      ? visuals.borderColor
                      : visuals.borderColor.withValues(alpha: 0.35),
                  showGlow: enabled && visuals.showGlow,
                  width: 24,
                  height: 18,
                  radius: 5,
                ),
                const SizedBox(width: 9),
                Icon(
                  visuals.icon,
                  color: foreground.withValues(alpha: 0.78),
                  size: 16,
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    visuals.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: foreground,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0,
                    ),
                  ),
                ),
                if (selected)
                  Icon(
                    Icons.check_circle,
                    color: enabled ? const Color(0xFF38BDF8) : Colors.white24,
                    size: 15,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

@Preview(name: 'Property object preset grid', size: Size(320, 180))
Widget propertyObjectPresetGridPreview() {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    home: Scaffold(
      backgroundColor: const Color(0xFF1E293B),
      body: Center(
        child: SizedBox(
          width: 280,
          child: PropertyObjectPresetGrid(
            accentColor: const Color(0xFF38BDF8),
            secondaryColor: const Color(0xFF14B8A6),
            onSelected: (_) {},
          ),
        ),
      ),
    ),
  );
}
