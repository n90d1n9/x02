// lib/models/component.dart
import 'package:flutter/material.dart';
import 'rich_text_content.dart';

enum ComponentType {
  text,
  richText,
  image,
  shape,
  circle,
  triangle,
  chart,
  video,
  audio,
  diagram,
  icon,
  gif,
  hotspot,
  poll,
  quiz,
  countdown,
  progressBar,
  lottie,
  particles,
  gradient,
  unknown, // Added unknown type for fallback
}

extension ComponentTypeExtension on ComponentType {
  static ComponentType? fromString(String? typeStr) {
    if (typeStr == null) return null;
    return ComponentType.values.firstWhere(
      (e) => e.name == typeStr || e.name.toLowerCase() == typeStr.toLowerCase(),
      orElse: () => ComponentType.unknown,
    );
  }
  
  String get value => name;
}

/// Represents the type of placeholder in a master slide layout
enum PlaceholderType {
  title,
  subtitle,
  content,
  picture,
  chart,
  table,
  smartArt,
  media,
  clipArt,
  body,
  header,
  footer,
  date,
  slideNumber,
  custom,
}

extension PlaceholderTypeExtension on PlaceholderType {
  static PlaceholderType fromString(String? typeStr) {
    if (typeStr == null) return PlaceholderType.custom;
    return PlaceholderType.values.firstWhere(
      (e) => e.name == typeStr || e.name.toLowerCase() == typeStr.toLowerCase(),
      orElse: () => PlaceholderType.custom,
    );
  }
  
  String get value => name;
}

/// Simple text style model for component serialization
class ComponentTextStyle {
  final String fontFamily;
  final double fontSize;
  final bool isBold;
  final bool isItalic;
  final String color;
  final bool isUnderline;
  final bool isStrikethrough;
  
  ComponentTextStyle({
    required this.fontFamily,
    required this.fontSize,
    this.isBold = false,
    this.isItalic = false,
    required this.color,
    this.isUnderline = false,
    this.isStrikethrough = false,
  });
  
  Map<String, dynamic> toJson() {
    return {
      'fontFamily': fontFamily,
      'fontSize': fontSize,
      'isBold': isBold,
      'isItalic': isItalic,
      'color': color,
      'isUnderline': isUnderline,
      'isStrikethrough': isStrikethrough,
    };
  }
  
  factory ComponentTextStyle.fromJson(Map<String, dynamic> json) {
    return ComponentTextStyle(
      fontFamily: json['fontFamily'] as String? ?? 'Arial',
      fontSize: (json['fontSize'] as num?)?.toDouble() ?? 14.0,
      isBold: json['isBold'] as bool? ?? false,
      isItalic: json['isItalic'] as bool? ?? false,
      color: json['color'] as String? ?? '#000000',
      isUnderline: json['isUnderline'] as bool? ?? false,
      isStrikethrough: json['isStrikethrough'] as bool? ?? false,
    );
  }
  
  /// Convert to Flutter TextStyle
  TextStyle toTextStyle() {
    return TextStyle(
      fontFamily: fontFamily,
      fontSize: fontSize,
      fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
      fontStyle: isItalic ? FontStyle.italic : FontStyle.normal,
      color: _hexToColor(color),
      decoration: TextDecoration.combine([
        if (isUnderline) TextDecoration.underline,
        if (isStrikethrough) TextDecoration.lineThrough,
      ]),
    );
  }
  
  static Color _hexToColor(String hex) {
    hex = hex.replaceAll('#', '');
    if (hex.length == 6) hex = 'FF$hex';
    return Color(int.parse(hex, radix: 16));
  }
}

/// Legacy TextContent class for backward compatibility with master slides
class TextContent {
  final String content;
  final ComponentTextStyle style;
  final TextAlign alignment;
  final double lineHeight;
  
  TextContent({
    required this.content,
    required this.style,
    this.alignment = TextAlign.start,
    this.lineHeight = 1.2,
  });
  
  Map<String, dynamic> toJson() {
    return {
      'content': content,
      'style': style.toJson(),
      'alignment': alignment.name,
      'lineHeight': lineHeight,
    };
  }
  
  factory TextContent.fromJson(Map<String, dynamic> json) {
    return TextContent(
      content: json['content'] as String ?? '',
      style: ComponentTextStyle.fromJson(json['style'] as Map<String, dynamic>? ?? {}),
      alignment: TextAlign.values.firstWhere(
        (e) => e.name == json['alignment'],
        orElse: () => TextAlign.start,
      ),
      lineHeight: (json['lineHeight'] as num?)?.toDouble() ?? 1.2,
    );
  }
  
  TextContent copyWith({
    String? content,
    ComponentTextStyle? style,
    TextAlign? alignment,
    double? lineHeight,
  }) {
    return TextContent(
      content: content ?? this.content,
      style: style ?? this.style,
      alignment: alignment ?? this.alignment,
      lineHeight: lineHeight ?? this.lineHeight,
    );
  }
  
  /// Convert to RichTextContent
  RichTextContent toRichTextContent() {
    return RichTextContent(
      text: content,
      style: style.toTextStyle(),
      isBold: style.isBold,
      isItalic: style.isItalic,
      isUnderline: style.isUnderline,
      isStrikethrough: style.isStrikethrough,
      alignment: alignment,
    );
  }
}

