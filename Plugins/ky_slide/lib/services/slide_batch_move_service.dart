/// Direction for moving a batch of selected slides by one position.
enum SlideBatchMoveDirection { earlier, later }

/// One move operation to apply to the current slide list.
class SlideBatchMoveStep {
  final int oldIndex;
  final int newIndex;

  const SlideBatchMoveStep({required this.oldIndex, required this.newIndex});
}

/// Builds stable one-step move plans for selected slide batches.
class SlideBatchMoveService {
  const SlideBatchMoveService._();

  static List<SlideBatchMoveStep> steps({
    required Iterable<int> indexes,
    required int slideCount,
    required SlideBatchMoveDirection direction,
  }) {
    if (slideCount <= 1) return const [];

    final selected = indexes
        .where((index) => index >= 0 && index < slideCount)
        .toSet();
    if (selected.isEmpty) return const [];

    return switch (direction) {
      SlideBatchMoveDirection.earlier => _moveEarlier(
        selected: selected,
        slideCount: slideCount,
      ),
      SlideBatchMoveDirection.later => _moveLater(
        selected: selected,
        slideCount: slideCount,
      ),
    };
  }

  static bool canMove({
    required Iterable<int> indexes,
    required int slideCount,
    required SlideBatchMoveDirection direction,
  }) {
    return steps(
      indexes: indexes,
      slideCount: slideCount,
      direction: direction,
    ).isNotEmpty;
  }

  static List<SlideBatchMoveStep> _moveEarlier({
    required Set<int> selected,
    required int slideCount,
  }) {
    final steps = <SlideBatchMoveStep>[];
    for (var index = 0; index < slideCount; index++) {
      if (!selected.contains(index)) continue;
      if (index == 0 || selected.contains(index - 1)) continue;

      steps.add(SlideBatchMoveStep(oldIndex: index, newIndex: index - 1));
      selected
        ..remove(index)
        ..add(index - 1);
    }

    return steps;
  }

  static List<SlideBatchMoveStep> _moveLater({
    required Set<int> selected,
    required int slideCount,
  }) {
    final steps = <SlideBatchMoveStep>[];
    for (var index = slideCount - 1; index >= 0; index--) {
      if (!selected.contains(index)) continue;
      if (index == slideCount - 1 || selected.contains(index + 1)) continue;

      steps.add(SlideBatchMoveStep(oldIndex: index, newIndex: index + 1));
      selected
        ..remove(index)
        ..add(index + 1);
    }

    return steps;
  }
}
