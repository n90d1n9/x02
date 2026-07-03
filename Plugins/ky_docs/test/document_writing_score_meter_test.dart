import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ky_docs/docx/services/document_writing_insights.dart';
import 'package:ky_docs/docx/widgets/document_writing_score_meter.dart';

void main() {
  group('DocumentWritingScoreMeter', () {
    testWidgets('renders score and accessible label', (tester) async {
      final semantics = tester.ensureSemantics();

      final insights = DocumentWritingInsights.fromText(
        List.filled(38, 'strategy').join(' '),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(child: DocumentWritingScoreMeter(insights: insights)),
          ),
        ),
      );

      expect(find.text('66'), findsOneWidget);
      expect(find.text('/100'), findsOneWidget);
      expect(
        find.bySemanticsLabel('Writing score 66 out of 100, Needs review'),
        findsOneWidget,
      );

      semantics.dispose();
    });
  });
}
