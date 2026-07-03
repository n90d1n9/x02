import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ky_docs/docx/widgets/command_palette/document_command.dart';
import 'package:ky_docs/docx/widgets/command_palette/document_command_preview_model.dart';
import 'package:ky_docs/docx/widgets/command_palette/document_command_preview_panel.dart';

void main() {
  group('DocumentCommandPreviewPanel', () {
    testWidgets('renders command details and routes enabled actions', (
      tester,
    ) async {
      DocumentCommand? selectedCommand;
      final command = _command(shortcut: 'Ctrl F');

      await _pumpPreview(
        tester,
        command: command,
        onSelected: (value) => selectedCommand = value,
      );

      expect(find.text('Top result'), findsOneWidget);
      expect(find.text('Find and replace'), findsOneWidget);
      expect(find.text('Search the document'), findsOneWidget);
      expect(find.text('Ready'), findsOneWidget);
      expect(find.text('Edit'), findsOneWidget);
      expect(find.text('Ctrl F'), findsOneWidget);

      await tester.tap(find.byKey(DocumentCommandPreviewPanel.runButtonKey));

      expect(selectedCommand?.id, 'find');
    });

    testWidgets('keeps disabled command actions inactive', (tester) async {
      DocumentCommand? selectedCommand;

      await _pumpPreview(
        tester,
        command: _command(
          enabled: false,
          disabledLabel: 'Saved',
          disabledReason: 'No unsaved changes right now',
        ),
        onSelected: (value) => selectedCommand = value,
      );

      expect(find.text('Saved'), findsOneWidget);
      expect(find.byTooltip('No unsaved changes right now'), findsOneWidget);

      await tester.tap(
        find.byKey(DocumentCommandPreviewPanel.runButtonKey),
        warnIfMissed: false,
      );

      expect(selectedCommand, isNull);
    });
  });
}

Future<void> _pumpPreview(
  WidgetTester tester, {
  required DocumentCommand command,
  required ValueChanged<DocumentCommand> onSelected,
}) {
  return tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 620,
          child: DocumentCommandPreviewPanel(
            model: DocumentCommandPreviewModel(command: command),
            onSelected: onSelected,
          ),
        ),
      ),
    ),
  );
}

DocumentCommand _command({
  String? shortcut,
  bool enabled = true,
  String? disabledLabel,
  String? disabledReason,
}) {
  return DocumentCommand(
    id: 'find',
    title: 'Find and replace',
    subtitle: 'Search the document',
    icon: Icons.find_replace,
    category: 'Edit',
    shortcut: shortcut,
    enabled: enabled,
    disabledLabel: disabledLabel,
    disabledReason: disabledReason,
    onSelected: () {},
  );
}
