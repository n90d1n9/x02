import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ky_docs/docx/widgets/document_zoom_controls.dart';

void main() {
  group('DocumentZoomControls', () {
    testWidgets('renders zoom percent and invokes zoom actions', (
      tester,
    ) async {
      var zoomedOut = false;
      var zoomedIn = false;
      var reset = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: DocumentZoomControls(
                zoom: 1.0,
                onZoomOut: () => zoomedOut = true,
                onZoomIn: () => zoomedIn = true,
                onResetZoom: () => reset = true,
              ),
            ),
          ),
        ),
      );

      expect(find.text('100%'), findsOneWidget);

      await tester.tap(find.byTooltip('Zoom out'));
      await tester.tap(find.byTooltip('Zoom in'));
      await tester.tap(find.text('100%'));

      expect(zoomedOut, isTrue);
      expect(zoomedIn, isTrue);
      expect(reset, isTrue);
    });

    testWidgets('disables zoom controls at configured bounds', (tester) async {
      var zoomedOut = false;
      var zoomedIn = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: DocumentZoomControls(
                zoom: DocumentZoomControls.defaultMinZoom,
                onZoomOut: () => zoomedOut = true,
                onZoomIn: () => zoomedIn = true,
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byTooltip('Zoom out'));
      await tester.tap(find.byTooltip('Zoom in'));

      expect(zoomedOut, isFalse);
      expect(zoomedIn, isTrue);
    });

    testWidgets('supports direct zoom selection from the slider', (
      tester,
    ) async {
      double? selectedZoom;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: DocumentZoomControls(
                zoom: 1.0,
                onZoomChanged: (zoom) => selectedZoom = zoom,
              ),
            ),
          ),
        ),
      );

      final slider = tester.widget<Slider>(
        find.byKey(DocumentZoomControls.sliderKey),
      );
      slider.onChanged?.call(1.25);

      expect(selectedZoom, 1.25);
    });
  });
}
