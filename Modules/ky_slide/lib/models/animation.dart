// lib/models/animation.dart
import 'dart:convert';

/// Animation effect types - similar to PowerPoint animations
enum AnimationEffect {
  // Entrance effects
  fadeIn,
  flyInFromLeft,
  flyInFromRight,
  flyInFromTop,
  flyInFromBottom,
  zoomIn,
  bounceIn,
  
  // Emphasis effects
  pulse,
  spin,
  wobble,
  growShrink,
  colorPulse,
  
  // Exit effects
  fadeOut,
  flyOutToLeft,
  flyOutToRight,
  flyOutToTop,
  flyOutToBottom,
  zoomOut,
  bounceOut,
  
  // Motion paths
  motionPathLine,
  motionPathArc,
  motionPathLoop,
}

/// Animation trigger types
enum AnimationTrigger {
  onClick,
  withPrevious,
  afterPrevious,
}

/// Easing functions for smooth animations
enum Easing {
  linear,
  easeIn,
  easeOut,
  easeInOut,
  bounce,
  elastic,
}

/// Legacy AnimationType enum (kept for backward compatibility)
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

/// Represents an animation applied to a specific element/component
class ElementAnimation {
  final String id;
  final String targetId;
  final AnimationEffect effect;
  final AnimationTrigger trigger;
  final Duration delay;
  final Duration duration;
  final Easing easing;

  ElementAnimation({
    required this.id,
    required this.targetId,
    required this.effect,
    this.trigger = AnimationTrigger.onClick,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 500),
    this.easing = Easing.easeInOut,
  });

  ElementAnimation copyWith({
    String? id,
    String? targetId,
    AnimationEffect? effect,
    AnimationTrigger? trigger,
    Duration? delay,
    Duration? duration,
    Easing? easing,
  }) {
    return ElementAnimation(
      id: id ?? this.id,
      targetId: targetId ?? this.targetId,
      effect: effect ?? this.effect,
      trigger: trigger ?? this.trigger,
      delay: delay ?? this.delay,
      duration: duration ?? this.duration,
      easing: easing ?? this.easing,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'targetId': targetId,
      'effect': effect.name,
      'trigger': trigger.name,
      'delayMs': delay.inMilliseconds,
      'durationMs': duration.inMilliseconds,
      'easing': easing.name,
    };
  }

  factory ElementAnimation.fromJson(Map<String, dynamic> json) {
    return ElementAnimation(
      id: json['id'] as String,
      targetId: json['targetId'] as String,
      effect: AnimationEffect.values.firstWhere(
        (e) => e.name == json['effect'],
        orElse: () => AnimationEffect.fadeIn,
      ),
      trigger: AnimationTrigger.values.firstWhere(
        (e) => e.name == json['trigger'],
        orElse: () => AnimationTrigger.onClick,
      ),
      delay: Duration(milliseconds: json['delayMs'] as int? ?? 0),
      duration: Duration(milliseconds: json['durationMs'] as int? ?? 500),
      easing: Easing.values.firstWhere(
        (e) => e.name == json['easing'],
        orElse: () => Easing.easeInOut,
      ),
    );
  }
}

/// Container for all animations on a slide
class SlideAnimation {
  final List<ElementAnimation> effects;
  double totalDurationMs;

  SlideAnimation({
    required this.effects,
    this.totalDurationMs = 0,
  });

  Map<String, dynamic> toJson() {
    return {
      'effects': effects.map((e) => e.toJson()).toList(),
      'totalDurationMs': totalDurationMs,
    };
  }

  factory SlideAnimation.fromJson(Map<String, dynamic> json) {
    final effectsJson = json['effects'] as List<dynamic>? ?? [];
    final effects = effectsJson
        .map((e) => ElementAnimation.fromJson(e as Map<String, dynamic>))
        .toList();
    return SlideAnimation(
      effects: effects,
      totalDurationMs: json['totalDurationMs'] as double? ?? 0,
    );
  }
}

/// Animation type categories for UI organization
enum AnimationCategory {
  entrance('Entrance'),
  emphasis('Emphasis'),
  exit('Exit'),
  motionPaths('Motion Paths');

  final String label;