/// Main Component class representing elements on a slide or master layout
class Component {
  final String id;
  final ComponentType type;
  final double x;
  final double y;
  final double width;
  final double height;
  final String? name;
  final TextContent? text;
  final RichTextContent? richText;
  final String? imageUrl;
  final String? shapeType;
  final Map<String, dynamic>? style;
  final Map<String, dynamic>? properties;
  final bool isPlaceholder;
  final PlaceholderType? placeholderType;
  final String? placeholderLabel;
  final int zIndex;
  final double rotation;
  final double opacity;
  final bool isVisible;
  final bool isLocked;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  
  Component({
    required this.id,
    required this.type,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    this.name,
    this.text,
    this.richText,
    this.imageUrl,
    this.shapeType,
    this.style,
    this.properties,
    this.isPlaceholder = false,
    this.placeholderType,
    this.placeholderLabel,
    this.zIndex = 0,
    this.rotation = 0.0,
    this.opacity = 1.0,
    this.isVisible = true,
    this.isLocked = false,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();
  
  Component copyWith({
    String? id,
    ComponentType? type,
    double? x,
    double? y,
    double? width,
    double? height,
    String? name,
    TextContent? text,
    RichTextContent? richText,
    String? imageUrl,
    String? shapeType,
    Map<String, dynamic>? style,
    Map<String, dynamic>? properties,
    bool? isPlaceholder,
    PlaceholderType? placeholderType,
    String? placeholderLabel,
    int? zIndex,
    double? rotation,
    double? opacity,
    bool? isVisible,
    bool? isLocked,
    DateTime? updatedAt,
  }) {
    return Component(
      id: id ?? this.id,
      type: type ?? this.type,
      x: x ?? this.x,
      y: y ?? this.y,
      width: width ?? this.width,
      height: height ?? this.height,
      name: name ?? this.name,
      text: text ?? this.text,
      richText: richText ?? this.richText,
      imageUrl: imageUrl ?? this.imageUrl,
      shapeType: shapeType ?? this.shapeType,
      style: style ?? this.style,
      properties: properties ?? this.properties,
      isPlaceholder: isPlaceholder ?? this.isPlaceholder,
      placeholderType: placeholderType ?? this.placeholderType,
      placeholderLabel: placeholderLabel ?? this.placeholderLabel,
      zIndex: zIndex ?? this.zIndex,
      rotation: rotation ?? this.rotation,
      opacity: opacity ?? this.opacity,
      isVisible: isVisible ?? this.isVisible,
      isLocked: isLocked ?? this.isLocked,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'x': x,
      'y': y,
      'width': width,
      'height': height,
      'name': name,
      'text': text?.toJson(),
      'richText': richText?.toJson(),
      'imageUrl': imageUrl,
      'shapeType': shapeType,
      'style': style,
      'properties': properties,
      'isPlaceholder': isPlaceholder,
      'placeholderType': placeholderType?.name,
      'placeholderLabel': placeholderLabel,
      'zIndex': zIndex,
      'rotation': rotation,
      'opacity': opacity,
      'isVisible': isVisible,
      'isLocked': isLocked,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
  
  factory Component.fromJson(Map<String, dynamic> json) {
    return Component(
      id: json['id'] as String,
      type: ComponentType.fromString(json['type'] as String?) ?? ComponentType.unknown,
      x: (json['x'] as num?)?.toDouble() ?? 0.0,
      y: (json['y'] as num?)?.toDouble() ?? 0.0,
      width: (json['width'] as num?)?.toDouble() ?? 0.0,
      height: (json['height'] as num?)?.toDouble() ?? 0.0,
      name: json['name'] as String?,
      text: json['text'] != null ? TextContent.fromJson(json['text']) : null,
      richText: json['richText'] != null ? RichTextContent.fromJson(json['richText']) : null,
      imageUrl: json['imageUrl'] as String?,
      shapeType: json['shapeType'] as String?,
      style: json['style'] as Map<String, dynamic>?,
      properties: json['properties'] as Map<String, dynamic>?,
      isPlaceholder: json['isPlaceholder'] as bool? ?? false,
      placeholderType: PlaceholderType.fromString(json['placeholderType'] as String?),
      placeholderLabel: json['placeholderLabel'] as String?,
      zIndex: json['zIndex'] as int? ?? 0,
      rotation: (json['rotation'] as num?)?.toDouble() ?? 0.0,
      opacity: (json['opacity'] as num?)?.toDouble() ?? 1.0,
      isVisible: json['isVisible'] as bool? ?? true,
      isLocked: json['isLocked'] as bool? ?? false,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
    );
  }
  
  /// Get the bounding rectangle
  Rect get bounds => Rect.fromLTWH(x, y, width, height);
  
  /// Check if point is inside component
  bool containsPoint(double px, double py) {
    return px >= x && px <= x + width && py >= y && py <= y + height;
  }
  
  /// Convert to PresentationComponent
  PresentationComponent toPresentationComponent() {
    // This would require importing PresentationComponent
    // For now, return basic conversion logic
    throw UnimplementedError('Conversion to PresentationComponent not implemented');
  }
}
