import 'dart:async';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../models/animation.dart';
import '../models/slide.dart';
import '../models/presentation.dart';

/// Service for managing animation timelines in presentations
/// Similar to PowerPoint's Animation Pane and Google Slides' Motion panel
class AnimationTimelineService extends ChangeNotifier {
  final Uuid _uuid = const Uuid();

  /// Currently selected slide's animations
  final Map<String, SlideAnimation> _slideAnimations = {};

  /// Currently playing animation index
  int _currentAnimationIndex = -1;

  /// Is animation preview currently playing
  bool _isPlaying = false;

  /// Total duration of all animations on current slide (in milliseconds)
  double _totalDuration = 0;

  /// Selected animation ID for editing
  String? _selectedAnimationId;

  /// Timeline zoom level (1.0 = 100%)
  double _timelineZoom = 1.0;

  /// Get all animations for a slide
  List<ElementAnimation> getAnimationsForSlide(String slideId) {
    return _slideAnimations[slideId]?.effects ?? [];
  }

  /// Get animation by ID
  ElementAnimation? getAnimation(String slideId, String animationId) {
    final animations = _slideAnimations[slideId]?.effects;
    if (animations == null) return null;
    return animations.firstWhere(
      (a) => a.id == animationId,
      orElse: () => throw Exception('Animation not found'),
    );
  }

  /// Add animation effect to a slide
  void addAnimation({
    required String slideId,
    required String targetComponentId,
    required AnimationEffect effect,
    AnimationTrigger trigger = AnimationTrigger.onClick,
    Duration? delay,
    Duration? duration,
    Easing? easing,
  }) {
    _slideAnimations.putIfAbsent(slideId, () => SlideAnimation(effects: []));

    final animation = ElementAnimation(
      id: _uuid.v4(),
      targetId: targetComponentId,
      effect: effect,
      trigger: trigger,
      delay: delay ?? Duration.zero,
      duration: duration ?? const Duration(milliseconds: 500),
      easing: easing ?? Easing.easeInOut,
    );

    _slideAnimations[slideId]!.effects.add(animation);
    _recalculateTotalDuration(slideId);
    notifyListeners();
  }

  /// Remove animation from slide
  void removeAnimation(String slideId, String animationId) {
    final slideAnims = _slideAnimations[slideId];
    if (slideAnims == null) return;

    slideAnims.effects.removeWhere((a) => a.id == animationId);
    if (_selectedAnimationId == animationId) {
      _selectedAnimationId = null;
    }
    _recalculateTotalDuration(slideId);
    notifyListeners();
  }

  /// Update animation properties
  void updateAnimation({
    required String slideId,
    required String animationId,
    AnimationEffect? effect,
    AnimationTrigger? trigger,
    Duration? delay,
    Duration? duration,
    Easing? easing,
    int? order,
  }) {
    final animations = _slideAnimations[slideId]?.effects;
    if (animations == null) return;

    final index = animations.indexWhere((a) => a.id == animationId);
    if (index == -1) return;

    final animation = animations[index];
    animations[index] = ElementAnimation(
      id: animation.id,
      targetId: animation.targetId,
      effect: effect ?? animation.effect,
      trigger: trigger ?? animation.trigger,
      delay: delay ?? animation.delay,
      duration: duration ?? animation.duration,
      easing: easing ?? animation.easing,
    );

    // Reorder if needed
    if (order != null && order >= 0 && order < animations.length) {
      final removed = animations.removeAt(index);
      animations.insert(order, removed);
    }

    _recalculateTotalDuration(slideId);
    notifyListeners();
  }

  /// Reorder animations
  void reorderAnimation(String slideId, int oldIndex, int newIndex) {
    final animations = _slideAnimations[slideId]?.effects;
    if (animations == null || oldIndex == newIndex) return;

    final animation = animations.removeAt(oldIndex);
    animations.insert(newIndex, animation);
    _recalculateTotalDuration(slideId);
    notifyListeners();
  }

  /// Clear all animations for a slide
  void clearSlideAnimations(String slideId) {
    _slideAnimations.remove(slideId);
    _selectedAnimationId = null;
    _totalDuration = 0;
    notifyListeners();
  }

