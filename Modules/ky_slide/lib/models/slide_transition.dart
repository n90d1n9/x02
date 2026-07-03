import 'package:flutter/material.dart';

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

class SlideTransition {
  final String id;
  final TransitionType type;
  final double duration;
  final TransitionDirection direction;
  final bool applyToAll;
  final String? soundEffect;
  final bool autoAdvance;
  final double? autoAdvanceDelay;

  const SlideTransition({
    required this.id,
    required this.type,
    this.duration = 0.5,
    this.direction = TransitionDirection.fromRight,
    this.applyToAll = false,
    this.soundEffect,
    this.autoAdvance = false,
    this.autoAdvanceDelay,
  });

  factory SlideTransition.defaultTransition() => const SlideTransition(
    id: 'default',
    type: TransitionType.none,
    duration: 0.5,
  );

  factory SlideTransition.fromJson(Map<String, dynamic> json) {
    return SlideTransition(
      id: json['id'] as String,
      type: TransitionType.values.firstWhere((e) => e.name == json['type']),
      duration: (json['duration'] ?? 0.5) as double,
      direction: TransitionDirection.values.firstWhere(
        (e) => e.name == json['direction'],
      ),
      applyToAll: json['applyToAll'] ?? false,
      soundEffect: json['soundEffect'] as String?,
      autoAdvance: json['autoAdvance'] ?? false,
      autoAdvanceDelay: json['autoAdvanceDelay'] as double?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.name, // assuming enum has name
    'duration': duration,
    'direction': direction.name,
    'applyToAll': applyToAll,
    'soundEffect': soundEffect,
    'autoAdvance': autoAdvance,
    'autoAdvanceDelay': autoAdvanceDelay,
  };

  SlideTransition copyWith({
    String? id,
    TransitionType? type,
    double? duration,
    TransitionDirection? direction,
    bool? applyToAll,
    String? soundEffect,
    bool? autoAdvance,
    double? autoAdvanceDelay,
  }) {
    return SlideTransition(
      id: id ?? this.id,
      type: type ?? this.type,
      duration: duration ?? this.duration,
      direction: direction ?? this.direction,
      applyToAll: applyToAll ?? this.applyToAll,
      soundEffect: soundEffect ?? this.soundEffect,
      autoAdvance: autoAdvance ?? this.autoAdvance,
      autoAdvanceDelay: autoAdvanceDelay ?? this.autoAdvanceDelay,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SlideTransition &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          type == other.type &&
          duration == other.duration &&
          direction == other.direction &&
          applyToAll == other.applyToAll &&
          soundEffect == other.soundEffect &&
          autoAdvance == other.autoAdvance &&
          autoAdvanceDelay == other.autoAdvanceDelay;

  @override
  int get hashCode =>
      id.hashCode ^
      type.hashCode ^
      duration.hashCode ^
      direction.hashCode ^
      applyToAll.hashCode ^
      soundEffect.hashCode ^
      autoAdvance.hashCode ^
      autoAdvanceDelay.hashCode;
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
