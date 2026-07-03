// lib/models/presentation_component.dart
import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'animation.dart';
import 'chart_data.dart';
import 'component.dart';
import 'enums.dart';
import 'interactive_element.dart';
import 'rich_text_content.dart';
import 'style/glasmorphism_style.dart';
import 'style/gradient_animation.dart';
import 'style/neumorphism_style.dart';
import 'style/particle_effect.dart';

/// Model for a drawable and editable object placed on a presentation slide.
class PresentationComponent {
  static const Object _unset = Object();

  final String id;
  final ComponentType type;
  final Offset position;
  final Size size;
  final String? layerName;
  final RichTextContent? richText;
  final Uint8List? imageData;
  final Color? backgroundColor;
  final double rotation;
  final int zIndex;
  final AnimationType animation;
  final double opacity;
  final BorderSide? border;
  final bool isEditing;
  final ChartData? chartData;
  final String? videoUrl;
  final String? audioUrl;
  final double animationDelay;
  final double animationDuration;
  final VisualEffect? visualEffect;
  final GlassmorphismStyle? glassStyle;
  final NeumorphismStyle? neumoStyle;
  final ParticleEffect? particleEffect;
  final GradientAnimation? gradientAnim;
  final InteractiveElement? interactive;
  final String? lottieAsset;
  final bool hasGlow;
  final Color? glowColor;
  final bool isVisible;
  final bool isLocked;

  PresentationComponent({
    required this.id,
    required this.type,
    required this.position,
    required this.size,
    this.layerName,
    this.richText,
    this.imageData,
    this.backgroundColor,
    this.rotation = 0,
    this.zIndex = 0,
    this.animation = AnimationType.none,
    this.opacity = 1.0,
    this.border,
    this.isEditing = false,
    this.chartData,
    this.videoUrl,
    this.audioUrl,
    this.animationDelay = 0,
    this.animationDuration = 0.6,
    this.visualEffect,
    this.glassStyle,
    this.neumoStyle,
    this.particleEffect,
    this.gradientAnim,
    this.interactive,
    this.lottieAsset,
    this.hasGlow = false,
    this.glowColor,
    this.isVisible = true,
    this.isLocked = false,
  });

  PresentationComponent copyWith({
    String? id,
    Offset? position,
    Size? size,
    Object? layerName = _unset,
    RichTextContent? richText,
    Uint8List? imageData,
    Object? backgroundColor = _unset,
    double? rotation,
    int? zIndex,
    AnimationType? animation,
    double? opacity,
    Object? border = _unset,
    bool? isEditing,
    ChartData? chartData,
    String? videoUrl,
    String? audioUrl,
    double? animationDelay,
    double? animationDuration,
    VisualEffect? visualEffect,
    GlassmorphismStyle? glassStyle,
    NeumorphismStyle? neumoStyle,
    ParticleEffect? particleEffect,
    GradientAnimation? gradientAnim,
    InteractiveElement? interactive,
    String? lottieAsset,
    bool? hasGlow,
    Object? glowColor = _unset,
    bool? isVisible,
    bool? isLocked,
  }) {
    return PresentationComponent(
      id: id ?? this.id,
      type: type,
      position: position ?? this.position,
      size: size ?? this.size,
      layerName: identical(layerName, _unset)
          ? this.layerName
          : layerName as String?,
      richText: richText ?? this.richText,
      imageData: imageData ?? this.imageData,
      backgroundColor: identical(backgroundColor, _unset)
          ? this.backgroundColor
          : backgroundColor as Color?,
      rotation: rotation ?? this.rotation,
      zIndex: zIndex ?? this.zIndex,
      animation: animation ?? this.animation,
      opacity: opacity ?? this.opacity,
      border: identical(border, _unset) ? this.border : border as BorderSide?,
      isEditing: isEditing ?? this.isEditing,
      chartData: chartData ?? this.chartData,
      videoUrl: videoUrl ?? this.videoUrl,
      audioUrl: audioUrl ?? this.audioUrl,
      animationDelay: animationDelay ?? this.animationDelay,
      animationDuration: animationDuration ?? this.animationDuration,
      visualEffect: visualEffect ?? this.visualEffect,
      glassStyle: glassStyle ?? this.glassStyle,
      neumoStyle: neumoStyle ?? this.neumoStyle,
      particleEffect: particleEffect ?? this.particleEffect,
      gradientAnim: gradientAnim ?? this.gradientAnim,
      interactive: interactive ?? this.interactive,
      lottieAsset: lottieAsset ?? this.lottieAsset,
      hasGlow: hasGlow ?? this.hasGlow,
      glowColor: identical(glowColor, _unset)
          ? this.glowColor
          : glowColor as Color?,
      isVisible: isVisible ?? this.isVisible,
      isLocked: isLocked ?? this.isLocked,
    );
  }

