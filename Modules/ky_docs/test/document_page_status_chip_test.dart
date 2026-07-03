import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ky_docs/docx/models/page_settings.dart';
import 'package:ky_docs/docx/widgets/status_bar/document_page_status_chip.dart';

void main() {
  group('DocumentPageStatusChip', () {
    testWidgets('opens page details and navigator action', (tester) async {
      var openedNavigator = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: DocumentPageStatusChip(
                currentPage: 2,
                totalPages: 5,
                pageSettings: const PageSettings(),
                onOpenPageNavigator: () => openedNavigator = true,
              ),
            ),
          ),
        ),
      );

      expect(find.byKey(DocumentPageStatusChip.chipKey), findsOneWidget);
      expect(find.text('Page 2 of 5'), findsOneWidget);

      await tester.tap(find.byKey(DocumentPageStatusChip.chipKey));
      await tester.pumpAndSettle();

      expect(find.byKey(DocumentPageStatusChip.menuKey), findsOneWidget);
      expect(find.text('Page position'), findsOneWidget);
      expect(find.text('A4 portrait'), findsOneWidget);
      expect(find.text('Current page'), findsOneWidget);
      expect(find.text('Page 2'), findsOneWidget);
      expect(find.text('Total pages'), findsOneWidget);
      expect(find.text('5 pages'), findsOneWidget);
      expect(find.text('Position'), findsOneWidget);
      expect(find.text('40% through'), findsOneWidget);
      expect(find.text('Range'), findsOneWidget);
      expect(find.text('1-5'), findsOneWidget);

      await tester.tap(find.byKey(DocumentPageStatusChip.openNavigatorKey));
      await tester.pumpAndSettle();

      expect(openedNavigator, isTrue);
    });
  });
}
