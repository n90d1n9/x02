// lib/models/slide_transition_type.dart
enum SlideTransitionType {
  none,
  fade,
  slide,
  zoom,
  cube,
  flip,
  dissolve,
  push,
  cover,
  reveal,
  swap,
  glitch,
  morphing,
  ripple,
  page,
  rotate3D,
}

extension SlideTransitionTypeExtension on SlideTransitionType {
  static SlideTransitionType? fromString(String? typeStr) {
    if (typeStr == null) return null;
    return SlideTransitionType.values.firstWhere(
      (e) => e.name == typeStr,
      orElse: () => SlideTransitionType.none,
    );
  }
}
