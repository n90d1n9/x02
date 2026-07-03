import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ky_docs/docx/models/cloud_sync_service.dart';
import 'package:ky_docs/docx/models/document_editing_mode.dart';
import 'package:ky_docs/docx/models/document_metadata.dart';
import 'package:ky_docs/docx/models/document_storage_service.dart';
import 'package:ky_docs/docx/states/provider.dart';
import 'package:ky_docs/docx/widgets/more_options.dart';
import 'package:ky_docs/docx/widgets/more_options/document_more_option.dart';
import 'package:ky_docs/docx/widgets/more_options/document_more_options_panel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('MoreOptions', () {
    testWidgets('opens rename dialog from sidebar options and updates title', (
      tester,
    ) async {
      final container = ProviderContainer(
        overrides: [
          cloudSyncServiceProvider.overrideWithValue(_FakeCloudSyncService()),
          documentStorageServiceProvider.overrideWithValue(_FakeStorage()),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  return TextButton(
                    onPressed: () {
                      showModalBottomSheet<void>(
                        context: context,
                        builder: (context) => const MoreOptions(),
                      );
                    },
                    child: const Text('Open sidebar options'),
                  );
                },
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open sidebar options'));
      await tester.pumpAndSettle();

      expect(find.text('Rename document'), findsOneWidget);

      await tester.tap(_optionFinder(DocumentMoreOptionId.rename));
      await tester.pumpAndSettle();

      expect(find.text('Document Title'), findsOneWidget);

      await tester.enterText(
        find.widgetWithText(TextField, 'Title'),
        ' Updated Proposal ',
      );
      await tester.pump();
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(
        container.read(documentProvider).metadata.title,
        'Updated Proposal',
      );
      expect(find.text('Document renamed'), findsOneWidget);
    });

    testWidgets('routes find and replace from sidebar options', (tester) async {
      var openedFindReplace = false;
      final container = ProviderContainer(
        overrides: [
          cloudSyncServiceProvider.overrideWithValue(_FakeCloudSyncService()),
          documentStorageServiceProvider.overrideWithValue(_FakeStorage()),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  return TextButton(
                    onPressed: () {
                      showModalBottomSheet<void>(
                        context: context,
                        builder: (context) => MoreOptions(
                          editingMode: DocumentEditingMode.suggesting,
                          onShowFindReplace: () => openedFindReplace = true,
                        ),
                      );
                    },
                    child: const Text('Open sidebar options'),
                  );
                },
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open sidebar options'));
      await tester.pumpAndSettle();

      expect(find.text('Find and replace'), findsOneWidget);
      expect(find.text('Replacements are made in review mode'), findsOneWidget);

      await tester.ensureVisible(
        _optionFinder(DocumentMoreOptionId.findReplace),
      );
      await tester.pumpAndSettle();
      await tester.tap(_optionFinder(DocumentMoreOptionId.findReplace));
      await tester.pumpAndSettle();

      expect(openedFindReplace, isTrue);
      expect(find.text('Find and replace'), findsNothing);
    });

    testWidgets('routes create panels from sidebar options', (tester) async {
      var openedAiAssistant = false;
      var openedInsertTools = false;
      final container = ProviderContainer(
        overrides: [
          cloudSyncServiceProvider.overrideWithValue(_FakeCloudSyncService()),
          documentStorageServiceProvider.overrideWithValue(_FakeStorage()),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  return TextButton(
                    onPressed: () {
                      showModalBottomSheet<void>(
                        context: context,
                        builder: (context) => MoreOptions(
                          onShowAIAssistant: () => openedAiAssistant = true,
                          onShowInsertPanel: () => openedInsertTools = true,
                        ),
                      );
                    },
                    child: const Text('Open sidebar options'),
                  );
                },
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open sidebar options'));
      await tester.pumpAndSettle();

      expect(find.text('AI assistant'), findsOneWidget);
      expect(find.text('Draft, rewrite, summarize, improve'), findsOneWidget);
      expect(find.text('Insert tools'), findsOneWidget);
      expect(find.text('Tables, charts, shapes, footnotes'), findsOneWidget);

      await tester.ensureVisible(
        _optionFinder(DocumentMoreOptionId.aiAssistant),
      );
      await tester.pumpAndSettle();
      await tester.tap(_optionFinder(DocumentMoreOptionId.aiAssistant));
      await tester.pumpAndSettle();

      expect(openedAiAssistant, isTrue);

      await tester.tap(find.text('Open sidebar options'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(
        _optionFinder(DocumentMoreOptionId.insertTools),
      );
      await tester.pumpAndSettle();
      await tester.tap(_optionFinder(DocumentMoreOptionId.insertTools));
      await tester.pumpAndSettle();

      expect(openedInsertTools, isTrue);
    });

    testWidgets('locks create panels in viewing mode', (tester) async {
      var openedAiAssistant = false;
      var openedInsertTools = false;
      final container = ProviderContainer(
        overrides: [
          cloudSyncServiceProvider.overrideWithValue(_FakeCloudSyncService()),
          documentStorageServiceProvider.overrideWithValue(_FakeStorage()),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  return TextButton(
                    onPressed: () {
                      showModalBottomSheet<void>(
                        context: context,
                        builder: (context) => MoreOptions(
                          editingMode: DocumentEditingMode.viewing,
                          onShowAIAssistant: () => openedAiAssistant = true,
                          onShowInsertPanel: () => openedInsertTools = true,
                        ),
                      );
                    },
                    child: const Text('Open sidebar options'),
                  );
                },
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open sidebar options'));
      await tester.pumpAndSettle();

      expect(
        find.text(
          'Switch to Editing or Suggesting mode to change the document',
        ),
        findsNWidgets(2),
      );

      await tester.ensureVisible(
        _optionFinder(DocumentMoreOptionId.aiAssistant),
      );
      await tester.pumpAndSettle();
      await tester.tap(_optionFinder(DocumentMoreOptionId.aiAssistant));
      await tester.pumpAndSettle();
      await tester.ensureVisible(
        _optionFinder(DocumentMoreOptionId.insertTools),
      );
      await tester.pumpAndSettle();
      await tester.tap(_optionFinder(DocumentMoreOptionId.insertTools));
      await tester.pumpAndSettle();

      expect(openedAiAssistant, isFalse);
      expect(openedInsertTools, isFalse);
    });

    testWidgets('filters sidebar tools by keywords and shortcuts', (
      tester,
    ) async {
      final container = ProviderContainer(
        overrides: [
          cloudSyncServiceProvider.overrideWithValue(_FakeCloudSyncService()),
          documentStorageServiceProvider.overrideWithValue(_FakeStorage()),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  return TextButton(
                    onPressed: () {
                      showModalBottomSheet<void>(
                        context: context,
                        builder: (context) => const MoreOptions(),
                      );
                    },
                    child: const Text('Open sidebar options'),
                  );
                },
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open sidebar options'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(DocumentMoreOptionsPanel.searchFieldKey),
        'word count',
      );
      await tester.pump();

      expect(find.text('Writing statistics'), findsOneWidget);
      expect(find.text('AI assistant'), findsNothing);

      await tester.enterText(
        find.byKey(DocumentMoreOptionsPanel.searchFieldKey),
        'ctrl p',
      );
      await tester.pump();

      expect(find.text('Print'), findsOneWidget);
      expect(find.text('Ctrl P'), findsOneWidget);
      expect(find.text('Writing statistics'), findsNothing);
    });

    testWidgets('routes navigation panels from sidebar options', (
      tester,
    ) async {
      var openedOutline = false;
      var openedPageNavigator = false;
      final container = ProviderContainer(
        overrides: [
          cloudSyncServiceProvider.overrideWithValue(_FakeCloudSyncService()),
          documentStorageServiceProvider.overrideWithValue(_FakeStorage()),
        ],
      );
      addTearDown(container.dispose);

      container
          .read(documentProvider)
          .controller
          .document
          .insert(0, '# Overview\n\n## Details\nBody text');
      container.read(documentProvider.notifier).updatePageCount(5);
      container.read(documentProvider.notifier).selectPage(2);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  return TextButton(
                    onPressed: () {
                      showModalBottomSheet<void>(
                        context: context,
                        builder: (context) => MoreOptions(
                          onShowOutline: () => openedOutline = true,
                          onShowPageNavigator: () => openedPageNavigator = true,
                        ),
                      );
                    },
                    child: const Text('Open sidebar options'),
                  );
                },
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open sidebar options'));
      await tester.pumpAndSettle();

      expect(find.text('Document outline'), findsOneWidget);
      expect(find.text('2 headings'), findsOneWidget);
      expect(find.text('Page navigator'), findsOneWidget);
      expect(find.text('Page 2 of 5 pages'), findsOneWidget);

      await tester.ensureVisible(_optionFinder(DocumentMoreOptionId.outline));
      await tester.pumpAndSettle();
      await tester.tap(_optionFinder(DocumentMoreOptionId.outline));
      await tester.pumpAndSettle();

      expect(openedOutline, isTrue);

      await tester.tap(find.text('Open sidebar options'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(
        _optionFinder(DocumentMoreOptionId.pageNavigator),
      );
      await tester.pumpAndSettle();
      await tester.tap(_optionFinder(DocumentMoreOptionId.pageNavigator));
      await tester.pumpAndSettle();

      expect(openedPageNavigator, isTrue);
    });

    testWidgets('routes writing statistics from sidebar options', (
      tester,
    ) async {
      var openedStatistics = false;
      final container = ProviderContainer(
        overrides: [
          cloudSyncServiceProvider.overrideWithValue(_FakeCloudSyncService()),
          documentStorageServiceProvider.overrideWithValue(_FakeStorage()),
        ],
      );
      addTearDown(container.dispose);

      container
          .read(documentProvider)
          .controller
          .document
          .insert(0, 'Alpha beta gamma.');

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  return TextButton(
                    onPressed: () {
                      showModalBottomSheet<void>(
                        context: context,
                        builder: (context) => MoreOptions(
                          onShowStatistics: () => openedStatistics = true,
                        ),
                      );
                    },
                    child: const Text('Open sidebar options'),
                  );
                },
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open sidebar options'));
      await tester.pumpAndSettle();

      expect(find.text('Writing statistics'), findsOneWidget);
      expect(find.text('3 words - 1 min read'), findsOneWidget);

      await tester.ensureVisible(
        _optionFinder(DocumentMoreOptionId.statistics),
      );
      await tester.pumpAndSettle();
      await tester.tap(_optionFinder(DocumentMoreOptionId.statistics));
      await tester.pumpAndSettle();

      expect(openedStatistics, isTrue);
      expect(find.text('Writing statistics'), findsNothing);
    });
  });
}

Finder _optionFinder(DocumentMoreOptionId option) {
  return find.byKey(
    ValueKey('${DocumentMoreOptionsPanel.optionPrefixKey}-$option'),
  );
}

class _FakeStorage extends DocumentStorageService {
  @override
  Future<void> initialize() async {}
}

class _FakeCloudSyncService extends CloudSyncService {
  @override
  Future<void> syncDocument(
    String docId,
    String content,
    DocumentMetadata metadata,
  ) async {}
}
