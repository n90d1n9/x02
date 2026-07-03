import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ky_docs/docx/models/cloud_sync_service.dart';
import 'package:ky_docs/docx/models/document_metadata.dart';
import 'package:ky_docs/docx/models/document_storage_service.dart';
import 'package:ky_docs/docx/states/provider.dart';
import 'package:ky_docs/docx/widgets/insert_elements/insert_table_dialog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('InsertTableDialog', () {
    testWidgets('renders table sizing controls and inserts selected table', (
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
                    onPressed: () => InsertTableDialog.show(context),
                    child: const Text('Open table dialog'),
                  );
                },
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open table dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Insert Table'), findsOneWidget);
      expect(find.text('Table size'), findsOneWidget);
      expect(find.text('Rows'), findsOneWidget);
      expect(find.text('Columns'), findsOneWidget);
      expect(find.text('3'), findsNWidgets(2));

      tester
          .widget<Slider>(find.byKey(InsertTableDialog.rowsSliderKey))
          .onChanged
          ?.call(5);
      await tester.pump();
      tester
          .widget<Slider>(find.byKey(InsertTableDialog.columnsSliderKey))
          .onChanged
          ?.call(4);
      await tester.pump();

      await tester.tap(find.text('Insert'));
      await tester.pumpAndSettle();

      final table = container.read(documentProvider).tables.single;
      expect(table.rows, 5);
      expect(table.columns, 4);
      expect(find.text('Table (5x4) inserted'), findsOneWidget);
    });
  });
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
