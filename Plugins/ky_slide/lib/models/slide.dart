// lib/models/slide.dart
import 'dart:typed_data';
import 'dart:ui';

import 'presentation_component.dart';
import 'slide_transition_type.dart';
import 'style/gradient_animation.dart';
import 'style/particle_effect.dart';

class Slide {
  static const Object _unset = Object();

  final String id;
  final List<PresentationComponent> components;
  final Color? backgroundColor;
  final String? notes;
  final String? title;
  final SlideTransitionType transition;
  final Uint8List? backgroundImage;
  final GradientAnimation? backgroundGradient;
  final ParticleEffect? backgroundParticles;
  final String? backgroundVideo;

  Slide({
    required this.id,
    required this.components,
    this.backgroundColor,
    this.notes,
    this.title,
    this.transition = SlideTransitionType.fade,
    this.backgroundImage,
    this.backgroundGradient,
    this.backgroundParticles,
    this.backgroundVideo,
  });

  Slide copyWith({
    List<PresentationComponent>? components,
    Object? backgroundColor = _unset,
    Object? notes = _unset,
    Object? title = _unset,
    SlideTransitionType? transition,
    Object? backgroundImage = _unset,
    Object? backgroundGradient = _unset,
    Object? backgroundParticles = _unset,
    Object? backgroundVideo = _unset,
  }) {
    return Slide(
      id: id,
      components: components ?? this.components,
      backgroundColor: identical(backgroundColor, _unset)
          ? this.backgroundColor
          : backgroundColor as Color?,
      notes: identical(notes, _unset) ? this.notes : notes as String?,
      title: identical(title, _unset) ? this.title : title as String?,
      transition: transition ?? this.transition,
      backgroundImage: identical(backgroundImage, _unset)
          ? this.backgroundImage
          : backgroundImage as Uint8List?,
      backgroundGradient: identical(backgroundGradient, _unset)
          ? this.backgroundGradient
          : backgroundGradient as GradientAnimation?,
      backgroundParticles: identical(backgroundParticles, _unset)
          ? this.backgroundParticles
          : backgroundParticles as ParticleEffect?,
      backgroundVideo: identical(backgroundVideo, _unset)
          ? this.backgroundVideo
          : backgroundVideo as String?,
    );
  }

  // ---------------------------------------------------------------------
  // JSON deserialization (used by the slide_engine FFI bridge)
  // ---------------------------------------------------------------------
  factory Slide.fromJson(Map<String, dynamic> json) {
    return Slide(
      id: json['id'] as String? ?? 'unknown',
      components: (json['components'] as List<dynamic>? ?? [])
          .map((e) => PresentationComponent.fromJson(e as Map<String, dynamic>))
          .toList(),
      backgroundColor: json['backgroundColor'] != null
          ? Color(json['backgroundColor'] as int)
          : null,
      notes: json['notes'] as String?,
      title: json['title'] as String?,
      transition:
          SlideTransitionTypeExtension.fromString(
            json['transition'] as String?,
          ) ??
          SlideTransitionType.fade,
      backgroundImage: json['backgroundImage'] != null
          ? Uint8List.fromList(List<int>.from(json['backgroundImage']))
          : null,
      backgroundGradient: json['backgroundGradient'] != null
          ? GradientAnimation.fromJson(
              json['backgroundGradient'] as Map<String, dynamic>,
            )
          : null,
      backgroundParticles: json['backgroundParticles'] != null
          ? ParticleEffect.fromJson(
              json['backgroundParticles'] as Map<String, dynamic>,
            )
          : null,
      backgroundVideo: json['backgroundVideo'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'components': components.map((component) => component.toJson()).toList(),
      'backgroundColor': backgroundColor?.toARGB32(),
      'notes': notes,
      'title': title,
      'transition': transition.name,
      'backgroundImage': backgroundImage == null
          ? null
          : List<int>.from(backgroundImage!),
      'backgroundGradient': backgroundGradient?.toJson(),
      'backgroundParticles': backgroundParticles?.toJson(),
      'backgroundVideo': backgroundVideo,
    };
  }
}
