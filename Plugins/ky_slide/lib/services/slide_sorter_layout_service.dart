import '../models/slide_sorter_density.dart';

/// Resolved grid metrics for the slide board thumbnail layout.
class SlideSorterGridLayout {
  final int crossAxisCount;
  final double crossAxisSpacing;
  final double mainAxisSpacing;
  final double childAspectRatio;

  const SlideSorterGridLayout({
    required this.crossAxisCount,
    required this.crossAxisSpacing,
    required this.mainAxisSpacing,
    required this.childAspectRatio,
  });
}

/// Converts slide board density choices into stable responsive grid geometry.
class SlideSorterLayoutService {
  const SlideSorterLayoutService._();

  static SlideSorterGridLayout resolve({
    required double availableWidth,
    required SlideSorterDensity density,
  }) {
    final narrow = availableWidth < 560;
    final targetTileWidth = switch (density) {
      SlideSorterDensity.compact => narrow ? 154.0 : 176.0,
      SlideSorterDensity.balanced => narrow ? 178.0 : 218.0,
      SlideSorterDensity.roomy => narrow ? 220.0 : 268.0,
    };
    final maxColumns = switch (density) {
      SlideSorterDensity.compact => 8,
      SlideSorterDensity.balanced => 6,
      SlideSorterDensity.roomy => 4,
    };
    final spacing = switch (density) {
      SlideSorterDensity.compact => narrow ? 8.0 : 10.0,
      SlideSorterDensity.balanced => narrow ? 10.0 : 14.0,
      SlideSorterDensity.roomy => narrow ? 12.0 : 18.0,
    };
    final aspectRatio = switch (density) {
      SlideSorterDensity.compact => narrow ? 0.86 : 0.88,
      SlideSorterDensity.balanced => narrow ? 0.9 : 0.95,
      SlideSorterDensity.roomy => narrow ? 0.96 : 1.0,
    };

    final rawCount = (availableWidth / targetTileWidth).floor();
    final crossAxisCount = rawCount.clamp(1, maxColumns).toInt();

    return SlideSorterGridLayout(
      crossAxisCount: crossAxisCount,
      crossAxisSpacing: spacing,
      mainAxisSpacing: spacing,
      childAspectRatio: aspectRatio,
    );
  }
}
