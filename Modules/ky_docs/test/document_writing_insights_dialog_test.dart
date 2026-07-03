import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ky_docs/docx/services/document_writing_insights.dart';
import 'package:ky_docs/docx/widgets/document_writing_insights_dialog.dart';

void main() {
  group('DocumentWritingInsightsDialog', () {
    TestWidgetsFlutterBinding.ensureInitialized();

    testWidgets('shows score, highlights, and recommendations', (tester) async {
      final longSentence = List.filled(38, 'strategy').join(' ');

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return TextButton(
                onPressed: () => DocumentWritingInsightsDialog.show(
                  context,
                  insights: DocumentWritingInsights.fromText(longSentence),
                ),
                child: const Text('Open'),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Writing Insights'), findsOneWidget);
      expect(find.text('Needs review'), findsOneWidget);
      expect(find.text('Readability: Heavy'), findsOneWidget);
      expect(find.text('Structure: Light'), findsOneWidget);
      expect(find.text('Avg sentence'), findsOneWidget);
      expect(find.text('38 words'), findsOneWidget);
      expect(find.text('Long sentences'), findsOneWidget);
      expect(find.text('Recommendations'), findsOneWidget);
      expect(
        find.text('Break up long sentences for easier scanning'),
        findsOneWidget,
      );
      expect(
        find.text('Add punctuation to clarify sentence boundaries'),
        findsOneWidget,
      );
    });

    testWidgets('copies recommendations to the clipboard', (tester) async {
      String? copiedText;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, (call) async {
            if (call.method == 'Clipboard.setData') {
              final data = call.arguments as Map<dynamic, dynamic>;
              copiedText = data['text'] as String?;
            }
            return null;
          });
      addTearDown(() {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(SystemChannels.platform, null);
      });

      final longSentence = List.filled(38, 'strategy').join(' ');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return TextButton(
                  onPressed: () => DocumentWritingInsightsDialog.show(
                    context,
                    insights: DocumentWritingInsights.fromText(longSentence),
                  ),
                  child: const Text('Open'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Copy recommendations'));
      await tester.pumpAndSettle();

      expect(copiedText, contains('Break up long sentences'));
      expect(copiedText, contains('Add punctuation'));
      expect(find.text('Writing recommendations copied'), findsOneWidget);
    });
  });
}
