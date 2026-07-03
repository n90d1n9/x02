import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ky_docs/docx/widgets/command_palette/document_command.dart';
import 'package:ky_docs/docx/widgets/command_palette/document_command_suggestion_strip.dart';

void main() {
  group('DocumentCommandSuggestionStrip', () {
    testWidgets('renders suggested commands and routes selection', (
      tester,
    ) async {
      DocumentCommand? selectedCommand;
      final command = _command(id: 'find', title: 'Find');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DocumentCommandSuggestionStrip(
              commands: [command],
              onSelected: (value) => selectedCommand = value,
            ),
          ),
        ),
      );

      expect(
        find.byKey(DocumentCommandSuggestionStrip.stripKey),
        findsOneWidget,
      );
      expect(find.text('Suggested'), findsOneWidget);
      expect(
        find.byKey(DocumentCommandSuggestionStrip.chipKey('find')),
        findsOneWidget,
      );

      await tester.tap(find.text('Find'));

      expect(selectedCommand, same(command));
    });

    testWidgets('keeps disabled suggestions inactive', (tester) async {
      DocumentCommand? selectedCommand;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DocumentCommandSuggestionStrip(
              commands: [
                _command(id: 'ai', title: 'Open AI assistant', enabled: false),
              ],
              onSelected: (value) => selectedCommand = value,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open AI assistant'), warnIfMissed: false);

      expect(selectedCommand, isNull);
    });

    testWidgets('does not render when there are no suggestions', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DocumentCommandSuggestionStrip(
              commands: [],
              onSelected: _noopCommand,
            ),
          ),
        ),
      );

      expect(find.byKey(DocumentCommandSuggestionStrip.stripKey), findsNothing);
    });
  });
}

void _noopCommand(DocumentCommand command) {}

DocumentCommand _command({
  required String id,
  required String title,
  bool enabled = true,
}) {
  return DocumentCommand(
    id: id,
    title: title,
    subtitle: title,
    icon: Icons.bolt_outlined,
    enabled: enabled,
    onSelected: () {},
  );
}
