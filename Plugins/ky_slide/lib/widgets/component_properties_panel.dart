import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/presentation.dart';
import '../models/presentation_component.dart';
import '../services/object_style_preset_service.dart';
import '../states/component_property_actions_provider.dart';
import '../states/component_provider.dart';
import '../states/presentation_provider.dart';
import 'properties/component_property_summary_card.dart';
import 'properties/property_color_swatches.dart';
import 'properties/property_number_field.dart';
import 'properties/property_object_preset_grid.dart';
import 'properties/property_panel_header.dart';
import 'properties/property_section.dart';
import 'properties/property_slider_field.dart';
import 'properties/property_text_field.dart';
import 'properties/property_toggle_tile.dart';

/// Inspector panel for editing the selected component's frame and appearance.
class ComponentPropertiesPanel extends ConsumerWidget {
  static const ObjectStylePresetService _objectStylePresetService =
      ObjectStylePresetService();

  const ComponentPropertiesPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedId = ref.watch(selectedComponentProvider);
    final presentation = ref.watch(presentationProvider);
    final component = _selectedComponent(presentation, selectedId);

    if (component == null) {
      return const _NoComponentSelected();
    }

    final palette = _fillPalette(presentation.theme.colorPalette);
    final actions = ref.read(componentPropertyActionsProvider);
    final isLocked = component.isLocked;
    final selectedPreset = _objectStylePresetService.detectPreset(
      component: component,
      theme: presentation.theme,
    );

