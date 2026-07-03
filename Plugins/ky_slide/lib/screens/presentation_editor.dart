import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/enums.dart';
import '../models/presentation_component.dart';
import '../models/style/glasmorphism_style.dart';
import '../models/style/gradient_animation.dart';
import '../models/style/neumorphism_style.dart';
import '../models/style/presentation_theme.dart';
import '../states/component_provider.dart';
import '../states/editor_view_provider.dart';
import '../states/history_provider.dart';
import '../states/presentation_provider.dart';
import '../widgets/canvas/slide_canvas_area.dart';
import '../widgets/dialogs/theme_picker_dialog.dart';
import '../widgets/dialogs/visual_effects_dialog.dart';
import '../widgets/editor/editor_top_bar.dart';
import '../widgets/editor/editor_status_bar.dart';
import '../widgets/editor/editor_workspace_shell.dart';
import '../widgets/editor/presentation_keyboard_shortcuts.dart';
import '../widgets/editor/presentation_command_palette_overlay.dart';
import '../widgets/editor/speaker_notes_pane.dart';
import '../widgets/properties_panel.dart';
import '../widgets/slide_panel.dart';
import '../widgets/slide_sorter/slide_sorter_overlay.dart';
import '../widgets/toolbar/modern_toolbar.dart';
import 'presenter_view.dart';

/// Main presentation editor shell for chrome, panels, canvas, and dialogs.
class PresentationEditor extends ConsumerWidget {
  const PresentationEditor({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPresenterMode = ref.watch(presenterModeProvider);
    final showSpeakerNotes = ref.watch(speakerNotesVisibleProvider);
    final showSlideNavigator = ref.watch(slideNavigatorVisibleProvider);
    final showPropertiesPanel = ref.watch(propertiesPanelVisibleProvider);
    final showSlideSorter = ref.watch(slideSorterVisibleProvider);
    final showCommandPalette = ref.watch(commandPaletteVisibleProvider);

    if (isPresenterMode) {
      return const PresenterView();
    }

    return PresentationKeyboardShortcuts(
      child: Scaffold(
        backgroundColor: const Color(0xFF0F172A),
        appBar: EditorTopBar(
          onOpenCommandPalette: () {
            ref.read(commandPaletteVisibleProvider.notifier).state = true;
          },
          onShowThemes: () => _showThemeDialog(context, ref),
          onShowEffects: () => _showEffectsDialog(context, ref),
          onPresent: () {
            ref.read(presenterModeProvider.notifier).state = true;
          },
        ),
        body: Stack(
          children: [
            EditorWorkspaceShell(
              showSlideNavigator: showSlideNavigator,
              showPropertiesPanel: showPropertiesPanel,
              showSpeakerNotes: showSpeakerNotes,
              slideNavigator: const SlidePanel(),
              toolbar: const ModernToolbar(),
              canvasArea: const SlideCanvasArea(),
              speakerNotes: const SpeakerNotesPane(),
              statusBar: const EditorStatusBar(),
              propertiesPanel: const PropertiesPanel(),
            ),
            if (showSlideSorter)
              const Positioned.fill(child: SlideSorterOverlay()),
            if (showCommandPalette)
              PresentationCommandPaletteOverlay(
                onShowThemes: () => _showThemeDialog(context, ref),
                onShowEffects: () => _showEffectsDialog(context, ref),
                onPresent: () {
                  ref.read(presenterModeProvider.notifier).state = true;
                },
              ),
          ],
        ),
      ),
    );
  }

  void _showThemeDialog(BuildContext context, WidgetRef ref) {
    final presentation = ref.read(presentationProvider);

    showDialog(
      context: context,
      builder: (dialogContext) => ThemePickerDialog(
        themes: PresentationTheme.allThemes,
        selectedThemeId: presentation.theme.id,
        accentColor: presentation.theme.primaryColor,
        onThemeSelected: (theme) {
          ref.read(presentationProvider.notifier).applyTheme(theme);
          ref
              .read(historyProvider.notifier)
              .addState(ref.read(presentationProvider));
          Navigator.pop(dialogContext);
        },
      ),
    );
  }

  void _showEffectsDialog(BuildContext context, WidgetRef ref) {
    final selected = ref.read(selectedComponentProvider);
    if (selected == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Select a component first')));
      return;
    }

    showDialog(
      context: context,
      builder: (dialogContext) {
        final presentation = ref.read(presentationProvider);

        return VisualEffectsDialog(
          accentColor: presentation.theme.primaryColor,
          onEffectSelected: (effect) =>
              _applyEffect(ref, selected, effect, dialogContext),
        );
      },
    );
  }

  void _applyEffect(
    WidgetRef ref,
    String componentId,
    VisualEffect effect,
    BuildContext context,
  ) {
    final presentation = ref.read(presentationProvider);
    final component = presentation
        .slides[presentation.currentSlideIndex]
        .components
        .firstWhere((c) => c.id == componentId);

    PresentationComponent updated = component.copyWith(visualEffect: effect);

    switch (effect) {
      case VisualEffect.glassmorphism:
        updated = updated.copyWith(
          glassStyle: GlassmorphismStyle(
            blur: 10,
            opacity: 0.2,
            tintColor: Colors.white,
          ),
        );
        break;
      case VisualEffect.neumorphism:
        updated = updated.copyWith(
          neumoStyle: NeumorphismStyle(
            baseColor: component.backgroundColor ?? Colors.grey[300]!,
            depth: 10,
          ),
        );
        break;
      case VisualEffect.glow:
        updated = updated.copyWith(
          hasGlow: true,
          glowColor: presentation.theme.primaryColor,
        );
        break;
      case VisualEffect.neon:
        updated = updated.copyWith(
          hasGlow: true,
          glowColor: presentation.theme.primaryColor,
        );
        break;
      case VisualEffect.gradient:
        updated = updated.copyWith(
          gradientAnim: GradientAnimation(
            colors: presentation.theme.colorPalette.take(3).toList(),
            duration: 3.0,
          ),
        );
        break;
      default:
        break;
    }

    ref
        .read(presentationProvider.notifier)
        .updateComponent(componentId, updated);
    ref.read(historyProvider.notifier).addState(ref.read(presentationProvider));
    Navigator.pop(context);
  }
}
