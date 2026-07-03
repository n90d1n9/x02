import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ky_docs/docx/models/cloud_sync_service.dart';
import 'package:ky_docs/docx/models/document_metadata.dart';
import 'package:ky_docs/docx/models/document_storage_service.dart';
import 'package:ky_docs/docx/states/provider.dart';
import 'package:ky_docs/docx/widgets/tags_dialog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TagsDialog', () {
    testWidgets('adds and removes tags through shared text field', (
      tester,
    ) async {
      final container = _createContainer();
      addTearDown(container.dispose);

      await _pumpDialog(tester, container);

      expect(find.text('Manage Tags'), findsOneWidget);
      expect(find.text('No tags yet. Add one above!'), findsOneWidget);
      expect(find.byIcon(Icons.sell_outlined), findsOneWidget);
      expect(
        tester
            .widget<IconButton>(find.widgetWithIcon(IconButton, Icons.add))
            .onPressed,
        isNull,
      );

      await tester.enterText(
        find.widgetWithText(TextField, 'Add Tag'),
        ' review ',
      );
      await tester.pump();

      expect(
        tester
            .widget<IconButton>(find.widgetWithIcon(IconButton, Icons.add))
            .onPressed,
        isNotNull,
      );

      await tester.tap(find.byTooltip('Add tag'));
      await tester.pumpAndSettle();

      expect(container.read(documentProvider).metadata.tags, ['review']);
      expect(find.text('review'), findsOneWidget);

      await tester.tap(find.byTooltip('Delete'));
      await tester.pumpAndSettle();

      expect(container.read(documentProvider).metadata.tags, isEmpty);
      expect(find.text('No tags yet. Add one above!'), findsOneWidget);
    });

    testWidgets('adds a tag from submitted text', (tester) async {
      final container = _createContainer();
      addTearDown(container.dispose);

      await _pumpDialog(tester, container);

      tester
          .widget<TextField>(find.widgetWithText(TextField, 'Add Tag'))
          .onSubmitted
          ?.call('client');
      await tester.pumpAndSettle();

      expect(container.read(documentProvider).metadata.tags, ['client']);
      expect(find.text('client'), findsOneWidget);
    });
  });
}

ProviderContainer _createContainer() {
  return ProviderContainer(
    overrides: [
      cloudSyncServiceProvider.overrideWithValue(_FakeCloudSyncService()),
      documentStorageServiceProvider.overrideWithValue(_FakeStorage()),
    ],
  );
}

Future<void> _pumpDialog(WidgetTester tester, ProviderContainer container) {
  return tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: Scaffold(body: TagsDialog())),
    ),
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
