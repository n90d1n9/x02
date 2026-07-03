import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ky_docs/docx/models/page_layout.dart';
import 'package:ky_docs/docx/models/page_margin_preset.dart';
import 'package:ky_docs/docx/models/page_settings.dart';
import 'package:ky_docs/docx/models/page_size.dart';
import 'package:ky_docs/docx/widgets/document_canvas_surface_frame.dart';
import 'package:ky_docs/docx/widgets/document_editor_canvas.dart';
import 'package:ky_docs/docx/widgets/document_page_chrome.dart';
import 'package:ky_docs/docx/widgets/document_page_ruler.dart';
import 'package:ky_docs/docx/widgets/document_page_vertical_ruler.dart';
import 'package:ky_docs/docx/widgets/page_margin/document_page_margin_guides.dart';
import 'package:ky_docs/docx/widgets/page_chrome/document_header_footer_quick_edit_dialog.dart';
import 'package:ky_docs/docx/widgets/ruler/document_ruler_corner_button.dart';
import 'package:ky_docs/docx/widgets/ruler/document_ruler_metrics_chip.dart';

void main() {
  group('DocumentEditorCanvas', () {
    void useWideTestViewport(WidgetTester tester) {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
    }

    testWidgets('uses a centered page surface for print layout', (
      tester,
    ) async {
      useWideTestViewport(tester);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 1000,
              height: 600,
              child: DocumentEditorCanvas(
                layout: PageLayout.print,
                child: SizedBox.expand(),
              ),
            ),
          ),
        ),
      );

      final surfaceSize = tester.getSize(
        find.byKey(DocumentEditorCanvas.surfaceKey),
      );

      expect(surfaceSize.width, 816);
      expect(surfaceSize.height, 552);
      expect(find.byKey(DocumentPageRuler.rulerKey), findsOneWidget);
      expect(find.byKey(DocumentPageVerticalRuler.rulerKey), findsOneWidget);
      expect(find.byKey(DocumentRulerCornerButton.buttonKey), findsOneWidget);
      expect(find.byKey(DocumentRulerMetricsChip.chipKey), findsOneWidget);
      expect(find.text('A4 · 1 in margins'), findsOneWidget);
      expect(find.byKey(DocumentPageMarginGuides.guidesKey), findsOneWidget);
      expect(
        find.byKey(DocumentCanvasSurfaceFrame.layoutBadgeKey),
        findsOneWidget,
      );
      expect(find.text('Print Layout · 100%'), findsOneWidget);
    });

    testWidgets('allows web layout to use a wider writing surface', (
      tester,
    ) async {
      useWideTestViewport(tester);

      Future<Size> surfaceSizeFor(PageLayout layout) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 1000,
                height: 600,
                child: DocumentEditorCanvas(
                  layout: layout,
                  child: const SizedBox.expand(),
                ),
              ),
            ),
          ),
        );
        return tester.getSize(find.byKey(DocumentEditorCanvas.surfaceKey));
      }

      final printSize = await surfaceSizeFor(PageLayout.print);
      final webSize = await surfaceSizeFor(PageLayout.web);

      expect(webSize.width, greaterThan(printSize.width));
      expect(webSize.height, printSize.height);
      expect(find.byKey(DocumentPageRuler.rulerKey), findsNothing);
      expect(find.byKey(DocumentPageVerticalRuler.rulerKey), findsNothing);
      expect(find.byKey(DocumentRulerCornerButton.buttonKey), findsNothing);
      expect(find.byKey(DocumentRulerMetricsChip.chipKey), findsNothing);
      expect(find.byKey(DocumentPageMarginGuides.guidesKey), findsNothing);
    });

    testWidgets('applies zoom to the writing surface width', (tester) async {
      useWideTestViewport(tester);

      Future<Size> surfaceSizeFor(double zoom) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 1200,
                height: 600,
                child: DocumentEditorCanvas(
                  layout: PageLayout.print,
                  zoom: zoom,
                  child: const SizedBox.expand(),
                ),
              ),
            ),
          ),
        );
        return tester.getSize(find.byKey(DocumentEditorCanvas.surfaceKey));
      }

      final defaultSize = await surfaceSizeFor(1.0);
      final zoomedOutSize = await surfaceSizeFor(0.75);
      final zoomedInSize = await surfaceSizeFor(1.25);

      expect(zoomedOutSize.width, lessThan(defaultSize.width));
      expect(zoomedInSize.width, greaterThan(defaultSize.width));
    });

    testWidgets('renders page chrome in print layout', (tester) async {
      useWideTestViewport(tester);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 1000,
              height: 600,
              child: DocumentEditorCanvas(
                layout: PageLayout.print,
                pageSettings: PageSettings(
                  showHeader: true,
                  header: 'Proposal',
                  showFooter: true,
                  footer: 'Internal',
                  pageNumberFormat: 'Page {n}',
                ),
                currentPage: 2,
                child: SizedBox.expand(),
              ),
            ),
          ),
        ),
      );

      expect(find.byKey(DocumentPageRuler.rulerKey), findsOneWidget);
      expect(find.byKey(DocumentPageChrome.headerKey), findsOneWidget);
      expect(find.text('Proposal'), findsOneWidget);
      expect(find.text('Internal'), findsOneWidget);
      expect(find.text('Page 2'), findsOneWidget);
    });

    testWidgets('forwards header quick edits as page settings changes', (
      tester,
    ) async {
      useWideTestViewport(tester);
      PageSettings? updatedSettings;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 1000,
              height: 600,
              child: DocumentEditorCanvas(
                layout: PageLayout.print,
                pageSettings: const PageSettings(
                  showHeader: true,
                  header: 'Proposal',
                ),
                onPageSettingsChanged: (settings) {
                  updatedSettings = settings;
                },
                child: const SizedBox.expand(),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byKey(DocumentPageChrome.headerEditButtonKey));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(DocumentHeaderFooterQuickEditDialog.textFieldKey),
        'Client Proposal',
      );
      await tester.tap(
        find.byKey(DocumentHeaderFooterQuickEditDialog.saveButtonKey),
      );

      expect(updatedSettings, isNotNull);
      expect(updatedSettings!.header, 'Client Proposal');
      expect(updatedSettings!.showHeader, isTrue);
    });

    testWidgets('forwards ruler margin drags as page settings changes', (
      tester,
    ) async {
      useWideTestViewport(tester);
      PageSettings? updatedSettings;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 1000,
              height: 600,
              child: DocumentEditorCanvas(
                layout: PageLayout.print,
                pageSettings: const PageSettings(
                  margins: EdgeInsets.fromLTRB(72, 36, 54, 90),
                ),
                onPageSettingsChanged: (settings) {
                  updatedSettings = settings;
                },
                child: const SizedBox.expand(),
              ),
            ),
          ),
        ),
      );

      await tester.drag(
        find.byKey(DocumentPageRuler.leftMarginHandleKey),
        const Offset(24, 0),
      );

      expect(updatedSettings, isNotNull);
      expect(updatedSettings!.margins.left, greaterThan(72));
      expect(updatedSettings!.margins.top, 36);
      expect(updatedSettings!.margins.right, 54);
      expect(updatedSettings!.margins.bottom, 90);
    });

    testWidgets('forwards vertical ruler drags as page settings changes', (
      tester,
    ) async {
      useWideTestViewport(tester);
      PageSettings? updatedSettings;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 1000,
              height: 600,
              child: DocumentEditorCanvas(
                layout: PageLayout.print,
                pageSettings: const PageSettings(
                  margins: EdgeInsets.fromLTRB(72, 36, 54, 90),
                ),
                onPageSettingsChanged: (settings) {
                  updatedSettings = settings;
                },
                child: const SizedBox.expand(),
              ),
            ),
          ),
        ),
      );

      await tester.drag(
        find.byKey(DocumentPageVerticalRuler.topMarginHandleKey),
        const Offset(0, 60),
      );

      expect(updatedSettings, isNotNull);
      expect(updatedSettings!.margins.left, 72);
      expect(updatedSettings!.margins.top, greaterThan(36));
      expect(updatedSettings!.margins.right, 54);
      expect(updatedSettings!.margins.bottom, 90);
    });

    testWidgets('opens page settings from the ruler corner control', (
      tester,
    ) async {
      useWideTestViewport(tester);
      var openedPageSettings = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 1000,
              height: 600,
              child: DocumentEditorCanvas(
                layout: PageLayout.print,
                onPageSettingsPressed: () {
                  openedPageSettings = true;
                },
                child: const SizedBox.expand(),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byKey(DocumentRulerCornerButton.buttonKey));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(DocumentRulerCornerButton.settingsOptionKey));

      expect(openedPageSettings, isTrue);
    });

    testWidgets('applies page setup changes from the ruler corner control', (
      tester,
    ) async {
      useWideTestViewport(tester);
      PageSettings? updatedSettings;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 1000,
              height: 600,
              child: DocumentEditorCanvas(
                layout: PageLayout.print,
                onPageSettingsChanged: (settings) {
                  updatedSettings = settings;
                },
                child: const SizedBox.expand(),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byKey(DocumentRulerCornerButton.buttonKey));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(DocumentRulerCornerButton.pageSizeOptionKey(PageSize.legal)),
      );

      expect(updatedSettings, isNotNull);
      expect(updatedSettings!.pageSize, PageSize.legal);
    });

    testWidgets('opens page settings from the ruler metrics chip', (
      tester,
    ) async {
      useWideTestViewport(tester);
      var openedPageSettings = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 1000,
              height: 600,
              child: DocumentEditorCanvas(
                layout: PageLayout.print,
                pageSettings: const PageSettings(
                  margins: EdgeInsets.symmetric(horizontal: 72, vertical: 54),
                ),
                onPageSettingsPressed: () {
                  openedPageSettings = true;
                },
                child: const SizedBox.expand(),
              ),
            ),
          ),
        ),
      );

      expect(find.text('A4 · H 1 in · V 0.8 in'), findsOneWidget);

      await tester.tap(find.byKey(DocumentRulerMetricsChip.settingsButtonKey));

      expect(openedPageSettings, isTrue);
    });

    testWidgets('applies margin presets from the ruler metrics chip', (
      tester,
    ) async {
      useWideTestViewport(tester);
      PageSettings? updatedSettings;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 1000,
              height: 600,
              child: DocumentEditorCanvas(
                layout: PageLayout.print,
                onPageSettingsChanged: (settings) {
                  updatedSettings = settings;
                },
                child: const SizedBox.expand(),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byKey(DocumentRulerMetricsChip.chipKey));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(
          DocumentRulerMetricsChip.optionKey(DocumentPageMarginPreset.narrow),
        ),
      );

      expect(updatedSettings, isNotNull);
      expect(updatedSettings!.margins, DocumentPageMarginPreset.narrow.margins);
    });
  });
}
