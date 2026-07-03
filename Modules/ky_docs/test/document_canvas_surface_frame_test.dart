import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ky_docs/docx/models/page_layout.dart';
import 'package:ky_docs/docx/widgets/document_canvas_surface_frame.dart';

void main() {
  group('DocumentCanvasSurfaceFrame', () {
    testWidgets('renders child content with a layout and zoom badge', (
      tester,
    ) async {
      await _pumpFrame(tester, layout: PageLayout.web, zoom: 1.25);

      expect(find.byKey(DocumentCanvasSurfaceFrame.frameKey), findsOneWidget);
      expect(
        find.byKey(DocumentCanvasSurfaceFrame.layoutBadgeKey),
        findsOneWidget,
      );
      expect(find.text('Web Layout · 125%'), findsOneWidget);
      expect(find.text('Document body'), findsOneWidget);
    });

    testWidgets('clamps the displayed zoom percentage', (tester) async {
      await _pumpFrame(tester, layout: PageLayout.print, zoom: 2.0);

      expect(find.text('Print Layout · 150%'), findsOneWidget);

      await _pumpFrame(tester, layout: PageLayout.outline, zoom: 0.2);

      expect(find.text('Outline Layout · 50%'), findsOneWidget);
    });
  });
}

Future<void> _pumpFrame(
  WidgetTester tester, {
  required PageLayout layout,
  required double zoom,
}) {
  return tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 420,
          height: 320,
          child: DocumentCanvasSurfaceFrame(
            layout: layout,
            zoom: zoom,
            isCompact: false,
            child: const Center(child: Text('Document body')),
          ),
        ),
      ),
    ),
  );
}
