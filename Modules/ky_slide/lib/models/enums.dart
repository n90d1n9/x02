// lib/models/enums.dart
enum ToolMode { select, text, image, shape, chart, video, audio, interactive }

enum ChartType { line, bar, pie, scatter, radar, gauge, funnel, heatmap }

enum VisualEffect {
  none,
  glassmorphism,
  neumorphism,
  shadow3D,
  glow,
  neon,
  gradient,
  blur,
  noise,
  grain,
  vignette,
}

extension VisualEffectExtension on VisualEffect {
  static VisualEffect? fromString(String? typeStr) {
    if (typeStr == null) return null;
    return VisualEffect.values.firstWhere(
      (e) => e.name == typeStr,
      orElse: () => VisualEffect.none,
    );
  }
}

enum InteractiveType { hotspot, poll, quiz, countdown, button, link, form }

enum ResizeHandle {
  topLeft,
  topRight,
  bottomLeft,
  bottomRight,
  top,
  bottom,
  left,
  right,
  rotate,
}
