import 'dart:ui';

import 'presentation.dart';

/// Derived presentation metadata used by compact editor chrome.
class EditorDeckInsight {
  final int slideCount;
  final int objectCount;
  final int notesSlideCount;
  final String themeName;
  final Size slideSize;

  const EditorDeckInsight({
    required this.slideCount,
    required this.objectCount,
    required this.notesSlideCount,
    required this.themeName,
    required this.slideSize,
  });

  factory EditorDeckInsight.fromPresentation(Presentation presentation) {
    return EditorDeckInsight(
      slideCount: presentation.slides.length,
      objectCount: presentation.slides.fold<int>(
        0,
        (count, slide) => count + slide.components.length,
      ),
      notesSlideCount: presentation.slides
          .where((slide) => slide.notes?.trim().isNotEmpty ?? false)
          .length,
      themeName: presentation.theme.name,
      slideSize: presentation.slideSize,
    );
  }

  String get slideLabel => _pluralize(slideCount, 'slide');

  String get objectLabel => _pluralize(objectCount, 'object');

  String get notesLabel {
    if (notesSlideCount == 0) return 'No notes';
    return _pluralize(notesSlideCount, 'note');
  }

  String get aspectRatioLabel => _aspectRatioLabel(slideSize);

  String get tooltipLabel {
    return '$slideLabel, $objectLabel, $notesLabel, '
        '$aspectRatioLabel canvas, $themeName theme';
  }

  static String _pluralize(int count, String noun) {
    return '$count $noun${count == 1 ? '' : 's'}';
  }

  static String _aspectRatioLabel(Size size) {
    final width = size.width.round().abs();
    final height = size.height.round().abs();
    if (width == 0 || height == 0) return 'Custom';

    final divisor = _greatestCommonDivisor(width, height);
    return '${width ~/ divisor}:${height ~/ divisor}';
  }

  static int _greatestCommonDivisor(int a, int b) {
    var left = a;
    var right = b;
    while (right != 0) {
      final remainder = left % right;
      left = right;
      right = remainder;
    }
    return left;
  }
}
