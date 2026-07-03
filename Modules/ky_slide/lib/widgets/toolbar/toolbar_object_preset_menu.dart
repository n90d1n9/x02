import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

import '../../models/object_style_preset.dart';
import '../object_style/object_style_preset_swatch.dart';
import '../object_style/object_style_preset_visuals.dart';
import 'ribbon_menu_button.dart';

/// Ribbon menu for applying reusable visual presets to selected objects.
class ToolbarObjectPresetMenu extends StatelessWidget {
  final Color accentColor;
  final Color secondaryColor;
  final ObjectStylePreset? selectedPreset;
  final bool enabled;
  final bool compact;
  final ValueChanged<ObjectStylePreset> onSelected;

  const ToolbarObjectPresetMenu({
    super.key,
    required this.accentColor,
    required this.secondaryColor,
    required this.onSelected,
    this.selectedPreset,
    this.enabled = true,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return RibbonMenuButton<ObjectStylePreset>(
      icon: Icons.auto_awesome_motion_outlined,
      tooltip: 'Object Presets',
      enabled: enabled,
      compact: compact,
      onSelected: onSelected,
      itemBuilder: (context) => [
        for (final preset in ObjectStylePreset.values)
          PopupMenuItem(
            value: preset,
            child: _ObjectPresetMenuRow(
              selected: preset == selectedPreset,
              visuals: ObjectStylePresetVisuals.forPreset(
                preset: preset,
                accentColor: accentColor,
                secondaryColor: secondaryColor,
              ),
            ),
          ),
      ],
    );
  }
}

/// Popup menu row that previews the visual tone of an object preset.
class _ObjectPresetMenuRow extends StatelessWidget {
  final ObjectStylePresetVisuals visuals;
  final bool selected;

  const _ObjectPresetMenuRow({required this.visuals, required this.selected});

  @override
  Widget build(BuildContext context) {
    final accentColor = selected ? const Color(0xFF38BDF8) : Colors.white70;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
      decoration: BoxDecoration(
        color: selected
            ? const Color(0xFF38BDF8).withValues(alpha: 0.12)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(7),
        border: Border.all(
          color: selected
              ? const Color(0xFF38BDF8).withValues(alpha: 0.35)
              : Colors.transparent,
        ),
      ),
      child: Row(
        children: [
          ObjectStylePresetSwatch(
            fillColor: visuals.fillColor,
            borderColor: visuals.borderColor,
            showGlow: visuals.showGlow,
          ),
          const SizedBox(width: 10),
          Icon(
            selected ? Icons.check_circle : visuals.icon,
            color: accentColor,
            size: 18,
          ),
          const SizedBox(width: 8),
          Text(
            visuals.label,
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

@Preview(name: 'Toolbar object preset menu', size: Size(140, 88))
Widget toolbarObjectPresetMenuPreview() {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    home: Scaffold(
      backgroundColor: const Color(0xFF1E293B),
      body: Center(
        child: ToolbarObjectPresetMenu(
          accentColor: const Color(0xFF38BDF8),
          secondaryColor: const Color(0xFF14B8A6),
          onSelected: (_) {},
        ),
      ),
    ),
  );
}
