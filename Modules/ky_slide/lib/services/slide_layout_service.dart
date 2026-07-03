import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../models/component.dart';
import '../models/presentation.dart';
import '../models/presentation_component.dart';
import '../models/rich_text_content.dart';
import '../models/slide.dart';
import '../models/slide_layout.dart';

class SlideLayoutService {
  const SlideLayoutService._();

  static List<SlideLayoutRecipe> get recipes => SlideLayoutCatalog.recipes;

  static SlideLayoutRecipe recipeFor(SlideLayoutType type) {
    return recipes.firstWhere((recipe) => recipe.type == type);
  }

  static Slide createSlide({
    required SlideLayoutType type,
    required Presentation presentation,
  }) {
    final recipe = recipeFor(type);
    final theme = presentation.theme;

    return Slide(
      id: const Uuid().v4(),
      title: recipe.name,
      backgroundColor: theme.backgroundColor,
      components: _componentsFor(type, presentation),
    );
  }

  static List<PresentationComponent> _componentsFor(
    SlideLayoutType type,
    Presentation presentation,
  ) {
    switch (type) {
      case SlideLayoutType.blank:
        return const [];
      case SlideLayoutType.title:
        return [
          _title(
            presentation,
            text: 'Click to add title',
            position: _offset(presentation.slideSize, 0.12, 0.31),
            size: _size(presentation.slideSize, 0.76, 0.15),
            alignment: TextAlign.center,
            zIndex: 1,
          ),
          _body(
            presentation,
            text: 'Click to add subtitle',
            position: _offset(presentation.slideSize, 0.18, 0.49),
            size: _size(presentation.slideSize, 0.64, 0.1),
            alignment: TextAlign.center,
            zIndex: 2,
          ),
        ];
      case SlideLayoutType.titleAndContent:
        return [
          _title(
            presentation,
            text: 'Click to add title',
            position: _offset(presentation.slideSize, 0.08, 0.08),
            size: _size(presentation.slideSize, 0.84, 0.12),
            zIndex: 1,
          ),
          _body(
            presentation,
            text: 'Click to add text',
            position: _offset(presentation.slideSize, 0.09, 0.27),
            size: _size(presentation.slideSize, 0.82, 0.58),
            zIndex: 2,
          ),
        ];
      case SlideLayoutType.twoColumn:
        return [
          _title(
            presentation,
            text: 'Click to add title',
            position: _offset(presentation.slideSize, 0.08, 0.08),
            size: _size(presentation.slideSize, 0.84, 0.12),
            zIndex: 1,
          ),
          _body(
            presentation,
            text: 'Left column',
            position: _offset(presentation.slideSize, 0.08, 0.29),
            size: _size(presentation.slideSize, 0.4, 0.56),
            zIndex: 2,
          ),
          _body(
            presentation,
            text: 'Right column',
            position: _offset(presentation.slideSize, 0.52, 0.29),
            size: _size(presentation.slideSize, 0.4, 0.56),
            zIndex: 3,
          ),
        ];
      case SlideLayoutType.sectionHeader:
        return [
          _title(
            presentation,
            text: 'Click to add section title',
            position: _offset(presentation.slideSize, 0.13, 0.33),
            size: _size(presentation.slideSize, 0.74, 0.14),
            alignment: TextAlign.center,
            zIndex: 1,
          ),
          _body(
            presentation,
            text: 'Click to add section context',
            position: _offset(presentation.slideSize, 0.18, 0.5),
            size: _size(presentation.slideSize, 0.64, 0.1),
            alignment: TextAlign.center,
            zIndex: 2,
          ),
        ];
      case SlideLayoutType.comparison:
        return [
          _title(
            presentation,
            text: 'Click to add title',
            position: _offset(presentation.slideSize, 0.08, 0.08),
            size: _size(presentation.slideSize, 0.84, 0.12),
            zIndex: 1,
          ),
          _body(
            presentation,
            text: 'Option A',
            position: _offset(presentation.slideSize, 0.08, 0.27),
            size: _size(presentation.slideSize, 0.4, 0.12),
            zIndex: 2,
          ),
          _body(
            presentation,
            text: 'Option B',
            position: _offset(presentation.slideSize, 0.52, 0.27),
            size: _size(presentation.slideSize, 0.4, 0.12),
            zIndex: 3,
          ),
          _body(
            presentation,
            text: 'Click to add details',
            position: _offset(presentation.slideSize, 0.08, 0.43),
            size: _size(presentation.slideSize, 0.4, 0.42),
            zIndex: 4,
          ),
          _body(
            presentation,
            text: 'Click to add details',
            position: _offset(presentation.slideSize, 0.52, 0.43),
            size: _size(presentation.slideSize, 0.4, 0.42),
            zIndex: 5,
          ),
        ];
    }
  }

  static PresentationComponent _title(
    Presentation presentation, {
    required String text,
    required Offset position,
    required Size size,
    required int zIndex,
    TextAlign alignment = TextAlign.left,
  }) {
    final theme = presentation.theme;

    return _textBox(
      text: text,
      position: position,
      size: size,
      style: theme.titleStyle.copyWith(
        color: theme.textColor,
        fontSize: 48,
        fontWeight: FontWeight.w800,
        letterSpacing: 0,
      ),
      alignment: alignment,
      borderColor: theme.primaryColor,
      zIndex: zIndex,
      layerName: 'Title Placeholder',
    );
  }

  static PresentationComponent _body(
    Presentation presentation, {
    required String text,
    required Offset position,
    required Size size,
    required int zIndex,
    TextAlign alignment = TextAlign.left,
  }) {
    final theme = presentation.theme;

    return _textBox(
      text: text,
      position: position,
      size: size,
      style: theme.bodyStyle.copyWith(
        color: theme.textColor.withValues(alpha: 0.72),
        fontSize: 26,
        height: 1.28,
        letterSpacing: 0,
      ),
      alignment: alignment,
      borderColor: theme.secondaryColor,
      zIndex: zIndex,
      layerName: 'Content Placeholder',
    );
  }

  static PresentationComponent _textBox({
    required String text,
    required Offset position,
    required Size size,
    required TextStyle style,
    required TextAlign alignment,
    required Color borderColor,
    required int zIndex,
    required String layerName,
  }) {
    return PresentationComponent(
      id: const Uuid().v4(),
      type: ComponentType.richText,
      position: position,
      size: size,
      layerName: layerName,
      richText: RichTextContent(text: text, style: style, alignment: alignment),
      backgroundColor: Colors.white.withValues(alpha: 0.035),
      border: BorderSide(
        color: borderColor.withValues(alpha: 0.28),
        width: 1.2,
      ),
      zIndex: zIndex,
    );
  }

  static Offset _offset(Size size, double x, double y) {
    return Offset(size.width * x, size.height * y);
  }

  static Size _size(Size size, double width, double height) {
    return Size(size.width * width, size.height * height);
  }
}