    return Container(
      color: const Color(0xFF1E293B),
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PropertyPanelHeader(
              icon: Icons.tune,
              title: 'Component Properties',
              subtitle: isLocked ? 'Locked layer' : 'Ready to edit',
              primaryColor: presentation.theme.primaryColor,
              secondaryColor: presentation.theme.secondaryColor,
            ),
            const SizedBox(height: 18),
            ComponentPropertySummaryCard(
              component: component,
              accentColor: presentation.theme.primaryColor,
            ),
            const SizedBox(height: 16),
            PropertySection(
              title: 'Layer',
              children: [
                PropertyTextField(
                  label: 'Layer name',
                  value: component.layerName ?? '',
                  onSubmitted: actions.renameSelectedLayer,
                ),
                const SizedBox(height: 12),
                PropertyToggleTile(
                  icon: component.isVisible
                      ? Icons.visibility
                      : Icons.visibility_off,
                  label: 'Visible',
                  description: 'Show this layer on the slide',
                  value: component.isVisible,
                  onChanged: actions.setSelectedVisibility,
                ),
                const SizedBox(height: 8),
                PropertyToggleTile(
                  icon: component.isLocked ? Icons.lock : Icons.lock_open,
                  label: 'Locked',
                  description: 'Prevent accidental frame and style edits',
                  value: component.isLocked,
                  onChanged: actions.setSelectedLocked,
                ),
              ],
            ),
            const SizedBox(height: 16),
            PropertySection(
              title: 'Frame',
              children: [
                Row(
                  children: [
                    Expanded(
                      child: PropertyNumberField(
                        label: 'X',
                        value: component.position.dx,
                        enabled: !isLocked,
                        onSubmitted: (value) {
                          actions.updateSelectedFrame(x: value);
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: PropertyNumberField(
                        label: 'Y',
                        value: component.position.dy,
                        enabled: !isLocked,
                        onSubmitted: (value) {
                          actions.updateSelectedFrame(y: value);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: PropertyNumberField(
                        label: 'W',
                        value: component.size.width,
                        enabled: !isLocked,
                        onSubmitted: (value) {
                          actions.updateSelectedFrame(width: value);
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: PropertyNumberField(
                        label: 'H',
                        value: component.size.height,
                        enabled: !isLocked,
                        onSubmitted: (value) {
                          actions.updateSelectedFrame(height: value);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                PropertyNumberField(
                  label: 'Rotation',
                  value: component.rotation,
                  enabled: !isLocked,
                  onSubmitted: (value) {
                    actions.updateSelectedFrame(rotation: value);
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            PropertySection(
              title: 'Appearance',
              children: [
                const Text(
                  'Presets',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                PropertyObjectPresetGrid(
                  accentColor: presentation.theme.primaryColor,
                  secondaryColor: presentation.theme.secondaryColor,
                  selectedPreset: selectedPreset,
                  enabled: !isLocked,
                  onSelected: actions.applySelectedObjectStylePreset,
                ),
                const SizedBox(height: 14),
                PropertySliderField(
                  label: 'Opacity',
                  value: component.opacity,
                  enabled: !isLocked,
                  valueLabelBuilder: (value) => '${(value * 100).round()}%',
                  onChangeEnd: actions.updateSelectedOpacity,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Fill',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                PropertyColorSwatches(
                  colors: palette,
                  selectedColor: component.backgroundColor,
                  enabled: !isLocked,
                  onSelected: actions.updateSelectedFillColor,
                ),
                const SizedBox(height: 14),
                const _AppearanceLabel('Border color'),
                const SizedBox(height: 8),
                PropertyColorSwatches(
                  colors: palette,
                  selectedColor: component.border?.color,
                  enabled: !isLocked,
                  onSelected: (color) {
                    actions.updateSelectedBorder(color: color);
                  },
                ),
                const SizedBox(height: 14),
                PropertySliderField(
                  label: 'Border width',
                  value: component.border?.width ?? 0,
                  max: 12,
                  divisions: 12,
                  enabled: !isLocked,
                  valueLabelBuilder: _borderWidthLabel,
                  onChangeEnd: (value) {
                    actions.updateSelectedBorder(width: value);
                  },
                ),
                const SizedBox(height: 12),
                PropertyToggleTile(
                  icon: component.hasGlow
                      ? Icons.auto_awesome
                      : Icons.auto_awesome_outlined,
                  label: 'Glow',
                  description: 'Add a soft highlight around this object',
                  value: component.hasGlow,
                  enabled: !isLocked,
                  onChanged: (enabled) {
                    actions.updateSelectedGlow(enabled: enabled);
                  },
                ),
                const SizedBox(height: 12),
                const _AppearanceLabel('Glow color'),
                const SizedBox(height: 8),
                PropertyColorSwatches(
                  colors: palette,
                  selectedColor:
                      component.glowColor ?? presentation.theme.primaryColor,
                  enabled: !isLocked && component.hasGlow,
                  onSelected: (color) {
                    actions.updateSelectedGlow(enabled: true, color: color);
                  },
                ),
                if (isLocked) ...[
                  const SizedBox(height: 12),
                  const _LockedHint(),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  PresentationComponent? _selectedComponent(
    Presentation presentation,
    String? selectedId,
  ) {
    if (selectedId == null) return null;

    final currentSlide = presentation.slides[presentation.currentSlideIndex];
    for (final component in currentSlide.components) {
      if (component.id == selectedId) return component;
    }

    return null;
  }

  List<Color> _fillPalette(List<Color> themePalette) {
    return [
      ...themePalette,
      const Color(0xFF0F172A),
      const Color(0xFFFFFFFF),
      const Color(0xFFF43F5E),
      const Color(0xFFF59E0B),
      const Color(0xFF10B981),
    ];
  }

  String _borderWidthLabel(double value) {
    if (value <= 0) return 'No border';
    return '${value.round()} px';
  }
}

/// Compact label used inside the component appearance inspector.
class _AppearanceLabel extends StatelessWidget {
  final String text;

  const _AppearanceLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: Colors.white70,
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

/// Locked-state hint for component frame and appearance controls.
class _LockedHint extends StatelessWidget {
  const _LockedHint();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFFF59E0B).withValues(alpha: 0.28),
        ),
      ),
      child: const Text(
        'Unlock the layer to edit frame and appearance.',
        style: TextStyle(color: Colors.white70, fontSize: 12),
      ),
    );
  }
}

/// Empty state shown when the inspector has no selected component.
class _NoComponentSelected extends StatelessWidget {
  const _NoComponentSelected();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF1E293B),
      padding: const EdgeInsets.all(16),
      child: const Center(
        child: Text(
          'Select a component to edit its properties.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white54, fontSize: 13),
        ),
      ),
    );
  }
}
