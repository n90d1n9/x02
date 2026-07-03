import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/command_palette_action.dart';
import '../models/component.dart';
import '../models/presentation.dart';
import '../models/presentation_component.dart';
import '../models/slide.dart';
import '../models/sidebar_menu_item.dart';
import '../states/component_layer_actions_provider.dart';
import '../states/component_provider.dart';
import '../states/editor_view_provider.dart';
import '../states/history_provider.dart';
import '../states/sidebar_panel_provider.dart';
import '../states/slide_actions_provider.dart';

/// Builds editor command palette actions from current presentation state.
class PresentationCommandPaletteCatalog {
  final WidgetRef ref;
  final Presentation presentation;
  final VoidCallback onShowThemes;
  final VoidCallback onShowEffects;
  final VoidCallback onPresent;

  const PresentationCommandPaletteCatalog({
    required this.ref,
    required this.presentation,
    required this.onShowThemes,
    required this.onShowEffects,
    required this.onPresent,
  });

  List<CommandPaletteAction> actions() {
    final history = ref.watch(historyProvider);
    final showSpeakerNotes = ref.watch(speakerNotesVisibleProvider);
    final showSlideNavigator = ref.watch(slideNavigatorVisibleProvider);
    final showPropertiesPanel = ref.watch(propertiesPanelVisibleProvider);
    final selectedComponentId = ref.watch(selectedComponentProvider);
    final selectedComponent = _selectedComponent(selectedComponentId);

    return [
      CommandPaletteAction(
        id: 'open-slide-board',
        title: 'Open Slide Board',
        description: 'Organize, search, and batch edit slides',
        category: 'View',
        icon: Icons.view_module_outlined,
        keywords: const ['sorter', 'grid', 'slides', 'organize'],
        metadataLabels: const ['Overlay'],
        onInvoke: () {
          ref.read(slideSorterVisibleProvider.notifier).state = true;
        },
      ),
      CommandPaletteAction(
        id: 'toggle-speaker-notes',
        title: showSpeakerNotes ? 'Hide Speaker Notes' : 'Show Speaker Notes',
        description: 'Toggle the presenter notes pane',
        category: 'View',
        icon: Icons.speaker_notes_outlined,
        keywords: const ['notes', 'speaker', 'presenter'],
        metadataLabels: const ['Toggle'],
        onInvoke: () {
          ref.read(speakerNotesVisibleProvider.notifier).state =
              !showSpeakerNotes;
        },
      ),
      CommandPaletteAction(
        id: 'toggle-slide-navigator',
        title: showSlideNavigator
            ? 'Hide Slide Navigator'
            : 'Show Slide Navigator',
        description: 'Toggle the left slide workspace',
        category: 'View',
        icon: Icons.view_sidebar_outlined,
        keywords: const ['slides', 'left', 'sidebar', 'panel'],
        metadataLabels: const ['Toggle'],
        onInvoke: () {
          ref.read(slideNavigatorVisibleProvider.notifier).state =
              !showSlideNavigator;
        },
      ),
      CommandPaletteAction(
        id: 'toggle-inspector',
        title: showPropertiesPanel ? 'Hide Inspector' : 'Show Inspector',
        description: 'Toggle the right formatting inspector',
        category: 'View',
        icon: Icons.tune_outlined,
        keywords: const ['properties', 'format', 'right', 'sidebar'],
        metadataLabels: const ['Toggle'],
        onInvoke: () {
          ref.read(propertiesPanelVisibleProvider.notifier).state =
              !showPropertiesPanel;
        },
      ),
      CommandPaletteAction(
        id: 'open-files-panel',
        title: 'Open Import / Export',
        description: 'Show presentation file actions',
        category: 'Files',
        icon: Icons.folder_open_outlined,
        keywords: const ['ppt', 'pptx', 'import', 'export', 'files'],
        metadataLabels: const ['Panel', 'PPTX'],
        onInvoke: () => _openSidebarPanel(SidebarMenuItem.files),
      ),
      CommandPaletteAction(
        id: 'open-design-panel',
        title: 'Open Design Assist',
        description: 'Browse templates and deck styling aids',
        category: 'Design',
        icon: Icons.auto_awesome_outlined,
        keywords: const ['templates', 'design', 'theme', 'assist'],
        metadataLabels: const ['Panel'],
        onInvoke: () => _openSidebarPanel(SidebarMenuItem.design),
      ),
      CommandPaletteAction(
        id: 'open-outline-panel',
        title: 'Open Outline',
        description: 'Navigate deck structure by text',
        category: 'Slides',
        icon: Icons.subject_outlined,
        keywords: const ['outline', 'text', 'structure'],
        metadataLabels: const ['Panel'],
        onInvoke: () => _openSidebarPanel(SidebarMenuItem.outline),
      ),
      ..._slideActions(),
      CommandPaletteAction(
        id: 'open-layers-panel',
        title: 'Open Layers',
        description: 'Manage objects on the current slide',
        category: 'Objects',
        icon: Icons.layers_outlined,
        keywords: const ['objects', 'components', 'stack', 'order'],
        metadataLabels: const ['Panel'],
        onInvoke: () => _openSidebarPanel(SidebarMenuItem.layers),
      ),
      CommandPaletteAction(
        id: 'open-arrange-panel',
        title: 'Open Arrange Panel',
        description: 'Align, rotate, and layer selected objects',
        category: 'Objects',
        icon: Icons.center_focus_strong,
        keywords: const ['arrange', 'align', 'rotate', 'position', 'object'],
        metadataLabels: const ['Panel'],
        onInvoke: () => _openSidebarPanel(SidebarMenuItem.arrange),
      ),
      ..._selectedObjectActions(selectedComponent),
      CommandPaletteAction(
        id: 'open-history-panel',
        title: 'Open History',
        description: 'Review recent deck changes',
        category: 'Review',
        icon: Icons.history_outlined,
        keywords: const ['undo', 'redo', 'changes', 'timeline'],
        metadataLabels: const ['Panel'],
        onInvoke: () => _openSidebarPanel(SidebarMenuItem.history),
      ),
      CommandPaletteAction(
        id: 'undo',
        title: history.undoLabel == null ? 'Undo' : 'Undo ${history.undoLabel}',
        description: history.canUndo
            ? 'Revert the latest deck change'
            : 'No changes available to undo',
        category: 'Edit',
        icon: Icons.undo,
        keywords: const ['edit', 'history', 'reverse'],
        shortcutLabel: 'Cmd/Ctrl+Z',
        enabled: history.canUndo,
        onInvoke: () => ref.read(historyProvider.notifier).undo(),
      ),
      CommandPaletteAction(
        id: 'redo',
        title: history.redoLabel == null ? 'Redo' : 'Redo ${history.redoLabel}',
        description: history.canRedo
            ? 'Reapply the next deck change'
            : 'No changes available to redo',
        category: 'Edit',
        icon: Icons.redo,
        keywords: const ['edit', 'history', 'repeat'],
        shortcutLabel: 'Cmd/Ctrl+Shift+Z',
        enabled: history.canRedo,
        onInvoke: () => ref.read(historyProvider.notifier).redo(),
      ),
      CommandPaletteAction(
        id: 'choose-theme',
        title: 'Choose Theme',
        description: 'Open the presentation theme picker',
        category: 'Design',
        icon: Icons.palette_outlined,
        keywords: const ['theme', 'colors', 'style', 'palette'],
        metadataLabels: const ['Dialog'],
        onInvoke: onShowThemes,
      ),
      CommandPaletteAction(
        id: 'visual-effects',
        title: 'Apply Visual Effects',
        description: selectedComponent == null
            ? 'Select an object to apply effects'
            : 'Open effects for ${_componentLabel(selectedComponent)}',
        category: 'Design',
        icon: Icons.auto_awesome,
        keywords: const ['effects', 'glass', 'glow', 'neon', 'gradient'],
        metadataLabels: const ['Dialog'],
        enabled: selectedComponent != null,
        onInvoke: onShowEffects,
      ),
      CommandPaletteAction(
        id: 'start-presenting',
        title: 'Start Presenting',
        description: 'Open presenter mode',
        category: 'Present',
        icon: Icons.play_arrow_rounded,
        keywords: const ['present', 'slideshow', 'play', 'deck'],
        shortcutLabel: 'F5',
        onInvoke: onPresent,
      ),
    ];
  }

