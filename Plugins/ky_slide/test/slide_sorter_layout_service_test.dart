import 'package:flutter_test/flutter_test.dart';
import 'package:ky_slide/models/slide_sorter_density.dart';
import 'package:ky_slide/services/slide_sorter_layout_service.dart';

void main() {
  test('compact density shows more slide columns than balanced density', () {
    final compact = SlideSorterLayoutService.resolve(
      availableWidth: 760,
      density: SlideSorterDensity.compact,
    );
    final balanced = SlideSorterLayoutService.resolve(
      availableWidth: 760,
      density: SlideSorterDensity.balanced,
    );

    expect(compact.crossAxisCount, greaterThan(balanced.crossAxisCount));
    expect(compact.crossAxisSpacing, lessThan(balanced.crossAxisSpacing));
  });

  test('roomy density keeps a larger slide preview layout', () {
    final balanced = SlideSorterLayoutService.resolve(
      availableWidth: 1040,
      density: SlideSorterDensity.balanced,
    );
    final roomy = SlideSorterLayoutService.resolve(
      availableWidth: 1040,
      density: SlideSorterDensity.roomy,
    );

    expect(roomy.crossAxisCount, lessThanOrEqualTo(balanced.crossAxisCount));
    expect(roomy.childAspectRatio, greaterThan(balanced.childAspectRatio));
  });

  test(
    'density layout always keeps at least one column on narrow surfaces',
    () {
      final layout = SlideSorterLayoutService.resolve(
        availableWidth: 180,
        density: SlideSorterDensity.roomy,
      );

      expect(layout.crossAxisCount, 1);
    },
  );
}
