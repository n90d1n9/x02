import 'package:flutter_test/flutter_test.dart';
import 'package:ky_docs/docx/widgets/formatting/document_style_preset.dart';

void main() {
  group('DocumentStylePresetCatalog', () {
    test('should have 14 preset styles', () {
      expect(DocumentStylePresetCatalog.presets.length, 14);
    });

    test('should include all heading levels 1-6', () {
      final headings = DocumentStylePresetCatalog.presets
          .where((p) => p.headerLevel != null)
          .toList();
      
      expect(headings.length, 8); // Title, Subtitle, H1-H6
      
      final headingLevels = headings.map((h) => h.headerLevel).toSet();
      expect(headingLevels.contains(1), true);
      expect(headingLevels.contains(2), true);
      expect(headingLevels.contains(3), true);
      expect(headingLevels.contains(4), true);
      expect(headingLevels.contains(5), true);
      expect(headingLevels.contains(6), true);
    });

    test('should include special styles', () {
      final ids = DocumentStylePresetCatalog.presets.map((p) => p.id).toSet();
      
      expect(ids.contains(DocumentStylePresetId.normal), true);
      expect(ids.contains(DocumentStylePresetId.noSpacing), true);
      expect(ids.contains(DocumentStylePresetId.title), true);
      expect(ids.contains(DocumentStylePresetId.subtitle), true);
      expect(ids.contains(DocumentStylePresetId.quote), true);
      expect(ids.contains(DocumentStylePresetId.caption), true);
      expect(ids.contains(DocumentStylePresetId.code), true);
      expect(ids.contains(DocumentStylePresetId.listParagraph), true);
    });

    test('all presets should have required fields', () {
      for (final preset in DocumentStylePresetCatalog.presets) {
        expect(preset.label.isNotEmpty, true);
        expect(preset.sampleText.isNotEmpty, true);
        expect(preset.description.isNotEmpty, true);
      }
    });
  });

  group('DocumentStylePresetId enum', () {
    test('should have all expected values', () {
      final values = DocumentStylePresetId.values;
      
      expect(values.contains(DocumentStylePresetId.normal), true);
      expect(values.contains(DocumentStylePresetId.noSpacing), true);
      expect(values.contains(DocumentStylePresetId.title), true);
      expect(values.contains(DocumentStylePresetId.subtitle), true);
      expect(values.contains(DocumentStylePresetId.heading1), true);
      expect(values.contains(DocumentStylePresetId.heading2), true);
      expect(values.contains(DocumentStylePresetId.heading3), true);
      expect(values.contains(DocumentStylePresetId.heading4), true);
      expect(values.contains(DocumentStylePresetId.heading5), true);
      expect(values.contains(DocumentStylePresetId.heading6), true);
      expect(values.contains(DocumentStylePresetId.quote), true);
      expect(values.contains(DocumentStylePresetId.caption), true);
      expect(values.contains(DocumentStylePresetId.code), true);
      expect(values.contains(DocumentStylePresetId.listParagraph), true);
    });

    test('should have 14 values', () {
      expect(DocumentStylePresetId.values.length, 14);
    });
  });

  group('DocumentStylePreset constructor', () {
    test('should create preset with custom attributes', () {
      const customAttributes = {'fontSize': 14, 'fontFamily': 'Arial'};
      
      const preset = DocumentStylePreset(
        id: DocumentStylePresetId.normal,
        label: 'Custom Style',
        sampleText: 'Aa',
        description: 'Custom style',
        icon: Icons.star,
        isCustom: true,
        customAttributes: customAttributes,
      );

      expect(preset.isCustom, true);
      expect(preset.customAttributes, equals(customAttributes));
    });

    test('should default isCustom to false', () {
      const preset = DocumentStylePreset(
        id: DocumentStylePresetId.normal,
        label: 'Normal',
        sampleText: 'Aa',
        description: 'Normal style',
        icon: Icons.notes_outlined,
      );

      expect(preset.isCustom, false);
      expect(preset.customAttributes, isNull);
    });
  });
}
