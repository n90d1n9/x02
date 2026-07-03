// lib/models/rich_text_content.dart
import 'package:flutter/material.dart';

/// Editable rich text payload used by text components and PPTX mapping.
class RichTextContent {
  final String text;
  final TextStyle style;
  final bool isBold;
  final bool isItalic;
  final bool isUnderline;
  final bool isStrikethrough;
  final TextAlign alignment;

  RichTextContent({
    required this.text,
    required this.style,
    this.isBold = false,
    this.isItalic = false,
    this.isUnderline = false,
    this.isStrikethrough = false,
    this.alignment = TextAlign.left,
  });

  TextStyle get effectiveStyle {
    final decorations = <TextDecoration>[
      if (isUnderline) TextDecoration.underline,
      if (isStrikethrough) TextDecoration.lineThrough,
    ];

    return style.copyWith(
      fontWeight: isBold ? FontWeight.w700 : style.fontWeight,
      fontStyle: isItalic ? FontStyle.italic : style.fontStyle,
      decoration: decorations.isEmpty
          ? style.decoration
          : TextDecoration.combine(decorations),
    );
  }

  RichTextContent copyWith({
    String? text,
    TextStyle? style,
    bool? isBold,
    bool? isItalic,
    bool? isUnderline,
    bool? isStrikethrough,
    TextAlign? alignment,
  }) {
    return RichTextContent(
      text: text ?? this.text,
      style: style ?? this.style,
      isBold: isBold ?? this.isBold,
      isItalic: isItalic ?? this.isItalic,
      isUnderline: isUnderline ?? this.isUnderline,
      isStrikethrough: isStrikethrough ?? this.isStrikethrough,
      alignment: alignment ?? this.alignment,
    );
  }

  factory RichTextContent.fromJson(Map<String, dynamic> json) {
    return RichTextContent(
      text: json['text'] as String? ?? '',
      style: TextStyle(
        fontSize: (json['fontSize'] as num?)?.toDouble() ?? 14.0,
        color: json['color'] != null
            ? Color(json['color'] as int)
            : Colors.black,
        fontFamily: json['fontFamily'] as String?,
        height: (json['lineHeight'] as num?)?.toDouble(),
        letterSpacing: (json['letterSpacing'] as num?)?.toDouble(),
        backgroundColor: json['highlightColor'] != null
            ? Color(json['highlightColor'] as int)
            : null,
      ),
      isBold: json['isBold'] as bool? ?? false,
      isItalic: json['isItalic'] as bool? ?? false,
      isUnderline: json['isUnderline'] as bool? ?? false,
      isStrikethrough: json['isStrikethrough'] as bool? ?? false,
      alignment: TextAlign.values.firstWhere(
        (e) => e.name == json['alignment'],
        orElse: () => TextAlign.left,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'fontSize': style.fontSize,
      'color': style.color?.toARGB32(),
      'fontFamily': style.fontFamily,
      'lineHeight': style.height,
      'letterSpacing': style.letterSpacing,
      'highlightColor': style.backgroundColor?.toARGB32(),
      'isBold': isBold,
      'isItalic': isItalic,
      'isUnderline': isUnderline,
      'isStrikethrough': isStrikethrough,
      'alignment': alignment.name,
    };
  }
}
