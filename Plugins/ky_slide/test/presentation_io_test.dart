import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ky_slide/models/component.dart';
import 'package:ky_slide/models/presentation.dart';
import 'package:ky_slide/models/presentation_component.dart';
import 'package:ky_slide/models/presentation_file_format.dart';
import 'package:ky_slide/models/rich_text_content.dart';
import 'package:ky_slide/models/slide.dart';
import 'package:ky_slide/models/style/presentation_theme.dart';
import 'package:ky_slide/services/presentation_io/pptx_export_service.dart';
import 'package:ky_slide/services/presentation_io/pptx_import_service.dart';
import 'package:ky_slide/services/presentation_io/presentation_file_capability_service.dart';

void main() {
  test(
    'file capability service describes native PPTX and legacy PPT paths',
    () {
      const service = PresentationFileCapabilityService();

      final pptxExport = service.capabilityFor(
        PresentationFileOperation.export,
        PresentationFileFormat.pptx,
      );
      final pptImport = service.capabilityFor(
        PresentationFileOperation.import,
        PresentationFileFormat.ppt,
      );

      expect(pptxExport.isNative, isTrue);
      expect(pptxExport.title, 'Export PPTX');
      expect(pptImport.support, PresentationFileSupport.converterRequired);
    },
  );

  test('pptx export creates an OpenXML package that can be imported', () {
    const exporter = PptxExportService();
    const importer = PptxImportService();
    final bytes = exporter.exportBytes(_presentation());
    final archive = ZipDecoder().decodeBytes(bytes);

    expect(archive.findFile('[Content_Types].xml'), isNotNull);
    expect(archive.findFile('ppt/presentation.xml'), isNotNull);
    expect(archive.findFile('ppt/slides/slide1.xml'), isNotNull);
    expect(archive.findFile('ppt/slides/slide2.xml'), isNotNull);
    expect(archive.findFile('ppt/media/image1.png'), isNotNull);
    expect(archive.findFile('ppt/notesSlides/notesSlide1.xml'), isNotNull);
    expect(archive.findFile('ppt/notesSlides/notesSlide2.xml'), isNull);
    final slideXml = String.fromCharCodes(
      archive.findFile('ppt/slides/slide1.xml')!.content,
    );
    expect(slideXml, contains('rot="900000"'));
    _expectBefore(slideXml, 'name="Rectangle 2"', 'name="Triangle 3"');
    _expectBefore(slideXml, 'name="Triangle 3"', 'name="Picture 4"');
    _expectBefore(slideXml, 'name="Picture 4"', 'name="Revenue headline"');
    _expectBefore(slideXml, 'name="Revenue headline"', 'name="Ellipse 6"');
    expect(slideXml, contains('<a:alpha val="72000"/>'));
    expect(slideXml, contains('<a:alphaModFix amt="45000"/>'));
    expect(slideXml, contains('<a:alpha val="60000"/>'));
    expect(slideXml, contains('<a:buChar char="&#8226;"/>'));
    expect(
      slideXml,
      contains('<a:buAutoNum type="arabicPeriod" startAt="1"/>'),
    );
    expect(slideXml, contains('<a:t>Revenue improved</a:t>'));
    expect(slideXml, contains('<a:t>Launch pilot</a:t>'));
    expect(slideXml, contains('<a:lnSpc><a:spcPct val="130000"/></a:lnSpc>'));
    expect(slideXml, contains('<a:latin typeface="Poppins"/>'));
    expect(slideXml, contains('spc="1500"'));
    expect(slideXml, contains('strike="sngStrike"'));
    expect(
      slideXml,
      contains('<a:highlight><a:srgbClr val="FFF3BF"/></a:highlight>'),
    );
    expect(slideXml, isNot(contains('Hidden export marker')));

    final imported = importer.importBytes(
      Uint8List.fromList(bytes),
      title: 'Round Trip',
    );

    expect(imported.title, 'Round Trip');
    expect(imported.slides, hasLength(2));
    expect(imported.slides.first.backgroundColor, const Color(0xFFF8FAFC));
    expect(imported.slides.first.notes, 'Discuss risks\nConfirm owners');
    final importedTextComponent = imported.slides.first.components.firstWhere(
      (component) => component.type == ComponentType.richText,
    );
    final importedText = importedTextComponent.richText;
    expect(
      importedText?.text,
      'Quarterly <story>\n- Revenue improved\n1. Launch pilot',
    );
    expect(importedText?.style.color, const Color(0xFF111827));
    expect(importedText?.style.fontSize, 44);
    expect(importedText?.style.fontFamily, 'Poppins');
    expect(importedText?.style.height, 1.3);
    expect(importedText?.style.letterSpacing, 1.5);
    expect(importedText?.style.backgroundColor, const Color(0xFFFFF3BF));
    expect(importedText?.isBold, isTrue);
    expect(importedText?.isItalic, isTrue);
    expect(importedText?.isUnderline, isTrue);
    expect(importedText?.isStrikethrough, isTrue);
    expect(importedText?.alignment, TextAlign.center);
    expect(importedTextComponent.rotation, 15);
    expect(importedTextComponent.opacity, closeTo(0.72, 0.001));
    expect(importedTextComponent.layerName, 'Revenue headline');
    final importedImage = imported.slides.first.components.firstWhere(
      (component) => component.type == ComponentType.image,
    );
    expect(importedImage.imageData, _pngBytes);
    expect(importedImage.rotation, -12.5);
    expect(importedImage.opacity, closeTo(0.45, 0.001));
    final importedTypes = imported.slides.first.components.map(
      (component) => component.type,
    );
    expect(
      importedTypes,
      containsAll([
        ComponentType.shape,
        ComponentType.circle,
        ComponentType.triangle,
      ]),
    );
    final importedCircle = imported.slides.first.components.firstWhere(
      (component) => component.type == ComponentType.circle,
    );
    expect(importedCircle.backgroundColor, const Color(0xFF14B8A6));
    expect(importedCircle.border?.color, const Color(0xFF0F172A));
    expect(importedCircle.rotation, 30);
    expect(importedCircle.opacity, closeTo(0.6, 0.001));
    final nextStepsText = imported.slides.last.components.firstWhere(
      (component) => component.type == ComponentType.richText,
    );
    expect(nextStepsText.richText?.text, 'Next steps');
  });
}

