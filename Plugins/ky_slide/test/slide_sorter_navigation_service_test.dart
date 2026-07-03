import 'package:flutter_test/flutter_test.dart';
import 'package:ky_slide/services/slide_sorter_navigation_service.dart';

void main() {
  test(
    'resolves linear previous and next navigation inside visible slides',
    () {
      final visibleIndexes = [0, 2, 4];

      expect(
        SlideSorterNavigationService.resolve(
          visibleIndexes: visibleIndexes,
          currentIndex: 2,
          intent: SlideSorterNavigationIntent.previous,
          crossAxisCount: 2,
        ),
        0,
      );
      expect(
        SlideSorterNavigationService.resolve(
          visibleIndexes: visibleIndexes,
          currentIndex: 2,
          intent: SlideSorterNavigationIntent.next,
          crossAxisCount: 2,
        ),
        4,
      );
    },
  );

  test('uses column count for row navigation', () {
    final visibleIndexes = [0, 1, 2, 3, 4, 5];

    expect(
      SlideSorterNavigationService.resolve(
        visibleIndexes: visibleIndexes,
        currentIndex: 1,
        intent: SlideSorterNavigationIntent.down,
        crossAxisCount: 3,
      ),
      4,
    );
    expect(
      SlideSorterNavigationService.resolve(
        visibleIndexes: visibleIndexes,
        currentIndex: 4,
        intent: SlideSorterNavigationIntent.up,
        crossAxisCount: 3,
      ),
      1,
    );
  });

  test('clamps navigation to visible slide bounds', () {
    final visibleIndexes = [2, 4, 6];

    expect(
      SlideSorterNavigationService.resolve(
        visibleIndexes: visibleIndexes,
        currentIndex: 2,
        intent: SlideSorterNavigationIntent.up,
        crossAxisCount: 4,
      ),
      2,
    );
    expect(
      SlideSorterNavigationService.resolve(
        visibleIndexes: visibleIndexes,
        currentIndex: 6,
        intent: SlideSorterNavigationIntent.down,
        crossAxisCount: 4,
      ),
      6,
    );
  });

  test(
    'falls back to first visible slide when current slide is filtered out',
    () {
      expect(
        SlideSorterNavigationService.resolve(
          visibleIndexes: const [3, 5],
          currentIndex: 1,
          intent: SlideSorterNavigationIntent.next,
          crossAxisCount: 2,
        ),
        3,
      );
    },
  );
}
