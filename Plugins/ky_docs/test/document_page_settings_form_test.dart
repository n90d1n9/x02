import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ky_docs/docx/models/page_orientation.dart';
import 'package:ky_docs/docx/models/page_settings.dart';
import 'package:ky_docs/docx/models/page_size.dart';
import 'package:ky_docs/docx/widgets/page_settings/page_settings_form.dart';

void main() {
  group('DocumentPageSettingsForm', () {
    testWidgets('emits page size changes without losing draft state', (
      tester,
    ) async {
      PageSettings? changedSettings;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: DocumentPageSettingsForm(
                settings: const PageSettings(),
                onChanged: (settings) => changedSettings = settings,
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Letter'));
      await tester.pump();

      expect(changedSettings?.pageSize, PageSize.letter);
      expect(find.text('Letter portrait'), findsOneWidget);
    });

    testWidgets('emits orientation changes', (tester) async {
      PageSettings? changedSettings;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: DocumentPageSettingsForm(
                settings: const PageSettings(),
                onChanged: (settings) => changedSettings = settings,
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Landscape'));
      await tester.pump();

      expect(changedSettings?.orientation, DocumentPageOrientation.landscape);
      expect(find.text('A4 landscape'), findsOneWidget);
    });

    testWidgets('emits margin preset changes', (tester) async {
      PageSettings? changedSettings;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: DocumentPageSettingsForm(
                settings: const PageSettings(),
                onChanged: (settings) => changedSettings = settings,
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Narrow'));
      await tester.pump();

      expect(changedSettings?.margins, const EdgeInsets.all(36));
    });

    testWidgets('emits header and footer text only when enabled', (
      tester,
    ) async {
      PageSettings? changedSettings;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: DocumentPageSettingsForm(
                settings: const PageSettings(),
                onChanged: (settings) => changedSettings = settings,
              ),
            ),
          ),
        ),
      );

      await tester.ensureVisible(find.text('Header'));
      await tester.pump();
      await tester.tap(find.text('Header'));
      await tester.pump();
      await tester.ensureVisible(find.widgetWithText(TextField, 'Header text'));
      await tester.pump();
      await tester.enterText(
        find.widgetWithText(TextField, 'Header text'),
        'Confidential',
      );
      await tester.pump();

      expect(changedSettings?.showHeader, isTrue);
      expect(changedSettings?.header, 'Confidential');

      await tester.ensureVisible(find.text('Header'));
      await tester.pump();
      await tester.tap(find.text('Header'));
      await tester.pump();

      expect(changedSettings?.showHeader, isFalse);
      expect(changedSettings?.header, isNull);
    });

    testWidgets('falls back to the default page number format', (tester) async {
      PageSettings? changedSettings;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: DocumentPageSettingsForm(
                settings: const PageSettings(pageNumberFormat: 'Page {n}'),
                onChanged: (settings) => changedSettings = settings,
              ),
            ),
          ),
        ),
      );

      await tester.enterText(
        find.widgetWithText(TextField, 'Page number format'),
        '',
      );
      await tester.pump();

      expect(changedSettings?.pageNumberFormat, 'Page {n}');
    });
  });
}
