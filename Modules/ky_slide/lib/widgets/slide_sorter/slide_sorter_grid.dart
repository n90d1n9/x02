import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

import '../../models/component.dart';
import '../../models/presentation_component.dart';
import '../../models/slide.dart';
import '../../models/slide_sorter_density.dart';
import '../../models/style/presentation_theme.dart';
import '../../services/slide_sorter_layout_service.dart';
import 'slide_sorter_tile.dart';

/// Responsive storyboard grid for scanning and managing many slides at once.
class SlideSorterGrid extends StatelessWidget {
  final List<Slide> slides;
  final List<int> visibleIndexes;
  final int currentSlideIndex;
  final Set<String> selectedSlideIds;
  final PresentationTheme theme;
  final Size slideSize;
  final SlideSorterDensity density;
  final ValueChanged<int> onSelectSlide;
  final void Function(int index, bool extendRange) onToggleSlideSelection;
  final ValueChanged<int> onDuplicateSlide;
  final ValueChanged<int> onDeleteSlide;
  final void Function(int oldIndex, int newIndex) onMoveSlide;
  final ValueChanged<int>? onColumnCountChanged;
  final bool canDeleteSlides;

  const SlideSorterGrid({
    super.key,
    required this.slides,
    required this.visibleIndexes,
    required this.currentSlideIndex,
    required this.selectedSlideIds,
    required this.theme,
    required this.slideSize,
    this.density = SlideSorterDensity.balanced,
    required this.onSelectSlide,
    required this.onToggleSlideSelection,
    required this.onDuplicateSlide,
    required this.onDeleteSlide,
    required this.onMoveSlide,
    this.onColumnCountChanged,
    required this.canDeleteSlides,
  });

  @override
  Widget build(BuildContext context) {
    if (visibleIndexes.isEmpty) {
      return _SlideSorterEmptyState(accentColor: theme.primaryColor);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final layout = SlideSorterLayoutService.resolve(
          availableWidth: constraints.maxWidth,
          density: density,
        );
        final onColumnCountChanged = this.onColumnCountChanged;
        if (onColumnCountChanged != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            onColumnCountChanged(layout.crossAxisCount);
          });
        }

        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(18, 4, 18, 18),
          itemCount: visibleIndexes.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: layout.crossAxisCount,
            crossAxisSpacing: layout.crossAxisSpacing,
            mainAxisSpacing: layout.mainAxisSpacing,
            childAspectRatio: layout.childAspectRatio,
          ),
          itemBuilder: (context, resultIndex) {
            final index = visibleIndexes[resultIndex];
            final slide = slides[index];

            return _ReorderableSlideSorterTile(
              slide: slide,
              index: index,
              isSelected: index == currentSlideIndex,
              isBatchSelected: selectedSlideIds.contains(slide.id),
              theme: theme,
              slideSize: slideSize,
              canDelete: canDeleteSlides,
              canMoveEarlier: index > 0,
              canMoveLater: index < slides.length - 1,
              onSelect: () => onSelectSlide(index),
              onToggleSelection: (extendRange) =>
                  onToggleSlideSelection(index, extendRange),
              onDuplicate: () => onDuplicateSlide(index),
              onDelete: () => onDeleteSlide(index),
              onMoveEarlier: () => onMoveSlide(index, index - 1),
              onMoveLater: () => onMoveSlide(index, index + 1),
              onMoveSlide: onMoveSlide,
            );
          },
        );
      },
    );
  }
}

/// Drag/drop wrapper that lets slide board tiles reorder through existing actions.
class _ReorderableSlideSorterTile extends StatelessWidget {
  final Slide slide;
  final int index;
  final bool isSelected;
  final bool isBatchSelected;
  final PresentationTheme theme;
  final Size slideSize;
  final bool canDelete;
  final bool canMoveEarlier;
  final bool canMoveLater;
  final VoidCallback onSelect;
  final ValueChanged<bool> onToggleSelection;
  final VoidCallback onDuplicate;
  final VoidCallback onDelete;
  final VoidCallback? onMoveEarlier;
  final VoidCallback? onMoveLater;
  final void Function(int oldIndex, int newIndex) onMoveSlide;

  const _ReorderableSlideSorterTile({
    required this.slide,
    required this.index,
    required this.isSelected,
    required this.isBatchSelected,
    required this.theme,
    required this.slideSize,
    required this.canDelete,
    required this.canMoveEarlier,
    required this.canMoveLater,
    required this.onSelect,
    required this.onToggleSelection,
    required this.onDuplicate,
    required this.onDelete,
    required this.onMoveEarlier,
    required this.onMoveLater,
    required this.onMoveSlide,
  });

