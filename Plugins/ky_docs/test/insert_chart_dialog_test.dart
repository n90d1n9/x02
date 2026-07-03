import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ky_docs/docx/models/chart_type.dart';
import 'package:ky_docs/docx/models/cloud_sync_service.dart';
import 'package:ky_docs/docx/models/document_metadata.dart';
import 'package:ky_docs/docx/models/document_storage_service.dart';
import 'package:ky_docs/docx/states/provider.dart';
import 'package:ky_docs/docx/widgets/insert_elements/insert_chart_dialog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('InsertChartDialog', () {
    testWidgets('renders chart fields and inserts selected chart', (
      tester,
    ) async {
      final container = _createContainer();
      addTearDown(container.dispose);

      await _pumpDialogLauncher(tester, container);

      await tester.tap(find.text('Open chart dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Insert Chart'), findsOneWidget);
      expect(find.text('Chart setup'), findsOneWidget);
      expect(find.text('Data series'), findsOneWidget);
      expect(find.text('BAR'), findsOneWidget);

      await tester.enterText(
        find.widgetWithText(TextField, 'Title'),
        'Revenue mix',
      );
      await tester.pump();
      tester
          .widget<DropdownButtonFormField<ChartType>>(
            find.byKey(InsertChartDialog.chartTypeFieldKey),
          )
          .onChanged
          ?.call(ChartType.line);
      await tester.pump();
      await tester.enterText(
        find.widgetWithText(TextField, 'Labels (comma-separated)'),
        'Q1, Q2, Q3',
      );
      await tester.pump();
      await tester.enterText(
        find.widgetWithText(TextField, 'Values (comma-separated)'),
        '12, 18, 24',
      );
      await tester.pump();

      await tester.tap(find.text('Insert'));
      await tester.pumpAndSettle();

      final chart = container.read(documentProvider).charts.single;
      expect(chart.type, ChartType.line);
      expect(chart.title, 'Revenue mix');
      expect(chart.labels, ['Q1', 'Q2', 'Q3']);
      expect(chart.values, [12, 18, 24]);
      expect(find.text('Chart inserted'), findsOneWidget);
    });

    testWidgets('shows validation feedback when label/value counts differ', (
      tester,
    ) async {
      final container = _createContainer();
      addTearDown(container.dispose);

      await _pumpDialogLauncher(tester, container);

      await tester.tap(find.text('Open chart dialog'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextField, 'Labels (comma-separated)'),
        'A, B, C',
      );
      await tester.pump();
      await tester.enterText(
        find.widgetWithText(TextField, 'Values (comma-separated)'),
        '10, 20',
      );
      await tester.pump();

      await tester.tap(find.text('Insert'));
      await tester.pumpAndSettle();

      expect(container.read(documentProvider).charts, isEmpty);
      expect(
        find.textContaining('Labels and values count must match'),
        findsOneWidget,
      );
      expect(find.text('Insert Chart'), findsOneWidget);
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

Future<void> _pumpDialogLauncher(
  WidgetTester tester,
  ProviderContainer container,
) {
  return tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return TextButton(
                onPressed: () => InsertChartDialog.show(context),
                child: const Text('Open chart dialog'),
              );
            },
          ),
        ),
      ),
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