  List<CommandPaletteAction> _slideActions() {
    final slideCount = presentation.slides.length;
    if (slideCount == 0) return [_addBlankSlideAction()];

    final currentIndex = _currentSlideIndex();
    final currentSlide = presentation.slides[currentIndex];
    final slideLabel = _slideLabel(currentIndex, currentSlide);
    final slidePositionLabel = 'Slide ${currentIndex + 1}';
    final canDelete = slideCount > 1;
    final canMoveEarlier = currentIndex > 0;
    final canMoveLater = currentIndex < slideCount - 1;

    return [
      _addBlankSlideAction(),
      CommandPaletteAction(
        id: 'duplicate-current-slide',
        title: 'Duplicate Current Slide',
        description: 'Create a copy of $slideLabel',
        category: 'Slides',
        icon: Icons.copy_all_outlined,
        keywords: const ['duplicate', 'copy', 'current', 'slide'],
        metadataLabels: [slidePositionLabel],
        onInvoke: () => ref.read(slideActionsProvider).duplicateSlide(),
      ),
      CommandPaletteAction(
        id: 'delete-current-slide',
        title: 'Delete Current Slide',
        description: canDelete
            ? 'Remove $slideLabel from the deck'
            : 'A deck needs at least one slide',
        category: 'Slides',
        icon: Icons.delete_outline,
        keywords: const ['delete', 'remove', 'current', 'slide'],
        metadataLabels: [slidePositionLabel],
        enabled: canDelete,
        onInvoke: () => ref.read(slideActionsProvider).deleteSlide(),
      ),
      CommandPaletteAction(
        id: 'move-current-slide-earlier',
        title: 'Move Slide Earlier',
        description: canMoveEarlier
            ? 'Move $slideLabel before the previous slide'
            : '$slideLabel is already first',
        category: 'Slides',
        icon: Icons.arrow_upward_rounded,
        keywords: const [
          'move',
          'reorder',
          'earlier',
          'up',
          'current',
          'slide',
        ],
        metadataLabels: [slidePositionLabel],
        enabled: canMoveEarlier,
        onInvoke: () {
          ref
              .read(slideActionsProvider)
              .moveSlide(currentIndex, currentIndex - 1);
        },
      ),
      CommandPaletteAction(
        id: 'move-current-slide-later',
        title: 'Move Slide Later',
        description: canMoveLater
            ? 'Move $slideLabel after the next slide'
            : '$slideLabel is already last',
        category: 'Slides',
        icon: Icons.arrow_downward_rounded,
        keywords: const [
          'move',
          'reorder',
          'later',
          'down',
          'current',
          'slide',
        ],
        metadataLabels: [slidePositionLabel],
        enabled: canMoveLater,
        onInvoke: () {
          ref
              .read(slideActionsProvider)
              .moveSlide(currentIndex, currentIndex + 1);
        },
      ),
    ];
  }

