import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/editor_slide_jump_summary.dart';
import '../../models/editor_slide_insight.dart';
import '../../models/presentation_component.dart';
import '../../services/editor_zoom_service.dart';
import '../../states/component_provider.dart';
import '../../states/editor_view_provider.dart';
import '../../states/presentation_provider.dart';
import 'editor_selection_geometry_chip.dart';
import 'editor_slide_insight_chip.dart';
import 'editor_status_bar_widgets.dart';
import 'editor_status_slide_navigator.dart';
import 'editor_status_view_switcher.dart';

/// Bottom editor rail for selection, view toggles, cursor, and zoom state.
class EditorStatusBar extends ConsumerWidget {
  const EditorStatusBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final presentation = ref.watch(presentationProvider);
    final currentSlide = presentation.slides[presentation.currentSlideIndex];
    final slideInsight = EditorSlideInsight.fromSlide(currentSlide);
    final selectedId = ref.watch(selectedComponentProvider);
    final cursorPosition = ref.watch(cursorPositionProvider);
    final zoom = ref.watch(zoomLevelProvider);
    final showRuler = ref.watch(rulerVisibilityProvider);
    final showGrid = ref.watch(showGridProvider);
    final snapToGrid = ref.watch(snapToGridProvider);
    final showNotes = ref.watch(speakerNotesVisibleProvider);
    final showSlideSorter = ref.watch(slideSorterVisibleProvider);
    final isPresenterMode = ref.watch(presenterModeProvider);
    final canvasViewportSize = ref.watch(canvasViewportSizeProvider);
    final selectedComponent = _selectedComponent(
      currentSlide.components,
      selectedId,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final showSlideInsight = constraints.maxWidth >= 1240;
        final compactSlideInsight = constraints.maxWidth < 1420;
        final showSelectionGeometry = constraints.maxWidth >= 980;
        final compactSelectionGeometry = constraints.maxWidth < 1240;
        final showCursor = constraints.maxWidth >= 1240;
        final showViewControls = constraints.maxWidth >= 1240;
        final showViewSwitcher = constraints.maxWidth >= 1460;
        final showZoomSlider = constraints.maxWidth >= 1240;

        return Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF0B1220),
            border: Border(
              top: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
            ),
          ),
          child: Row(
            children: [
              EditorStatusControlGroup(
                children: [
                  EditorStatusSlideNavigator(
                    currentSlideIndex: presentation.currentSlideIndex,
                    slideCount: presentation.slides.length,
                    slideTitles: [
                      for (var i = 0; i < presentation.slides.length; i++)
                        _slideTitle(presentation.slides[i].title, i),
                    ],
                    slideSummaries: [
                      for (var i = 0; i < presentation.slides.length; i++)
                        EditorSlideJumpSummary.fromSlide(
                          presentation.slides[i],
                          index: i,
                        ),
                    ],
                    onPrevious: () {
                      ref.read(presentationProvider.notifier).previousSlide();
                    },
                    onNext: () {
                      ref.read(presentationProvider.notifier).nextSlide();
                    },
                    onSlideSelected: (index) {
                      ref
                          .read(presentationProvider.notifier)
                          .setCurrentSlide(index);
                    },
                  ),
                ],
              ),
              if (showSlideInsight) ...[
                const EditorStatusDivider(),
                EditorSlideInsightChip(
                  insight: slideInsight,
                  accentColor: presentation.theme.primaryColor,
                  compact: compactSlideInsight,
                ),
              ],
              const EditorStatusDivider(),
              Expanded(
                child: EditorStatusText(_selectionLabel(selectedComponent)),
              ),
              if (selectedComponent != null && showSelectionGeometry) ...[
                const SizedBox(width: 10),
                EditorSelectionGeometryChip(
                  component: selectedComponent,
                  accentColor: presentation.theme.secondaryColor,
                  compact: compactSelectionGeometry,
                ),
                const SizedBox(width: 12),
              ],
              if (showCursor) ...[
                EditorStatusText(
                  'X ${cursorPosition.dx.round()}  Y ${cursorPosition.dy.round()}',
                ),
                const SizedBox(width: 12),
              ],
              if (showViewControls) ...[
                EditorStatusControlGroup(
                  children: [
                    EditorStatusToggleButton(
                      tooltip: 'Toggle ruler',
                      icon: Icons.straighten,
                      isActive: showRuler,
                      onPressed: () {
                        ref.read(rulerVisibilityProvider.notifier).state =
                            !showRuler;
                      },
                    ),
                    EditorStatusToggleButton(
                      tooltip: 'Toggle grid',
                      icon: Icons.grid_on,
                      isActive: showGrid,
                      onPressed: () {
                        ref.read(showGridProvider.notifier).state = !showGrid;
                      },
                    ),
                    EditorStatusToggleButton(
                      tooltip: 'Toggle snap to grid',
                      icon: Icons.center_focus_strong,
                      isActive: snapToGrid,
                      onPressed: () {
                        ref.read(snapToGridProvider.notifier).state =
                            !snapToGrid;
                      },
                    ),
                    EditorStatusToggleButton(
                      tooltip: 'Toggle notes pane',
                      icon: Icons.speaker_notes,
                      isActive: showNotes,
                      onPressed: () {
                        ref.read(speakerNotesVisibleProvider.notifier).state =
                            !showNotes;
                      },
                    ),
                  ],
                ),
                const SizedBox(width: 8),
              ],
              if (showViewSwitcher) ...[
                EditorStatusControlGroup(
                  children: [
                    EditorStatusViewSwitcher(
                      activeMode: _activeViewMode(
                        slideSorterVisible: showSlideSorter,
                        presenterMode: isPresenterMode,
                      ),
                      onEditSelected: () => _showEditingView(ref),
                      onSlideBoardSelected: () => _showSlideBoard(ref),
                      onPresentSelected: () => _showPresenter(ref),
                    ),
                  ],
                ),
                const SizedBox(width: 8),
              ],
              EditorStatusControlGroup(
                children: [
                  EditorZoomButton(
                    tooltip: 'Zoom out',
                    icon: Icons.remove,
                    onPressed: () => _setZoom(ref, zoom - 0.1),
                  ),
                  EditorZoomPresetMenu(
                    zoom: zoom,
                    onZoomSelected: (value) => _setZoom(ref, value),
                    onFitToWindow: () {
                      _fitToWindow(
                        ref,
                        presentation.slideSize,
                        canvasViewportSize,
                      );
                    },
                  ),
                  if (showZoomSlider)
                    EditorZoomSlider(
                      zoom: zoom,
                      onChanged: (value) => _setZoom(ref, value),
                    ),
                  EditorZoomButton(
                    tooltip: 'Zoom in',
                    icon: Icons.add,
                    onPressed: () => _setZoom(ref, zoom + 0.1),
                  ),
                  EditorZoomButton(
                    tooltip: 'Fit to window',
                    icon: Icons.fit_screen,
                    onPressed: () {
                      _fitToWindow(
                        ref,
                        presentation.slideSize,
                        canvasViewportSize,
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  PresentationComponent? _selectedComponent(
    List<PresentationComponent> components,
    String? selectedId,
  ) {
    if (selectedId == null) return null;

    for (final component in components) {
      if (component.id == selectedId) return component;
    }

    return null;
  }

  String _selectionLabel(PresentationComponent? component) {
    if (component == null) return 'No selection';

    final layerName = component.layerName?.trim();
    if (layerName != null && layerName.isNotEmpty) {
      return 'Selected: $layerName';
    }

    return 'Selected: ${component.type.name}';
  }

  String _slideTitle(String? title, int index) {
    final trimmedTitle = title?.trim();
    if (trimmedTitle == null || trimmedTitle.isEmpty) {
      return 'Slide ${index + 1}';
    }

    return trimmedTitle;
  }

  EditorStatusViewMode _activeViewMode({
    required bool slideSorterVisible,
    required bool presenterMode,
  }) {
    if (presenterMode) return EditorStatusViewMode.present;
    if (slideSorterVisible) return EditorStatusViewMode.slideBoard;
    return EditorStatusViewMode.edit;
  }

  void _showEditingView(WidgetRef ref) {
    ref.read(slideSorterVisibleProvider.notifier).state = false;
    ref.read(presenterModeProvider.notifier).state = false;
  }

  void _showSlideBoard(WidgetRef ref) {
    ref.read(presenterModeProvider.notifier).state = false;
    ref.read(slideSorterVisibleProvider.notifier).state = true;
  }

  void _showPresenter(WidgetRef ref) {
    ref.read(slideSorterVisibleProvider.notifier).state = false;
    ref.read(presenterModeProvider.notifier).state = true;
  }

  void _setZoom(WidgetRef ref, double zoom) {
    ref.read(zoomLevelProvider.notifier).state = EditorZoomService.clamp(zoom);
  }

  void _fitToWindow(WidgetRef ref, Size slideSize, Size viewportSize) {
    _setZoom(
      ref,
      EditorZoomService.fitToWindow(
        slideSize: slideSize,
        viewportSize: viewportSize,
      ),
    );
  }
}
