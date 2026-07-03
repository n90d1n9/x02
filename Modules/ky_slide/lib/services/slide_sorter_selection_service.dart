import 'dart:math' as math;

import '../models/slide.dart';
import '../models/slide_sorter_selection.dart';

/// Pure selection utilities for Slide Board single and range selection.
class SlideSorterSelectionService {
  const SlideSorterSelectionService._();

  static SlideSorterSelection toggle({
    required List<Slide> slides,
    required SlideSorterSelection selection,
    required int index,
    List<int>? visibleIndexes,
    bool extendRange = false,
  }) {
    if (!_isValidIndex(index, slides.length)) return selection;

    final slideId = slides[index].id;
    if (!extendRange || selection.anchorSlideId == null) {
      final selected = Set<String>.from(selection.selectedSlideIds);
      if (!selected.add(slideId)) {
        selected.remove(slideId);
      }

      return SlideSorterSelection(
        selectedSlideIds: selected,
        anchorSlideId: slideId,
      );
    }

    final orderedIndexes = _visibleIndexes(
      slideCount: slides.length,
      visibleIndexes: visibleIndexes,
    );
    final anchorPosition = orderedIndexes.indexWhere(
      (visibleIndex) => slides[visibleIndex].id == selection.anchorSlideId,
    );
    final targetPosition = orderedIndexes.indexOf(index);
    if (anchorPosition == -1 || targetPosition == -1) {
      return toggle(slides: slides, selection: selection, index: index);
    }

    final selected = Set<String>.from(selection.selectedSlideIds);
    final start = math.min(anchorPosition, targetPosition);
    final end = math.max(anchorPosition, targetPosition);
    for (var position = start; position <= end; position++) {
      selected.add(slides[orderedIndexes[position]].id);
    }

    return selection.copyWith(selectedSlideIds: selected);
  }

  static SlideSorterSelection selectVisible({
    required List<Slide> slides,
    required SlideSorterSelection selection,
    required List<int> visibleIndexes,
  }) {
    final selected = Set<String>.from(selection.selectedSlideIds);
    String? lastSelectedSlideId;

    for (final index in visibleIndexes) {
      if (!_isValidIndex(index, slides.length)) continue;
      lastSelectedSlideId = slides[index].id;
      selected.add(lastSelectedSlideId);
    }

    return SlideSorterSelection(
      selectedSlideIds: selected,
      anchorSlideId: lastSelectedSlideId ?? selection.anchorSlideId,
    );
  }

  static SlideSorterSelection removeSlideId({
    required SlideSorterSelection selection,
    required String slideId,
  }) {
    final selected = Set<String>.from(selection.selectedSlideIds)
      ..remove(slideId);
    return SlideSorterSelection(
      selectedSlideIds: selected,
      anchorSlideId: selection.anchorSlideId == slideId
          ? null
          : selection.anchorSlideId,
    );
  }

  static List<int> selectedIndexes({
    required List<Slide> slides,
    required SlideSorterSelection selection,
  }) {
    return [
      for (var index = 0; index < slides.length; index++)
        if (selection.selectedSlideIds.contains(slides[index].id)) index,
    ];
  }

  static List<int> _visibleIndexes({
    required int slideCount,
    List<int>? visibleIndexes,
  }) {
    final indexes = visibleIndexes;
    if (indexes == null) {
      return [for (var index = 0; index < slideCount; index++) index];
    }

    return [
      for (final index in indexes)
        if (_isValidIndex(index, slideCount)) index,
    ];
  }

  static bool _isValidIndex(int index, int slideCount) {
    return index >= 0 && index < slideCount;
  }
}
