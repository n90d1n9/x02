import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../models/component.dart';
import '../../models/enums.dart';
import '../../models/presentation_component.dart';
import '../../models/rich_text_content.dart';
import '../../models/sidebar_menu_item.dart';
import '../../states/alignment_guides_provider.dart';
import '../../states/component_provider.dart';
import '../../states/editor_view_provider.dart';
import '../../states/history_provider.dart';
import '../../states/presentation_provider.dart';
import '../../states/sidebar_panel_provider.dart';
import '../../states/transform_feedback_provider.dart';
import '../modern_resizable_component.dart';
import '../particle_background.dart';
import 'alignment_guides_overlay.dart';
import 'grid_painter.dart';
import 'slide_canvas_empty_state.dart';
import 'slide_selection_context_toolbar.dart';
import 'slide_selection_metrics_badge.dart';
import 'transform_feedback_badge.dart';

class SlideCanvas extends ConsumerStatefulWidget {
  const SlideCanvas({super.key});

  @override
  ConsumerState<SlideCanvas> createState() => _SlideCanvasState();
}

class _SlideCanvasState extends ConsumerState<SlideCanvas> {
  @override
  Widget build(BuildContext context) {
    final presentation = ref.watch(presentationProvider);
    final currentSlide = presentation.slides[presentation.currentSlideIndex];
    final isEmptySlide = currentSlide.components.isEmpty;
    final sortedComponents = List<PresentationComponent>.from(
      currentSlide.components.where((component) => component.isVisible),
    )..sort((a, b) => a.zIndex.compareTo(b.zIndex));
    final showGrid = ref.watch(showGridProvider);
    final gridPreset = ref.watch(canvasGridPresetProvider);
    final currentTool = ref.watch(currentToolProvider);
    final selectedId = ref.watch(selectedComponentProvider);
    final selectedComponent = _selectedVisibleComponent(
      sortedComponents,
      selectedId,
    );
    final zoom = ref.watch(zoomLevelProvider);
    final alignmentGuides = ref.watch(alignmentGuidesProvider);
    final transformFeedback = ref.watch(transformFeedbackProvider);

    return MouseRegion(
      onHover: (event) {
        ref.read(cursorPositionProvider.notifier).state = event.localPosition;
      },
      child: Container(
        width: presentation.slideSize.width,
        height: presentation.slideSize.height,
        decoration: BoxDecoration(
          color:
              currentSlide.backgroundColor ??
              presentation.theme.backgroundColor,
          image: currentSlide.backgroundImage != null
              ? DecorationImage(
                  image: MemoryImage(currentSlide.backgroundImage!),
                  fit: BoxFit.cover,
                )
              : null,
          gradient: currentSlide.backgroundGradient != null
              ? LinearGradient(
                  colors: currentSlide.backgroundGradient!.colors,
                  begin: currentSlide.backgroundGradient!.begin,
                  end: currentSlide.backgroundGradient!.end,
                )
              : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapDown: (details) {
                  final localPos = details.localPosition;
                  if (currentTool == ToolMode.text) {
                    _addTextBox(localPos);
                  } else {
                    ref.read(selectedComponentProvider.notifier).state = null;
                  }
                },
              ),
            ),
            if (currentSlide.backgroundParticles != null)
              ParticleBackground(effect: currentSlide.backgroundParticles!),
            if (showGrid) GridPainter(gridSize: gridPreset.spacing),
            if (isEmptySlide)
              SlideCanvasEmptyState(
                onAddTitle: _addTitlePlaceholder,
                onOpenTemplates: _openTemplates,
              ),
            ...sortedComponents.map(
              (c) => ModernResizableComponent(component: c),
            ),
            if (alignmentGuides.isNotEmpty)
              Positioned.fill(
                child: AlignmentGuidesOverlay(
                  guides: alignmentGuides,
                  slideSize: presentation.slideSize,
                ),
              ),
            if (transformFeedback != null)
              TransformFeedbackBadge(
                feedback: transformFeedback,
                slideSize: presentation.slideSize,
                zoom: zoom,
              ),
            if (selectedComponent != null)
              SlideSelectionContextToolbar(
                component: selectedComponent,
                slideSize: presentation.slideSize,
                zoom: zoom,
              ),
            if (selectedComponent != null)
              SlideSelectionMetricsBadge(
                component: selectedComponent,
                slideSize: presentation.slideSize,
                zoom: zoom,
              ),
          ],
        ),
      ),
    );
  }

  void _addTextBox(Offset position) {
    final presentation = ref.read(presentationProvider);
    _addRichText(
      text: 'Double click to edit',
      position: position,
      size: const Size(300, 100),
      style: presentation.theme.bodyStyle,
      alignment: TextAlign.left,
      label: 'Add text',
    );
  }

  void _addTitlePlaceholder() {
    final presentation = ref.read(presentationProvider);
    final slideSize = presentation.slideSize;
    const widthRatio = 0.7;
    final width = slideSize.width * widthRatio;
    final position = Offset(
      (slideSize.width - width) / 2,
      slideSize.height * 0.24,
    );

    _addRichText(
      text: 'Title',
      position: position,
      size: Size(width, 120),
      style: presentation.theme.titleStyle,
      alignment: TextAlign.center,
      label: 'Add title',
    );
  }

  void _addRichText({
    required String text,
    required Offset position,
    required Size size,
    required TextStyle style,
    required TextAlign alignment,
    required String label,
  }) {
    final richText = RichTextContent(
      text: text,
      style: style,
      alignment: alignment,
    );

    final component = PresentationComponent(
      id: const Uuid().v4(),
      type: ComponentType.richText,
      position: position,
      size: size,
      richText: richText,
      backgroundColor: Colors.transparent,
    );

    ref.read(historyProvider.notifier).recordPresentationMutation((notifier) {
      notifier.addComponent(component);
    }, label: label);
    ref.read(selectedComponentProvider.notifier).state = component.id;
    ref.read(currentToolProvider.notifier).state = ToolMode.select;
  }

  void _openTemplates() {
    ref.read(slideNavigatorVisibleProvider.notifier).state = true;
    ref.read(activeSidebarMenuProvider.notifier).state = SidebarMenuItem.design;
  }

  PresentationComponent? _selectedVisibleComponent(
    List<PresentationComponent> components,
    String? selectedId,
  ) {
    if (selectedId == null) return null;

    for (final component in components) {
      if (component.id == selectedId) return component;
    }

    return null;
  }
}
