import 'package:ky_slide/models/presentation.dart';
import 'package:ky_slide/models/slide.dart';
import 'package:ky_slide/models/component.dart';

/// Represents a master slide layout type (similar to PowerPoint layouts)
enum MasterLayoutType {
  titleSlide,
  titleAndContent,
  sectionHeader,
  twoContent,
  comparison,
  titleOnly,
  blank,
  contentWithCaption,
  pictureWithCaption,
  custom,
}

/// Model representing a Master Slide Layout
class MasterLayout {
  final String id;
  final String name;
  final MasterLayoutType type;
  final List<Component> placeholders;
  final Map<String, dynamic> background;
  final TextStyleDefaults? textStyles;
  final bool isHidden;
  final DateTime createdAt;
  final DateTime updatedAt;

  MasterLayout({
    required this.id,
    required this.name,
    required this.type,
    this.placeholders = const [],
    this.background = const {},
    this.textStyles,
    this.isHidden = false,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  MasterLayout copyWith({
    String? name,
    MasterLayoutType? type,
    List<Component>? placeholders,
    Map<String, dynamic>? background,
    TextStyleDefaults? textStyles,
    bool? isHidden,
    DateTime? updatedAt,
  }) {
    return MasterLayout(
      id: id,
      name: name ?? this.name,
      type: type ?? this.type,
      placeholders: placeholders ?? this.placeholders,
      background: background ?? this.background,
      textStyles: textStyles ?? this.textStyles,
      isHidden: isHidden ?? this.isHidden,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  /// Convert to JSON for serialization
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type.name,
      'placeholders': placeholders.map((p) => p.toJson()).toList(),
      'background': background,
      'textStyles': textStyles?.toJson(),
      'isHidden': isHidden,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Create from JSON
  factory MasterLayout.fromJson(Map<String, dynamic> json) {
    return MasterLayout(
      id: json['id'] as String,
      name: json['name'] as String,
      type: MasterLayoutType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => MasterLayoutType.custom,
      ),
      placeholders: (json['placeholders'] as List<dynamic>)
          .map((p) => Component.fromJson(p))
          .toList(),
      background: json['background'] as Map<String, dynamic>? ?? {},
      textStyles: json['textStyles'] != null
          ? TextStyleDefaults.fromJson(json['textStyles'])
          : null,
      isHidden: json['isHidden'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  /// Get default placeholder positions based on layout type
  static List<Component> getDefaultPlaceholdersForType(MasterLayoutType type) {
    switch (type) {
      case MasterLayoutType.titleSlide:
        return [
          Component(
            id: 'title_placeholder',
            type: ComponentType.text,
            x: 100,
            y: 150,
            width: 760,
            height: 120,
            text: TextContent(
              content: 'Click to add title',
              style: TextStyleModel(fontSize: 44, isBold: true),
            ),
            isPlaceholder: true,
            placeholderType: PlaceholderType.title,
          ),
          Component(
            id: 'subtitle_placeholder',
            type: ComponentType.text,
            x: 100,
            y: 300,
            width: 760,
            height: 80,
            text: TextContent(
              content: 'Click to add subtitle',
              style: TextStyleModel(fontSize: 24),
            ),
            isPlaceholder: true,
            placeholderType: PlaceholderType.subtitle,
          ),
        ];

      case MasterLayoutType.titleAndContent:
        return [
          Component(
            id: 'title_placeholder',
            type: ComponentType.text,
            x: 100,
            y: 50,
            width: 760,
            height: 80,
            text: TextContent(
              content: 'Click to add title',
              style: TextStyleModel(fontSize: 36, isBold: true),
            ),
            isPlaceholder: true,
            placeholderType: PlaceholderType.title,
          ),
          Component(
            id: 'content_placeholder',
            type: ComponentType.text,
            x: 100,
            y: 150,
            width: 760,
            height: 400,
            text: TextContent(
              content: 'Click to add content',
              style: TextStyleModel(fontSize: 18),
            ),
            isPlaceholder: true,
            placeholderType: PlaceholderType.content,
          ),
        ];

      case MasterLayoutType.twoContent:
        return [
          Component(
            id: 'title_placeholder',
            type: ComponentType.text,
            x: 100,
            y: 50,
            width: 760,
            height: 80,
            text: TextContent(
              content: 'Click to add title',
              style: TextStyleModel(fontSize: 36, isBold: true),
            ),
            isPlaceholder: true,
            placeholderType: PlaceholderType.title,
          ),
          Component(
            id: 'left_content',
            type: ComponentType.text,
            x: 100,
            y: 150,
            width: 360,
            height: 400,
            text: TextContent(
              content: 'Click to add content',
              style: TextStyleModel(fontSize: 18),
            ),
            isPlaceholder: true,
            placeholderType: PlaceholderType.content,
          ),
          Component(
            id: 'right_content',
            type: ComponentType.text,
            x: 500,
            y: 150,
            width: 360,
            height: 400,
            text: TextContent(
              content: 'Click to add content',
              style: TextStyleModel(fontSize: 18),
            ),
            isPlaceholder: true,
            placeholderType: PlaceholderType.content,
          ),
        ];

      case MasterLayoutType.blank:
        return [];

      default:
        return [
          Component(
            id: 'default_placeholder',
            type: ComponentType.text,
            x: 100,
            y: 100,
            width: 760,
            height: 450,
            text: TextContent(
              content: 'Click to add content',
              style: TextStyleModel(fontSize: 18),
            ),
            isPlaceholder: true,
            placeholderType: PlaceholderType.content,
          ),
        ];
    }
  }
}

/// Default text styles for a master slide
class TextStyleDefaults {
  final TextStyleModel titleStyle;
  final TextStyleModel bodyStyle;
  final TextStyleModel accentStyle;
  final List<ColorSchemeLevel> colorLevels;

  TextStyleDefaults({
    required this.titleStyle,
    required this.bodyStyle,
    required this.accentStyle,
    this.colorLevels = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'titleStyle': titleStyle.toJson(),
      'bodyStyle': bodyStyle.toJson(),
      'accentStyle': accentStyle.toJson(),
      'colorLevels': colorLevels.map((c) => c.toJson()).toList(),
    };
  }

  factory TextStyleDefaults.fromJson(Map<String, dynamic> json) {
    return TextStyleDefaults(
      titleStyle: TextStyleModel.fromJson(json['titleStyle']),
      bodyStyle: TextStyleModel.fromJson(json['bodyStyle']),
      accentStyle: TextStyleModel.fromJson(json['accentStyle']),
      colorLevels: (json['colorLevels'] as List<dynamic>?)
              ?.map((c) => ColorSchemeLevel.fromJson(c))
              .toList() ??
          [],
    );
  }
}

/// Color scheme level for hierarchical coloring
class ColorSchemeLevel {
  final String name;
  final String colorHex;
  final int level;

  ColorSchemeLevel({
    required this.name,
    required this.colorHex,
    required this.level,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'colorHex': colorHex,
      'level': level,
    };
  }

  factory ColorSchemeLevel.fromJson(Map<String, dynamic> json) {
    return ColorSchemeLevel(
      name: json['name'] as String,
      colorHex: json['colorHex'] as String,
      level: json['level'] as int,
    );
  }
}

/// Represents the Master Slide (parent of all layouts)
class MasterSlide {
  final String id;
  final String name;
  final List<MasterLayout> layouts;
  final Map<String, dynamic> background;
  final TextStyleDefaults? textStyles;
  final ThemeData? theme;
  final DateTime createdAt;
  final DateTime updatedAt;

  MasterSlide({
    required this.id,
    required this.name,
    this.layouts = const [],
    this.background = const {},
    this.textStyles,
    this.theme,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  MasterSlide copyWith({
    String? name,
    List<MasterLayout>? layouts,
    Map<String, dynamic>? background,
    TextStyleDefaults? textStyles,
    ThemeData? theme,
    DateTime? updatedAt,
  }) {
    return MasterSlide(
      id: id,
      name: name ?? this.name,
      layouts: layouts ?? this.layouts,
      background: background ?? this.background,
      textStyles: textStyles ?? this.textStyles,
      theme: theme ?? this.theme,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'layouts': layouts.map((l) => l.toJson()).toList(),
      'background': background,
      'textStyles': textStyles?.toJson(),
      'theme': theme?.toJson(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory MasterSlide.fromJson(Map<String, dynamic> json) {
    return MasterSlide(
      id: json['id'] as String,
      name: json['name'] as String,
      layouts: (json['layouts'] as List<dynamic>)
          .map((l) => MasterLayout.fromJson(l))
          .toList(),
      background: json['background'] as Map<String, dynamic>? ?? {},
      textStyles: json['textStyles'] != null
          ? TextStyleDefaults.fromJson(json['textStyles'])
          : null,
      theme: json['theme'] != null ? ThemeData.fromJson(json['theme']) : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  /// Create a default master slide with standard layouts
  static MasterSlide createDefault() {
    return MasterSlide(
      id: 'default_master',
      name: 'Office Theme',
      layouts: [
        MasterLayout(
          id: 'title_layout',
          name: 'Title Slide',
          type: MasterLayoutType.titleSlide,
          placeholders: MasterLayout.getDefaultPlaceholdersForType(
              MasterLayoutType.titleSlide),
        ),
        MasterLayout(
          id: 'title_content_layout',
          name: 'Title and Content',
          type: MasterLayoutType.titleAndContent,
          placeholders: MasterLayout.getDefaultPlaceholdersForType(
              MasterLayoutType.titleAndContent),
        ),
        MasterLayout(
          id: 'section_header_layout',
          name: 'Section Header',
          type: MasterLayoutType.sectionHeader,
          placeholders: MasterLayout.getDefaultPlaceholdersForType(
              MasterLayoutType.sectionHeader),
        ),
        MasterLayout(
          id: 'two_content_layout',
          name: 'Two Content',
          type: MasterLayoutType.twoContent,
          placeholders: MasterLayout.getDefaultPlaceholdersForType(
              MasterLayoutType.twoContent),
        ),
        MasterLayout(
          id: 'blank_layout',
          name: 'Blank',
          type: MasterLayoutType.blank,
          placeholders: MasterLayout.getDefaultPlaceholdersForType(
              MasterLayoutType.blank),
        ),
      ],
      background: {
        'type': 'solid',
        'color': '#FFFFFF',
      },
      textStyles: TextStyleDefaults(
        titleStyle: TextStyleModel(
          fontFamily: 'Arial',
          fontSize: 44,
          isBold: true,
          color: '#1A1A1A',
        ),
        bodyStyle: TextStyleModel(
          fontFamily: 'Arial',
          fontSize: 18,
          color: '#333333',
        ),
        accentStyle: TextStyleModel(
          fontFamily: 'Arial',
          fontSize: 24,
          isBold: true,
          color: '#0066CC',
        ),
      ),
    );
  }
}
