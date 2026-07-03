/// Directional navigation intents supported by the slide board.
enum SlideSorterNavigationIntent { previous, next, up, down, first, last }

/// Resolves keyboard navigation in the slide board against visible slide order.
class SlideSorterNavigationService {
  const SlideSorterNavigationService._();

  static int? resolve({
    required List<int> visibleIndexes,
    required int currentIndex,
    required SlideSorterNavigationIntent intent,
    required int crossAxisCount,
  }) {
    if (visibleIndexes.isEmpty) return null;

    final currentPosition = visibleIndexes.indexOf(currentIndex);
    if (currentPosition < 0) return visibleIndexes.first;

    final rowStep = crossAxisCount.clamp(1, visibleIndexes.length);
    final targetPosition = switch (intent) {
      SlideSorterNavigationIntent.previous => currentPosition - 1,
      SlideSorterNavigationIntent.next => currentPosition + 1,
      SlideSorterNavigationIntent.up => currentPosition - rowStep,
      SlideSorterNavigationIntent.down => currentPosition + rowStep,
      SlideSorterNavigationIntent.first => 0,
      SlideSorterNavigationIntent.last => visibleIndexes.length - 1,
    };

    return visibleIndexes[targetPosition.clamp(0, visibleIndexes.length - 1)];
  }
}
