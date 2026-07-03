import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

import '../../models/object_style_preset.dart';
import '../object_style/object_style_preset_swatch.dart';
import '../object_style/object_style_preset_visuals.dart';

/// Compact preset picker used by the selected-object quick-format popup.
class SelectionQuickFormatPresetRow extends StatelessWidget {
  final Color accentColor;
  final Color secondaryColor;
  final ObjectStylePreset? selectedPreset;
  final ValueChanged<ObjectStylePreset> onSelected;

  const SelectionQuickFormatPresetRow({
    super.key,
    required this.accentColor,
    required this.secondaryColor,
    required this.onSelected,
    this.selectedPreset,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final preset in ObjectStylePreset.values)
          _QuickFormatPresetButton(
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
  }
}

/// Tappable object preset option with a miniature visual preview.
class _QuickFormatPresetButton extends StatelessWidget {
  final ObjectStylePresetVisuals visuals;
  final bool selected;
  final ValueChanged<ObjectStylePreset> onSelected;

  const _QuickFormatPresetButton({
    required this.visuals,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Apply ${visuals.label} preset',
      child: Semantics(
        button: true,
        selected: selected,
        label: 'Apply ${visuals.label} preset',
        child: InkWell(
          borderRadius: BorderRadius.circular(7),
          onTap: () => onSelected(visuals.preset),
          child: Container(
            width: 86,
            height: 34,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: selected
                  ? const Color(0xFF38BDF8).withValues(alpha: 0.14)
                  : Colors.white.withValues(alpha: 0.055),
              borderRadius: BorderRadius.circular(7),
              border: Border.all(
                color: selected
                    ? const Color(0xFF38BDF8).withValues(alpha: 0.42)
                    : Colors.white.withValues(alpha: 0.08),
              ),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Row(
                  children: [
                    ObjectStylePresetSwatch(
                      fillColor: visuals.fillColor,
                      borderColor: visuals.borderColor,
                      showGlow: visuals.showGlow,
                      width: 18,
                      height: 16,
                      radius: 5,
                    ),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Text(
                        visuals.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0,
                        ),
                      ),
                    ),
                  ],
                ),
                if (selected)
                  const Positioned(
                    right: 0,
                    child: Icon(
                      Icons.check_circle,
                      color: Color(0xFF38BDF8),
                      size: 13,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

@Preview(name: 'Selection quick format presets', size: Size(240, 96))
Widget selectionQuickFormatPresetRowPreview() {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    home: Scaffold(
      backgroundColor: const Color(0xFF101114),
      body: Center(
        child: SelectionQuickFormatPresetRow(
          accentColor: const Color(0xFF38BDF8),
          secondaryColor: const Color(0xFF14B8A6),
          onSelected: (_) {},
        ),
      ),
    ),
  );
}