  /// Copy animations from one slide to another
  void copyAnimationsToSlide(String fromSlideId, String toSlideId) {
    final sourceAnimations = _slideAnimations[fromSlideId];
    if (sourceAnimations == null) return;

    // Deep copy animations with new IDs
    final copiedEffects = sourceAnimations.effects.map((anim) {
      return ElementAnimation(
        id: _uuid.v4(),
        targetId: anim.targetId,
        effect: anim.effect,
        trigger: anim.trigger,
        delay: anim.delay,
        duration: anim.duration,
        easing: anim.easing,
      );
    }).toList();

    _slideAnimations[toSlideId] = SlideAnimation(effects: copiedEffects);
    _recalculateTotalDuration(toSlideId);
    notifyListeners();
  }

  /// Preview animations for a slide
  Future<void> playPreview(String slideId, VoidCallback onAnimate) async {
    if (_isPlaying) return;

    final animations = _slideAnimations[slideId]?.effects;
    if (animations == null || animations.isEmpty) return;

    _isPlaying = true;
    _currentAnimationIndex = -1;
    notifyListeners();

    var currentTime = Duration.zero;

    for (var i = 0; i < animations.length; i++) {
      _currentAnimationIndex = i;
      notifyListeners();

      final animation = animations[i];

      // Wait for delay
      if (animation.delay > Duration.zero) {
        await Future.delayed(animation.delay);
      }

      // Execute animation
      onAnimate();

      // Wait for duration
      await Future.delayed(animation.duration);

      currentTime += animation.delay + animation.duration;
    }

    _isPlaying = false;
    _currentAnimationIndex = -1;
    notifyListeners();
  }

  /// Stop preview
  void stopPreview() {
    _isPlaying = false;
    _currentAnimationIndex = -1;
    notifyListeners();
  }

  /// Get total duration for slide
  double getTotalDuration(String slideId) {
    return _slideAnimations[slideId]?.totalDurationMs ?? 0;
  }

  /// Set selected animation for editing
  void selectAnimation(String? animationId) {
    _selectedAnimationId = animationId;
    notifyListeners();
  }

  /// Set timeline zoom level
  void setTimelineZoom(double zoom) {
    _timelineZoom = zoom.clamp(0.5, 4.0);
    notifyListeners();
  }

  /// Get animation at time position
  ElementAnimation? getAnimationAtTime(String slideId, Duration time) {
    final animations = _slideAnimations[slideId]?.effects;
    if (animations == null) return null;

    var currentTime = Duration.zero;
    for (final animation in animations) {
      currentTime += animation.delay;
      if (time >= currentTime && time < currentTime + animation.duration) {
        return animation;
      }
      currentTime += animation.duration;
    }
    return null;
  }

  /// Export animations to JSON
  Map<String, dynamic> toJson(String slideId) {
    final animations = _slideAnimations[slideId];
    if (animations == null) return {};

    return {
      'slideId': slideId,
      'effects': animations.effects.map((e) => e.toJson()).toList(),
      'totalDuration': animations.totalDurationMs,
    };
  }

  /// Import animations from JSON
  void fromJson(Map<String, dynamic> json) {
    final slideId = json['slideId'] as String;
    final effectsJson = json['effects'] as List<dynamic>;

    final effects = effectsJson
        .map((e) => ElementAnimation.fromJson(e as Map<String, dynamic>))
        .toList();

    _slideAnimations[slideId] = SlideAnimation(effects: effects);
    _recalculateTotalDuration(slideId);
    notifyListeners();
  }

  void _recalculateTotalDuration(String slideId) {
    final animations = _slideAnimations[slideId];
    if (animations == null) {
      _totalDuration = 0;
      return;
    }

    var total = 0.0;
    for (final anim in animations.effects) {
      total += anim.delay.inMilliseconds + anim.duration.inMilliseconds;
    }
    animations.totalDurationMs = total;
    _totalDuration = total;
  }

  // Getters
  bool get isPlaying => _isPlaying;
  int get currentAnimationIndex => _currentAnimationIndex;
  String? get selectedAnimationId => _selectedAnimationId;
  double get timelineZoom => _timelineZoom;
  double get totalDuration => _totalDuration;
}

/// Animation type categories for UI organization
enum AnimationCategory {
  entrance('Entrance', Colors.green),
  emphasis('Emphasis', Colors.yellow),
  exit('Exit', Colors.red),
  motionPaths('Motion Paths', Colors.blue);

  final String label;
  final Color color;

  const AnimationCategory(this.label, this.color);

  static AnimationCategory fromEffect(AnimationEffect effect) {
    switch (effect) {
      case AnimationEffect.fadeIn:
      case AnimationEffect flyInFromLeft:
      case AnimationEffect flyInFromRight:
      case AnimationEffect flyInFromTop:
      case AnimationEffect flyInFromBottom:
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
