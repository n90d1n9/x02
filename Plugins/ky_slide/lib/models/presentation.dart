// lib/models/presentation.dart
import 'dart:ui';
import 'slide.dart';
import 'style/presentation_theme.dart';

class Presentation {
  final String id;
  final String title;
  final List<Slide> slides;
  final int currentSlideIndex;
  final PresentationTheme theme;
  final Size slideSize;

  Presentation({
    required this.id,
    required this.title,
    required this.slides,
    this.currentSlideIndex = 0,
    PresentationTheme? theme,
    this.slideSize = const Size(1920, 1080),
  }) : theme = theme ?? PresentationTheme.modernGlass;

  Presentation copyWith({
    String? title,
    List<Slide>? slides,
    int? currentSlideIndex,
    PresentationTheme? theme,
    Size? slideSize,
  }) {
    return Presentation(
      id: id,
      title: title ?? this.title,
      slides: slides ?? this.slides,
      currentSlideIndex: currentSlideIndex ?? this.currentSlideIndex,
      theme: theme ?? this.theme,
      slideSize: slideSize ?? this.slideSize,
    );
  }

  // ---------------------------------------------------------------------
  // JSON deserialization (used by the slide_engine FFI bridge)
  // ---------------------------------------------------------------------
  factory Presentation.fromJson(Map<String, dynamic> json) {
    return Presentation(
      id: json['id'] as String? ?? json['title'] ?? 'unknown',
      title: json['title'] as String? ?? 'Untitled',
      slides: (json['slides'] as List<dynamic>? ?? [])
          .map((e) => Slide.fromJson(e as Map<String, dynamic>))
          .toList(),
      // The Rust side does not expose currentSlideIndex or theme; use defaults.
      currentSlideIndex: json['currentSlideIndex'] as int? ?? 0,
      theme: PresentationTheme.modernGlass,
      slideSize: const Size(1920, 1080),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'slides': slides.map((slide) => slide.toJson()).toList(),
      'currentSlideIndex': currentSlideIndex,
      'slideSize': {'width': slideSize.width, 'height': slideSize.height},
    };
  }
}
