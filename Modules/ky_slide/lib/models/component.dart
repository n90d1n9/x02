// lib/models/component.dart
enum ComponentType {
  richText,
  image,
  shape,
  circle,
  triangle,
  chart,
  video,
  audio,
  diagram,
  icon,
  gif,
  hotspot,
  poll,
  quiz,
  countdown,
  progressBar,
  lottie,
  particles,
  gradient,
  unknown, // Added unknown type for fallback
}

extension ComponentTypeExtension on ComponentType {
  static ComponentType? fromString(String? typeStr) {
    if (typeStr == null) return null;
    return ComponentType.values.firstWhere(
      (e) => e.name == typeStr,
      orElse: () => ComponentType.unknown,
    );
  }
}
