import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ky_docs/docx/widgets/navigation/document_navigation_rail_header.dart';

void main() {
  group('DocumentNavigationRailHeader', () {
    testWidgets('renders rail identity, count, and close action', (
      tester,
    ) async {
      var closed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DocumentNavigationRailHeader(
              icon: Icons.view_agenda_outlined,
              title: 'Pages',
              subtitle: 'A4 portrait',
              countLabel: '3 pages',
              badgeTone: DocumentNavigationRailBadgeTone.secondary,
              closeButtonKey: const Key('close-pages'),
              onClose: () => closed = true,
            ),
          ),
        ),
      );

      expect(find.text('Pages'), findsOneWidget);
      expect(find.text('A4 portrait'), findsOneWidget);
      expect(find.text('3 pages'), findsOneWidget);
      expect(
        find.byKey(DocumentNavigationRailHeader.countBadgeKey),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const Key('close-pages')));

      expect(closed, isTrue);
    });

    testWidgets('omits close control when no close handler is provided', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DocumentNavigationRailHeader(
              icon: Icons.account_tree_outlined,
              title: 'Document map',
              subtitle: 'Jump between headings',
              countLabel: '4',
              closeButtonKey: Key('close-outline'),
            ),
          ),
        ),
      );

      expect(find.text('Document map'), findsOneWidget);
      expect(find.byKey(const Key('close-outline')), findsNothing);
    });
  });
}
