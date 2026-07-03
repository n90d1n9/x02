// lib/models/animation.dart
enum AnimationType {
  none,
  fadeIn,
  slideIn,
  slideRight,
  slideLeft,
  slideUp,
  slideDown,
  zoom,
  bounce,
  rotate,
  flip,
  elastic,
  morphing,
  glitch,
  typewriter,
  blur,
  scale,
  swing,
  pulse,
  shake,
  wobble,
  tada,
  flip3D,
}

extension AnimationTypeExtension on AnimationType {
  static AnimationType? fromString(String? typeStr) {
    if (typeStr == null) return null;
    return AnimationType.values.firstWhere(
      (e) => e.name == typeStr,
      orElse: () => AnimationType.none,
    );
  }
}