  CommandPaletteAction _addBlankSlideAction() {
    return CommandPaletteAction(
      id: 'add-blank-slide',
      title: 'New Blank Slide',
      description: 'Append a blank slide to the deck',
      category: 'Slides',
      icon: Icons.add_to_photos_outlined,
      keywords: const ['new', 'add', 'create', 'blank', 'slide'],
      metadataLabels: const ['Blank'],
      onInvoke: () => ref.read(slideActionsProvider).addSlide(),
    );
  }

  List<CommandPaletteAction> _selectedObjectActions(
    PresentationComponent? selectedComponent,
  ) {
    final hasSelection = selectedComponent != null;
    final label = hasSelection
        ? _componentLabel(selectedComponent)
        : 'the selected object';
    final unavailableDescription = 'Select an object on the slide first';

    return [
      CommandPaletteAction(
        id: 'duplicate-selected-object',
        title: 'Duplicate Selected Object',
        description: hasSelection
            ? 'Create a copy of $label'
            : unavailableDescription,
        category: 'Object',
        icon: Icons.copy_all_outlined,
        keywords: const ['duplicate', 'copy', 'selected', 'object', 'layer'],
        shortcutLabel: 'Cmd/Ctrl+D',
        metadataLabels: const ['Selected'],
        enabled: hasSelection,
        onInvoke: () {
          ref.read(componentLayerActionsProvider).duplicateSelectedLayer();
        },
      ),
      CommandPaletteAction(
        id: 'delete-selected-object',
        title: 'Delete Selected Object',
        description: hasSelection
            ? 'Remove $label from the slide'
            : unavailableDescription,
        category: 'Object',
        icon: Icons.delete_outline,
        keywords: const ['delete', 'remove', 'selected', 'object', 'layer'],
        shortcutLabel: 'Delete',
        metadataLabels: const ['Selected'],
        enabled: hasSelection,
        onInvoke: () {
          ref.read(componentLayerActionsProvider).deleteSelectedLayer();
        },
      ),
      CommandPaletteAction(
        id: 'bring-selected-object-to-front',
        title: 'Bring Object to Front',
        description: hasSelection
            ? 'Move $label above other objects'
            : unavailableDescription,
        category: 'Object',
        icon: Icons.flip_to_front_outlined,
        keywords: const ['front', 'arrange', 'order', 'layer', 'object'],
        shortcutLabel: 'Cmd/Ctrl+Shift+]',
        metadataLabels: const ['Layer'],
        enabled: hasSelection,
        onInvoke: () {
          ref.read(componentLayerActionsProvider).bringSelectedLayerToFront();
        },
      ),
      CommandPaletteAction(
        id: 'send-selected-object-to-back',
        title: 'Send Object to Back',
        description: hasSelection
            ? 'Move $label behind other objects'
            : unavailableDescription,
        category: 'Object',
        icon: Icons.flip_to_back_outlined,
        keywords: const ['back', 'arrange', 'order', 'layer', 'object'],
        shortcutLabel: 'Cmd/Ctrl+Shift+[',
        metadataLabels: const ['Layer'],
        enabled: hasSelection,
        onInvoke: () {
          ref.read(componentLayerActionsProvider).sendSelectedLayerToBack();
        },
      ),
      CommandPaletteAction(
        id: 'toggle-selected-object-visibility',
        title: selectedComponent?.isVisible == false
            ? 'Show Selected Object'
            : 'Hide Selected Object',
        description: hasSelection
            ? 'Toggle visibility for $label'
            : unavailableDescription,
        category: 'Object',
        icon: selectedComponent?.isVisible == false
            ? Icons.visibility_outlined
            : Icons.visibility_off_outlined,
        keywords: const ['hide', 'show', 'visibility', 'object', 'layer'],
        metadataLabels: const ['Toggle'],
        enabled: hasSelection,
        onInvoke: () {
          if (selectedComponent == null) return;

          ref
              .read(componentLayerActionsProvider)
              .setLayerVisibility(
                selectedComponent.id,
                !selectedComponent.isVisible,
              );
        },
      ),
      CommandPaletteAction(
        id: 'toggle-selected-object-lock',
        title: selectedComponent?.isLocked == true
            ? 'Unlock Selected Object'
            : 'Lock Selected Object',
        description: hasSelection
            ? 'Toggle editing lock for $label'
            : unavailableDescription,
        category: 'Object',
        icon: selectedComponent?.isLocked == true
            ? Icons.lock_open_outlined
            : Icons.lock_outline,
        keywords: const ['lock', 'unlock', 'object', 'layer', 'selection'],
        metadataLabels: const ['Toggle'],
        enabled: hasSelection,
        onInvoke: () {
          if (selectedComponent == null) return;

          ref
              .read(componentLayerActionsProvider)
              .setLayerLocked(
                selectedComponent.id,
                !selectedComponent.isLocked,
              );
        },
      ),
    ];
  }

