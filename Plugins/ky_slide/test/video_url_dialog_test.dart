import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ky_slide/widgets/toolbar/video_url_dialog.dart';

void main() {
  testWidgets('video URL dialog trims input and submits from action button', (
    tester,
  ) async {
    String? submittedUrl;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Builder(
              builder: (context) {
                return TextButton(
                  onPressed: () {
                    showDialog<void>(
                      context: context,
                      builder: (context) => VideoUrlDialog(
                        onSubmitted: (url) => submittedUrl = url,
                      ),
                    );
                  },
                  child: const Text('Open'),
                );
              },
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.text('Add video'), findsNWidgets(2));
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );

    await tester.enterText(
      find.byType(TextField),
      '  https://example.com/video  ',
    );
    await tester.pumpAndSettle();

    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNotNull,
    );

    await tester.tap(find.widgetWithText(FilledButton, 'Add video'));
    await tester.pumpAndSettle();

    expect(submittedUrl, 'https://example.com/video');
    expect(find.byType(VideoUrlDialog), findsNothing);
  });

  testWidgets('video URL dialog submits from keyboard done action', (
    tester,
  ) async {
    String? submittedUrl;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: VideoUrlDialog(onSubmitted: (url) => submittedUrl = url),
        ),
      ),
    );

    await tester.enterText(find.byType(TextField), 'https://example.com/demo');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(submittedUrl, 'https://example.com/demo');
  });
}