void _expectBefore(String value, String first, String second) {
  final firstIndex = value.indexOf(first);
  final secondIndex = value.indexOf(second);

  expect(firstIndex, isNot(-1), reason: '$first was not found');
  expect(secondIndex, isNot(-1), reason: '$second was not found');
  expect(firstIndex, lessThan(secondIndex));
}

Presentation _presentation() {
  return Presentation(
    id: 'io-test',
    title: 'Board Review',
    theme: _theme(),
    slides: [
      _slide(
        id: 'slide-1',
        title: 'Quarterly story',
        text: 'Quarterly <story>\n- Revenue improved\n1. Launch pilot',
        notes: 'Discuss risks\nConfirm owners',
      ),
      _slide(id: 'slide-2', title: 'Next steps', text: 'Next steps'),
    ],
  );
}

PresentationTheme _theme() {
  return PresentationTheme(
    id: 'io-test-theme',
    name: 'IO Test',
    primaryColor: const Color(0xFF2563EB),
    secondaryColor: const Color(0xFF14B8A6),
    backgroundColor: Colors.white,
    textColor: const Color(0xFF111827),
    titleStyle: const TextStyle(color: Color(0xFF111827), fontSize: 44),
    bodyStyle: const TextStyle(color: Color(0xFF334155), fontSize: 22),
    colorPalette: const [Color(0xFF2563EB), Color(0xFF14B8A6)],
  );
}

Slide _slide({
  required String id,
  required String title,
  required String text,
  String? notes,
}) {
  return Slide(
    id: id,
    title: title,
    notes: notes,
    backgroundColor: const Color(0xFFF8FAFC),
    components: [
      PresentationComponent(
        id: '$id-text',
        type: ComponentType.richText,
        position: const Offset(140, 120),
        size: const Size(820, 160),
        layerName: 'Revenue headline',
        rotation: 15,
        zIndex: 30,
        opacity: 0.72,
        richText: RichTextContent(
          text: text,
          style: const TextStyle(
            color: Color(0xFF111827),
            fontFamily: 'Poppins',
            fontSize: 44,
            height: 1.3,
            letterSpacing: 1.5,
            backgroundColor: Color(0xFFFFF3BF),
          ),
          isBold: true,
          isItalic: true,
          isUnderline: true,
          isStrikethrough: true,
          alignment: TextAlign.center,
        ),
      ),
      PresentationComponent(
        id: '$id-image',
        type: ComponentType.image,
        position: const Offset(1040, 180),
        size: const Size(360, 240),
        rotation: -12.5,
        zIndex: 20,
        opacity: 0.45,
        imageData: _pngBytes,
      ),
      PresentationComponent(
        id: '$id-rect',
        type: ComponentType.shape,
        position: const Offset(160, 360),
        size: const Size(260, 120),
        backgroundColor: const Color(0xFF2563EB),
        zIndex: 0,
      ),
      PresentationComponent(
        id: '$id-circle',
        type: ComponentType.circle,
        position: const Offset(460, 360),
        size: const Size(140, 140),
        backgroundColor: const Color(0xFF14B8A6),
        border: const BorderSide(color: Color(0xFF0F172A), width: 2),
        rotation: 30,
        zIndex: 40,
        opacity: 0.6,
      ),
      PresentationComponent(
        id: '$id-triangle',
        type: ComponentType.triangle,
        position: const Offset(660, 360),
        size: const Size(180, 150),
        backgroundColor: const Color(0xFFF59E0B),
        zIndex: 10,
      ),
      PresentationComponent(
        id: '$id-hidden',
        type: ComponentType.richText,
        position: const Offset(900, 500),
        size: const Size(260, 80),
        isVisible: false,
        richText: RichTextContent(
          text: 'Hidden export marker',
          style: const TextStyle(color: Color(0xFFEF4444), fontSize: 24),
        ),
      ),
    ],
  );
}

final Uint8List _pngBytes = Uint8List.fromList([
  0x89,
  0x50,
  0x4E,
  0x47,
  0x0D,
  0x0A,
  0x1A,
  0x0A,
  0x00,
  0x00,
  0x00,
  0x0D,
  0x49,
  0x48,
  0x44,
  0x52,
  0x00,
  0x00,
  0x00,
  0x01,
  0x00,
  0x00,
  0x00,
  0x01,
  0x08,
  0x06,
  0x00,
  0x00,
  0x00,
  0x1F,
  0x15,
  0xC4,
  0x89,
  0x00,
  0x00,
  0x00,
  0x0A,
  0x49,
  0x44,
  0x41,
  0x54,
  0x78,
  0x9C,
  0x63,
  0x00,
  0x01,
  0x00,
  0x00,
  0x05,
  0x00,
  0x01,
  0x0D,
  0x0A,
  0x2D,
  0xB4,
  0x00,
  0x00,
  0x00,
  0x00,
  0x49,
  0x45,
  0x4E,
  0x44,
  0xAE,
  0x42,
  0x60,
  0x82,
]);