  int _currentSlideIndex() {
    if (presentation.slides.isEmpty) return 0;

    if (presentation.currentSlideIndex < 0) return 0;

    final lastIndex = presentation.slides.length - 1;
    if (presentation.currentSlideIndex > lastIndex) return lastIndex;

    return presentation.currentSlideIndex;
  }

  String _slideLabel(int index, Slide slide) {
    final title = slide.title?.trim();
    if (title == null || title.isEmpty) return 'slide ${index + 1}';

    return 'slide ${index + 1}: ${_truncate(title)}';
  }

  PresentationComponent? _selectedComponent(String? selectedComponentId) {
    if (selectedComponentId == null) return null;
    final slide = presentation.slides[presentation.currentSlideIndex];

    for (final component in slide.components) {
      if (component.id == selectedComponentId) return component;
    }

    return null;
  }

  String _componentLabel(PresentationComponent component) {
    final layerName = component.layerName?.trim();
    if (layerName != null && layerName.isNotEmpty) return layerName;

    final text = component.richText?.text.trim();
    if (text != null && text.isNotEmpty) return _truncate(text);

    return _componentTypeLabel(component.type);
  }

  String _truncate(String value) {
    const maxLength = 34;
    if (value.length <= maxLength) return value;

    return '${value.substring(0, maxLength - 3)}...';
  }

  String _componentTypeLabel(ComponentType type) {
    return switch (type) {
      ComponentType.richText => 'text box',
      ComponentType.image => 'image',
      ComponentType.shape => 'shape',
      ComponentType.circle => 'circle',
      ComponentType.triangle => 'triangle',
      ComponentType.chart => 'chart',
      ComponentType.video => 'video',
      ComponentType.audio => 'audio',
      ComponentType.diagram => 'diagram',
      ComponentType.icon => 'icon',
      ComponentType.gif => 'GIF',
      ComponentType.hotspot => 'hotspot',
      ComponentType.poll => 'poll',
      ComponentType.quiz => 'quiz',
      ComponentType.countdown => 'countdown',
      ComponentType.progressBar => 'progress bar',
      ComponentType.lottie => 'Lottie object',
      ComponentType.particles => 'particle effect',
      ComponentType.gradient => 'gradient object',
      ComponentType.unknown => 'object',
    };
  }

  void _openSidebarPanel(SidebarMenuItem item) {
    ref.read(slideNavigatorVisibleProvider.notifier).state = true;
    ref.read(activeSidebarMenuProvider.notifier).state = item;
  }
}
