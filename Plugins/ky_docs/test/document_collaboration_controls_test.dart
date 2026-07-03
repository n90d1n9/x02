import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ky_docs/docx/models/collaboration_user.dart';
import 'package:ky_docs/docx/widgets/collaboration/document_collaboration_controls.dart';

void main() {
  group('DocumentCollaborationControls', () {
    testWidgets('renders inactive collaboration call to action', (
      tester,
    ) async {
      var enabled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DocumentCollaborationControls(
              isEnabled: false,
              collaborators: const [],
              onEnable: () => enabled = true,
              onDisable: () {},
              onAddCollaborator: () {},
            ),
          ),
        ),
      );

      expect(find.text('Shared editing is off'), findsOneWidget);
      expect(find.text('Enable collaboration'), findsOneWidget);

      await tester.tap(find.text('Enable collaboration'));

      expect(enabled, isTrue);
    });

    testWidgets('renders active collaborator roster with presence details', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DocumentCollaborationControls(
              isEnabled: true,
              collaborators: [
                _user(
                  id: 'local',
                  name: 'You',
                  color: Colors.blue,
                  cursorPosition: 12,
                  lastActive: DateTime(2026, 6, 9, 8, 0),
                ),
                _user(
                  id: 'guest',
                  name: 'Mina Ray',
                  color: Colors.green,
                  cursorPosition: 42,
                  lastActive: DateTime(2026, 6, 9, 7, 55),
                ),
              ],
              now: DateTime(2026, 6, 9, 8, 0, 30),
              onEnable: () {},
              onDisable: () {},
              onAddCollaborator: () {},
            ),
          ),
        ),
      );

      expect(find.text('Collaboration active'), findsOneWidget);
      expect(find.text('2 people connected to this session'), findsOneWidget);
      expect(find.text('You'), findsOneWidget);
      expect(find.text('Mina Ray'), findsOneWidget);
      expect(find.text('Cursor 12 - active now'), findsOneWidget);
      expect(find.text('Cursor 42 - 5 min ago'), findsOneWidget);
    });

    testWidgets('routes active actions through callbacks', (tester) async {
      var added = false;
      var disabled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DocumentCollaborationControls(
              isEnabled: true,
              collaborators: const [],
              onEnable: () {},
              onDisable: () => disabled = true,
              onAddCollaborator: () => added = true,
            ),
          ),
        ),
      );

      expect(find.text('No collaborators yet'), findsOneWidget);

      await tester.tap(find.text('Add sample').last);
      await tester.tap(find.text('Disable'));

      expect(added, isTrue);
      expect(disabled, isTrue);
    });
  });
}

CollaborationUser _user({
  required String id,
  required String name,
  required Color color,
  required int cursorPosition,
  required DateTime lastActive,
}) {
  return CollaborationUser(
    id: id,
    name: name,
    color: color,
    cursorPosition: cursorPosition,
    lastActive: lastActive,
  );
}