  const AnimationCategory(this.label);

  static AnimationCategory fromEffect(AnimationEffect effect) {
    switch (effect) {
      case AnimationEffect.fadeIn:
      case AnimationEffect.flyInFromLeft:
      case AnimationEffect.flyInFromRight:
      case AnimationEffect.flyInFromTop:
      case AnimationEffect.flyInFromBottom:
      case AnimationEffect.zoomIn:
      case AnimationEffect.bounceIn:
        return AnimationCategory.entrance;

      case AnimationEffect.pulse:
      case AnimationEffect.spin:
      case AnimationEffect.wobble:
      case AnimationEffect.growShrink:
      case AnimationEffect.colorPulse:
        return AnimationCategory.emphasis;

      case AnimationEffect.fadeOut:
      case AnimationEffect.flyOutToLeft:
      case AnimationEffect.flyOutToRight:
      case AnimationEffect.flyOutToTop:
      case AnimationEffect.flyOutToBottom:
      case AnimationEffect.zoomOut:
      case AnimationEffect.bounceOut:
        return AnimationCategory.exit;

      case AnimationEffect.motionPathLine:
      case AnimationEffect.motionPathArc:
      case AnimationEffect.motionPathLoop:
        return AnimationCategory.motionPaths;
    }
  }
}

/// Preset animation configurations for quick access
class AnimationPresets {
  static const List<Map<String, dynamic>> entrancePresets = [
    {'effect': AnimationEffect.fadeIn, 'label': 'Fade In', 'duration': Duration(milliseconds: 500)},
    {'effect': AnimationEffect.flyInFromLeft, 'label': 'Fly In From Left', 'duration': Duration(milliseconds: 600)},
    {'effect': AnimationEffect.flyInFromRight, 'label': 'Fly In From Right', 'duration': Duration(milliseconds: 600)},
    {'effect': AnimationEffect.flyInFromTop, 'label': 'Fly In From Top', 'duration': Duration(milliseconds: 600)},
    {'effect': AnimationEffect.flyInFromBottom, 'label': 'Fly In From Bottom', 'duration': Duration(milliseconds: 600)},
    {'effect': AnimationEffect.zoomIn, 'label': 'Zoom In', 'duration': Duration(milliseconds: 500)},
    {'effect': AnimationEffect.bounceIn, 'label': 'Bounce In', 'duration': Duration(milliseconds: 700)},
  ];

  static const List<Map<String, dynamic>> emphasisPresets = [
    {'effect': AnimationEffect.pulse, 'label': 'Pulse', 'duration': Duration(milliseconds: 400)},
    {'effect': AnimationEffect.spin, 'label': 'Spin', 'duration': Duration(milliseconds: 800)},
    {'effect': AnimationEffect.wobble, 'label': 'Wobble', 'duration': Duration(milliseconds: 600)},
    {'effect': AnimationEffect.growShrink, 'label': 'Grow & Shrink', 'duration': Duration(milliseconds: 500)},
    {'effect': AnimationEffect.colorPulse, 'label': 'Color Pulse', 'duration': Duration(milliseconds: 400)},
  ];

  static const List<Map<String, dynamic>> exitPresets = [
    {'effect': AnimationEffect.fadeOut, 'label': 'Fade Out', 'duration': Duration(milliseconds: 500)},
    {'effect': AnimationEffect.flyOutToLeft, 'label': 'Fly Out To Left', 'duration': Duration(milliseconds: 600)},
    {'effect': AnimationEffect.flyOutToRight, 'label': 'Fly Out To Right', 'duration': Duration(milliseconds: 600)},
    {'effect': AnimationEffect.flyOutToTop, 'label': 'Fly Out To Top', 'duration': Duration(milliseconds: 600)},
    {'effect': AnimationEffect.flyOutToBottom, 'label': 'Fly Out To Bottom', 'duration': Duration(milliseconds: 600)},
    {'effect': AnimationEffect.zoomOut, 'label': 'Zoom Out', 'duration': Duration(milliseconds: 500)},
    {'effect': AnimationEffect.bounceOut, 'label': 'Bounce Out', 'duration': Duration(milliseconds: 700)},
  ];
}
