import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ky_docs/docx/widgets/command_palette/document_command.dart';
import 'package:ky_docs/docx/widgets/command_palette/document_command_empty_state.dart';
import 'package:ky_docs/docx/widgets/command_palette/document_command_palette.dart';
import 'package:ky_docs/docx/widgets/command_palette/document_command_preview_panel.dart';
import 'package:ky_docs/docx/widgets/command_palette/document_command_suggestion_strip.dart';

void main() {
  group('DocumentCommandPalette', () {
    testWidgets('filters commands by title and keywords', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: DocumentCommandPalette(commands: _commands())),
        ),
      );

      expect(
        find.byKey(const Key('document-command-palette-tile-find')),
        findsOneWidget,
      );
      expect(find.text('Share document'), findsWidgets);
      expect(find.text('Edit'), findsWidgets);
      expect(find.text('Collaborate'), findsOneWidget);
      expect(find.text('All 2'), findsOneWidget);
      expect(find.text('Edit 1'), findsOneWidget);
      expect(
        find.byKey(DocumentCommandSuggestionStrip.stripKey),
        findsOneWidget,
      );
      expect(
        find.byKey(DocumentCommandSuggestionStrip.chipKey('find')),
        findsOneWidget,
      );
      expect(find.byKey(DocumentCommandPalette.resultCountKey), findsOneWidget);

      await tester.enterText(
        find.byKey(DocumentCommandPalette.searchFieldKey),
        'collaboration',
      );
      await tester.pump();

      expect(find.text('Find and replace'), findsNothing);
      expect(find.text('Share document'), findsWidgets);
      expect(find.text('1 command'), findsOneWidget);
      expect(find.byKey(DocumentCommandSuggestionStrip.stripKey), findsNothing);
      expect(
        find.byKey(DocumentCommandPalette.commandPreviewKey),
        findsOneWidget,
      );
    });

    testWidgets('filters commands by category before applying search', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DocumentCommandPalette(
              commands: [
                ..._commands(),
                DocumentCommand(
                  id: 'review',
                  title: 'Open review panel',
                  subtitle: 'Review document quality',
                  icon: Icons.rate_review_outlined,
                  category: 'Review',
                  keywords: const ['quality'],
                  suggested: true,
                  suggestionPriority: 80,
                  onSelected: () {},
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('All 3'), findsOneWidget);
      expect(find.text('Review 1'), findsOneWidget);

      await tester.tap(find.text('Review 1'));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('document-command-palette-tile-review')),
        findsOneWidget,
      );
      expect(find.text('Find and replace'), findsNothing);
      expect(find.text('1 command'), findsOneWidget);
      expect(
        find.byKey(DocumentCommandSuggestionStrip.chipKey('review')),
        findsOneWidget,
      );

      await tester.enterText(
        find.byKey(DocumentCommandPalette.searchFieldKey),
        'share',
      );
      await tester.pump();

      expect(find.text('No commands found'), findsOneWidget);
      expect(find.text('0 commands'), findsOneWidget);
      expect(
        find.byKey(DocumentCommandEmptyState.clearSearchButtonKey),
        findsOneWidget,
      );
      expect(
        find.byKey(DocumentCommandEmptyState.resetCategoryButtonKey),
        findsOneWidget,
      );

      await tester.tap(
        find.byKey(DocumentCommandEmptyState.clearSearchButtonKey),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('document-command-palette-tile-review')),
        findsOneWidget,
      );

      await tester.enterText(
        find.byKey(DocumentCommandPalette.searchFieldKey),
        'share',
      );
      await tester.pump();
      await tester.tap(
        find.byKey(DocumentCommandEmptyState.resetCategoryButtonKey),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('document-command-palette-tile-share')),
        findsOneWidget,
      );
    });

    testWidgets('orders stronger title matches above keyword matches', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DocumentCommandPalette(
              commands: [
                DocumentCommand(
                  id: 'review',
                  title: 'Open review panel',
                  subtitle: 'Review document quality',
                  icon: Icons.rate_review_outlined,
                  keywords: const ['find'],
                  onSelected: () {},
                ),
                DocumentCommand(
                  id: 'find',
                  title: 'Find and replace',
                  subtitle: 'Search the document',
                  icon: Icons.find_replace,
                  onSelected: () {},
                ),
              ],
            ),
          ),
        ),
      );

      await tester.enterText(
        find.byKey(DocumentCommandPalette.searchFieldKey),
        'find',
      );
      await tester.pump();

      final findTile = find.byKey(
        const Key('document-command-palette-tile-find'),
      );
      final reviewTile = find.byKey(
        const Key('document-command-palette-tile-review'),
      );

      expect(
        tester.getTopLeft(findTile).dy,
        lessThan(tester.getTopLeft(reviewTile).dy),
      );
    });

    testWidgets('returns the selected command', (tester) async {
      DocumentCommand? selectedCommand;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DocumentCommandPalette(
              commands: _commands(),
              onCommandSelected: (command) => selectedCommand = command,
            ),
          ),
        ),
      );

      await tester.tap(
        find.byKey(const Key('document-command-palette-tile-find')),
      );

      expect(selectedCommand?.id, 'find');
    });

    testWidgets('previews and runs the top visible command', (tester) async {
      DocumentCommand? selectedCommand;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DocumentCommandPalette(
              commands: [
                DocumentCommand(
                  id: 'find',
                  title: 'Find and replace',
                  subtitle: 'Search the document',
                  icon: Icons.find_replace,
                  category: 'Edit',
                  shortcut: 'Ctrl F',
                  onSelected: () {},
                ),
                DocumentCommand(
                  id: 'share',
                  title: 'Share document',
                  subtitle: 'Open sharing controls',
                  icon: Icons.lock_open_outlined,
                  category: 'Collaborate',
                  shortcut: 'Ctrl Shift S',
                  keywords: const ['collaboration'],
                  onSelected: () {},
                ),
              ],
              onCommandSelected: (command) => selectedCommand = command,
            ),
          ),
        ),
      );

      expect(
        find.byKey(DocumentCommandPalette.commandPreviewKey),
        findsOneWidget,
      );
      expect(find.text('Top result'), findsOneWidget);
      expect(find.text('Ready'), findsOneWidget);
      expect(find.text('Ctrl F'), findsWidgets);

      await tester.enterText(
        find.byKey(DocumentCommandPalette.searchFieldKey),
        'collaboration',
      );
      await tester.pump();

      expect(find.text('Ctrl Shift S'), findsWidgets);

      await tester.tap(find.byKey(DocumentCommandPreviewPanel.runButtonKey));

      expect(selectedCommand?.id, 'share');
    });

    testWidgets('highlights and submits the active top result', (tester) async {
      DocumentCommand? selectedCommand;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DocumentCommandPalette(
              commands: [
                DocumentCommand(
                  id: 'find',
                  title: 'Find and replace',
                  subtitle: 'Search the document',
                  icon: Icons.find_replace,
                  category: 'Edit',
                  onSelected: () {},
                ),
                DocumentCommand(
                  id: 'share',
                  title: 'Share document',
                  subtitle: 'Open sharing controls',
                  icon: Icons.lock_open_outlined,
                  category: 'Collaborate',
                  keywords: const ['collaboration'],
                  onSelected: () {},
                ),
              ],
              onCommandSelected: (command) => selectedCommand = command,
            ),
          ),
        ),
      );

      expect(
        tester
            .widget<ListTile>(
              find.byKey(const Key('document-command-palette-tile-find')),
            )
            .selected,
        isTrue,
      );

      await tester.enterText(
        find.byKey(DocumentCommandPalette.searchFieldKey),
        'collaboration',
      );
      await tester.pump();

      expect(
        tester
            .widget<ListTile>(
              find.byKey(const Key('document-command-palette-tile-share')),
            )
            .selected,
        isTrue,
      );

      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pump();

      expect(selectedCommand?.id, 'share');
    });

    testWidgets('moves the active result with arrow keys', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DocumentCommandPalette(
              commands: [
                DocumentCommand(
                  id: 'find',
                  title: 'Find and replace',
                  subtitle: 'Search the document',
                  icon: Icons.find_replace,
                  category: 'Edit',
                  onSelected: () {},
                ),
                DocumentCommand(
                  id: 'share',
                  title: 'Share document',
                  subtitle: 'Open sharing controls',
                  icon: Icons.lock_open_outlined,
                  category: 'Collaborate',
                  onSelected: () {},
                ),
              ],
            ),
          ),
        ),
      );

      await tester.tap(find.byKey(DocumentCommandPalette.searchFieldKey));
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();

      expect(
        tester
            .widget<ListTile>(
              find.byKey(const Key('document-command-palette-tile-find')),
            )
            .selected,
        isFalse,
      );
      expect(
        tester
            .widget<ListTile>(
              find.byKey(const Key('document-command-palette-tile-share')),
            )
            .selected,
        isTrue,
      );

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pump();

      expect(
        tester
            .widget<ListTile>(
              find.byKey(const Key('document-command-palette-tile-find')),
            )
            .selected,
        isTrue,
      );
    });

    testWidgets('scrolls the active keyboard result into view', (tester) async {
      final commands = [
        for (var index = 0; index < 18; index++)
          DocumentCommand(
            id: 'command-$index',
            title: 'Command $index',
            subtitle: 'Run command $index',
            icon: Icons.bolt_outlined,
            category: 'General',
            onSelected: () {},
          ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: DocumentCommandPalette(commands: commands)),
        ),
      );

      await tester.tap(find.byKey(DocumentCommandPalette.searchFieldKey));
      await tester.pump();
      for (var index = 0; index < 12; index++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
        await tester.pumpAndSettle();
      }

      final targetTile = find.byKey(
        const Key('document-command-palette-tile-command-12'),
      );
      final targetRect = tester.getRect(targetTile);
      final resultMetaBottom = tester
          .getBottomLeft(find.byKey(DocumentCommandPalette.resultCountKey))
          .dy;
      final previewTop = tester
          .getTopLeft(find.byKey(DocumentCommandPalette.commandPreviewKey))
          .dy;

      expect(tester.widget<ListTile>(targetTile).selected, isTrue);
      expect(targetRect.top, greaterThanOrEqualTo(resultMetaBottom));
      expect(targetRect.bottom, lessThanOrEqualTo(previewTop));
    });

    testWidgets('keeps disabled commands visible but inactive', (tester) async {
      DocumentCommand? selectedCommand;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DocumentCommandPalette(
              commands: [
                DocumentCommand(
                  id: 'save',
                  title: 'Save document',
                  subtitle: 'No unsaved changes right now',
                  icon: Icons.save_outlined,
                  category: 'File',
                  enabled: false,
                  disabledLabel: 'Saved',
                  disabledReason: 'No unsaved changes right now',
                  disabledIcon: Icons.task_alt,
                  shortcut: 'Ctrl S',
                  onSelected: () {},
                ),
              ],
              onCommandSelected: (command) => selectedCommand = command,
            ),
          ),
        ),
      );

      expect(find.text('Save document'), findsWidgets);
      expect(find.text('File'), findsWidgets);
      expect(find.text('Saved'), findsWidgets);
      expect(find.byIcon(Icons.task_alt), findsOneWidget);
      expect(find.text('Ctrl S'), findsWidgets);
      expect(
        find.byKey(DocumentCommandPalette.commandPreviewKey),
        findsOneWidget,
      );

      await tester.tap(
        find.byKey(const Key('document-command-palette-tile-save')),
        warnIfMissed: false,
      );
      await tester.tap(
        find.byKey(DocumentCommandPreviewPanel.runButtonKey),
        warnIfMissed: false,
      );
      await tester.enterText(
        find.byKey(DocumentCommandPalette.searchFieldKey),
        'save',
      );
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pump();

      expect(selectedCommand, isNull);
    });
  });
}

List<DocumentCommand> _commands() {
  return [
    DocumentCommand(
      id: 'find',
      title: 'Find and replace',
      subtitle: 'Search the document',
      icon: Icons.find_replace,
      category: 'Edit',
      keywords: const ['search'],
      suggested: true,
      suggestionPriority: 90,
      onSelected: () {},
    ),
    DocumentCommand(
      id: 'share',
      title: 'Share document',
      subtitle: 'Open sharing controls',
      icon: Icons.lock_open_outlined,
      category: 'Collaborate',
      keywords: const ['collaboration', 'people'],
      onSelected: () {},
    ),
  ];
}
