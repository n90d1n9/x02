import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ky_docs/docx/models/document_metadata.dart';
import 'package:ky_docs/docx/services/document_statistics.dart';
import 'package:ky_docs/docx/widgets/document_info/document_info_summary.dart';

void main() {
  group('DocumentInfoSummary', () {
    testWidgets('renders document identity, metrics, and details', (
      tester,
    ) async {
      await _pumpSummary(tester);

      expect(find.text('Quarterly Plan'), findsOneWidget);
      expect(find.text('Owned by Aminah'), findsOneWidget);
      expect(find.byIcon(Icons.star_rounded), findsOneWidget);
      expect(find.text('Words'), findsOneWidget);
      expect(find.text('Characters'), findsOneWidget);
      expect(find.text('Reading time'), findsOneWidget);
      expect(find.text('Writing quality'), findsOneWidget);
      expect(find.text('Document details'), findsOneWidget);
      expect(find.text('June 9, 2026 at 08:05'), findsOneWidget);
      expect(find.text('Structure'), findsOneWidget);
      expect(find.text('Characters without spaces'), findsOneWidget);
    });

    testWidgets('renders document tags as chips', (tester) async {
      await _pumpSummary(tester);

      expect(find.text('Tags'), findsOneWidget);
      expect(find.text('draft'), findsOneWidget);
      expect(find.text('finance'), findsOneWidget);
    });

    testWidgets('omits tag section when no tags are available', (tester) async {
      await _pumpSummary(tester, metadata: _metadata(tags: const []));

      expect(find.text('Tags'), findsNothing);
      expect(find.text('None'), findsOneWidget);
    });
  });
}

Future<void> _pumpSummary(WidgetTester tester, {DocumentMetadata? metadata}) {
  return tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: SizedBox(
            width: 620,
            child: DocumentInfoSummary(
              metadata: metadata ?? _metadata(),
              statistics: DocumentTextStatistics.fromText(
                'This draft is clear. It has structure.\n\n'
                'Readers can scan it quickly.',
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

DocumentMetadata _metadata({List<String> tags = const ['draft', 'finance']}) {
  return DocumentMetadata(
    id: 'doc-1',
    title: 'Quarterly Plan',
    author: 'Aminah',
    createdAt: DateTime(2026, 6, 9, 8, 5),
    modifiedAt: DateTime(2026, 6, 10, 17, 45),
    tags: tags,
    isFavorite: true,
  );
}
