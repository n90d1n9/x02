import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ky_docs/docx/models/page_settings.dart';
import 'package:ky_docs/docx/widgets/page_margin/document_page_margin_guide_geometry.dart';

void main() {
  group('DocumentPageMarginGuideGeometry', () {
    test('maps point margins into scaled surface positions', () {
      final geometry = DocumentPageMarginGuideGeometry.fromSettings(
        pageSettings: const PageSettings(
          margins: EdgeInsets.fromLTRB(72, 36, 54, 90),
        ),
        surfaceSize: const Size(297.5, 421),
      );

      expect(geometry.leftGuideX, closeTo(36, 0.01));
      expect(geometry.topGuideY, closeTo(18, 0.01));
      expect(geometry.rightGuideX, closeTo(270.5, 0.01));
      expect(geometry.bottomGuideY, closeTo(376, 0.01));
      expect(geometry.writingRect.width, closeTo(234.5, 0.01));
      expect(geometry.writingRect.height, closeTo(358, 0.01));
    });

    test('keeps an inspectable writing area when margins are extreme', () {
      final geometry = DocumentPageMarginGuideGeometry.fromSettings(
        pageSettings: const PageSettings(margins: EdgeInsets.all(10000)),
        surfaceSize: const Size(120, 80),
      );

      expect(geometry.leftGuideX, 96);
      expect(geometry.rightGuideX, 120);
      expect(geometry.topGuideY, 48);
      expect(geometry.bottomGuideY, 80);
      expect(
        geometry.writingRect.width,
        DocumentPageMarginGuideGeometry.minWritingWidth,
      );
      expect(
        geometry.writingRect.height,
        DocumentPageMarginGuideGeometry.minWritingHeight,
      );
    });
  });
}
