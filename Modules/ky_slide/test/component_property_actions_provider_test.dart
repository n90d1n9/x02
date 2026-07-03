import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ky_slide/models/component.dart';
import 'package:ky_slide/models/object_style_preset.dart';
import 'package:ky_slide/models/presentation.dart';
import 'package:ky_slide/models/presentation_component.dart';
import 'package:ky_slide/models/rich_text_content.dart';
import 'package:ky_slide/models/slide.dart';
import 'package:ky_slide/models/style/presentation_theme.dart';
import 'package:ky_slide/models/text_paragraph_format.dart';
import 'package:ky_slide/models/text_style_preset.dart';
import 'package:ky_slide/states/component_property_actions_provider.dart';
import 'package:ky_slide/states/component_provider.dart';
import 'package:ky_slide/states/history_provider.dart';
import 'package:ky_slide/states/presentation_provider.dart';

void main() {
  test('updates selected component properties with history labels', () {
    final container = _container();
    addTearDown(container.dispose);
    container.read(selectedComponentProvider.notifier).state = 'title';

    final actions = container.read(componentPropertyActionsProvider);

    expect(actions.renameSelectedLayer('Hero title'), isTrue);
    expect(_component(container, 'title').layerName, 'Hero title');
    expect(container.read(historyProvider).undoLabel, 'Rename layer');

    expect(
      actions.updateSelectedFrame(
        x: 80,
        y: 90,
        width: 420,
        height: 140,
        rotation: 15,
      ),
      isTrue,
    );
    var component = _component(container, 'title');
    expect(component.position, const Offset(80, 90));
    expect(component.size, const Size(420, 140));
    expect(component.rotation, 15);
    expect(container.read(historyProvider).undoLabel, 'Update layer frame');

    expect(actions.updateSelectedOpacity(0.42), isTrue);
    expect(_component(container, 'title').opacity, closeTo(0.42, 0.001));
    expect(container.read(historyProvider).undoLabel, 'Update layer opacity');

    expect(actions.updateSelectedFillColor(const Color(0xFF14B8A6)), isTrue);
    expect(
      _component(container, 'title').backgroundColor,
      const Color(0xFF14B8A6),
    );
    expect(container.read(historyProvider).undoLabel, 'Update layer fill');

    expect(actions.clearSelectedFillColor(), isTrue);
    expect(_component(container, 'title').backgroundColor, isNull);
    expect(container.read(historyProvider).undoLabel, 'Update layer fill');

    expect(
      actions.updateSelectedBorder(color: const Color(0xFFF59E0B), width: 2),
      isTrue,
    );
    component = _component(container, 'title');
    expect(component.border?.color, const Color(0xFFF59E0B));
    expect(component.border?.width, 2);
    expect(container.read(historyProvider).undoLabel, 'Update layer border');

    expect(actions.clearSelectedBorder(), isTrue);
    expect(_component(container, 'title').border, isNull);
    expect(container.read(historyProvider).undoLabel, 'Update layer border');

    expect(actions.updateSelectedGlow(enabled: true), isTrue);
    component = _component(container, 'title');
    expect(component.hasGlow, isTrue);
    expect(component.glowColor, const Color(0xFF2563EB));
    expect(container.read(historyProvider).undoLabel, 'Update layer glow');

    expect(actions.updateSelectedGlow(color: const Color(0xFFF59E0B)), isTrue);
    component = _component(container, 'title');
    expect(component.hasGlow, isTrue);
    expect(component.glowColor, const Color(0xFFF59E0B));
    expect(container.read(historyProvider).undoLabel, 'Update layer glow');

    expect(actions.updateSelectedGlow(enabled: false), isTrue);
    component = _component(container, 'title');
    expect(component.hasGlow, isFalse);
    expect(component.glowColor, isNull);
    expect(container.read(historyProvider).undoLabel, 'Update layer glow');

    expect(actions.updateSelectedGlow(color: const Color(0xFFF59E0B)), isTrue);
    component = _component(container, 'title');
    expect(component.hasGlow, isTrue);
    expect(component.glowColor, const Color(0xFFF59E0B));
    expect(container.read(historyProvider).undoLabel, 'Update layer glow');

    expect(
      actions.applySelectedObjectStylePreset(ObjectStylePreset.soft),
      isTrue,
    );
    component = _component(container, 'title');
    expect(
      component.backgroundColor,
      const Color(0xFF14B8A6).withValues(alpha: 0.18),
    );
    expect(
      component.border?.color,
      const Color(0xFF2563EB).withValues(alpha: 0.42),
    );
    expect(component.border?.width, 1.5);
    expect(component.hasGlow, isTrue);
    expect(component.glowColor, const Color(0xFF14B8A6));
    expect(container.read(historyProvider).undoLabel, 'Apply object preset');

    expect(
      actions.updateSelectedTextStyle(
        color: const Color(0xFF38BDF8),
        highlightColor: const Color(0xFFFFF3BF),
        fontSize: 44,
        fontFamily: 'Poppins',
        lineHeight: 1.5,
        letterSpacing: 1.5,
        isBold: true,
        isItalic: true,
        isUnderline: true,
        isStrikethrough: true,
        alignment: TextAlign.center,
      ),
      isTrue,
    );
    final richText = _component(container, 'title').richText;
    expect(richText?.style.color, const Color(0xFF38BDF8));
    expect(richText?.style.backgroundColor, const Color(0xFFFFF3BF));
    expect(richText?.style.fontSize, 44);
    expect(richText?.style.fontFamily, 'Poppins');
    expect(richText?.style.height, 1.5);
    expect(richText?.style.letterSpacing, 1.5);
    expect(richText?.isBold, isTrue);
    expect(richText?.isItalic, isTrue);
    expect(richText?.isUnderline, isTrue);
    expect(richText?.isStrikethrough, isTrue);
    expect(richText?.alignment, TextAlign.center);
    expect(richText?.effectiveStyle.fontWeight, FontWeight.w700);
    expect(richText?.effectiveStyle.fontStyle, FontStyle.italic);
    expect(
      richText?.effectiveStyle.decoration,
      TextDecoration.combine([
        TextDecoration.underline,
        TextDecoration.lineThrough,
      ]),
    );
    expect(container.read(historyProvider).undoLabel, 'Update text style');

    expect(actions.updateSelectedTextStyle(clearHighlight: true), isTrue);
    expect(
      _component(container, 'title').richText?.style.backgroundColor,
      isNull,
    );
    expect(container.read(historyProvider).undoLabel, 'Update text style');

    expect(actions.applySelectedTextStylePreset(TextStylePreset.quote), isTrue);
    final presetText = _component(container, 'title').richText;
    expect(presetText?.style.fontSize, 28);
    expect(presetText?.style.fontStyle, FontStyle.italic);
    expect(presetText?.isItalic, isTrue);
    expect(presetText?.isUnderline, isFalse);
    expect(presetText?.isStrikethrough, isFalse);
    expect(container.read(historyProvider).undoLabel, 'Apply text preset');

    expect(
      actions.applySelectedParagraphListStyle(TextParagraphListStyle.bullet),
      isTrue,
    );
    expect(_component(container, 'title').richText?.text, '- Quarterly update');
    expect(container.read(historyProvider).undoLabel, 'Format paragraph');

    expect(
      actions.adjustSelectedTextIndent(TextIndentDirection.increase),
      isTrue,
    );
    expect(
      _component(container, 'title').richText?.text,
      '  - Quarterly update',
    );
    expect(
      container.read(historyProvider).undoLabel,
      'Update paragraph indent',
    );

    expect(actions.applySelectedTextCase(TextCaseTransform.uppercase), isTrue);
    expect(
      _component(container, 'title').richText?.text,
      '  - QUARTERLY UPDATE',
    );
    expect(container.read(historyProvider).undoLabel, 'Change text case');
  });

  test('ignores stale and locked selections for editable properties', () {
    final container = _container();
    addTearDown(container.dispose);
    container.read(selectedComponentProvider.notifier).state = 'missing';

    var actions = container.read(componentPropertyActionsProvider);
    expect(actions.selectedComponent, isNull);
    expect(actions.updateSelectedOpacity(0.4), isFalse);
    expect(container.read(historyProvider).entries, isEmpty);

    container.read(selectedComponentProvider.notifier).state = 'title';
    actions = container.read(componentPropertyActionsProvider);

    expect(actions.setSelectedLocked(true), isTrue);
    final historyLength = container.read(historyProvider).entries.length;
    expect(actions.updateSelectedFrame(x: 200), isFalse);
    expect(actions.updateSelectedFillColor(Colors.red), isFalse);
    expect(actions.clearSelectedFillColor(), isFalse);
    expect(actions.updateSelectedBorder(width: 4), isFalse);
    expect(actions.clearSelectedBorder(), isFalse);
    expect(actions.updateSelectedGlow(enabled: true), isFalse);
    expect(
      actions.applySelectedObjectStylePreset(ObjectStylePreset.filled),
      isFalse,
    );
    expect(actions.updateSelectedTextStyle(fontSize: 32), isFalse);
    expect(
      actions.applySelectedParagraphListStyle(TextParagraphListStyle.bullet),
      isFalse,
    );
    expect(
      actions.applySelectedTextStylePreset(TextStylePreset.title),
      isFalse,
    );
    expect(
      actions.adjustSelectedTextIndent(TextIndentDirection.increase),
      isFalse,
    );
    expect(actions.applySelectedTextCase(TextCaseTransform.uppercase), isFalse);
    expect(container.read(historyProvider).entries.length, historyLength);
    expect(_component(container, 'title').position, const Offset(40, 40));
    expect(_component(container, 'title').backgroundColor, isNull);

    expect(actions.setSelectedLocked(false), isTrue);
    expect(actions.setSelectedVisibility(false), isTrue);
    expect(_component(container, 'title').isVisible, isFalse);
    expect(container.read(historyProvider).undoLabel, 'Hide layer');
  });
}