  // ---------------------------------------------------------------------
  // JSON deserialization (used by the slide_engine FFI bridge)
  // ---------------------------------------------------------------------
  factory PresentationComponent.fromJson(Map<String, dynamic> json) {
    return PresentationComponent(
      id: json['id'] as String? ?? 'unknown',
      type:
          ComponentTypeExtension.fromString(json['type'] as String?) ??
          ComponentType.unknown,
      position: json['position'] != null && json['position'] is Map
          ? Offset(
              (json['position']['dx'] as num?)?.toDouble() ?? 0.0,
              (json['position']['dy'] as num?)?.toDouble() ?? 0.0,
            )
          : Offset.zero,
      size: json['size'] != null && json['size'] is Map
          ? Size(
              (json['size']['width'] as num?)?.toDouble() ?? 0.0,
              (json['size']['height'] as num?)?.toDouble() ?? 0.0,
            )
          : Size.zero,
      layerName: json['layerName'] as String?,
      richText: json['richText'] != null
          ? RichTextContent.fromJson(json['richText'] as Map<String, dynamic>)
          : null,
      imageData: json['imageData'] != null
          ? Uint8List.fromList(List<int>.from(json['imageData']))
          : null,
      backgroundColor: json['backgroundColor'] != null
          ? Color(json['backgroundColor'] as int)
          : null,
      rotation: (json['rotation'] as num?)?.toDouble() ?? 0.0,
      zIndex: json['zIndex'] as int? ?? 0,
      animation:
          AnimationTypeExtension.fromString(json['animation'] as String?) ??
          AnimationType.none,
      opacity: (json['opacity'] as num?)?.toDouble() ?? 1.0,
      border: json['border'] != null
          ? BorderSide(
              color: Color(json['border']['color'] as int),
              width: (json['border']['width'] as num).toDouble(),
            )
          : null,
      isEditing: json['isEditing'] as bool? ?? false,
      chartData: json['chartData'] != null
          ? ChartData.fromJson(json['chartData'] as Map<String, dynamic>)
          : null,
      videoUrl: json['videoUrl'] as String?,
      audioUrl: json['audioUrl'] as String?,
      animationDelay: (json['animationDelay'] as num?)?.toDouble() ?? 0.0,
      animationDuration: (json['animationDuration'] as num?)?.toDouble() ?? 0.6,
      visualEffect: json['visualEffect'] != null
          ? VisualEffectExtension.fromString(json['visualEffect'] as String?)
          : null,
      glassStyle: json['glassStyle'] != null
          ? GlassmorphismStyle.fromJson(
              json['glassStyle'] as Map<String, dynamic>,
            )
          : null,
      neumoStyle: json['neumoStyle'] != null
          ? NeumorphismStyle.fromJson(
              json['neumoStyle'] as Map<String, dynamic>,
            )
          : null,
      particleEffect: json['particleEffect'] != null
          ? ParticleEffect.fromJson(
              json['particleEffect'] as Map<String, dynamic>,
            )
          : null,
      gradientAnim: json['gradientAnim'] != null
          ? GradientAnimation.fromJson(
              json['gradientAnim'] as Map<String, dynamic>,
            )
          : null,
      interactive: json['interactive'] != null
          ? InteractiveElement.fromJson(
              json['interactive'] as Map<String, dynamic>,
            )
          : null,
      lottieAsset: json['lottieAsset'] as String?,
      hasGlow: json['hasGlow'] as bool? ?? false,
      glowColor: json['glowColor'] != null
          ? Color(json['glowColor'] as int)
          : null,
      isVisible: json['isVisible'] as bool? ?? true,
      isLocked: json['isLocked'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'position': {'dx': position.dx, 'dy': position.dy},
      'size': {'width': size.width, 'height': size.height},
      'layerName': layerName,
      'richText': richText?.toJson(),
      'imageData': imageData == null ? null : List<int>.from(imageData!),
      'backgroundColor': backgroundColor?.toARGB32(),
      'rotation': rotation,
      'zIndex': zIndex,
      'animation': animation.name,
      'opacity': opacity,
      'border': border == null
          ? null
          : {'color': border!.color.toARGB32(), 'width': border!.width},
      'isEditing': isEditing,
      'chartData': chartData?.toJson(),
      'videoUrl': videoUrl,
      'audioUrl': audioUrl,
      'animationDelay': animationDelay,
      'animationDuration': animationDuration,
      'visualEffect': visualEffect?.name,
      'glassStyle': glassStyle?.toJson(),
      'neumoStyle': neumoStyle?.toJson(),
      'particleEffect': particleEffect?.toJson(),
      'gradientAnim': gradientAnim?.toJson(),
      'interactive': interactive?.toJson(),
      'lottieAsset': lottieAsset,
      'hasGlow': hasGlow,
      'glowColor': glowColor?.toARGB32(),
      'isVisible': isVisible,
      'isLocked': isLocked,
    };
  }
}
