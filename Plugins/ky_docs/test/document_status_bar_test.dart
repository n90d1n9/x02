import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:flutter_test/flutter_test.dart';
import 'package:ky_docs/docx/models/document_editing_mode.dart';
import 'package:ky_docs/docx/models/document_metadata.dart';
import 'package:ky_docs/docx/models/document_state.dart';
import 'package:ky_docs/docx/models/page_layout.dart';
import 'package:ky_docs/docx/services/document_statistics.dart';
import 'package:ky_docs/docx/widgets/document_status_bar.dart';
import 'package:ky_docs/docx/widgets/document_zoom_controls.dart';
import 'package:ky_docs/docx/widgets/review_mode/document_editing_mode_status_chip.dart';
import 'package:ky_docs/docx/widgets/status_bar/document_page_status_chip.dart';
import 'package:ky_docs/docx/widgets/status_bar/document_statistics_status_chip.dart';

void main() {
  group('DocumentStatusBar', () {
    testWidgets('shows writing quality on wide layouts', (tester) async {
      tester.view.physicalSize = const Size(1200, 700);
      tester.view.devicePixelRatio = 1;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final controller = quill.QuillController.basic();
      addTearDown(controller.dispose);
      const draftText =
          'This draft is clear. It has useful rhythm.\n\n'
          'Readers can scan it quickly.';
      controller.document.insert(0, draftText);
      final statistics = DocumentStatistics(controller);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 1100,
              child: DocumentStatusBar(
                documentState: DocumentState(
                  controller: controller,
                  metadata: DocumentMetadata(
                    id: 'doc-1',
                    title: 'Proposal',
                    createdAt: DateTime(2026),
                    modifiedAt: DateTime(2026, 1, 2),
                  ),
                ),
                statistics: statistics,
              ),
            ),
          ),
        ),
      );

      expect(find.text('Page 1 of 1'), findsOneWidget);
      expect(find.byKey(DocumentStatisticsStatusChip.chipKey), findsOneWidget);
      expect(
        find.byTooltip(statistics.snapshot.summaryTooltip),
        findsOneWidget,
      );
      expect(find.text('1 min read'), findsOneWidget);
      expect(find.textContaining('selected'), findsNothing);
      expect(find.text('Quality: Polished'), findsOneWidget);
      expect(find.byTooltip('Print Layout'), findsOneWidget);

      await tester.tap(find.text('Quality: Polished'));
      await tester.pumpAndSettle();

      expect(find.text('Writing Insights'), findsOneWidget);
      expect(find.text('Looks good for now'), findsOneWidget);
    });

    testWidgets('keeps compact layouts focused on core document metadata', (
      tester,
    ) async {
      final controller = quill.QuillController.basic();
      addTearDown(controller.dispose);
      controller.document.insert(0, 'Compact status bar text.');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 520,
              child: DocumentStatusBar(
                documentState: DocumentState(
                  controller: controller,
                  metadata: DocumentMetadata(
                    id: 'doc-1',
                    title: 'Proposal',
                    createdAt: DateTime(2026),
                    modifiedAt: DateTime(2026, 1, 2),
                  ),
                ),
                statistics: DocumentStatistics(controller),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Page 1 of 1'), findsOneWidget);
      expect(find.text('Normal'), findsNothing);
      expect(find.byKey(DocumentEditingModeStatusChip.chipKey), findsNothing);
      expect(find.text('1 min read'), findsNothing);
      expect(find.text('Quality: Polished'), findsNothing);
    });

    testWidgets('keeps non-default editing modes visible on compact layouts', (
      tester,
    ) async {
      final controller = quill.QuillController.basic();
      addTearDown(controller.dispose);
      controller.document.insert(0, 'Suggested compact status bar text.');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 520,
              child: DocumentStatusBar(
                documentState: DocumentState(
                  controller: controller,
                  metadata: DocumentMetadata(
                    id: 'doc-1',
                    title: 'Proposal',
                    createdAt: DateTime(2026),
                    modifiedAt: DateTime(2026, 1, 2),
                  ),
                ),
                statistics: DocumentStatistics(controller),
                editingMode: DocumentEditingMode.suggesting,
              ),
            ),
          ),
        ),
      );

      expect(find.byKey(DocumentEditingModeStatusChip.chipKey), findsOneWidget);
      expect(find.text('Suggesting'), findsOneWidget);
      expect(find.text('1 min read'), findsNothing);
    });

    testWidgets('shows current text style on extra-wide layouts', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1500, 700);
      tester.view.devicePixelRatio = 1;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final controller = quill.QuillController.basic();
      addTearDown(controller.dispose);
      controller.document.insert(0, 'Styled status text.');
      controller.updateSelection(
        const TextSelection(baseOffset: 0, extentOffset: 18),
        quill.ChangeSource.local,
      );
      controller.formatSelection(quill.Attribute.h2);
      controller.formatSelection(quill.Attribute.bold);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 1400,
              child: DocumentStatusBar(
                documentState: DocumentState(
                  controller: controller,
                  metadata: DocumentMetadata(
                    id: 'doc-1',
                    title: 'Proposal',
                    createdAt: DateTime(2026),
                    modifiedAt: DateTime(2026, 1, 2),
                  ),
                ),
                statistics: DocumentStatistics(controller),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Heading 2 - Bold'), findsOneWidget);
    });

    testWidgets('shows selected text metrics from the editor controller', (
      tester,
    ) async {
      final controller = quill.QuillController.basic();
      addTearDown(controller.dispose);
      controller.document.insert(0, 'Selected status text.');
      controller.updateSelection(
        const TextSelection(baseOffset: 0, extentOffset: 15),
        quill.ChangeSource.local,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 1100,
              child: DocumentStatusBar(
                documentState: DocumentState(
                  controller: controller,
                  metadata: DocumentMetadata(
                    id: 'doc-1',
                    title: 'Proposal',
                    createdAt: DateTime(2026),
                    modifiedAt: DateTime(2026, 1, 2),
                  ),
                ),
                statistics: DocumentStatistics(controller),
              ),
            ),
          ),
        ),
      );

      expect(find.text('2 words selected'), findsOneWidget);
    });

    testWidgets('switches layouts from the editor chrome', (tester) async {
      PageLayout? selectedLayout;
      final controller = quill.QuillController.basic();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 1100,
              child: DocumentStatusBar(
                documentState: DocumentState(
                  controller: controller,
                  metadata: DocumentMetadata(
                    id: 'doc-1',
                    title: 'Proposal',
                    createdAt: DateTime(2026),
                    modifiedAt: DateTime(2026, 1, 2),
                  ),
                ),
                statistics: DocumentStatistics(controller),
                onSetPageLayout: (layout) => selectedLayout = layout,
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byTooltip('Web Layout'));

      expect(selectedLayout, PageLayout.web);
    });

    testWidgets('opens page navigator from the page status chip', (
      tester,
    ) async {
      var openedPageNavigator = false;
      final controller = quill.QuillController.basic();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 1100,
              child: DocumentStatusBar(
                documentState: DocumentState(
                  controller: controller,
                  metadata: DocumentMetadata(
                    id: 'doc-1',
                    title: 'Proposal',
                    createdAt: DateTime(2026),
                    modifiedAt: DateTime(2026, 1, 2),
                  ),
                  currentPage: 2,
                  totalPages: 5,
                ),
                statistics: DocumentStatistics(controller),
                onOpenPageNavigator: () => openedPageNavigator = true,
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byKey(DocumentPageStatusChip.chipKey));
      await tester.pumpAndSettle();

      expect(find.byKey(DocumentPageStatusChip.menuKey), findsOneWidget);

      await tester.tap(find.byKey(DocumentPageStatusChip.openNavigatorKey));
      await tester.pumpAndSettle();

      expect(openedPageNavigator, isTrue);
    });

    testWidgets('forwards direct zoom changes from the editor chrome', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1200, 700);
      tester.view.devicePixelRatio = 1;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      double? selectedZoom;
      final controller = quill.QuillController.basic();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 1100,
              child: DocumentStatusBar(
                documentState: DocumentState(
                  controller: controller,
                  metadata: DocumentMetadata(
                    id: 'doc-1',
                    title: 'Proposal',
                    createdAt: DateTime(2026),
                    modifiedAt: DateTime(2026, 1, 2),
                  ),
                ),
                statistics: DocumentStatistics(controller),
                onZoomChanged: (zoom) => selectedZoom = zoom,
              ),
            ),
          ),
        ),
      );

      final slider = tester.widget<Slider>(
        find.byKey(DocumentZoomControls.sliderKey),
      );
      slider.onChanged?.call(1.2);

      expect(selectedZoom, 1.2);
    });
  });
}
