import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ky_docs/docx/widgets/command_palette/document_command_availability_badge.dart';

void main() {
  group('DocumentCommandAvailabilityBadge', () {
    testWidgets('renders a compact disabled-state badge', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DocumentCommandAvailabilityBadge(
              label: 'Locked',
              reason: 'Viewing mode locks this command',
            ),
          ),
        ),
      );

      expect(find.text('Locked'), findsOneWidget);
      expect(find.byIcon(Icons.lock_outline), findsOneWidget);
      expect(find.byTooltip('Viewing mode locks this command'), findsOneWidget);
    });
  });
}
