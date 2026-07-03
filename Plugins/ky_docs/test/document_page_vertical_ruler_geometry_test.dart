import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ky_docs/docx/widgets/ruler/document_page_ruler_geometry.dart';
import 'package:ky_docs/docx/widgets/ruler/document_page_vertical_ruler_geometry.dart';

void main() {
  group('DocumentPageVerticalRulerGeometry', () {
    test('maps page margins into vertical ruler positions', () {
      const geometry = DocumentPageVerticalRulerGeometry(
        pageHeight: 842,
        surfaceHeight: 421,
        topMargin: 72,
        bottomMargin: 90,
      );

      expect(geometry.scale, 0.5);
      expect(geometry.topMarginY, 36);
      expect(geometry.bottomMarginY, 376);
      expect(geometry.writingHeight, 680);
    });

    test('converts vertical handle drags back into point margins', () {
      const geometry = DocumentPageVerticalRulerGeometry(
        pageHeight: 842,
        surfaceHeight: 421,
        topMargin: 36,
        bottomMargin: 90,
      );
      const margins = EdgeInsets.fromLTRB(72, 36, 54, 90);

      final deltaPoints = geometry.pointsForPixels(18);
      final topMoved = geometry.moveTopMargin(
        margins: margins,
        deltaPoints: deltaPoints,
      );
      final bottomMoved = geometry.moveBottomMargin(
        margins: margins,
        deltaPoints: deltaPoints,
      );

      expect(deltaPoints, 36);
      expect(topMoved, const EdgeInsets.fromLTRB(72, 72, 54, 90));
      expect(bottomMoved, const EdgeInsets.fromLTRB(72, 36, 54, 54));
    });

    test('keeps vertical margins from collapsing the writing area', () {
      const geometry = DocumentPageVerticalRulerGeometry(
        pageHeight: 842,
        surfaceHeight: 421,
        topMargin: 36,
        bottomMargin: 90,
      );
      const margins = EdgeInsets.fromLTRB(72, 36, 54, 90);

      final topMoved = geometry.moveTopMargin(
        margins: margins,
        deltaPoints: 1000,
      );
      final bottomMoved = geometry.moveBottomMargin(
        margins: margins,
        deltaPoints: -1000,
      );

      expect(topMoved.top, 608);
      expect(bottomMoved.bottom, 662);
    });

    test('classifies vertical ruler ticks', () {
      const geometry = DocumentPageVerticalRulerGeometry(
        pageHeight: 144,
        surfaceHeight: 144,
        topMargin: 18,
        bottomMargin: 18,
      );

      final ticks = geometry.ticks().toList();

      expect(ticks.first.kind, DocumentPageRulerTickKind.inch);
      expect(ticks[1].kind, DocumentPageRulerTickKind.eighthInch);
      expect(ticks[2].kind, DocumentPageRulerTickKind.quarterInch);
      expect(ticks[4].kind, DocumentPageRulerTickKind.halfInch);
      expect(ticks[8].kind, DocumentPageRulerTickKind.inch);
      expect(ticks[8].inchNumber, 1);
    });
  });
}
