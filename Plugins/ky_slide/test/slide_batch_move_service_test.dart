import 'package:flutter_test/flutter_test.dart';
import 'package:ky_slide/services/slide_batch_move_service.dart';

void main() {
  test('moves a selected contiguous block earlier by one position', () {
    final steps = SlideBatchMoveService.steps(
      indexes: const [2, 3],
      slideCount: 5,
      direction: SlideBatchMoveDirection.earlier,
    );

    expect(steps.map((step) => (step.oldIndex, step.newIndex)), [
      (2, 1),
      (3, 2),
    ]);
  });

  test('moves a selected contiguous block later by one position', () {
    final steps = SlideBatchMoveService.steps(
      indexes: const [1, 2],
      slideCount: 5,
      direction: SlideBatchMoveDirection.later,
    );

    expect(steps.map((step) => (step.oldIndex, step.newIndex)), [
      (2, 3),
      (1, 2),
    ]);
  });

  test('moves only selected blocks that can leave an edge', () {
    final steps = SlideBatchMoveService.steps(
      indexes: const [0, 2],
      slideCount: 4,
      direction: SlideBatchMoveDirection.earlier,
    );

    expect(steps.map((step) => (step.oldIndex, step.newIndex)), [(2, 1)]);
  });

  test('returns no steps when the selected block is pinned to an edge', () {
    expect(
      SlideBatchMoveService.canMove(
        indexes: const [0, 1],
        slideCount: 4,
        direction: SlideBatchMoveDirection.earlier,
      ),
      isFalse,
    );
    expect(
      SlideBatchMoveService.canMove(
        indexes: const [2, 3],
        slideCount: 4,
        direction: SlideBatchMoveDirection.later,
      ),
      isFalse,
    );
  });
}
