import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'slide_transition.freezed.dart';
part 'slide_transition.g.dart';

/// Defines the type of transition effect between slides.
enum TransitionType {
  none('None'),
  fade('Fade'),
  push('Push'),
  wipe('Wipe'),
  reveal('Reveal'),
  zoom('Zoom'),
  morph('Morph'), // Advanced shape-matching transition
  flip('Flip'),
  cover('Cover'),
  uncover('Uncover'),
  dissolve('Dissolve'),
  random('Random');

  final String displayName;
  const TransitionType(this.displayName);

  IconData get icon {
    switch (this) {
      case TransitionType.none:
        return Icons.block_outlined;
      case TransitionType.fade:
        return Icons.opacity_outlined;
      case TransitionType.push:
        return Icons.arrow_forward_outlined;
      case TransitionType.wipe:
        return Icons.drag_handle_outlined;
      case TransitionType.reveal:
        return Icons.visibility_outlined;
      case TransitionType.zoom:
        return Icons.zoom_in_outlined;
      case TransitionType.morph:
        return Icons.auto_awesome_outlined;
      case TransitionType.flip:
        return Icons.flip_outlined;
      case TransitionType.cover:
        return Icons.layers_outlined;
      case TransitionType.uncover:
        return Icons.layers_clear_outlined;
      case TransitionType.dissolve:
        return Icons.blur_off_outlined;
      case TransitionType.random:
        return Icons.casino_outlined;
    }
  }
}

/// Defines the direction for directional transitions (Push, Wipe, etc.).
enum TransitionDirection {
  fromLeft('From Left'),
  fromRight('From Right'),
  fromTop('From Top'),
  fromBottom('From Bottom');

  final String displayName;
  const TransitionDirection(this.displayName);
}

/// Model representing a slide transition configuration.
@freezed
class SlideTransition with _$SlideTransition {
  const factory SlideTransition({
    required String id,
    required TransitionType type,
    @Default(0.5) double duration, // in seconds
    @Default(TransitionDirection.fromRight) TransitionDirection direction,
    @Default(false) bool applyToAll, // UI flag, not persisted per slide usually
    @Default(null) String? soundEffect, // Future: path to audio file
    @Default(false) bool autoAdvance, // If true, ignores click
    @Default(null) double? autoAdvanceDelay, // Seconds before auto advance
  }) = _SlideTransition;

  factory SlideTransition.fromJson(Map<String, dynamic> json) =>
      _$SlideTransitionFromJson(json);

  factory SlideTransition.defaultTransition() => const SlideTransition(
        id: 'default',
        type: TransitionType.none,
        duration: 0.5,
      );
}

/// Helper class to generate preview animations for the UI gallery.
class TransitionPreviewGenerator {
  static Curve getCurveForType(TransitionType type) {
    switch (type) {
      case TransitionType.fade:
        return Curves.easeInOut;
      case TransitionType.push:
      case TransitionType.wipe:
      case TransitionType.reveal:
        return Curves.easeOutCubic;
      case TransitionType.zoom:
        return Curves.easeOutBack;
      case TransitionType.morph:
        return Curves.easeInOutCubic;
      default:
        return Curves.linear;
    }
  }
}
