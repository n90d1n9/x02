import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:flutter_test/flutter_test.dart';
import 'package:ky_docs/docx/widgets/formatting/document_style_preset.dart';

void main() {
  group('DocumentStylePresetApplier', () {
    test('applies heading and quote presets to the current selection', () {
      final controller = _controllerWithText('Selected heading');
      addTearDown(controller.dispose);
      const applier = DocumentStylePresetApplier();

      applier.apply(
        controller: controller,
        preset: DocumentStylePresetCatalog.presets.firstWhere(
          (preset) => preset.id == DocumentStylePresetId.heading3,
        ),
      );

      expect(
        controller
            .getSelectionStyle()
            .attributes[quill.Attribute.header.key]
            ?.value,
        3,
      );

      applier.apply(
        controller: controller,
        preset: DocumentStylePresetCatalog.presets.firstWhere(
          (preset) => preset.id == DocumentStylePresetId.quote,
        ),
      );

      final style = controller.getSelectionStyle().attributes;
      expect(style.containsKey(quill.Attribute.header.key), isFalse);
      expect(style.containsKey(quill.Attribute.blockQuote.key), isTrue);
    });

    test('normal preset clears block-level styles', () {
      final controller = _controllerWithText('Selected heading');
      addTearDown(controller.dispose);
      const applier = DocumentStylePresetApplier();

      applier.apply(
        controller: controller,
        preset: DocumentStylePresetCatalog.presets.firstWhere(
          (preset) => preset.id == DocumentStylePresetId.quote,
        ),
      );
      applier.apply(
        controller: controller,
        preset: DocumentStylePresetCatalog.presets.firstWhere(
          (preset) => preset.id == DocumentStylePresetId.normal,
        ),
      );

      final style = controller.getSelectionStyle().attributes;
      expect(style.containsKey(quill.Attribute.header.key), isFalse);
      expect(style.containsKey(quill.Attribute.blockQuote.key), isFalse);
    });

    test('resolves one active preset for gallery and picker controls', () {
      final controller = _controllerWithText('Selected heading');
      addTearDown(controller.dispose);
      const applier = DocumentStylePresetApplier();

      applier.apply(
        controller: controller,
        preset: DocumentStylePresetCatalog.presets.firstWhere(
          (preset) => preset.id == DocumentStylePresetId.heading2,
        ),
      );

      expect(
        applier.activePreset(controller: controller).id,
        DocumentStylePresetId.heading2,
      );

      applier.apply(
        controller: controller,
        preset: DocumentStylePresetCatalog.presets.firstWhere(
          (preset) => preset.id == DocumentStylePresetId.quote,
        ),
      );

      expect(
        applier.activePreset(controller: controller).id,
        DocumentStylePresetId.quote,
      );
    });
  });
}

quill.QuillController _controllerWithText(String text) {
  final controller = quill.QuillController.basic();
  controller.document.insert(0, text);
  controller.updateSelection(
    TextSelection(baseOffset: 0, extentOffset: text.length),
    quill.ChangeSource.local,
  );
  return controller;
}
