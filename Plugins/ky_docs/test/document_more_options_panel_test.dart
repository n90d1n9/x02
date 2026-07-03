import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ky_docs/docx/widgets/more_options/document_more_option.dart';
import 'package:ky_docs/docx/widgets/more_options/document_more_options_panel.dart';

void main() {
  group('DocumentMoreOptionsPanel', () {
    testWidgets('renders grouped document tools', (tester) async {
      await _pumpPanel(tester);

      expect(find.text('Document tools'), findsOneWidget);
      expect(find.text('2 tools across 2 groups'), findsOneWidget);
      expect(find.text('Document'), findsOneWidget);
      expect(find.text('Layout'), findsOneWidget);
      expect(find.text('Duplicate document'), findsOneWidget);
      expect(find.text('Page settings'), findsOneWidget);
      expect(find.text('Headers and footers'), findsOneWidget);
      expect(find.text('Ctrl P'), findsOneWidget);
    });

    testWidgets('routes option selections', (tester) async {
      DocumentMoreOptionId? selectedOption;

      await _pumpPanel(
        tester,
        onOptionSelected: (option) => selectedOption = option,
      );

      await tester.tap(_optionFinder(DocumentMoreOptionId.pageSettings));

      expect(selectedOption, DocumentMoreOptionId.pageSettings);
    });

    testWidgets('filters tools by title and subtitle', (tester) async {
      await _pumpPanel(tester);

      await tester.enterText(
        find.byKey(DocumentMoreOptionsPanel.searchFieldKey),
        'page',
      );
      await tester.pump();

      expect(find.text('1 of 2 tool matching "page"'), findsOneWidget);
      expect(find.text('Page settings'), findsOneWidget);
      expect(find.text('Headers and footers'), findsOneWidget);
      expect(find.text('Duplicate document'), findsNothing);
    });

    testWidgets('clears filtered tools search', (tester) async {
      await _pumpPanel(tester);

      await tester.enterText(
        find.byKey(DocumentMoreOptionsPanel.searchFieldKey),
        'page',
      );
      await tester.pump();
      await tester.tap(
        find.byKey(DocumentMoreOptionsPanel.clearSearchButtonKey),
      );
      await tester.pump();

      expect(find.text('2 tools across 2 groups'), findsOneWidget);
      expect(find.text('Duplicate document'), findsOneWidget);
      expect(find.text('Page settings'), findsOneWidget);
    });

    testWidgets('renders empty state for searches without matches', (
      tester,
    ) async {
      await _pumpPanel(tester);

      await tester.enterText(
        find.byKey(DocumentMoreOptionsPanel.searchFieldKey),
        'unavailable',
      );
      await tester.pump();

      expect(find.text('No tools match "unavailable"'), findsOneWidget);
      expect(find.text('No matching tools'), findsOneWidget);
      expect(
        find.text('No document tools match "unavailable".'),
        findsOneWidget,
      );
    });

    testWidgets('renders disabled tools without routing selections', (
      tester,
    ) async {
      DocumentMoreOptionId? selectedOption;

      await _pumpPanel(
        tester,
        groups: const [
          DocumentMoreOptionGroup(
            title: 'Create',
            icon: Icons.add_box_outlined,
            options: [
              DocumentMoreOption(
                id: DocumentMoreOptionId.aiAssistant,
                icon: Icons.psychology_outlined,
                title: 'AI assistant',
                subtitle: 'Switch to Editing mode',
                enabled: false,
                disabledReason: 'Switch to Editing mode',
              ),
            ],
          ),
        ],
        onOptionSelected: (option) => selectedOption = option,
      );

      expect(find.text('AI assistant'), findsOneWidget);
      expect(find.byIcon(Icons.lock_outline), findsOneWidget);

      await tester.tap(_optionFinder(DocumentMoreOptionId.aiAssistant));

      expect(selectedOption, isNull);
    });

    testWidgets('routes close action when provided', (tester) async {
      var closed = false;

      await _pumpPanel(tester, onClose: () => closed = true);
      await tester.tap(find.byKey(DocumentMoreOptionsPanel.closeButtonKey));

      expect(closed, isTrue);
    });

    testWidgets('renders empty state when no tools are registered', (
      tester,
    ) async {
      await _pumpPanel(tester, groups: const []);

      expect(find.text('No document tools available'), findsOneWidget);
      expect(find.text('No document tools'), findsOneWidget);
      expect(
        find.text('Configured document commands will appear here.'),
        findsOneWidget,
      );
    });
  });
}

Finder _optionFinder(DocumentMoreOptionId option) {
  return find.byKey(
    ValueKey('${DocumentMoreOptionsPanel.optionPrefixKey}-$option'),
  );
}

Future<void> _pumpPanel(
  WidgetTester tester, {
  List<DocumentMoreOptionGroup>? groups,
  ValueChanged<DocumentMoreOptionId>? onOptionSelected,
  VoidCallback? onClose,
}) {
  return tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: DocumentMoreOptionsPanel(
          groups:
              groups ??
              const [
                DocumentMoreOptionGroup(
                  title: 'Document',
                  icon: Icons.description_outlined,
                  options: [
                    DocumentMoreOption(
                      id: DocumentMoreOptionId.duplicate,
                      icon: Icons.content_copy,
                      title: 'Duplicate document',
                    ),
                  ],
                ),
                DocumentMoreOptionGroup(
                  title: 'Layout',
                  icon: Icons.view_quilt_outlined,
                  options: [
                    DocumentMoreOption(
                      id: DocumentMoreOptionId.pageSettings,
                      icon: Icons.settings_outlined,
                      title: 'Page settings',
                      subtitle: 'Headers and footers',
                      shortcutLabel: 'Ctrl P',
                    ),
                  ],
                ),
              ],
          onOptionSelected: onOptionSelected ?? (_) {},
          onClose: onClose,
        ),
      ),
    ),
  );
}