  @override
  Widget build(BuildContext context) {
    return DragTarget<int>(
      onWillAcceptWithDetails: (details) => details.data != index,
      onAcceptWithDetails: (details) => onMoveSlide(details.data, index),
      builder: (context, candidateData, rejectedData) {
        final isDropTarget = candidateData.isNotEmpty;

        return _SlideSorterDropFrame(
          highlighted: isDropTarget,
          accentColor: theme.secondaryColor,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final tile = _buildTile();

              return Draggable<int>(
                data: index,
                ignoringFeedbackSemantics: true,
                feedback: _SlideSorterDragFeedback(
                  width: constraints.maxWidth,
                  height: constraints.maxHeight,
                  child: _buildFeedbackTile(),
                ),
                childWhenDragging: Opacity(opacity: 0.42, child: tile),
                child: tile,
              );
            },
          ),
        );
      },
    );
  }

  SlideSorterTile _buildTile() {
    return SlideSorterTile(
      key: ValueKey('slide-sorter-${slide.id}'),
      slide: slide,
      index: index,
      isSelected: isSelected,
      isBatchSelected: isBatchSelected,
      theme: theme,
      slideSize: slideSize,
      canDelete: canDelete,
      canMoveEarlier: canMoveEarlier,
      canMoveLater: canMoveLater,
      onSelect: onSelect,
      onToggleSelection: onToggleSelection,
      onDuplicate: onDuplicate,
      onDelete: onDelete,
      onMoveEarlier: onMoveEarlier,
      onMoveLater: onMoveLater,
    );
  }

  SlideSorterTile _buildFeedbackTile() {
    return SlideSorterTile(
      slide: slide,
      index: index,
      isSelected: true,
      isBatchSelected: isBatchSelected,
      theme: theme,
      slideSize: slideSize,
      canDelete: canDelete,
      canMoveEarlier: canMoveEarlier,
      canMoveLater: canMoveLater,
      onSelect: () {},
      onToggleSelection: (_) {},
      onDuplicate: () {},
      onDelete: () {},
      onMoveEarlier: () {},
      onMoveLater: () {},
    );
  }
}

/// Stable visual frame that highlights the current drag target without layout jump.
class _SlideSorterDropFrame extends StatelessWidget {
  final Widget child;
  final bool highlighted;
  final Color accentColor;

  const _SlideSorterDropFrame({
    required this.child,
    required this.highlighted,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 140),
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(11),
        border: Border.all(
          color: highlighted
              ? accentColor.withValues(alpha: 0.92)
              : Colors.transparent,
          width: 2,
        ),
        boxShadow: [
          if (highlighted)
            BoxShadow(
              color: accentColor.withValues(alpha: 0.2),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
        ],
      ),
      child: child,
    );
  }
}

/// Floating tile preview shown while a slide is being dragged.
class _SlideSorterDragFeedback extends StatelessWidget {
  final double width;
  final double height;
  final Widget child;

  const _SlideSorterDragFeedback({
    required this.width,
    required this.height,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Opacity(
        opacity: 0.94,
        child: Transform.scale(
          scale: 0.98,
          child: SizedBox(width: width, height: height, child: child),
        ),
      ),
    );
  }
}

/// Empty result state for filtered slide board searches.
class _SlideSorterEmptyState extends StatelessWidget {
  final Color accentColor;

  const _SlideSorterEmptyState({required this.accentColor});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 260,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.045),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.manage_search, color: accentColor, size: 30),
            const SizedBox(height: 10),
            const Text(
              'No matching slides',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 5),
            const Text(
              'No titles, notes, or slide text matched.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white54,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

@Preview(name: 'Slide sorter grid', size: Size(760, 520))
Widget slideSorterGridPreview() {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    home: Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SlideSorterGrid(
        slides: _previewSlides(),
        visibleIndexes: const [0, 1, 2, 3],
        currentSlideIndex: 1,
        selectedSlideIds: const {'slide-2', 'slide-3'},
        theme: _previewTheme(),
        slideSize: const Size(1920, 1080),
        density: SlideSorterDensity.balanced,
        canDeleteSlides: true,
        onSelectSlide: (_) {},
        onToggleSlideSelection: (_, _) {},
        onDuplicateSlide: (_) {},
        onDeleteSlide: (_) {},
        onMoveSlide: (_, _) {},
      ),
    ),
  );
}

List<Slide> _previewSlides() {
  return [
    _previewSlide('slide-1', 'Opening', const Color(0xFF111827)),
    _previewSlide('slide-2', 'Audience need', const Color(0xFF0F766E)),
    _previewSlide('slide-3', 'Quarter plan', const Color(0xFF1D4ED8)),
    _previewSlide('slide-4', 'Close', const Color(0xFF4338CA)),
  ];
}

Slide _previewSlide(String id, String title, Color color) {
  return Slide(
    id: id,
    title: title,
    backgroundColor: color,
    components: [
      PresentationComponent(
        id: '$id-title',
        type: ComponentType.shape,
        position: const Offset(180, 160),
        size: const Size(780, 120),
        zIndex: 1,
        backgroundColor: Colors.white,
      ),
      PresentationComponent(
        id: '$id-accent',
        type: ComponentType.circle,
        position: const Offset(1160, 340),
        size: const Size(340, 340),
        zIndex: 2,
        backgroundColor: const Color(0xFF38BDF8),
      ),
    ],
  );
}

PresentationTheme _previewTheme() {
  return PresentationTheme(
    id: 'sorter-grid-preview-theme',
    name: 'Sorter Grid Preview',
    primaryColor: const Color(0xFF38BDF8),
    secondaryColor: const Color(0xFF14B8A6),
    backgroundColor: const Color(0xFF0F172A),
    textColor: Colors.white,
    titleStyle: const TextStyle(color: Colors.white, fontSize: 48),
    bodyStyle: const TextStyle(color: Colors.white70, fontSize: 20),
    colorPalette: const [Color(0xFF38BDF8), Color(0xFF14B8A6)],
  );
}
