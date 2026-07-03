import 'package:flutter_test/flutter_test.dart';
import 'package:ky_slide/models/slide.dart';
import 'package:ky_slide/models/slide_sorter_selection.dart';
import 'package:ky_slide/services/slide_sorter_selection_service.dart';

void main() {
  test('toggle selects and deselects a slide while updating the anchor', () {
    final slides = _slides(3);
    var selection = SlideSorterSelection();

    selection = SlideSorterSelectionService.toggle(
      slides: slides,
      selection: selection,
      index: 1,
    );

    expect(selection.selectedSlideIds, {'slide-1'});
    expect(selection.anchorSlideId, 'slide-1');

    selection = SlideSorterSelectionService.toggle(
      slides: slides,
      selection: selection,
      index: 1,
    );

    expect(selection.selectedSlideIds, isEmpty);
    expect(selection.anchorSlideId, 'slide-1');
  });

  test('shift range selection follows visible slide order', () {
    final slides = _slides(6);
    var selection = SlideSorterSelection();

    selection = SlideSorterSelectionService.toggle(
      slides: slides,
      selection: selection,
      index: 0,
      visibleIndexes: const [0, 2, 4, 5],
    );
    selection = SlideSorterSelectionService.toggle(
      slides: slides,
      selection: selection,
      index: 4,
      visibleIndexes: const [0, 2, 4, 5],
      extendRange: true,
    );

    expect(selection.selectedSlideIds, {'slide-0', 'slide-2', 'slide-4'});
    expect(selection.anchorSlideId, 'slide-0');
  });

  test(
    'selection helpers ignore invalid indexes and clean removed anchors',
    () {
      final slides = _slides(3);
      var selection = SlideSorterSelection(selectedSlideIds: {'slide-1'});

      selection = SlideSorterSelectionService.selectVisible(
        slides: slides,
        selection: selection,
        visibleIndexes: const [2, 20],
      );

      expect(selection.selectedSlideIds, {'slide-1', 'slide-2'});
      expect(selection.anchorSlideId, 'slide-2');
      expect(
        SlideSorterSelectionService.selectedIndexes(
          slides: slides,
          selection: selection,
        ),
        [1, 2],
      );

      selection = SlideSorterSelectionService.removeSlideId(
        selection: selection,
        slideId: 'slide-2',
      );

      expect(selection.selectedSlideIds, {'slide-1'});
      expect(selection.anchorSlideId, isNull);
    },
  );
}

List<Slide> _slides(int count) {
  return [
    for (var index = 0; index < count; index++)
      Slide(id: 'slide-$index', title: 'Slide $index', components: const []),
  ];
}
