import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/slide_transition_type.dart';
import '../states/presentation_provider.dart';
import '../states/slide_property_actions_provider.dart';
import 'properties/property_action_button.dart';
import 'properties/property_color_swatches.dart';
import 'properties/property_multiline_field.dart';
import 'properties/property_panel_header.dart';
import 'properties/property_section.dart';
import 'properties/property_select_field.dart';
import 'properties/property_text_field.dart';
import 'properties/slide_property_summary_card.dart';

class SlidePropertiesPanel extends ConsumerWidget {
  const SlidePropertiesPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final presentation = ref.watch(presentationProvider);
    final currentSlide = presentation.slides[presentation.currentSlideIndex];
    final actions = ref.read(slidePropertyActionsProvider);
    final palette = _backgroundPalette(presentation.theme.colorPalette);

    return Container(
      color: const Color(0xFF1E293B),
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PropertyPanelHeader(
              icon: Icons.slideshow,
              title: 'Slide Properties',
              subtitle:
                  'Slide ${presentation.currentSlideIndex + 1} of ${presentation.slides.length}',
              primaryColor: presentation.theme.primaryColor,
              secondaryColor: presentation.theme.secondaryColor,
            ),
            const SizedBox(height: 18),
            SlidePropertySummaryCard(
              presentation: presentation,
              slide: currentSlide,
            ),
            const SizedBox(height: 16),
            PropertySection(
              title: 'Slide',
              children: [
                PropertyTextField(
                  label: 'Slide title',
                  value: currentSlide.title ?? '',
                  onSubmitted: actions.renameCurrentSlide,
                ),
              ],
            ),
            const SizedBox(height: 16),
            PropertySection(
              title: 'Speaker Notes',
              children: [
                PropertyMultilineField(
                  label: 'Notes',
                  value: currentSlide.notes ?? '',
                  onSubmitted: actions.updateSpeakerNotes,
                ),
              ],
            ),
            const SizedBox(height: 16),
            PropertySection(
              title: 'Background',
              children: [
                PropertyColorSwatches(
                  colors: palette,
                  selectedColor: currentSlide.backgroundColor,
                  onSelected: actions.updateBackgroundColor,
                ),
                const SizedBox(height: 12),
                PropertyActionButton(
                  icon: Icons.format_color_reset,
                  label: 'Use theme background',
                  tooltip: 'Clear slide-specific background color',
                  enabled: currentSlide.backgroundColor != null,
                  onPressed: () {
                    actions.updateBackgroundColor(null);
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            PropertySection(
              title: 'Background Effects',
              children: [
                Row(
                  children: [
                    Expanded(
                      child: PropertyActionButton(
                        icon: Icons.gradient,
                        label: currentSlide.backgroundGradient == null
                            ? 'Apply gradient'
                            : 'Refresh gradient',
                        onPressed: actions.applyBackgroundGradient,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: PropertyActionButton(
                        icon: Icons.layers_clear,
                        label: 'Remove',
                        enabled: currentSlide.backgroundGradient != null,
                        onPressed: actions.clearBackgroundGradient,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: PropertyActionButton(
                        icon: Icons.blur_on,
                        label: currentSlide.backgroundParticles == null
                            ? 'Add particles'
                            : 'Refresh particles',
                        onPressed: actions.applyBackgroundParticles,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: PropertyActionButton(
                        icon: Icons.hide_source,
                        label: 'Remove',
                        enabled: currentSlide.backgroundParticles != null,
                        onPressed: actions.clearBackgroundParticles,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            PropertySection(
              title: 'Playback',
              children: [
                PropertySelectField<SlideTransitionType>(
                  label: 'Transition',
                  value: currentSlide.transition,
                  options: SlideTransitionType.values,
                  labelBuilder: _transitionLabel,
                  onChanged: actions.updateTransition,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<Color> _backgroundPalette(List<Color> themePalette) {
    final colors = [
      ...themePalette,
      const Color(0xFF0F172A),
      const Color(0xFFFFFFFF),
      const Color(0xFFF43F5E),
      const Color(0xFFF59E0B),
      const Color(0xFF10B981),
      const Color(0xFF6366F1),
    ];

    return colors.toSet().toList();
  }

  String _transitionLabel(SlideTransitionType transition) {
    final words = transition.name.replaceAllMapped(
      RegExp(r'([a-z])([A-Z0-9])'),
      (match) => '${match.group(1)} ${match.group(2)}',
    );

    return words[0].toUpperCase() + words.substring(1);
  }
}
