import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ky_docs/docx/models/export_options.dart';
import 'package:ky_docs/docx/widgets/pdf_export_options_dialog.dart';

void main() {
  group('PdfExportOptionsDialog', () {
    testWidgets('renders modern export switches and returns options', (
      tester,
    ) async {
      ExportOptions? exportedOptions;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return TextButton(
                  onPressed: () async {
                    exportedOptions = await PdfExportOptionsDialog.show(
                      context,
                    );
                  },
                  child: const Text('Open export'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open export'));
      await tester.pumpAndSettle();

      expect(find.text('PDF Export Options'), findsOneWidget);
      expect(find.byIcon(Icons.pin_outlined), findsOneWidget);
      expect(
        find.text('Add generated numbers to each exported page.'),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.badge_outlined), findsOneWidget);
      expect(find.text('Font size'), findsOneWidget);
      expect(find.text('12 pt'), findsOneWidget);
      expect(find.text('Line spacing'), findsOneWidget);
      expect(find.text('1.5'), findsOneWidget);

      await tester.tap(find.text('Include Metadata'));
      await tester.pump();
      await tester.tap(find.text('Include Header'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextField, 'Header Text'),
        'Confidential Draft',
      );
      await tester.pump();
      tester
          .widget<Slider>(find.byKey(PdfExportOptionsDialog.fontSizeSliderKey))
          .onChanged
          ?.call(16);
      await tester.pump();
      tester
          .widget<Slider>(
            find.byKey(PdfExportOptionsDialog.lineSpacingSliderKey),
          )
          .onChanged
          ?.call(2);
      await tester.pump();
      await tester.tap(find.text('Export'));
      await tester.pumpAndSettle();

      expect(exportedOptions, isNotNull);
      expect(exportedOptions!.includeMetadata, isFalse);
      expect(exportedOptions!.includeHeader, isTrue);
      expect(exportedOptions!.headerText, 'Confidential Draft');
      expect(exportedOptions!.fontSize, greaterThan(12));
      expect(exportedOptions!.lineSpacing, greaterThan(1.5));
    });
  });
}
