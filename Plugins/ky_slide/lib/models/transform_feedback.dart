import 'dart:ui';

import 'presentation_component.dart';

/// Active direct-manipulation state shown as a compact canvas measurement badge.
class TransformFeedback {
  final TransformFeedbackMode mode;
  final Offset position;
  final Size size;
  final double rotation;

  const TransformFeedback({
    required this.mode,
    required this.position,
    required this.size,
    required this.rotation,
  });

  factory TransformFeedback.fromComponent({
    required TransformFeedbackMode mode,
    required PresentationComponent component,
  }) {
    return TransformFeedback(
      mode: mode,
      position: component.position,
      size: component.size,
      rotation: component.rotation,
    );
  }
}

/// Type of active canvas transform represented by a feedback badge.
enum TransformFeedbackMode { move, resize, rotate }