ProviderContainer _container() {
  return ProviderContainer(
    overrides: [
      presentationProvider.overrideWith(
        (ref) => PresentationNotifier(initialPresentation: _presentation()),
      ),
    ],
  );
}

Presentation _presentation() {
  return Presentation(
    id: 'property-actions-test',
    title: 'Property Actions Test',
    slides: [
      Slide(
        id: 'slide',
        components: [
          PresentationComponent(
            id: 'title',
            type: ComponentType.richText,
            position: const Offset(40, 40),
            size: const Size(240, 80),
            zIndex: 1,
            richText: RichTextContent(
              text: 'Quarterly update',
              style: const TextStyle(color: Colors.white, fontSize: 24),
            ),
          ),
        ],
      ),
    ],
    theme: PresentationTheme(
      id: 'test-theme',
      name: 'Test Theme',
      primaryColor: const Color(0xFF2563EB),
      secondaryColor: const Color(0xFF14B8A6),
      backgroundColor: const Color(0xFF0F172A),
      textColor: Colors.white,
      titleStyle: const TextStyle(color: Colors.white, fontSize: 48),
      bodyStyle: const TextStyle(color: Colors.white70, fontSize: 20),
      colorPalette: const [Color(0xFF2563EB), Color(0xFF14B8A6)],
    ),
    slideSize: const Size(1000, 600),
  );
}

PresentationComponent _component(ProviderContainer container, String id) {
  final presentation = container.read(presentationProvider);
  return presentation.slides[presentation.currentSlideIndex].components
      .firstWhere((component) => component.id == id);
}
