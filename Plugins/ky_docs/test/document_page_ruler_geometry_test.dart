import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ky_docs/docx/widgets/ruler/document_page_ruler_geometry.dart';

void main() {
  group('DocumentPageRulerGeometry', () {
    test('maps page margins into ruler positions', () {
      const geometry = DocumentPageRulerGeometry(
        pageWidth: 612,
        surfaceWidth: 306,
        leftMargin: 72,
        rightMargin: 36,
      );

      expect(geometry.scale, 0.5);
      expect(geometry.leftMarginX, 36);
      expect(geometry.rightMarginX, 288);
      expect(geometry.writingWidth, 504);
    });

    test('converts dragged margin handles back into point margins', () {
      const geometry = DocumentPageRulerGeometry(
        pageWidth: 612,
        surfaceWidth: 306,
        leftMargin: 72,
        rightMargin: 54,
      );
      const margins = EdgeInsets.fromLTRB(72, 36, 54, 90);

      final deltaPoints = geometry.pointsForPixels(18);
      final leftMoved = geometry.moveLeftMargin(
        margins: margins,
        deltaPoints: deltaPoints,
      );
      final rightMoved = geometry.moveRightMargin(
        margins: margins,
        deltaPoints: deltaPoints,
      );

      expect(deltaPoints, 36);
      expect(leftMoved, const EdgeInsets.fromLTRB(108, 36, 54, 90));
      expect(rightMoved, const EdgeInsets.fromLTRB(72, 36, 18, 90));
    });

    test('keeps dragged margins from collapsing the writing area', () {
      const geometry = DocumentPageRulerGeometry(
        pageWidth: 612,
        surfaceWidth: 306,
        leftMargin: 72,
        rightMargin: 54,
      );
      const margins = EdgeInsets.fromLTRB(72, 36, 54, 90);

      final leftMoved = geometry.moveLeftMargin(
        margins: margins,
        deltaPoints: 1000,
      );
      final rightMoved = geometry.moveRightMargin(
        margins: margins,
        deltaPoints: -1000,
      );

      expect(leftMoved.left, 414);
      expect(rightMoved.right, 396);
    });

    test('classifies eighth-inch ruler ticks', () {
      const geometry = DocumentPageRulerGeometry(
        pageWidth: 144,
        surfaceWidth: 144,
        leftMargin: 18,
        rightMargin: 18,
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
