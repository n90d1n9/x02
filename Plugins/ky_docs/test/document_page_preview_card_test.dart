import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ky_docs/docx/models/page_orientation.dart';
import 'package:ky_docs/docx/models/page_settings.dart';
import 'package:ky_docs/docx/models/page_size.dart';
import 'package:ky_docs/docx/widgets/page_settings/document_page_preview_card.dart';

void main() {
  group('DocumentPagePreviewCard', () {
    testWidgets('renders page size and known margin preset summary', (
      tester,
    ) async {
      await _pumpPreview(
        tester,
        settings: const PageSettings(pageSize: PageSize.letter),
      );

      expect(find.byKey(DocumentPagePreviewCard.previewKey), findsOneWidget);
      expect(find.byKey(DocumentPagePreviewCard.pageSheetKey), findsOneWidget);
      expect(
        find.byKey(DocumentPagePreviewCard.marginFrameKey),
        findsOneWidget,
      );
      expect(find.text('Letter portrait'), findsOneWidget);
      expect(find.text('612 x 792 pt'), findsOneWidget);
      expect(find.text('Normal margins'), findsOneWidget);
      expect(find.text('T 72 · R 72 · B 72 · L 72 pt'), findsOneWidget);
    });

    testWidgets('renders landscape page dimensions', (tester) async {
      await _pumpPreview(
        tester,
        settings: const PageSettings(
          pageSize: PageSize.letter,
          orientation: DocumentPageOrientation.landscape,
        ),
      );

      expect(find.text('Letter landscape'), findsOneWidget);
      expect(find.text('792 x 612 pt'), findsOneWidget);
    });

    testWidgets('renders custom margin values', (tester) async {
      await _pumpPreview(
        tester,
        settings: const PageSettings(
          margins: EdgeInsets.fromLTRB(72, 36, 54, 90),
          showHeader: true,
          showFooter: true,
        ),
      );

      expect(find.text('Custom margins'), findsOneWidget);
      expect(find.text('T 36 · R 54 · B 90 · L 72 pt'), findsOneWidget);
    });
  });
}

Future<void> _pumpPreview(
  WidgetTester tester, {
  required PageSettings settings,
}) {
  return tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 420,
          child: DocumentPagePreviewCard(settings: settings),
        ),
      ),
    ),
  );
}
