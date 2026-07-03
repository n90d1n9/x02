import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ky_office_core/ky_office_core.dart';
import 'package:ky_sheet/ky_sheet.dart';
import 'package:ky_sheet/widget/sheet_headers.dart';
import 'package:ky_sheet/widget/spreadsheet_cell.dart';

void main() {
  test('exposes Office family product metadata', () {
    expect(kySheetOfficeProduct, KyOfficeProducts.sheets);
    expect(kySheetOfficeProduct.id, 'sheets');
    expect(kySheetOfficeProduct.familyName, 'Kaysir');
    expect(kySheetOfficeProduct.kind, KyOfficeProductKind.spreadsheet);
    expect(kySheetOfficeProduct.supports('analyze'), isTrue);
  });

  testWidgets('renders the spreadsheet inside the Office family shell', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1600, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    KyOfficeProductDescriptor? selectedProduct;

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: SheetOfficeWorkspace(
            onProductSelected: (product) => selectedProduct = product,
          ),
        ),
      ),
    );

    expect(find.text('Kaysir Office'), findsOneWidget);
    expect(find.text('Kaysir Sheets'), findsOneWidget);
    expect(find.text('Ky Sheet'), findsOneWidget);

    await tester.tap(find.text('Kaysir Slides'));
    expect(selectedProduct, KyOfficeProducts.slides);
  });

  group('SheetCommandCatalog', () {
    test('searches spreadsheet commands by title, shortcut, and keywords', () {
      expect(
        SheetCommandCatalog.search('formula health').single.id,
        'panel.formulaHealth',
      );
      expect(SheetCommandCatalog.search('ctrl z').first.id, 'edit.undo');
      expect(
        SheetCommandCatalog.search('valid values').single.id,
        'panel.dataValidation',
      );
      expect(
        SheetCommandCatalog.search('keyboard guide').single.id,
        'panel.shortcuts',
      );
      expect(SheetCommandCatalog.search('ctrl /').single.id, 'panel.shortcuts');
      expect(
        SheetCommandCatalog.search('f1 help').single.id,
        'panel.shortcuts',
      );
      expect(
        SheetCommandCatalog.search('ctrl shift l').single.id,
        'panel.sortFilter',
      );
    });

    test('tracks recent commands newest first without duplicates', () {
      final recent = RecentSheetCommandNotifier();
      final dataValidation = SheetCommandCatalog.search('valid values').single;
      final formulaHealth = SheetCommandCatalog.search('formula health').single;

      recent.record(dataValidation);
      recent.record(formulaHealth);
      recent.record(dataValidation);

      expect(recent.state, ['panel.dataValidation', 'panel.formulaHealth']);
      expect(
        recent.resolve(SheetCommandCatalog.all).map((command) => command.id),
        ['panel.dataValidation', 'panel.formulaHealth'],
      );
    });
  });

  group('SheetShortcutCatalog', () {
    test('searches supported shortcuts by title, key, and category', () {
      expect(
        SheetShortcutCatalog.search('ctrl+f').single.id,
        'tools.findReplace',
      );
      expect(SheetShortcutCatalog.search('ctrl+h').single.id, 'tools.replace');
      expect(
        SheetShortcutCatalog.search('ctrl shift l').single.id,
        'tools.sortFilter',
      );
      expect(
        SheetShortcutCatalog.search('esc sidebar').single.id,
        'tools.closePanel',
      );
      expect(
        SheetShortcutCatalog.search('ctrl / guide').single.id,
        'tools.shortcuts',
      );
      expect(SheetShortcutCatalog.search('f1 help').single.id, 'tools.help');
      expect(SheetShortcutCatalog.search('ctrl+b').single.id, 'format.bold');
      expect(SheetShortcutCatalog.search('f2').single.id, 'edit.cell');
      expect(
        SheetShortcutCatalog.search('visible sheet').map((shortcut) {
          return shortcut.id;
        }),
        containsAll(['sheets.previousVisible', 'sheets.nextVisible']),
      );
      expect(
        SheetShortcutCatalog.search(
          '',
          category: SheetShortcutCategory.tools,
        ).map((shortcut) => shortcut.id),
        containsAll(['tools.commandPalette', 'tools.help']),
      );
      expect(
        SheetShortcutCatalog.search(
          '',
          category: SheetShortcutCategory.tools,
        ).map((shortcut) => shortcut.category).toSet(),
        {SheetShortcutCategory.tools},
      );
    });
  });

  group('SheetCommandPaletteDialog', () {
    testWidgets('shows recent commands and disabled command hints', (
      tester,
    ) async {
      final dataValidation = SheetCommandCatalog.search('valid values').single;

      await tester.pumpWidget(
        MaterialApp(
          home: SheetCommandPaletteDialog(
            recentCommands: [dataValidation],
            availability: const SheetCommandAvailability(
              disabledReasons: {'edit.undo': 'Nothing to undo'},
            ),
          ),
        ),
      );

      expect(find.text('Recent'), findsOneWidget);
      expect(find.text('Nothing to undo'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('ky-sheet-command-panel.dataValidation')),
        findsOneWidget,
      );
    });

    testWidgets('supports arrow key selection and enter execution', (
      tester,
    ) async {
      final commands = [
        SheetCommandCatalog.search('data insights').single,
        SheetCommandCatalog.search('valid values').single,
      ];

      await tester.pumpWidget(
        MaterialApp(home: _CommandPaletteSelectionHost(commands: commands)),
      );

      await tester.tap(
        find.byKey(const ValueKey('ky-sheet-test-open-palette')),
      );
      await tester.pumpAndSettle();

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();

      expect(find.text('panel.dataValidation'), findsOneWidget);
    });

    testWidgets('filters commands and opens the selected sidebar panel', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1600, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: SpreadsheetScreen()),
        ),
      );

      await tester.tap(
        find.byKey(const ValueKey('ky-sheet-command-palette-button')),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('ky-sheet-command-palette-search')),
        findsOneWidget,
      );

      await tester.enterText(
        find.byKey(const ValueKey('ky-sheet-command-palette-search')),
        'validation',
      );
      await tester.pumpAndSettle();

      expect(find.text('Data Validation'), findsOneWidget);
      expect(find.text('Chart Builder'), findsNothing);

      await tester.tap(
        find.byKey(const ValueKey('ky-sheet-command-panel.dataValidation')),
      );
      await tester.pumpAndSettle();

      expect(
        container.read(activeSidebarPanelProvider),
        SheetSidebarPanel.dataValidation,
      );
      expect(container.read(recentSheetCommandIdsProvider), [
        'panel.dataValidation',
      ]);
      expect(find.text('Data Validation'), findsOneWidget);
    });
  });

  group('CellAddress', () {
    test('formats spreadsheet labels', () {
      expect(CellAddress(0, 0).label, 'A1');
      expect(CellAddress(9, 25).label, 'Z10');
      expect(CellAddress(0, 26).label, 'AA1');
      expect(CellAddress(0, 701).label, 'ZZ1');
    });
  });

  group('CellSelection', () {
    test('normalizes reversed ranges for labels and containment', () {
      final selection = CellSelection(CellAddress(4, 3), CellAddress(1, 1));

      expect(selection.label, 'B2:D5');
      expect(selection.cellCount, 12);
      expect(selection.contains(CellAddress(2, 2)), isTrue);
      expect(selection.contains(CellAddress(5, 2)), isFalse);
      expect(selection.spansRow(3), isTrue);
      expect(selection.spansColumn(0), isFalse);
    });
  });

  group('SheetRangeParser', () {
    test('parses cells, absolute references, and reversed ranges', () {
      expect(SheetRangeParser.parseSelection('b12')?.label, 'B12');
      expect(SheetRangeParser.parseSelection(r'$C$3')?.label, 'C3');
      expect(SheetRangeParser.parseSelection('D4:A1')?.label, 'A1:D4');
    });

    test('rejects invalid or out-of-bounds references', () {
      expect(SheetRangeParser.parseSelection('A0'), isNull);
      expect(SheetRangeParser.parseSelection('A1:B'), isNull);
      expect(SheetRangeParser.parseSelection('BA1', maxColumns: 52), isNull);
      expect(SheetRangeParser.parseSelection('A201', maxRows: 200), isNull);
    });
  });

  group('SheetNamedRangeNotifier', () {
    test(
      'normalizes names, updates existing ranges, and rejects references',
      () {
        final notifier = SheetNamedRangeNotifier();

        final saved = notifier.save(
          name: 'Revenue FY',
          selection: CellSelection(CellAddress(0, 0), CellAddress(2, 1)),
        );

        expect(saved.name, 'Revenue_FY');
        expect(notifier.state.single.selection.label, 'A1:B3');

        notifier.save(
          name: 'revenue_fy',
          selection: CellSelection(CellAddress(4, 3)),
        );

        expect(notifier.state, hasLength(1));
        expect(notifier.state.single.selection.label, 'D5');
        expect(
          () => notifier.save(
            name: 'A1',
            selection: CellSelection(CellAddress(0, 0)),
          ),
          throwsArgumentError,
        );
      },
    );
  });

  group('SheetTable', () {
    test(
      'normalizes selected ranges and identifies header and banded cells',
      () {
        final table = SheetTable.fromSelection(
          id: 'table-1',
          name: 'Table1',
          selection: CellSelection(CellAddress(3, 2), CellAddress(0, 0)),
          styleId: SheetTableStyleId.mint,
        );

        expect(table.selection.label, 'A1:C4');
        expect(table.isHeaderCell(CellAddress(0, 1)), isTrue);
        expect(table.isHeaderCell(CellAddress(1, 1)), isFalse);
        expect(table.isBandedBodyCell(CellAddress(2, 1)), isTrue);
        expect(table.isBandedBodyCell(CellAddress(1, 1)), isFalse);
        final totalsTable = table.copyWith(showTotalsRow: true);
        expect(totalsTable.hasTotalsRow, isTrue);
        expect(totalsTable.isTotalsCell(CellAddress(3, 1)), isTrue);
        expect(totalsTable.isBandedBodyCell(CellAddress(3, 1)), isFalse);
        expect(
          SheetTable.fromJson(totalsTable.toJson()).styleId,
          SheetTableStyleId.mint,
        );
        expect(SheetTable.fromJson(totalsTable.toJson()).showTotalsRow, isTrue);
      },
    );
  });

  group('SheetTableNotifier', () {
    test('creates uniquely named structured tables from selections', () {
      final notifier = SheetTableNotifier();

      final first = notifier.createFromSelection(
        CellSelection(CellAddress(0, 0), CellAddress(2, 1)),
      );
      final second = notifier.createFromSelection(
        CellSelection(CellAddress(4, 2), CellAddress(7, 4)),
      );

      expect(first.name, 'Table1');
      expect(first.selection.label, 'A1:B3');
      expect(second.name, 'Table2');
      expect(notifier.state.map((table) => table.styleId), [
        SheetTableStyleId.prism,
        SheetTableStyleId.graphite,
      ]);
    });

    test('updates table metadata without touching surrounding tables', () {
      final notifier = SheetTableNotifier();
      final first = notifier.createFromSelection(
        CellSelection(CellAddress(0, 0), CellAddress(2, 1)),
      );
      final second = notifier.createFromSelection(
        CellSelection(CellAddress(4, 2), CellAddress(7, 4)),
      );

      notifier.rename(first.id, 'Sales');
      notifier.rename(second.id, 'Sales');
      notifier.setStyle(first.id, SheetTableStyleId.mint);
      notifier.setSelection(
        first.id,
        CellSelection(CellAddress(5, 4), CellAddress(3, 2)),
      );
      notifier.setHeaderRowVisible(first.id, false);
      notifier.setBandedRowsVisible(first.id, false);
      notifier.setTotalsRowVisible(first.id, true);

      expect(notifier.state[0].name, 'Sales');
      expect(notifier.state[1].name, 'Sales 2');
      expect(notifier.state[0].selection.label, 'C4:E6');
      expect(notifier.state[0].styleId, SheetTableStyleId.mint);
      expect(notifier.state[0].showHeaderRow, isFalse);
      expect(notifier.state[0].showBandedRows, isFalse);
      expect(notifier.state[0].showTotalsRow, isTrue);

      notifier.remove(first.id);

      expect(notifier.state.single.id, second.id);
    });
  });

  group('SheetTableRangeResolver', () {
    test('expands down and right from the table anchor to occupied data', () {
      final table = SheetTable.fromSelection(
        id: 'table-1',
        name: 'Sales',
        selection: CellSelection(CellAddress(1, 1), CellAddress(2, 2)),
      );
      final expanded = SheetTableRangeResolver.expandDownRight(
        table: table,
        cells: {
          CellAddress(0, 0): CellData(value: 'Ignored'),
          CellAddress(1, 1): CellData(value: 'Header'),
          CellAddress(4, 3): CellData(value: 'Tail'),
          CellAddress(5, 0): CellData(value: 'Left side'),
        },
      );

      expect(expanded.label, 'B2:D5');
    });

    test('builds appended row and column table ranges', () {
      final table = SheetTable.fromSelection(
        id: 'table-1',
        name: 'Sales',
        selection: CellSelection(CellAddress(1, 1), CellAddress(3, 3)),
      );

      expect(
        SheetTableRangeResolver.appendRowBelow(table: table).label,
        'B2:D5',
      );
      expect(
        SheetTableRangeResolver.appendColumnRight(table: table).label,
        'B2:E4',
      );
      expect(SheetTableRangeResolver.appendedRow(table: table).label, 'B5:D5');
      expect(
        SheetTableRangeResolver.appendedColumn(table: table).label,
        'E2:E4',
      );
    });
  });

  group('SheetTableTotalFormulaBuilder', () {
    test('builds aggregate formulas against table body columns', () {
      final table = SheetTable.fromSelection(
        id: 'table-1',
        name: 'Sales',
        selection: CellSelection(CellAddress(0, 0), CellAddress(3, 2)),
      ).copyWith(showTotalsRow: true);

      expect(
        SheetTableTotalFormulaBuilder.bodyRangeForColumn(
          table: table,
          column: 1,
        )?.label,
        'B2:B3',
      );
      expect(
        SheetTableTotalFormulaBuilder.buildFormula(
          table: table,
          column: 1,
          function: SheetTableTotalFunction.sum,
        ),
        '=SUM(B2:B3)',
      );
      expect(
        SheetTableTotalFormulaBuilder.buildFormula(
          table: table,
          column: 2,
          function: SheetTableTotalFunction.countA,
        ),
        '=COUNTA(C2:C3)',
      );
    });

    test('returns null when a totals column has no body cells', () {
      final table = SheetTable.fromSelection(
        id: 'table-1',
        name: 'Sales',
        selection: CellSelection(CellAddress(0, 0), CellAddress(1, 1)),
      ).copyWith(showTotalsRow: true);

      expect(
        SheetTableTotalFormulaBuilder.bodyRangeForColumn(
          table: table,
          column: 1,
        ),
        isNull,
      );
    });
  });

  group('SheetTableTotalLabelBuilder', () {
    test('offers label presets only for the leading totals row column', () {
      final table = SheetTable.fromSelection(
        id: 'table-1',
        name: 'Sales',
        selection: CellSelection(CellAddress(0, 0), CellAddress(3, 2)),
      ).copyWith(showTotalsRow: true);

      expect(
        SheetTableTotalLabelBuilder.presetsForColumn(table: table, column: 0),
        SheetTableTotalLabelPreset.values,
      );
      expect(
        SheetTableTotalLabelBuilder.buildLabel(
          table: table,
          column: 0,
          preset: SheetTableTotalLabelPreset.grandTotal,
        ),
        'Grand Total',
      );
      expect(
        SheetTableTotalLabelBuilder.presetsForColumn(table: table, column: 1),
        isEmpty,
      );
      expect(
        SheetTableTotalLabelBuilder.buildLabel(
          table: table,
          column: 1,
          preset: SheetTableTotalLabelPreset.total,
        ),
        isNull,
      );
    });
  });

  group('SheetTableTotalSuggestionBuilder', () {
    test('suggests sum for mostly numeric table body columns', () {
      final table = SheetTable.fromSelection(
        id: 'table-1',
        name: 'Sales',
        selection: CellSelection(CellAddress(0, 0), CellAddress(3, 1)),
      ).copyWith(showTotalsRow: true);

      final suggestion = SheetTableTotalSuggestionBuilder.suggest(
        table: table,
        column: 1,
        cells: {
          CellAddress(1, 1): CellData(value: '12'),
          CellAddress(2, 1): CellData(value: '8'),
        },
      );

      expect(suggestion?.function, SheetTableTotalFunction.sum);
      expect(suggestion?.label, 'Suggested: Sum');
      expect(suggestion?.filledCells, 2);
      expect(suggestion?.numericCells, 2);
    });

    test('suggests count values for text-heavy table body columns', () {
      final table = SheetTable.fromSelection(
        id: 'table-1',
        name: 'Sales',
        selection: CellSelection(CellAddress(0, 0), CellAddress(3, 1)),
      ).copyWith(showTotalsRow: true);

      final suggestion = SheetTableTotalSuggestionBuilder.suggest(
        table: table,
        column: 0,
        cells: {
          CellAddress(1, 0): CellData(value: 'EMEA'),
          CellAddress(2, 0): CellData(value: 'APAC'),
        },
      );

      expect(suggestion?.function, SheetTableTotalFunction.countA);
      expect(suggestion?.label, 'Suggested: Count Values');
    });

    test('returns null when the totals column has no filled body cells', () {
      final table = SheetTable.fromSelection(
        id: 'table-1',
        name: 'Sales',
        selection: CellSelection(CellAddress(0, 0), CellAddress(3, 1)),
      ).copyWith(showTotalsRow: true);

      expect(
        SheetTableTotalSuggestionBuilder.suggest(
          table: table,
          column: 1,
          cells: const {},
        ),
        isNull,
      );
    });
  });

  group('SheetTableTotalAutofillBuilder', () {
    test(
      'builds a totals label and suggested formulas across table columns',
      () {
        final table = SheetTable.fromSelection(
          id: 'table-1',
          name: 'Sales',
          selection: CellSelection(CellAddress(0, 0), CellAddress(3, 3)),
        ).copyWith(showTotalsRow: true);

        final updates = SheetTableTotalAutofillBuilder.buildCells(
          table: table,
          cells: {
            CellAddress(1, 0): CellData(value: 'EMEA'),
            CellAddress(2, 0): CellData(value: 'APAC'),
            CellAddress(1, 1): CellData(value: '12'),
            CellAddress(2, 1): CellData(value: '8'),
            CellAddress(1, 2): CellData(value: 'Open'),
            CellAddress(2, 2): CellData(value: 'Closed'),
          },
        );

        expect(updates[CellAddress(3, 0)]?.value, 'Total');
        expect(updates[CellAddress(3, 0)]?.formula, isNull);
        expect(updates[CellAddress(3, 1)]?.formula, '=SUM(B2:B3)');
        expect(updates[CellAddress(3, 2)]?.formula, '=COUNTA(C2:C3)');
        expect(updates.containsKey(CellAddress(3, 3)), isFalse);
      },
    );

    test('returns no updates for tables without totals rows', () {
      final table = SheetTable.fromSelection(
        id: 'table-1',
        name: 'Sales',
        selection: CellSelection(CellAddress(0, 0), CellAddress(3, 1)),
      );

      expect(
        SheetTableTotalAutofillBuilder.buildCells(
          table: table,
          cells: const {},
        ),
        isEmpty,
      );
    });

    test('blocks appended totals rows when the target row has data', () {
      final table = SheetTable.fromSelection(
        id: 'table-1',
        name: 'Sales',
        selection: CellSelection(CellAddress(0, 0), CellAddress(2, 1)),
      );

      final plan = SheetTableTotalAutofillBuilder.buildAppendPlan(
        table: table,
        cells: {
          CellAddress(3, 0): CellData(value: 'Existing'),
          CellAddress(1, 1): CellData(value: '2'),
          CellAddress(2, 1): CellData(value: '5'),
        },
      );

      expect(plan.canApply, isFalse);
      expect(plan.tableSelection.label, 'A1:B4');
      expect(plan.totalsRowSelection.label, 'A4:B4');
      expect(plan.cells, isEmpty);
      expect(plan.blockedCells, [CellAddress(3, 0)]);
      expect(plan.blockedLabel, 'A4 has data');
    });
  });

  group('SheetTableDataRowAppendBuilder', () {
    test('appends a plain table row when no totals row is active', () {
      final table = SheetTable.fromSelection(
        id: 'table-1',
        name: 'Sales',
        selection: CellSelection(CellAddress(0, 0), CellAddress(2, 1)),
      );

      final plan = SheetTableDataRowAppendBuilder.build(
        table: table,
        cells: const {},
      );

      expect(plan.canApply, isTrue);
      expect(plan.preservesTotalsRow, isFalse);
      expect(plan.actionLabel, 'Add Row Below');
      expect(plan.tableSelection.label, 'A1:B4');
      expect(plan.rowSelection.label, 'A4:B4');
      expect(plan.replacements, isEmpty);
    });

    test('inherits formatting and validation when appending plain rows', () {
      final table = SheetTable.fromSelection(
        id: 'table-1',
        name: 'Sales',
        selection: CellSelection(CellAddress(0, 0), CellAddress(2, 1)),
      );
      final validation = CellValidation(type: ValidationType.number, min: '0');

      final plan = SheetTableDataRowAppendBuilder.build(
        table: table,
        cells: {
          CellAddress(2, 1): CellData(
            value: '12',
            style: const CellStyle(
              align: TextAlign.right,
              numberFormat: SheetNumberFormatId.currency,
            ),
            validation: validation,
            comment: 'Do not clone',
            hyperlink: 'https://example.com',
          ),
        },
      );

      final inherited = plan.replacements[CellAddress(3, 1)];

      expect(plan.canApply, isTrue);
      expect(plan.tableSelection.label, 'A1:B4');
      expect(plan.rowSelection.label, 'A4:B4');
      expect(inherited?.value, '');
      expect(inherited?.formula, isNull);
      expect(inherited?.style.align, TextAlign.right);
      expect(inherited?.style.numberFormat, SheetNumberFormatId.currency);
      expect(inherited?.validation, validation);
      expect(inherited?.comment, isNull);
      expect(inherited?.hyperlink, isNull);
      expect(plan.replacements.containsKey(CellAddress(3, 0)), isFalse);
    });

    test('fills calculated formulas when appending plain rows', () {
      final table = SheetTable.fromSelection(
        id: 'table-1',
        name: 'Sales',
        selection: CellSelection(CellAddress(0, 0), CellAddress(2, 1)),
      );

      final plan = SheetTableDataRowAppendBuilder.build(
        table: table,
        cells: {
          CellAddress(2, 1): CellData(value: '12', formula: r'=B2+$A$1+"B3"'),
        },
      );

      final filled = plan.replacements[CellAddress(3, 1)];

      expect(plan.canApply, isTrue);
      expect(filled?.value, '');
      expect(filled?.formula, r'=B3+$A$1+"B3"');
      expect(filled?.comment, isNull);
      expect(filled?.hyperlink, isNull);
    });

    test('can append plain rows without copying row templates', () {
      final table = SheetTable.fromSelection(
        id: 'table-1',
        name: 'Sales',
        selection: CellSelection(CellAddress(0, 0), CellAddress(2, 1)),
      );

      final plan = SheetTableDataRowAppendBuilder.build(
        table: table,
        smartFill: false,
        cells: {
          CellAddress(2, 1): CellData(
            value: '12',
            formula: '=B2+3',
            style: const CellStyle(numberFormat: SheetNumberFormatId.number),
            validation: CellValidation(type: ValidationType.number),
          ),
        },
      );

      expect(plan.canApply, isTrue);
      expect(plan.tableSelection.label, 'A1:B4');
      expect(plan.rowSelection.label, 'A4:B4');
      expect(plan.replacements, isEmpty);
    });

    test('blocks plain row appends when the row below has data', () {
      final table = SheetTable.fromSelection(
        id: 'table-1',
        name: 'Sales',
        selection: CellSelection(CellAddress(0, 0), CellAddress(2, 1)),
      );

      final plan = SheetTableDataRowAppendBuilder.build(
        table: table,
        cells: {CellAddress(3, 1): CellData(value: 'Adjacent')},
      );

      expect(plan.canApply, isFalse);
      expect(plan.preservesTotalsRow, isFalse);
      expect(plan.tableSelection.label, 'A1:B4');
      expect(plan.rowSelection.label, 'A4:B4');
      expect(plan.replacements, isEmpty);
      expect(plan.blockedCells, [CellAddress(3, 1)]);
      expect(plan.blockedLabel, 'B4 has data');
    });

    test('moves existing totals cells down when appending a data row', () {
      final table = SheetTable.fromSelection(
        id: 'table-1',
        name: 'Sales',
        selection: CellSelection(CellAddress(0, 0), CellAddress(3, 2)),
      ).copyWith(showTotalsRow: true);

      final plan = SheetTableDataRowAppendBuilder.build(
        table: table,
        cells: {
          CellAddress(1, 0): CellData(value: 'EMEA'),
          CellAddress(2, 0): CellData(value: 'APAC'),
          CellAddress(1, 1): CellData(value: '2'),
          CellAddress(2, 1): CellData(value: '5'),
          CellAddress(1, 2): CellData(value: 'Open'),
          CellAddress(2, 2): CellData(value: 'Closed'),
          CellAddress(3, 0): CellData(value: 'Total'),
          CellAddress(3, 1): CellData(value: '7.00', formula: '=SUM(B2:B3)'),
          CellAddress(3, 2): CellData(value: '2.00', formula: '=COUNTA(C2:C3)'),
        },
      );

      expect(plan.canApply, isTrue);
      expect(plan.preservesTotalsRow, isTrue);
      expect(plan.actionLabel, 'Add Data Row');
      expect(plan.tableSelection.label, 'A1:C5');
      expect(plan.rowSelection.label, 'A4:C4');
      expect(plan.replacements[CellAddress(3, 0)], isNull);
      expect(plan.replacements[CellAddress(3, 1)], isNull);
      expect(plan.replacements[CellAddress(4, 0)]?.value, 'Total');
      expect(plan.replacements[CellAddress(4, 1)]?.formula, '=SUM(B2:B4)');
      expect(plan.replacements[CellAddress(4, 2)]?.formula, '=COUNTA(C2:C4)');
    });

    test('moves totals down without copying row templates for blank rows', () {
      final table = SheetTable.fromSelection(
        id: 'table-1',
        name: 'Sales',
        selection: CellSelection(CellAddress(0, 0), CellAddress(3, 1)),
      ).copyWith(showTotalsRow: true);

      final plan = SheetTableDataRowAppendBuilder.build(
        table: table,
        smartFill: false,
        cells: {
          CellAddress(1, 1): CellData(value: '2'),
          CellAddress(2, 1): CellData(
            value: '5',
            formula: '=B2+3',
            style: const CellStyle(numberFormat: SheetNumberFormatId.number),
            validation: CellValidation(type: ValidationType.number),
          ),
          CellAddress(3, 0): CellData(value: 'Total'),
          CellAddress(3, 1): CellData(value: '7.00', formula: '=SUM(B2:B3)'),
        },
      );

      expect(plan.canApply, isTrue);
      expect(plan.preservesTotalsRow, isTrue);
      expect(plan.tableSelection.label, 'A1:B5');
      expect(plan.rowSelection.label, 'A4:B4');
      expect(plan.replacements.containsKey(CellAddress(3, 0)), isTrue);
      expect(plan.replacements.containsKey(CellAddress(3, 1)), isTrue);
      expect(plan.replacements[CellAddress(3, 0)], isNull);
      expect(plan.replacements[CellAddress(3, 1)], isNull);
      expect(plan.replacements[CellAddress(4, 0)]?.value, 'Total');
      expect(plan.replacements[CellAddress(4, 1)]?.formula, '=SUM(B2:B4)');
    });

    test('inherits row templates when moving totals rows down', () {
      final table = SheetTable.fromSelection(
        id: 'table-1',
        name: 'Sales',
        selection: CellSelection(CellAddress(0, 0), CellAddress(3, 1)),
      ).copyWith(showTotalsRow: true);
      final validation = CellValidation(type: ValidationType.number);

      final plan = SheetTableDataRowAppendBuilder.build(
        table: table,
        cells: {
          CellAddress(1, 1): CellData(value: '2'),
          CellAddress(2, 1): CellData(
            value: '5',
            formula: '=B2+3',
            style: const CellStyle(numberFormat: SheetNumberFormatId.number),
            validation: validation,
          ),
          CellAddress(3, 0): CellData(value: 'Total'),
          CellAddress(3, 1): CellData(value: '7.00', formula: '=SUM(B2:B3)'),
        },
      );

      expect(plan.canApply, isTrue);
      expect(plan.replacements[CellAddress(3, 0)], isNull);
      expect(plan.replacements[CellAddress(3, 1)]?.value, '');
      expect(plan.replacements[CellAddress(3, 1)]?.formula, '=B3+3');
      expect(
        plan.replacements[CellAddress(3, 1)]?.style.numberFormat,
        SheetNumberFormatId.number,
      );
      expect(plan.replacements[CellAddress(3, 1)]?.validation, validation);
      expect(plan.replacements[CellAddress(4, 0)]?.value, 'Total');
      expect(plan.replacements[CellAddress(4, 1)]?.formula, '=SUM(B2:B4)');
    });

    test('blocks totals-row preserving appends when the next row has data', () {
      final table = SheetTable.fromSelection(
        id: 'table-1',
        name: 'Sales',
        selection: CellSelection(CellAddress(0, 0), CellAddress(3, 1)),
      ).copyWith(showTotalsRow: true);

      final plan = SheetTableDataRowAppendBuilder.build(
        table: table,
        cells: {
          CellAddress(4, 1): CellData(value: 'Blocked'),
          CellAddress(1, 1): CellData(value: '2'),
          CellAddress(2, 1): CellData(value: '5'),
        },
      );

      expect(plan.canApply, isFalse);
      expect(plan.replacements, isEmpty);
      expect(plan.blockedCells, [CellAddress(4, 1)]);
      expect(plan.blockedLabel, 'B5 has data');
    });
  });

  group('SheetTableColumnAppendBuilder', () {
    test('appends a table column with a generated header', () {
      final table = SheetTable.fromSelection(
        id: 'table-1',
        name: 'Sales',
        selection: CellSelection(CellAddress(0, 0), CellAddress(2, 1)),
      );

      final plan = SheetTableColumnAppendBuilder.build(
        table: table,
        cells: {
          CellAddress(0, 0): CellData(value: 'Region'),
          CellAddress(0, 1): CellData(value: 'Sales'),
        },
      );

      expect(plan.canApply, isTrue);
      expect(plan.tableSelection.label, 'A1:C3');
      expect(plan.columnSelection.label, 'C1:C3');
      expect(plan.blockedCells, isEmpty);
      expect(plan.replacements[CellAddress(0, 2)]?.value, 'Column 3');
    });

    test('keeps generated table headers unique', () {
      final table = SheetTable.fromSelection(
        id: 'table-1',
        name: 'Sales',
        selection: CellSelection(CellAddress(0, 0), CellAddress(2, 2)),
      );

      final plan = SheetTableColumnAppendBuilder.build(
        table: table,
        cells: {
          CellAddress(0, 0): CellData(value: 'Region'),
          CellAddress(0, 1): CellData(value: 'Column 4'),
          CellAddress(0, 2): CellData(value: 'Sales'),
        },
      );

      expect(plan.canApply, isTrue);
      expect(plan.tableSelection.label, 'A1:D3');
      expect(plan.columnSelection.label, 'D1:D3');
      expect(plan.replacements[CellAddress(0, 3)]?.value, 'Column 5');
    });

    test('extends adjacent totals formulas into appended columns', () {
      final table = SheetTable.fromSelection(
        id: 'table-1',
        name: 'Sales',
        selection: CellSelection(CellAddress(0, 0), CellAddress(3, 2)),
      ).copyWith(showTotalsRow: true);

      final plan = SheetTableColumnAppendBuilder.build(
        table: table,
        cells: {
          CellAddress(0, 0): CellData(value: 'Region'),
          CellAddress(0, 1): CellData(value: 'Sales'),
          CellAddress(0, 2): CellData(value: 'Units'),
          CellAddress(3, 2): CellData(formula: '=SUM(C2:C3)'),
        },
      );

      expect(plan.canApply, isTrue);
      expect(plan.tableSelection.label, 'A1:D4');
      expect(plan.columnSelection.label, 'D1:D4');
      expect(plan.replacements[CellAddress(0, 3)]?.value, 'Column 4');
      expect(plan.replacements[CellAddress(3, 3)]?.formula, '=SUM(D2:D3)');
    });

    test('does not extend custom totals formulas into appended columns', () {
      final table = SheetTable.fromSelection(
        id: 'table-1',
        name: 'Sales',
        selection: CellSelection(CellAddress(0, 0), CellAddress(3, 2)),
      ).copyWith(showTotalsRow: true);

      final plan = SheetTableColumnAppendBuilder.build(
        table: table,
        cells: {
          CellAddress(0, 0): CellData(value: 'Region'),
          CellAddress(0, 1): CellData(value: 'Sales'),
          CellAddress(0, 2): CellData(value: 'Units'),
          CellAddress(3, 2): CellData(formula: '=SUM(B2:B3)'),
        },
      );

      expect(plan.canApply, isTrue);
      expect(plan.replacements[CellAddress(0, 3)]?.value, 'Column 4');
      expect(plan.replacements.containsKey(CellAddress(3, 3)), isFalse);
    });

    test('inherits adjacent column formatting and validation metadata', () {
      final table = SheetTable.fromSelection(
        id: 'table-1',
        name: 'Sales',
        selection: CellSelection(CellAddress(0, 0), CellAddress(2, 2)),
      );
      final validation = CellValidation(
        type: ValidationType.number,
        min: '0',
        max: '100',
      );

      final plan = SheetTableColumnAppendBuilder.build(
        table: table,
        cells: {
          CellAddress(0, 0): CellData(value: 'Region'),
          CellAddress(0, 1): CellData(value: 'Sales'),
          CellAddress(0, 2): CellData(value: 'Margin'),
          CellAddress(1, 2): CellData(
            value: '12',
            style: const CellStyle(
              align: TextAlign.right,
              numberFormat: SheetNumberFormatId.currency,
              wrapText: true,
            ),
            validation: validation,
            comment: 'Do not clone',
            hyperlink: 'https://example.com',
          ),
        },
      );

      final inherited = plan.replacements[CellAddress(1, 3)];

      expect(plan.canApply, isTrue);
      expect(plan.replacements[CellAddress(0, 3)]?.value, 'Column 4');
      expect(inherited?.value, '');
      expect(inherited?.formula, isNull);
      expect(inherited?.style.align, TextAlign.right);
      expect(inherited?.style.numberFormat, SheetNumberFormatId.currency);
      expect(inherited?.style.wrapText, isTrue);
      expect(inherited?.validation, validation);
      expect(inherited?.comment, isNull);
      expect(inherited?.hyperlink, isNull);
      expect(plan.replacements.containsKey(CellAddress(2, 3)), isFalse);
    });

    test('fills calculated formulas when appending table columns', () {
      final table = SheetTable.fromSelection(
        id: 'table-1',
        name: 'Sales',
        selection: CellSelection(CellAddress(0, 0), CellAddress(2, 2)),
      );

      final plan = SheetTableColumnAppendBuilder.build(
        table: table,
        cells: {
          CellAddress(0, 0): CellData(value: 'Region'),
          CellAddress(0, 1): CellData(value: 'Sales'),
          CellAddress(0, 2): CellData(value: 'Margin'),
          CellAddress(1, 2): CellData(value: '12', formula: r'=B2+$A$1+"C2"'),
        },
      );

      final filled = plan.replacements[CellAddress(1, 3)];

      expect(plan.canApply, isTrue);
      expect(filled?.value, '');
      expect(filled?.formula, r'=C2+$A$1+"C2"');
      expect(filled?.comment, isNull);
      expect(filled?.hyperlink, isNull);
    });

    test('can append columns without copying smart fill templates', () {
      final table = SheetTable.fromSelection(
        id: 'table-1',
        name: 'Sales',
        selection: CellSelection(CellAddress(0, 0), CellAddress(3, 2)),
      ).copyWith(showTotalsRow: true);

      final plan = SheetTableColumnAppendBuilder.build(
        table: table,
        smartFill: false,
        cells: {
          CellAddress(0, 0): CellData(value: 'Region'),
          CellAddress(0, 1): CellData(value: 'Sales'),
          CellAddress(0, 2): CellData(value: 'Units'),
          CellAddress(1, 2): CellData(
            value: '12',
            formula: '=B2+3',
            style: const CellStyle(numberFormat: SheetNumberFormatId.number),
            validation: CellValidation(type: ValidationType.number),
          ),
          CellAddress(3, 2): CellData(formula: '=SUM(C2:C3)'),
        },
      );

      expect(plan.canApply, isTrue);
      expect(plan.tableSelection.label, 'A1:D4');
      expect(plan.columnSelection.label, 'D1:D4');
      expect(plan.replacements[CellAddress(0, 3)]?.value, 'Column 4');
      expect(plan.replacements.containsKey(CellAddress(1, 3)), isFalse);
      expect(plan.replacements.containsKey(CellAddress(3, 3)), isFalse);
    });

    test('does not generate headers for headerless tables', () {
      final table = SheetTable.fromSelection(
        id: 'table-1',
        name: 'Sales',
        selection: CellSelection(CellAddress(0, 0), CellAddress(2, 1)),
      ).copyWith(showHeaderRow: false);

      final plan = SheetTableColumnAppendBuilder.build(
        table: table,
        cells: {
          CellAddress(0, 0): CellData(value: 'Region'),
          CellAddress(0, 1): CellData(value: 'Sales'),
        },
      );

      expect(plan.canApply, isTrue);
      expect(plan.tableSelection.label, 'A1:C3');
      expect(plan.columnSelection.label, 'C1:C3');
      expect(plan.replacements, isEmpty);
    });

    test('blocks column appends when the right side has data', () {
      final table = SheetTable.fromSelection(
        id: 'table-1',
        name: 'Sales',
        selection: CellSelection(CellAddress(0, 0), CellAddress(2, 1)),
      );

      final plan = SheetTableColumnAppendBuilder.build(
        table: table,
        cells: {CellAddress(1, 2): CellData(value: 'Adjacent')},
      );

      expect(plan.canApply, isFalse);
      expect(plan.tableSelection.label, 'A1:C3');
      expect(plan.columnSelection.label, 'C1:C3');
      expect(plan.blockedCells, [CellAddress(1, 2)]);
      expect(plan.blockedLabel, 'C2 has data');
      expect(plan.replacements, isEmpty);
    });
  });

  group('SheetTableAppendEffectSummaryBuilder', () {
    test('summarizes smart-filled rows that preserve totals', () {
      final table = SheetTable.fromSelection(
        id: 'table-1',
        name: 'Sales',
        selection: CellSelection(CellAddress(0, 0), CellAddress(3, 1)),
      ).copyWith(showTotalsRow: true);

      final plan = SheetTableDataRowAppendBuilder.build(
        table: table,
        cells: {
          CellAddress(1, 1): CellData(value: '2'),
          CellAddress(2, 1): CellData(
            value: '5',
            formula: '=B2+3',
            style: const CellStyle(numberFormat: SheetNumberFormatId.number),
            validation: CellValidation(type: ValidationType.number),
          ),
          CellAddress(3, 0): CellData(value: 'Total'),
          CellAddress(3, 1): CellData(value: '7.00', formula: '=SUM(B2:B3)'),
        },
      );

      final summary = SheetTableAppendEffectSummaryBuilder.forDataRow(
        plan: plan,
      );

      expect(summary.isBlocked, isFalse);
      expect(summary.hasSmartFill, isTrue);
      expect(summary.effects, [
        SheetTableAppendEffectKind.formulaFill,
        SheetTableAppendEffectKind.formatting,
        SheetTableAppendEffectKind.totalsRow,
      ]);
      expect(
        summary.detailLabel,
        'Smart fill: formulas, formatting and totals',
      );
    });

    test('summarizes smart-filled columns with headers and totals', () {
      final table = SheetTable.fromSelection(
        id: 'table-1',
        name: 'Sales',
        selection: CellSelection(CellAddress(0, 0), CellAddress(3, 2)),
      ).copyWith(showTotalsRow: true);

      final plan = SheetTableColumnAppendBuilder.build(
        table: table,
        cells: {
          CellAddress(0, 0): CellData(value: 'Region'),
          CellAddress(0, 1): CellData(value: 'Sales'),
          CellAddress(0, 2): CellData(value: 'Units'),
          CellAddress(1, 2): CellData(value: '2', formula: '=B2+1'),
          CellAddress(3, 2): CellData(formula: '=SUM(C2:C3)'),
        },
      );

      final summary = SheetTableAppendEffectSummaryBuilder.forColumn(
        table: table,
        plan: plan,
      );

      expect(summary.isBlocked, isFalse);
      expect(summary.effects, [
        SheetTableAppendEffectKind.generatedHeader,
        SheetTableAppendEffectKind.formulaFill,
        SheetTableAppendEffectKind.totalsRow,
      ]);
      expect(summary.detailLabel, 'Smart fill: header, formulas and totals');
    });

    test(
      'summarizes blocked row and column appends as actionable guidance',
      () {
        final table = SheetTable.fromSelection(
          id: 'table-1',
          name: 'Sales',
          selection: CellSelection(CellAddress(0, 0), CellAddress(2, 1)),
        );

        final rowPlan = SheetTableDataRowAppendBuilder.build(
          table: table,
          cells: {CellAddress(3, 0): CellData(value: 'Blocked')},
        );
        final columnPlan = SheetTableColumnAppendBuilder.build(
          table: table,
          cells: {CellAddress(1, 2): CellData(value: 'Blocked')},
        );

        final rowSummary = SheetTableAppendEffectSummaryBuilder.forDataRow(
          plan: rowPlan,
        );
        final columnSummary = SheetTableAppendEffectSummaryBuilder.forColumn(
          table: table,
          plan: columnPlan,
        );

        expect(rowSummary.isBlocked, isTrue);
        expect(rowSummary.detailLabel, 'Choose a clear row below first');
        expect(columnSummary.isBlocked, isTrue);
        expect(
          columnSummary.detailLabel,
          'Choose clear cells to the right first',
        );
      },
    );
  });

  group('SheetTableCalculatedColumnSummaryBuilder', () {
    test('detects fully calculated table columns', () {
      final table = SheetTable.fromSelection(
        id: 'table-1',
        name: 'Sales',
        selection: CellSelection(CellAddress(0, 0), CellAddress(3, 2)),
      ).copyWith(showTotalsRow: true);

      final summary = SheetTableCalculatedColumnSummaryBuilder.build(
        table: table,
        column: 1,
        cells: {
          CellAddress(1, 1): CellData(value: '12', formula: '=A2*2'),
          CellAddress(2, 1): CellData(value: '18', formula: '=A3*2'),
          CellAddress(3, 1): CellData(value: '30', formula: '=SUM(B2:B3)'),
        },
      );

      expect(summary.state, SheetTableCalculatedColumnState.calculated);
      expect(summary.hasFormulas, isTrue);
      expect(summary.isCalculated, isTrue);
      expect(summary.bodyCellCount, 2);
      expect(summary.formulaCellCount, 2);
      expect(summary.bodySelection?.label, 'B2:B3');
      expect(summary.title, 'Calculated Column');
      expect(summary.detailLabel, '2 formula rows');
    });

    test('detects mixed formula table columns', () {
      final table = SheetTable.fromSelection(
        id: 'table-1',
        name: 'Sales',
        selection: CellSelection(CellAddress(0, 0), CellAddress(3, 2)),
      ).copyWith(showTotalsRow: true);

      final summary = SheetTableCalculatedColumnSummaryBuilder.build(
        table: table,
        column: 1,
        cells: {
          CellAddress(1, 1): CellData(value: '12', formula: '=A2*2'),
          CellAddress(2, 1): CellData(value: 'Manual'),
          CellAddress(3, 1): CellData(value: '12', formula: '=SUM(B2:B3)'),
        },
      );

      expect(summary.state, SheetTableCalculatedColumnState.partial);
      expect(summary.hasFormulas, isTrue);
      expect(summary.isCalculated, isFalse);
      expect(summary.detailLabel, '1 of 2 body rows use formulas');
      expect(
        summary.tooltip,
        'Mixed Formula Column: 1 of 2 body rows use formulas',
      );
    });

    test('ignores header and totals formulas when scanning body columns', () {
      final table = SheetTable.fromSelection(
        id: 'table-1',
        name: 'Sales',
        selection: CellSelection(CellAddress(0, 0), CellAddress(2, 1)),
      ).copyWith(showTotalsRow: true);

      final summary = SheetTableCalculatedColumnSummaryBuilder.build(
        table: table,
        column: 1,
        cells: {
          CellAddress(0, 1): CellData(value: 'Sales', formula: '=A1'),
          CellAddress(2, 1): CellData(value: 'Total', formula: '=SUM(B2:B2)'),
        },
      );

      expect(summary.state, SheetTableCalculatedColumnState.none);
      expect(summary.hasFormulas, isFalse);
      expect(summary.bodyCellCount, 1);
      expect(summary.formulaCellCount, 0);
      expect(summary.bodySelection?.label, 'B2');
      expect(summary.detailLabel, 'No body formulas');
    });
  });

  group('SheetTableHeaderNameValidator', () {
    test('uses existing header names and fallback column labels', () {
      final table = SheetTable.fromSelection(
        id: 'table-1',
        name: 'Sales',
        selection: CellSelection(CellAddress(0, 0), CellAddress(2, 2)),
      );

      expect(
        SheetTableHeaderNameValidator.currentName(
          table: table,
          column: 0,
          cells: {CellAddress(0, 0): CellData(value: 'Region')},
        ),
        'Region',
      );
      expect(
        SheetTableHeaderNameValidator.currentName(
          table: table,
          column: 1,
          cells: const {},
        ),
        'B',
      );
    });

    test('rejects blank and duplicate table header names', () {
      final table = SheetTable.fromSelection(
        id: 'table-1',
        name: 'Sales',
        selection: CellSelection(CellAddress(0, 0), CellAddress(2, 1)),
      );
      final cells = {
        CellAddress(0, 0): CellData(value: 'Region'),
        CellAddress(0, 1): CellData(value: 'Sales'),
      };

      expect(
        SheetTableHeaderNameValidator.validate(
          table: table,
          column: 1,
          cells: cells,
          value: ' ',
        ),
        'Header name is required',
      );
      expect(
        SheetTableHeaderNameValidator.validate(
          table: table,
          column: 1,
          cells: cells,
          value: 'region',
        ),
        '"region" already exists in this table',
      );
      expect(
        SheetTableHeaderNameValidator.validate(
          table: table,
          column: 1,
          cells: cells,
          value: 'Sales',
        ),
        isNull,
      );
      expect(
        SheetTableHeaderNameValidator.validate(
          table: table,
          column: 1,
          cells: cells,
          value: 'Revenue',
        ),
        isNull,
      );
    });
  });

  group('SheetTableOutlineResolver', () {
    test('returns visible boundary edges for active table cells', () {
      final table = SheetTable.fromSelection(
        id: 'table-1',
        name: 'Sales',
        selection: CellSelection(CellAddress(0, 0), CellAddress(2, 2)),
      );

      final topLeft = SheetTableOutlineResolver.resolve(
        address: CellAddress(0, 0),
        activeTable: table,
      );
      final bottomRight = SheetTableOutlineResolver.resolve(
        address: CellAddress(2, 2),
        activeTable: table,
      );

      expect(topLeft?.top, isTrue);
      expect(topLeft?.left, isTrue);
      expect(topLeft?.right, isFalse);
      expect(topLeft?.bottom, isFalse);
      expect(bottomRight?.right, isTrue);
      expect(bottomRight?.bottom, isTrue);
      expect(bottomRight?.top, isFalse);
      expect(bottomRight?.left, isFalse);
      expect(
        SheetTableOutlineResolver.resolve(
          address: CellAddress(1, 1),
          activeTable: table,
        ),
        isNull,
      );
      expect(
        SheetTableOutlineResolver.resolve(
          address: CellAddress(0, 0),
          activeTable: null,
        ),
        isNull,
      );
    });
  });

  group('SheetTableBadgeResolver', () {
    test('shows the active table badge on the top-left table cell only', () {
      final table = SheetTable.fromSelection(
        id: 'table-1',
        name: 'Sales',
        selection: CellSelection(CellAddress(1, 2), CellAddress(4, 5)),
      );

      expect(
        SheetTableBadgeResolver.shouldShow(
          address: CellAddress(1, 2),
          activeTable: table,
        ),
        isTrue,
      );
      expect(
        SheetTableBadgeResolver.shouldShow(
          address: CellAddress(1, 3),
          activeTable: table,
        ),
        isFalse,
      );
      expect(
        SheetTableBadgeResolver.shouldShow(
          address: CellAddress(1, 2),
          activeTable: null,
        ),
        isFalse,
      );
    });
  });

  group('SheetTableCornerActionResolver', () {
    test('shows corner actions on the active table bottom-right cell only', () {
      final table = SheetTable.fromSelection(
        id: 'table-1',
        name: 'Sales',
        selection: CellSelection(CellAddress(1, 2), CellAddress(4, 5)),
      );

      expect(
        SheetTableCornerActionResolver.shouldShow(
          address: CellAddress(4, 5),
          activeTable: table,
        ),
        isTrue,
      );
      expect(
        SheetTableCornerActionResolver.shouldShow(
          address: CellAddress(4, 4),
          activeTable: table,
        ),
        isFalse,
      );
      expect(
        SheetTableCornerActionResolver.shouldShow(
          address: CellAddress(4, 5),
          activeTable: null,
        ),
        isFalse,
      );
    });
  });

  group('activeSheetTableProvider', () {
    test(
      'resolves the latest table containing the active selection anchor',
      () {
        final container = ProviderContainer();
        addTearDown(container.dispose);
        final base = SheetTable.fromSelection(
          id: 'table-base',
          name: 'Base',
          selection: CellSelection(CellAddress(0, 0), CellAddress(4, 3)),
        );
        final overlay = SheetTable.fromSelection(
          id: 'table-overlay',
          name: 'Overlay',
          selection: CellSelection(CellAddress(1, 1), CellAddress(2, 2)),
        );
        container.read(sheetTablesProvider.notifier).replaceAll([
          base,
          overlay,
        ]);

        container.read(selectedCellProvider.notifier).state = CellSelection(
          CellAddress(1, 1),
        );

        expect(container.read(activeSheetTableProvider)?.id, overlay.id);

        container.read(selectedCellProvider.notifier).state = CellSelection(
          CellAddress(4, 3),
        );

        expect(container.read(activeSheetTableProvider)?.id, base.id);

        container.read(selectedCellProvider.notifier).state = CellSelection(
          CellAddress(6, 0),
        );

        expect(container.read(activeSheetTableProvider), isNull);
      },
    );
  });

  group('SheetFormatSnapshot', () {
    test('repeats source range styles over larger target ranges', () {
      final snapshot = SheetFormatSnapshot.fromSelection(
        selection: CellSelection(CellAddress(0, 0), CellAddress(1, 0)),
        cells: {
          CellAddress(0, 0): CellData(
            style: const CellStyle(bold: true, fontSize: 18),
          ),
          CellAddress(1, 0): CellData(
            style: const CellStyle(italic: true, wrapText: true),
          ),
        },
      );
      final target = CellSelection(CellAddress(0, 2), CellAddress(3, 2));

      expect(snapshot.styleFor(CellAddress(0, 2), target).bold, isTrue);
      expect(snapshot.styleFor(CellAddress(1, 2), target).italic, isTrue);
      expect(snapshot.styleFor(CellAddress(2, 2), target).fontSize, 18);
      expect(snapshot.styleFor(CellAddress(3, 2), target).wrapText, isTrue);
    });
  });

  group('SpreadsheetNotifier', () {
    test('recalculates formulas when source cells change', () {
      final sheet = SpreadsheetNotifier();

      sheet.updateCellValue(CellAddress(0, 0), '10');
      sheet.updateCellValue(CellAddress(1, 0), '15');
      sheet.updateCellValue(CellAddress(2, 0), '=SUM(A1:A2)');

      expect(sheet.state[CellAddress(2, 0)]?.value, '25.00');

      sheet.updateCellValue(CellAddress(1, 0), '20');

      expect(sheet.state[CellAddress(2, 0)]?.value, '30.00');
    });

    test('recalculates formulas that reference named ranges', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final sheet = container.read(spreadsheetProvider.notifier);

      container
          .read(sheetNamedRangesProvider.notifier)
          .save(
            name: 'Sales_Total',
            selection: CellSelection(CellAddress(0, 0), CellAddress(1, 0)),
          );

      sheet.updateCellValue(CellAddress(0, 0), '10');
      sheet.updateCellValue(CellAddress(1, 0), '20');
      sheet.updateCellValue(CellAddress(0, 1), '=SUM(Sales_Total)');

      expect(sheet.state[CellAddress(0, 1)]?.value, '30.00');

      sheet.updateCellValue(CellAddress(1, 0), '25');

      expect(sheet.state[CellAddress(0, 1)]?.value, '35.00');
    });

    test('imports and exports CSV content', () {
      final sheet = SpreadsheetNotifier();

      sheet.importFromCSV('Name,Amount\nKaysir,42');

      expect(sheet.state[CellAddress(0, 0)]?.value, 'Name');
      expect(sheet.state[CellAddress(1, 1)]?.value, '42');
      expect(sheet.exportToCSV(), 'Name,Amount\r\nKaysir,42');
    });

    test('replaces search matches using the selected scope', () {
      final sheet = SpreadsheetNotifier();

      sheet.updateCellValue(CellAddress(0, 0), 'Kaysir alpha');
      sheet.updateCellValue(CellAddress(1, 0), '=SUM(A1:A1)');

      final valueCount = sheet.replaceAllMatches(
        'kaysir',
        'Syirkah',
        options: const SheetSearchOptions(scope: SheetSearchScope.cellValues),
      );
      final formulaCount = sheet.replaceAllMatches(
        'SUM',
        'AVERAGE',
        options: const SheetSearchOptions(
          matchCase: true,
          scope: SheetSearchScope.formulas,
        ),
      );

      expect(valueCount, 1);
      expect(formulaCount, 1);
      expect(sheet.state[CellAddress(0, 0)]?.value, 'Syirkah alpha');
      expect(sheet.state[CellAddress(1, 0)]?.formula, '=AVERAGE(A1:A1)');
    });

    test('exports and imports workbook metadata in JSON', () {
      final source = ProviderContainer();
      final target = ProviderContainer();
      addTearDown(source.dispose);
      addTearDown(target.dispose);

      final sourceSheet = source.read(spreadsheetProvider.notifier);
      sourceSheet.updateCellValue(CellAddress(0, 0), '12');
      source.read(conditionalFormatRulesProvider.notifier).state = [
        ConditionalFormatRule(
          id: 'rule-1',
          selection: CellSelection(CellAddress(0, 0)),
          condition: ConditionalFormatCondition.greaterThan,
          operand: '10',
          backgroundColor: const Color(0xFFDCFCE7),
          textColor: const Color(0xFF166534),
        ),
      ];
      source
          .read(sheetNamedRangesProvider.notifier)
          .save(
            name: 'Revenue_Table',
            selection: CellSelection(CellAddress(0, 0), CellAddress(1, 1)),
          );
      source.read(rowConfigProvider.notifier).state = {
        1: RowConfig(index: 1, height: 48, hidden: true),
      };
      source.read(columnConfigProvider.notifier).state = {
        2: ColumnConfig(index: 2, width: 160, hidden: true),
      };
      source.read(filterProvider.notifier).state = {0: 'paid'};
      source.read(sheetFilterRulesProvider.notifier).state = {
        2: const SheetFilterRule(
          operator: SheetFilterOperator.greaterThan,
          value: '10',
        ),
      };
      source
          .read(sheetTablesProvider.notifier)
          .createFromSelection(
            CellSelection(CellAddress(0, 0), CellAddress(2, 2)),
            styleId: SheetTableStyleId.mint,
          );
      source.read(sortColumnProvider.notifier).state = 2;
      source.read(sortAscendingProvider.notifier).state = false;
      source.read(freezePanesProvider.notifier).state = CellAddress(1, 1);
      source.read(zoomLevelProvider.notifier).state = 1.25;

      final exported = sourceSheet.exportToJson();
      target.read(spreadsheetProvider.notifier).importFromJson(exported);

      expect(target.read(spreadsheetProvider)[CellAddress(0, 0)]?.value, '12');
      expect(target.read(conditionalFormatRulesProvider), hasLength(1));
      expect(target.read(conditionalFormatRulesProvider).single.operand, '10');
      expect(target.read(sheetNamedRangesProvider), hasLength(1));
      expect(
        target.read(sheetNamedRangesProvider).single.name,
        'Revenue_Table',
      );
      expect(
        target.read(sheetNamedRangesProvider).single.selection.label,
        'A1:B2',
      );
      expect(target.read(rowConfigProvider)[1]?.height, 48);
      expect(target.read(rowConfigProvider)[1]?.hidden, isTrue);
      expect(target.read(columnConfigProvider)[2]?.width, 160);
      expect(target.read(columnConfigProvider)[2]?.hidden, isTrue);
      expect(target.read(filterProvider), {0: 'paid'});
      expect(
        target.read(sheetFilterRulesProvider)[2]?.operator,
        SheetFilterOperator.greaterThan,
      );
      expect(target.read(sheetFilterRulesProvider)[2]?.value, '10');
      expect(target.read(sheetTablesProvider), hasLength(1));
      expect(target.read(sheetTablesProvider).single.selection.label, 'A1:C3');
      expect(
        target.read(sheetTablesProvider).single.styleId,
        SheetTableStyleId.mint,
      );
      expect(target.read(sortColumnProvider), 2);
      expect(target.read(sortAscendingProvider), isFalse);
      expect(target.read(freezePanesProvider), CellAddress(1, 1));
      expect(target.read(zoomLevelProvider), 1.25);
    });

    test('clears workbook metadata when importing CSV', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(conditionalFormatRulesProvider.notifier).state = [
        ConditionalFormatRule(
          id: 'rule-1',
          selection: CellSelection(CellAddress(0, 0)),
          condition: ConditionalFormatCondition.notEmpty,
          backgroundColor: const Color(0xFFDCFCE7),
          textColor: const Color(0xFF166534),
        ),
      ];
      container
          .read(sheetNamedRangesProvider.notifier)
          .save(
            name: 'Imported_Data',
            selection: CellSelection(CellAddress(0, 0), CellAddress(2, 0)),
          );
      container.read(rowConfigProvider.notifier).state = {
        0: RowConfig(index: 0, height: 72),
      };
      container.read(filterProvider.notifier).state = {0: 'paid'};
      container
          .read(sheetTablesProvider.notifier)
          .createFromSelection(
            CellSelection(CellAddress(0, 0), CellAddress(2, 1)),
          );
      container.read(freezePanesProvider.notifier).state = CellAddress(1, 1);

      container
          .read(spreadsheetProvider.notifier)
          .importFromCSV('Name\nKaysir');

      expect(container.read(conditionalFormatRulesProvider), isEmpty);
      expect(container.read(sheetNamedRangesProvider), isEmpty);
      expect(container.read(rowConfigProvider), isEmpty);
      expect(container.read(filterProvider), isEmpty);
      expect(container.read(sheetTablesProvider), isEmpty);
      expect(container.read(freezePanesProvider), isNull);
      expect(container.read(zoomLevelProvider), 1);
    });

    test('undoes and redoes edits with dependent formula cells', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final sheet = container.read(spreadsheetProvider.notifier);

      sheet.updateCellValue(CellAddress(0, 0), '10');
      sheet.updateCellValue(CellAddress(1, 0), '=SUM(A1:A1)');
      sheet.updateCellValue(CellAddress(0, 0), '20');

      expect(sheet.state[CellAddress(1, 0)]?.value, '20.00');
      expect(container.read(undoStackProvider), hasLength(3));
      expect(container.read(redoStackProvider), isEmpty);

      sheet.undo();

      expect(sheet.state[CellAddress(0, 0)]?.value, '10');
      expect(sheet.state[CellAddress(1, 0)]?.value, '10.00');
      expect(container.read(undoStackProvider), hasLength(2));
      expect(container.read(redoStackProvider), hasLength(1));

      sheet.redo();

      expect(sheet.state[CellAddress(0, 0)]?.value, '20');
      expect(sheet.state[CellAddress(1, 0)]?.value, '20.00');
      expect(container.read(undoStackProvider), hasLength(3));
      expect(container.read(redoStackProvider), isEmpty);
    });

    test('clears redo history after a new edit', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final sheet = container.read(spreadsheetProvider.notifier);

      sheet.updateCellValue(CellAddress(0, 0), 'A');
      sheet.updateCellValue(CellAddress(0, 0), 'B');
      sheet.undo();

      expect(container.read(redoStackProvider), hasLength(1));

      sheet.updateCellValue(CellAddress(0, 1), 'C');

      expect(container.read(redoStackProvider), isEmpty);
    });

    test('records Waraq sheet_engine operations for direct cell edits', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final sheet = container.read(spreadsheetProvider.notifier);

      sheet.updateCellValue(CellAddress(0, 0), '10');
      sheet.updateCellValue(CellAddress(0, 1), '=A1*2');
      sheet.updateCellValue(CellAddress(0, 0), '20');

      final operations = container
          .read(sheetEngineOperationLogProvider)
          .operations;

      expect(operations, hasLength(3));
      expect(operations[0]['operation_id'], 'ky-sheet-op-1');
      expect(operations[0]['document_id'], 'sheet-1');
      expect(operations[0]['actor_id'], 'ky-sheet');
      expect(operations[0]['sequence'], 1);
      expect(operations[0]['edit'], {
        'SetCell': {
          'position': {'col': 0, 'row': 0},
          'raw_content': '10',
        },
      });
      expect(operations[1]['edit'], {
        'SetCell': {
          'position': {'col': 1, 'row': 0},
          'raw_content': '=A1*2',
        },
      });
      expect(operations[2]['edit'], {
        'SetCell': {
          'position': {'col': 0, 'row': 0},
          'raw_content': '20',
        },
      });

      sheet.undo();

      expect(
        container.read(sheetEngineOperationLogProvider).operations,
        hasLength(3),
      );
    });

    test('records Waraq sheet_engine format and clear operations', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final sheet = container.read(spreadsheetProvider.notifier);

      sheet.updateCellStyle(
        CellAddress(1, 2),
        const CellStyle(bold: true, numberFormat: '0.00'),
      );
      sheet.clearCell(CellAddress(1, 2));

      final operations = container
          .read(sheetEngineOperationLogProvider)
          .operations;

      expect(operations, hasLength(2));
      expect(operations[0]['edit'], {
        'SetCellFormat': {
          'position': {'col': 2, 'row': 1},
          'format': {
            'bold': true,
            'italic': false,
            'background_color': null,
            'text_color': 'DD000000',
            'number_format': '0.00',
          },
        },
      });
      expect(operations[1]['edit'], {
        'ClearCell': {
          'position': {'col': 2, 'row': 1},
        },
      });
    });

    test('resets Waraq sheet_engine operation logs after sheet imports', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final sheet = container.read(spreadsheetProvider.notifier);

      sheet.updateCellValue(CellAddress(0, 0), 'Before import');
      expect(
        container.read(sheetEngineOperationLogProvider).operations,
        isNotEmpty,
      );

      sheet.importFromCSV('Name\nKaysir');

      final log = container.read(sheetEngineOperationLogProvider);
      expect(log.operations, isEmpty);
      expect(log.nextSequence, 1);
      expect(log.documentId, 'sheet-1');
    });

    test('applies Waraq sheet_engine operation logs without local echo', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final sheet = container.read(spreadsheetProvider.notifier);

      sheet.updateCellValue(CellAddress(0, 0), '10');
      sheet.updateCellValue(CellAddress(0, 1), '=A1*2');
      sheet.clearHistory();
      container.read(sheetEngineOperationLogProvider.notifier).clear();

      final appliedCount = sheet.applySheetEngineOperationLog(
        SheetEngineEditCodec.operationLog([
          SheetEngineEditCodec.operation(
            operationId: 'remote-op-1',
            documentId: 'sheet-1',
            actorId: 'remote',
            sequence: 1,
            timestampMs: 100,
            edit: SheetEngineEditCodec.setCellRaw(CellAddress(0, 0), '25'),
          ),
          SheetEngineEditCodec.operation(
            operationId: 'remote-op-2',
            documentId: 'sheet-1',
            actorId: 'remote',
            sequence: 2,
            timestampMs: 200,
            edit: SheetEngineEditCodec.setCellFormat(
              CellAddress(0, 1),
              const CellStyle(bold: true, numberFormat: '0.00'),
            ),
          ),
        ]),
      );

      expect(appliedCount, 2);
      expect(sheet.state[CellAddress(0, 0)]?.value, '25');
      expect(sheet.state[CellAddress(0, 1)]?.formula, '=A1*2');
      expect(sheet.state[CellAddress(0, 1)]?.value, '50.00');
      expect(sheet.state[CellAddress(0, 1)]?.style.bold, isTrue);
      expect(sheet.state[CellAddress(0, 1)]?.style.numberFormat, '0.00');
      expect(
        container.read(sheetEngineOperationLogProvider).operations,
        isEmpty,
      );
      expect(container.read(undoStackProvider), isEmpty);
    });

    test('skips Waraq sheet_engine operations for other documents', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final sheet = container.read(spreadsheetProvider.notifier);

      final result = sheet.applySheetEngineOperationLogWithResult(
        SheetEngineEditCodec.operationLog([
          SheetEngineEditCodec.operation(
            operationId: 'remote-op-1',
            documentId: 'other-sheet',
            actorId: 'remote',
            sequence: 1,
            timestampMs: 100,
            edit: SheetEngineEditCodec.setCellRaw(CellAddress(0, 0), '25'),
          ),
        ]),
      );

      expect(result.appliedEditCount, 0);
      expect(result.skippedOperationCount, 1);
      expect(sheet.state[CellAddress(0, 0)], isNull);
      expect(
        container.read(sheetEngineOperationLogProvider).operations,
        isEmpty,
      );
      expect(container.read(undoStackProvider), isEmpty);
    });

    test(
      'applies Waraq sheet_engine recalculation edits without local echo',
      () {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        final sheet = container.read(spreadsheetProvider.notifier);
        sheet.restoreSheetState({
          CellAddress(0, 0): CellData(value: '7'),
          CellAddress(0, 1): CellData(value: 'stale', formula: '=A1*3'),
        }, recalculate: false);

        final appliedCount = sheet.applySheetEngineEdit(
          SheetEngineEditCodec.recalculate(),
        );

        expect(appliedCount, 1);
        expect(sheet.state[CellAddress(0, 1)]?.value, '21.00');
        expect(
          container.read(sheetEngineOperationLogProvider).operations,
          isEmpty,
        );
        expect(container.read(undoStackProvider), isEmpty);
      },
    );

    test('summarizes history stacks newest first', () {
      final first = UndoRedoAction(
        {CellAddress(0, 0): null},
        {CellAddress(0, 0): CellData(value: 'A')},
        'Edit A1',
      );
      final second = UndoRedoAction(
        {CellAddress(2, 1): null, CellAddress(1, 1): null},
        {
          CellAddress(2, 1): CellData(value: 'B3'),
          CellAddress(1, 1): CellData(value: 'B2'),
        },
        'Paste cells',
      );

      final snapshot = SheetHistorySummarizer.summarize(
        undoStack: [first, second],
        redoStack: [first],
      );

      expect(snapshot.undoCount, 2);
      expect(snapshot.redoCount, 1);
      expect(snapshot.undoEntries.first.title, 'Paste cells');
      expect(snapshot.undoEntries.first.rangeLabel, 'B2 + 1');
      expect(snapshot.undoEntries.first.detail, '2 cells changed');
      expect(snapshot.undoEntries.first.isNextAction, isTrue);
      expect(snapshot.undoEntries.last.title, 'Edit A1');
      expect(snapshot.redoEntries.single.title, 'Edit A1');
      expect(snapshot.redoEntries.single.isNextAction, isTrue);
    });

    test('pastes tabular values as one undoable operation', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final sheet = container.read(spreadsheetProvider.notifier);

      sheet.updateCellValue(CellAddress(0, 0), 'old');
      sheet.pasteCellValues([
        ['A', '10'],
        ['B', '=SUM(B1:B1)'],
      ], CellAddress(0, 0));

      expect(sheet.state[CellAddress(0, 0)]?.value, 'A');
      expect(sheet.state[CellAddress(0, 1)]?.value, '10');
      expect(sheet.state[CellAddress(1, 0)]?.value, 'B');
      expect(sheet.state[CellAddress(1, 1)]?.value, '10.00');

      sheet.undo();

      expect(sheet.state[CellAddress(0, 0)]?.value, 'old');
      expect(sheet.state[CellAddress(0, 1)], isNull);
      expect(sheet.state[CellAddress(1, 0)], isNull);
      expect(sheet.state[CellAddress(1, 1)], isNull);
    });

    test('fills generated cells as one undoable operation', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final sheet = container.read(spreadsheetProvider.notifier);
      sheet.updateCellValue(CellAddress(0, 0), '1');
      sheet.updateCellValue(CellAddress(1, 0), '2');

      final fillCells = SheetFillSeries.buildFill(
        sourceSelection: CellSelection(CellAddress(0, 0), CellAddress(1, 0)),
        targetSelection: CellSelection(CellAddress(0, 0), CellAddress(4, 0)),
        cells: sheet.state,
      );
      sheet.fillCells(fillCells);

      expect(sheet.state[CellAddress(2, 0)]?.value, '3');
      expect(sheet.state[CellAddress(3, 0)]?.value, '4');
      expect(sheet.state[CellAddress(4, 0)]?.value, '5');

      sheet.undo();

      expect(sheet.state[CellAddress(2, 0)], isNull);
      expect(sheet.state[CellAddress(3, 0)], isNull);
      expect(sheet.state[CellAddress(4, 0)], isNull);
    });

    test('formats a selected range as one undoable operation', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final sheet = container.read(spreadsheetProvider.notifier);
      final toolbar = container.read(toolbarControllerProvider);
      final selection = CellSelection(CellAddress(0, 0), CellAddress(0, 1));

      sheet.updateCellValue(CellAddress(0, 0), 'A');
      sheet.updateCellValue(CellAddress(0, 1), 'B');
      toolbar.toggleBold(selection);

      expect(container.read(undoStackProvider), hasLength(3));
      expect(sheet.state[CellAddress(0, 0)]?.style.bold, isTrue);
      expect(sheet.state[CellAddress(0, 1)]?.style.bold, isTrue);

      sheet.undo();

      expect(sheet.state[CellAddress(0, 0)]?.style.bold, isFalse);
      expect(sheet.state[CellAddress(0, 1)]?.style.bold, isFalse);
      expect(sheet.state[CellAddress(0, 0)]?.value, 'A');
      expect(sheet.state[CellAddress(0, 1)]?.value, 'B');
    });

    test('clears validation for a range as one undoable operation', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final sheet = container.read(spreadsheetProvider.notifier);
      final toolbar = container.read(toolbarControllerProvider);
      final selection = CellSelection(CellAddress(0, 0), CellAddress(0, 1));

      toolbar.applyEmailValidation(selection);
      toolbar.clearValidation(selection);

      expect(container.read(undoStackProvider), hasLength(2));
      expect(sheet.state[CellAddress(0, 0)]?.validation, isNull);
      expect(sheet.state[CellAddress(0, 1)]?.validation, isNull);

      sheet.undo();

      expect(
        sheet.state[CellAddress(0, 0)]?.validation?.type,
        ValidationType.email,
      );
      expect(
        sheet.state[CellAddress(0, 1)]?.validation?.type,
        ValidationType.email,
      );
    });

    test('applies number format to a range as one undoable operation', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final sheet = container.read(spreadsheetProvider.notifier);
      final toolbar = container.read(toolbarControllerProvider);
      final selection = CellSelection(CellAddress(0, 0), CellAddress(0, 1));

      sheet.updateCellValue(CellAddress(0, 0), '10');
      sheet.updateCellValue(CellAddress(0, 1), '20');
      toolbar.setNumberFormat(selection, SheetNumberFormatId.currency);

      expect(container.read(undoStackProvider), hasLength(3));
      expect(
        sheet.state[CellAddress(0, 0)]?.style.numberFormat,
        SheetNumberFormatId.currency,
      );
      expect(
        sheet.state[CellAddress(0, 1)]?.style.numberFormat,
        SheetNumberFormatId.currency,
      );

      sheet.undo();

      expect(sheet.state[CellAddress(0, 0)]?.style.numberFormat, isNull);
      expect(sheet.state[CellAddress(0, 1)]?.style.numberFormat, isNull);
    });

    test('sorts ranges numerically while preserving row data', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final sheet = container.read(spreadsheetProvider.notifier);
      sheet.updateCellValue(CellAddress(0, 0), '10');
      sheet.updateCellValue(CellAddress(0, 1), 'Ten');
      sheet.updateCellValue(CellAddress(1, 0), '2');
      sheet.updateCellValue(CellAddress(1, 1), 'Two');
      sheet.updateCellValue(CellAddress(2, 0), '30');
      sheet.updateCellValue(CellAddress(2, 1), 'Thirty');

      sheet.sortRange(
        CellSelection(CellAddress(0, 0), CellAddress(2, 1)),
        ascending: true,
      );

      expect(sheet.state[CellAddress(0, 0)]?.value, '2');
      expect(sheet.state[CellAddress(0, 1)]?.value, 'Two');
      expect(sheet.state[CellAddress(1, 0)]?.value, '10');
      expect(sheet.state[CellAddress(1, 1)]?.value, 'Ten');
      expect(sheet.state[CellAddress(2, 0)]?.value, '30');
      expect(sheet.state[CellAddress(2, 1)]?.value, 'Thirty');
      expect(container.read(sortColumnProvider), 0);
      expect(container.read(sortAscendingProvider), isTrue);
    });

    test('clears stale cells when sorting sparse rows', () {
      final sheet = SpreadsheetNotifier();
      sheet.updateCellValue(CellAddress(0, 0), '2');
      sheet.updateCellValue(CellAddress(0, 1), 'Two');
      sheet.updateCellValue(CellAddress(1, 0), '1');

      sheet.sortRange(
        CellSelection(CellAddress(0, 0), CellAddress(1, 1)),
        ascending: true,
      );

      expect(sheet.state[CellAddress(0, 0)]?.value, '1');
      expect(sheet.state[CellAddress(0, 1)], isNull);
      expect(sheet.state[CellAddress(1, 0)]?.value, '2');
      expect(sheet.state[CellAddress(1, 1)]?.value, 'Two');
    });

    test('normalizes and clears column filters from toolbar controller', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final toolbar = container.read(toolbarControllerProvider);
      toolbar.setFilter(1, '  paid  ');

      expect(container.read(filterProvider), {1: 'paid'});
      expect(
        container.read(sheetFilterRulesProvider)[1]?.operator,
        SheetFilterOperator.contains,
      );
      expect(container.read(sheetFilterRulesProvider)[1]?.value, 'paid');

      toolbar.setFilter(1, '');

      expect(container.read(filterProvider), isEmpty);
      expect(container.read(sheetFilterRulesProvider), isEmpty);
    });

    test('stores rich filter rules from toolbar controller', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final toolbar = container.read(toolbarControllerProvider);
      toolbar.setFilterRule(
        2,
        const SheetFilterRule(
          operator: SheetFilterOperator.greaterThanOrEqual,
          value: '25',
        ),
      );
      toolbar.setFilterRule(
        3,
        const SheetFilterRule(operator: SheetFilterOperator.empty),
      );

      expect(container.read(filterProvider), {2: '25'});
      expect(
        container.read(sheetFilterRulesProvider)[2]?.operator,
        SheetFilterOperator.greaterThanOrEqual,
      );
      expect(
        container.read(sheetFilterRulesProvider)[3]?.operator,
        SheetFilterOperator.empty,
      );

      toolbar.clearFilterColumns([2]);

      expect(container.read(filterProvider), isEmpty);
      expect(container.read(sheetFilterRulesProvider).keys, [3]);

      toolbar.clearFilters();

      expect(container.read(filterProvider), isEmpty);
      expect(container.read(sheetFilterRulesProvider), isEmpty);
    });

    test('applies quick filters from clicked cell values', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final sheet = container.read(spreadsheetProvider.notifier);
      sheet.updateCellValue(CellAddress(1, 2), '  Open  ');
      final toolbar = container.read(toolbarControllerProvider);

      toolbar.keepOnlyCellValue(CellAddress(1, 2));

      expect(container.read(filterProvider), {2: 'Open'});
      expect(
        container.read(sheetFilterRulesProvider)[2]?.operator,
        SheetFilterOperator.equals,
      );
      expect(container.read(sheetFilterRulesProvider)[2]?.value, 'Open');

      toolbar.excludeCellValue(CellAddress(1, 2));

      expect(container.read(filterProvider), {2: 'Open'});
      expect(
        container.read(sheetFilterRulesProvider)[2]?.operator,
        SheetFilterOperator.notEquals,
      );
      expect(container.read(sheetFilterRulesProvider)[2]?.value, 'Open');

      toolbar.keepOnlyCellValue(CellAddress(4, 2));

      expect(container.read(filterProvider), isEmpty);
      expect(
        container.read(sheetFilterRulesProvider)[2]?.operator,
        SheetFilterOperator.empty,
      );
    });

    test('applies freeze presets and clamps zoom from toolbar controller', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final toolbar = container.read(toolbarControllerProvider);
      toolbar.freezeFirstRow();
      expect(container.read(freezePanesProvider), CellAddress(1, 0));

      toolbar.freezeFirstColumn();
      expect(container.read(freezePanesProvider), CellAddress(0, 1));

      toolbar.freezeFirstRowAndColumn();
      expect(container.read(freezePanesProvider), CellAddress(1, 1));

      toolbar.freezePanesAt(CellSelection(CellAddress(3, 2)));
      expect(container.read(freezePanesProvider), CellAddress(3, 2));

      toolbar.unfreezePanes();
      expect(container.read(freezePanesProvider), isNull);

      toolbar.setZoom(4);
      expect(container.read(zoomLevelProvider), 3);

      toolbar.setZoom(0.1);
      expect(container.read(zoomLevelProvider), 0.5);

      toolbar.resetZoom();
      expect(container.read(zoomLevelProvider), 1);
    });

    test('paints formatting without changing target values', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final sheet = container.read(spreadsheetProvider.notifier);
      sheet.updateCell(
        CellAddress(0, 0),
        CellData(
          value: 'Source',
          style: const CellStyle(
            bold: true,
            backgroundColor: Color(0xFFDBEAFE),
            numberFormat: SheetNumberFormatId.currency,
          ),
        ),
      );
      sheet.updateCellValue(CellAddress(0, 1), 'Target');

      final painter = container.read(sheetFormatPainterControllerProvider);
      painter.start(CellSelection(CellAddress(0, 0)));

      expect(container.read(sheetFormatPainterSnapshotProvider), isNotNull);

      final applied = painter.applyTo(CellSelection(CellAddress(0, 1)));

      expect(applied, isTrue);
      expect(container.read(sheetFormatPainterSnapshotProvider), isNull);
      expect(sheet.state[CellAddress(0, 1)]?.value, 'Target');
      expect(sheet.state[CellAddress(0, 1)]?.style.bold, isTrue);
      expect(
        sheet.state[CellAddress(0, 1)]?.style.backgroundColor,
        const Color(0xFFDBEAFE),
      );
      expect(
        sheet.state[CellAddress(0, 1)]?.style.numberFormat,
        SheetNumberFormatId.currency,
      );
    });
  });

  group('WorkbookNotifier', () {
    test('adds sheets and preserves independent cell and metadata state', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final sheet = container.read(spreadsheetProvider.notifier);
      final workbook = container.read(workbookProvider.notifier);
      final firstSheetId = container.read(workbookProvider).activeSheetId;

      sheet.updateCellValue(CellAddress(0, 0), 'First');
      container.read(rowConfigProvider.notifier).state = {
        0: RowConfig(index: 0, height: 72),
      };

      workbook.addSheet();

      expect(container.read(workbookProvider).activeSheet.name, 'Sheet2');
      expect(container.read(spreadsheetProvider), isEmpty);
      expect(container.read(rowConfigProvider), isEmpty);

      sheet.updateCellValue(CellAddress(0, 0), 'Second');
      workbook.switchToSheet(firstSheetId);

      expect(
        container.read(spreadsheetProvider)[CellAddress(0, 0)]?.value,
        'First',
      );
      expect(container.read(rowConfigProvider)[0]?.height, 72);

      workbook.switchToSheet(container.read(workbookProvider).sheets[1].id);

      expect(
        container.read(spreadsheetProvider)[CellAddress(0, 0)]?.value,
        'Second',
      );
    });

    test('duplicates active sheet contents and creates unique names', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container
          .read(spreadsheetProvider.notifier)
          .updateCellValue(CellAddress(0, 0), 'Copy me');
      final workbook = container.read(workbookProvider.notifier);

      workbook.duplicateActiveSheet();

      expect(container.read(workbookProvider).sheets, hasLength(2));
      expect(container.read(workbookProvider).activeSheet.name, 'Sheet1 Copy');
      expect(
        container.read(spreadsheetProvider)[CellAddress(0, 0)]?.value,
        'Copy me',
      );

      workbook.renameSheet(
        container.read(workbookProvider).activeSheetId,
        'Sheet1',
      );

      expect(container.read(workbookProvider).activeSheet.name, 'Sheet1 2');
    });

    test('moves sheets while preserving independent sheet state', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final sheet = container.read(spreadsheetProvider.notifier);
      final workbook = container.read(workbookProvider.notifier);
      final firstSheetId = container.read(workbookProvider).activeSheetId;
      sheet.updateCellValue(CellAddress(0, 0), 'First');

      workbook.addSheet();
      final secondSheetId = container.read(workbookProvider).activeSheetId;
      sheet.updateCellValue(CellAddress(0, 0), 'Second');

      workbook.addSheet();
      final thirdSheetId = container.read(workbookProvider).activeSheetId;
      sheet.updateCellValue(CellAddress(0, 0), 'Third');

      workbook.moveSheet(thirdSheetId, -1);

      expect(container.read(workbookProvider).sheets.map((sheet) => sheet.id), [
        firstSheetId,
        thirdSheetId,
        secondSheetId,
      ]);
      expect(container.read(workbookProvider).activeSheetId, thirdSheetId);
      expect(
        container.read(spreadsheetProvider)[CellAddress(0, 0)]?.value,
        'Third',
      );

      workbook.switchToSheet(secondSheetId);
      expect(
        container.read(spreadsheetProvider)[CellAddress(0, 0)]?.value,
        'Second',
      );

      workbook.switchToSheet(firstSheetId);
      expect(
        container.read(spreadsheetProvider)[CellAddress(0, 0)]?.value,
        'First',
      );
    });

    test('hides active sheets and restores hidden sheets', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final sheet = container.read(spreadsheetProvider.notifier);
      final workbook = container.read(workbookProvider.notifier);
      final firstSheetId = container.read(workbookProvider).activeSheetId;

      sheet.updateCellValue(CellAddress(0, 0), 'First');
      workbook.addSheet();
      final secondSheetId = container.read(workbookProvider).activeSheetId;
      sheet.updateCellValue(CellAddress(0, 0), 'Second');

      workbook.hideSheet(secondSheetId);

      expect(container.read(workbookProvider).activeSheetId, firstSheetId);
      expect(
        container
            .read(workbookProvider)
            .sheets
            .firstWhere((sheet) => sheet.id == secondSheetId)
            .hidden,
        isTrue,
      );
      expect(
        container.read(spreadsheetProvider)[CellAddress(0, 0)]?.value,
        'First',
      );

      workbook.hideSheet(firstSheetId);

      expect(
        container
            .read(workbookProvider)
            .sheets
            .firstWhere((sheet) => sheet.id == firstSheetId)
            .hidden,
        isFalse,
      );

      workbook.unhideSheet(secondSheetId, makeActive: true);

      expect(container.read(workbookProvider).activeSheetId, secondSheetId);
      expect(
        container
            .read(workbookProvider)
            .sheets
            .firstWhere((sheet) => sheet.id == secondSheetId)
            .hidden,
        isFalse,
      );
      expect(
        container.read(spreadsheetProvider)[CellAddress(0, 0)]?.value,
        'Second',
      );
    });

    test('switches adjacent visible sheets while skipping hidden sheets', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final workbook = container.read(workbookProvider.notifier);
      final firstSheetId = container.read(workbookProvider).activeSheetId;
      workbook.addSheet();
      final secondSheetId = container.read(workbookProvider).activeSheetId;
      workbook.addSheet();
      final thirdSheetId = container.read(workbookProvider).activeSheetId;

      workbook.hideSheet(secondSheetId);
      workbook.switchToSheet(firstSheetId);

      workbook.switchToAdjacentVisibleSheet(1);
      expect(container.read(workbookProvider).activeSheetId, thirdSheetId);

      workbook.switchToAdjacentVisibleSheet(1);
      expect(container.read(workbookProvider).activeSheetId, firstSheetId);

      workbook.switchToAdjacentVisibleSheet(-1);
      expect(container.read(workbookProvider).activeSheetId, thirdSheetId);
    });

    test('reorders visible sheets while preserving hidden sheets', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final workbook = container.read(workbookProvider.notifier);
      final firstSheetId = container.read(workbookProvider).activeSheetId;
      workbook.addSheet();
      final secondSheetId = container.read(workbookProvider).activeSheetId;
      workbook.addSheet();
      final thirdSheetId = container.read(workbookProvider).activeSheetId;
      workbook.addSheet();
      final fourthSheetId = container.read(workbookProvider).activeSheetId;

      workbook.hideSheet(secondSheetId);
      workbook.switchToSheet(firstSheetId);
      workbook.moveSheetToVisibleIndex(fourthSheetId, 0);

      expect(container.read(workbookProvider).sheets.map((sheet) => sheet.id), [
        fourthSheetId,
        secondSheetId,
        firstSheetId,
        thirdSheetId,
      ]);
      expect(
        container
            .read(workbookProvider)
            .sheets
            .firstWhere((sheet) => sheet.id == secondSheetId)
            .hidden,
        isTrue,
      );
      expect(container.read(workbookProvider).activeSheetId, firstSheetId);
    });

    test('uses active sheet ids as Waraq sheet_engine document ids', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final workbook = container.read(workbookProvider.notifier);
      final sheet = container.read(spreadsheetProvider.notifier);

      workbook.addSheet();
      final secondSheetId = container.read(workbookProvider).activeSheetId;

      expect(
        container.read(sheetEngineOperationLogProvider).documentId,
        secondSheetId,
      );

      sheet.updateCellValue(CellAddress(0, 0), 'Second sheet');

      final operation = container
          .read(sheetEngineOperationLogProvider)
          .operations
          .single;

      expect(operation['document_id'], secondSheetId);
      expect(operation['edit'], {
        'SetCell': {
          'position': {'col': 0, 'row': 0},
          'raw_content': 'Second sheet',
        },
      });
    });

    test('exports and imports multi-sheet workbooks as JSON', () {
      final source = ProviderContainer();
      final target = ProviderContainer();
      addTearDown(source.dispose);
      addTearDown(target.dispose);

      final sourceSheet = source.read(spreadsheetProvider.notifier);
      final sourceWorkbook = source.read(workbookProvider.notifier);
      final firstSheetId = source.read(workbookProvider).activeSheetId;

      sourceSheet.updateCellValue(CellAddress(0, 0), 'First');
      source
          .read(sheetNamedRangesProvider.notifier)
          .save(
            name: 'First_Cell',
            selection: CellSelection(CellAddress(0, 0)),
          );
      sourceWorkbook.addSheet();
      sourceSheet.updateCellValue(CellAddress(0, 0), 'Second');
      source.read(filterProvider.notifier).state = {0: 'Second'};
      source
          .read(sheetNamedRangesProvider.notifier)
          .save(
            name: 'Second_Cell',
            selection: CellSelection(CellAddress(0, 0)),
          );

      final exported = sourceWorkbook.exportToJson();
      target.read(workbookProvider.notifier).importFromJson(exported);

      expect(target.read(workbookProvider).sheets, hasLength(2));
      expect(target.read(workbookProvider).activeSheet.name, 'Sheet2');
      expect(
        target.read(spreadsheetProvider)[CellAddress(0, 0)]?.value,
        'Second',
      );
      expect(target.read(filterProvider), {0: 'Second'});
      expect(target.read(sheetNamedRangesProvider).single.name, 'Second_Cell');

      target.read(workbookProvider.notifier).switchToSheet(firstSheetId);

      expect(
        target.read(spreadsheetProvider)[CellAddress(0, 0)]?.value,
        'First',
      );
      expect(target.read(sheetNamedRangesProvider).single.name, 'First_Cell');
    });

    test('imports and exports Waraq sheet_engine JSON snapshots', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(workbookProvider.notifier).importFromAnyJson({
        'engine': SheetEngineCodec.engine,
        'activeSheetIndex': 1,
        'sheets': [
          {
            'name': 'Inputs',
            'cells': [
              {
                'position': {'col': 0, 'row': 0},
                'cell': {
                  'raw_content': 'Seed',
                  'evaluated_value': {'String': 'Seed'},
                  'format': {
                    'bold': true,
                    'italic': false,
                    'background_color': null,
                    'text_color': null,
                    'number_format': null,
                  },
                },
              },
            ],
          },
          {
            'name': 'Calc',
            'cells': [
              {
                'position': {'col': 0, 'row': 0},
                'cell': {
                  'raw_content': '10',
                  'evaluated_value': {'Number': 10.0},
                  'format': {
                    'bold': false,
                    'italic': false,
                    'background_color': null,
                    'text_color': null,
                    'number_format': null,
                  },
                },
              },
              {
                'position': {'col': 1, 'row': 0},
                'cell': {
                  'raw_content': '=A1*2',
                  'evaluated_value': {'Number': 20.0},
                  'format': {
                    'bold': false,
                    'italic': true,
                    'background_color': null,
                    'text_color': null,
                    'number_format': null,
                  },
                },
              },
            ],
          },
        ],
      });

      expect(container.read(workbookProvider).sheets, hasLength(2));
      expect(container.read(workbookProvider).activeSheet.name, 'Calc');
      expect(
        container.read(spreadsheetProvider)[CellAddress(0, 1)]?.formula,
        '=A1*2',
      );
      expect(
        container.read(spreadsheetProvider)[CellAddress(0, 1)]?.value,
        '20.00',
      );
      expect(
        container.read(spreadsheetProvider)[CellAddress(0, 1)]?.style.italic,
        isTrue,
      );
      expect(container.read(undoStackProvider), isEmpty);

      final exported = container
          .read(workbookProvider.notifier)
          .exportToSheetEngineJson();
      final exportedSheets = exported['sheets'] as List;
      final activeSheet = exportedSheets[1] as Map;
      final activeCells = activeSheet['cells'] as List;
      final formulaCell = activeCells.cast<Map>().firstWhere(
        (cell) => (cell['position'] as Map)['col'] == 1,
      );

      expect(exported['type'], SheetEngineCodec.type);
      expect(exported['engine'], SheetEngineCodec.engine);
      expect(
        exported['activeSheetId'],
        container.read(workbookProvider).activeSheetId,
      );
      expect(activeSheet['name'], 'Calc');
      expect(formulaCell['position'], {'col': 1, 'row': 0});
      expect((formulaCell['cell'] as Map)['raw_content'], '=A1*2');
      expect((formulaCell['cell'] as Map)['evaluated_value'], {'Number': 20.0});
    });
  });

  group('SheetWorkbookCodec', () {
    test('round trips sheet cells and metadata', () {
      final workbook = SheetWorkbook(
        activeSheetId: 'sheet-2',
        sheets: [
          WorkbookSheet(
            id: 'sheet-1',
            name: 'Inputs',
            hidden: true,
            cells: {CellAddress(0, 0): CellData(value: 'Input')},
          ),
          WorkbookSheet(
            id: 'sheet-2',
            name: 'Report',
            tabColor: const Color(0xFF16A34A),
            cells: {CellAddress(1, 1): CellData(value: '42')},
            metadata: SheetMetadata(
              namedRanges: [
                SheetNamedRange(
                  id: 'named-range-1',
                  name: 'Report_Total',
                  selection: CellSelection(CellAddress(1, 1)),
                ),
              ],
              filters: {1: '42'},
              filterRules: const {
                1: SheetFilterRule(
                  operator: SheetFilterOperator.greaterThan,
                  value: '40',
                ),
              },
              sortColumn: 1,
              sortAscending: false,
              freezePane: CellAddress(1, 0),
              zoom: 1.25,
            ),
          ),
        ],
      );

      final restored = SheetWorkbookCodec.decode(
        SheetWorkbookCodec.encode(workbook),
      );
      final encodedSheets =
          SheetWorkbookCodec.encode(workbook)['sheets'] as List;

      expect(restored.activeSheetId, 'sheet-2');
      expect(restored.sheets, hasLength(2));
      expect(restored.sheets.first.hidden, isTrue);
      expect(restored.activeSheet.name, 'Report');
      expect(restored.activeSheet.tabColor, const Color(0xFF16A34A));
      expect((encodedSheets.first as Map)['hidden'], isTrue);
      expect((encodedSheets[1] as Map)['tabColor'], 0xFF16A34A);
      expect(restored.activeSheet.cells[CellAddress(1, 1)]?.value, '42');
      expect(restored.activeSheet.metadata.filters, {1: '42'});
      expect(
        restored.activeSheet.metadata.filterRules[1]?.operator,
        SheetFilterOperator.greaterThan,
      );
      expect(restored.activeSheet.metadata.filterRules[1]?.value, '40');
      expect(restored.activeSheet.metadata.namedRanges, hasLength(1));
      expect(
        restored.activeSheet.metadata.namedRanges.single.name,
        'Report_Total',
      );
      expect(restored.activeSheet.metadata.sortColumn, 1);
      expect(restored.activeSheet.metadata.sortAscending, isFalse);
      expect(restored.activeSheet.metadata.freezePane, CellAddress(1, 0));
      expect(restored.activeSheet.metadata.zoom, 1.25);
    });

    test('imports legacy single-sheet JSON as a workbook', () {
      final legacyJson = {
        'cells': {'0,0': CellData(value: 'Legacy').toJson()},
      };

      final workbook = SheetWorkbookCodec.decode(legacyJson);

      expect(workbook.sheets, hasLength(1));
      expect(workbook.activeSheet.name, 'Sheet1');
      expect(workbook.activeSheet.cells[CellAddress(0, 0)]?.value, 'Legacy');
    });
  });

  group('SheetEngineCodec', () {
    test('decodes Waraq sheet_engine grid snapshots into workbooks', () {
      final workbook = SheetEngineCodec.decodeWorkbook({
        'name': 'Engine Sheet',
        'max_col': 1,
        'max_row': 1,
        'cells': [
          {
            'position': {'col': 0, 'row': 0},
            'cell': {
              'raw_content': '10',
              'evaluated_value': {'Number': 10.0},
              'format': {
                'bold': true,
                'italic': false,
                'background_color': 'FFEFF6FF',
                'text_color': 'FF111827',
                'number_format': '0',
              },
            },
          },
          {
            'position': {'col': 1, 'row': 0},
            'cell': {
              'raw_content': '=A1*2',
              'evaluated_value': {'Number': 20.0},
              'format': {
                'bold': false,
                'italic': true,
                'background_color': null,
                'text_color': null,
                'number_format': null,
              },
            },
          },
          {
            'position': {'col': 0, 'row': 1},
            'cell': {
              'raw_content': 'Ready',
              'evaluated_value': 'Empty',
              'format': {
                'bold': false,
                'italic': false,
                'background_color': null,
                'text_color': null,
                'number_format': null,
              },
            },
          },
        ],
      });

      final sheet = workbook.activeSheet;

      expect(workbook.activeSheetId, 'sheet-engine-1-engine-sheet');
      expect(sheet.name, 'Engine Sheet');
      expect(sheet.cells[CellAddress(0, 0)]?.value, '10');
      expect(sheet.cells[CellAddress(0, 0)]?.style.bold, isTrue);
      expect(sheet.cells[CellAddress(0, 0)]?.style.numberFormat, '0');
      expect(
        sheet.cells[CellAddress(0, 0)]?.style.backgroundColor,
        const Color(0xFFEFF6FF),
      );
      expect(sheet.cells[CellAddress(0, 1)]?.formula, '=A1*2');
      expect(sheet.cells[CellAddress(0, 1)]?.value, '20');
      expect(sheet.cells[CellAddress(0, 1)]?.style.italic, isTrue);
      expect(sheet.cells[CellAddress(1, 0)]?.value, 'Ready');
    });

    test('encodes ky sheet workbooks as Waraq sheet_engine snapshots', () {
      final workbook = SheetWorkbook(
        activeSheetId: 'sheet-2',
        sheets: [
          WorkbookSheet(
            id: 'sheet-1',
            name: 'Inputs',
            cells: {
              CellAddress(0, 0): CellData(
                value: 'Input',
                style: const CellStyle(
                  bold: true,
                  backgroundColor: Color(0xFFEFF6FF),
                  textColor: Color(0xFF111827),
                  numberFormat: '@',
                ),
              ),
            },
          ),
          WorkbookSheet(
            id: 'sheet-2',
            name: 'Calc',
            cells: {
              CellAddress(0, 0): CellData(value: '10'),
              CellAddress(0, 1): CellData(value: '20', formula: '=A1*2'),
            },
          ),
        ],
      );

      final encoded = SheetEngineCodec.encodeWorkbook(workbook);
      final firstSheet = (encoded['sheets'] as List).first as Map;
      final firstCell = (firstSheet['cells'] as List).first as Map;
      final restored = SheetEngineCodec.decodeWorkbook(
        Map<String, dynamic>.from(encoded),
      );

      expect(encoded['type'], SheetEngineCodec.type);
      expect(encoded['engine'], SheetEngineCodec.engine);
      expect(encoded['activeSheetId'], 'sheet-2');
      expect(firstSheet['name'], 'Inputs');
      expect(firstCell['position'], {'col': 0, 'row': 0});
      expect((firstCell['cell'] as Map)['raw_content'], 'Input');
      expect((firstCell['cell'] as Map)['evaluated_value'], {
        'String': 'Input',
      });
      expect(restored.sheets, hasLength(2));
      expect(restored.activeSheet.name, 'Calc');
      expect(restored.activeSheet.cells[CellAddress(0, 1)]?.formula, '=A1*2');
      expect(restored.activeSheet.cells[CellAddress(0, 1)]?.value, '20');
    });
  });

  group('SheetEngineEditCodec', () {
    test('encodes Waraq sheet_engine cell edits', () {
      final address = CellAddress(2, 1);
      final formulaEdit = SheetEngineEditCodec.setCell(
        address,
        CellData(value: '20', formula: '=A1*2'),
      );
      final valueEdit = SheetEngineEditCodec.setCell(
        address,
        CellData(value: 'Ready'),
      );
      final clearEdit = SheetEngineEditCodec.clearCell(address);
      final formatEdit = SheetEngineEditCodec.setCellFormat(
        address,
        const CellStyle(
          bold: true,
          italic: true,
          backgroundColor: Color(0xFFEFF6FF),
          textColor: Color(0xFF111827),
          numberFormat: '0.00',
        ),
      );

      expect(formulaEdit, {
        'SetCell': {
          'position': {'col': 1, 'row': 2},
          'raw_content': '=A1*2',
        },
      });
      expect(valueEdit, {
        'SetCell': {
          'position': {'col': 1, 'row': 2},
          'raw_content': 'Ready',
        },
      });
      expect(clearEdit, {
        'ClearCell': {
          'position': {'col': 1, 'row': 2},
        },
      });
      expect(formatEdit, {
        'SetCellFormat': {
          'position': {'col': 1, 'row': 2},
          'format': {
            'bold': true,
            'italic': true,
            'background_color': 'FFEFF6FF',
            'text_color': 'FF111827',
            'number_format': '0.00',
          },
        },
      });
      expect(SheetEngineEditCodec.recalculate(), 'Recalculate');
    });

    test('builds Waraq sheet_engine operation envelopes', () {
      final edit = SheetEngineEditCodec.setCellRaw(CellAddress(0, 0), '=1+2');
      final operation = SheetEngineEditCodec.operation(
        operationId: 'op-1',
        documentId: 'sheet-1',
        actorId: 'actor-1',
        sequence: 7,
        timestampMs: 42000,
        edit: edit,
        metadata: {'source': 'ky_sheet'},
      );

      expect(operation, {
        'schema_version': 1,
        'operation_id': 'op-1',
        'engine': 'sheet',
        'document_id': 'sheet-1',
        'actor_id': 'actor-1',
        'sequence': 7,
        'timestamp_ms': 42000,
        'edit': {
          'SetCell': {
            'position': {'col': 0, 'row': 0},
            'raw_content': '=1+2',
          },
        },
        'metadata': {'source': 'ky_sheet'},
      });
    });

    test('builds Waraq operation logs without empty metadata', () {
      final operations = [
        SheetEngineEditCodec.operation(
          operationId: 'op-1',
          documentId: 'sheet-1',
          actorId: 'actor-1',
          sequence: 1,
          timestampMs: 100,
          edit: SheetEngineEditCodec.recalculate(),
        ),
      ];

      final log = SheetEngineEditCodec.operationLog(operations);

      expect(log['schema_version'], 1);
      expect(log['operations'], operations);
      expect(log.containsKey('metadata'), isFalse);
    });
  });

  group('SheetEngineOperationReplayer', () {
    test('parses Waraq edit, operation, and operation log payloads', () {
      final edit = SheetEngineEditCodec.setCellRaw(CellAddress(0, 0), '15');
      final operation = SheetEngineEditCodec.operation(
        operationId: 'op-1',
        documentId: 'sheet-1',
        actorId: 'actor-1',
        sequence: 1,
        timestampMs: 100,
        edit: edit,
      );
      final operationLog = SheetEngineEditCodec.operationLog([operation]);
      final mixedOperationLog = SheetEngineEditCodec.operationLog([
        SheetEngineEditCodec.operation(
          operationId: 'op-2',
          documentId: 'other-sheet',
          actorId: 'actor-1',
          sequence: 2,
          timestampMs: 200,
          edit: edit,
        ),
        operation,
      ]);

      expect(
        SheetEngineOperationPayloadParser.parseText(jsonEncode(edit)).kind,
        SheetEngineOperationPayloadKind.edit,
      );
      expect(
        SheetEngineOperationPayloadParser.parseText(jsonEncode(operation)).kind,
        SheetEngineOperationPayloadKind.operation,
      );
      expect(
        SheetEngineOperationPayloadParser.parseText(
          jsonEncode(operationLog),
        ).kind,
        SheetEngineOperationPayloadKind.operationLog,
      );
      expect(
        () => SheetEngineOperationPayloadParser.parseText('{}'),
        throwsFormatException,
      );

      final summary = SheetEngineOperationPayloadParser.summarizeText(
        jsonEncode(mixedOperationLog),
        expectedDocumentId: 'sheet-1',
      );

      expect(summary.kindLabel, 'Operation log');
      expect(summary.operationCount, 2);
      expect(summary.matchingOperationCount, 1);
      expect(summary.skippedOperationCount, 1);
      expect(summary.targetDocumentIds, ['other-sheet', 'sheet-1']);
    });

    test('skips operation envelopes for other document ids', () {
      final result = SheetEngineOperationReplayer.applyOperationLog(
        cells: const {},
        expectedDocumentId: 'sheet-1',
        operationLog: SheetEngineEditCodec.operationLog([
          SheetEngineEditCodec.operation(
            operationId: 'op-1',
            documentId: 'other-sheet',
            actorId: 'actor-1',
            sequence: 1,
            timestampMs: 100,
            edit: SheetEngineEditCodec.setCellRaw(CellAddress(0, 0), '15'),
          ),
          SheetEngineEditCodec.operation(
            operationId: 'op-2',
            documentId: 'sheet-1',
            actorId: 'actor-1',
            sequence: 2,
            timestampMs: 200,
            edit: SheetEngineEditCodec.setCellRaw(CellAddress(0, 1), '20'),
          ),
        ]),
      );

      expect(result.appliedEditCount, 1);
      expect(result.skippedOperationCount, 1);
      expect(result.cells[CellAddress(0, 0)], isNull);
      expect(result.cells[CellAddress(0, 1)]?.value, '20');
    });

    test('applies Waraq sheet_engine operation logs to cell maps', () {
      final result = SheetEngineOperationReplayer.applyOperationLog(
        cells: {
          CellAddress(0, 0): CellData(value: '10'),
          CellAddress(0, 1): CellData(value: '20', formula: '=A1*2'),
          CellAddress(2, 0): CellData(value: 'Remove me'),
        },
        operationLog: SheetEngineEditCodec.operationLog([
          SheetEngineEditCodec.operation(
            operationId: 'op-1',
            documentId: 'sheet-1',
            actorId: 'actor-1',
            sequence: 1,
            timestampMs: 100,
            edit: SheetEngineEditCodec.setCellRaw(CellAddress(0, 0), '15'),
          ),
          SheetEngineEditCodec.operation(
            operationId: 'op-2',
            documentId: 'sheet-1',
            actorId: 'actor-1',
            sequence: 2,
            timestampMs: 200,
            edit: SheetEngineEditCodec.setCellFormat(
              CellAddress(0, 1),
              const CellStyle(italic: true, numberFormat: '0.00'),
            ),
          ),
          SheetEngineEditCodec.operation(
            operationId: 'op-3',
            documentId: 'sheet-1',
            actorId: 'actor-1',
            sequence: 3,
            timestampMs: 300,
            edit: SheetEngineEditCodec.clearCell(CellAddress(2, 0)),
          ),
          SheetEngineEditCodec.operation(
            operationId: 'op-4',
            documentId: 'sheet-1',
            actorId: 'actor-1',
            sequence: 4,
            timestampMs: 400,
            edit: SheetEngineEditCodec.recalculate(),
          ),
        ]),
      );

      expect(result.appliedEditCount, 4);
      expect(result.shouldRecalculate, isTrue);
      expect(result.cells[CellAddress(0, 0)]?.value, '15');
      expect(result.cells[CellAddress(0, 1)]?.formula, '=A1*2');
      expect(result.cells[CellAddress(0, 1)]?.style.italic, isTrue);
      expect(result.cells[CellAddress(0, 1)]?.style.numberFormat, '0.00');
      expect(result.cells[CellAddress(2, 0)], isNull);
    });
  });

  group('SheetNameBox', () {
    testWidgets('selects typed ranges and publishes navigation requests', (
      tester,
    ) async {
      final nameBoxFinder = find.byKey(
        const ValueKey('ky-sheet-name-box-input'),
      );

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: Scaffold(body: SheetNameBox())),
        ),
      );

      await tester.tap(nameBoxFinder);
      await tester.enterText(nameBoxFinder, 'C3:D4');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();

      final container = ProviderScope.containerOf(
        tester.element(find.byType(SheetNameBox)),
        listen: false,
      );

      expect(container.read(selectedCellProvider)?.label, 'C3:D4');
      expect(
        container.read(sheetNavigationRequestProvider)?.selection.label,
        'C3:D4',
      );
    });

    testWidgets('selects saved named ranges from typed names', (tester) async {
      final nameBoxFinder = find.byKey(
        const ValueKey('ky-sheet-name-box-input'),
      );
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container
          .read(sheetNamedRangesProvider.notifier)
          .save(
            name: 'Sales_Table',
            selection: CellSelection(CellAddress(1, 0), CellAddress(3, 2)),
          );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: Scaffold(body: SheetNameBox())),
        ),
      );

      await tester.tap(nameBoxFinder);
      await tester.enterText(nameBoxFinder, 'Sales_Table');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();

      expect(container.read(selectedCellProvider)?.label, 'A2:C4');
      expect(
        container.read(sheetNavigationRequestProvider)?.selection.label,
        'A2:C4',
      );
    });
  });

  group('SheetNavigationController', () {
    test('clears formula previews by default and can preserve them', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(formulaReferencePreviewProvider.notifier).state = [
        CellSelection.single(CellAddress(0, 0)),
      ];
      container
          .read(formulaReferencePreviewContextProvider.notifier)
          .state = const SheetFormulaPreviewContext(
        source: SheetFormulaPreviewSource.formulaIssue,
        originLabel: 'A1',
        targetCount: 1,
      );

      container
          .read(sheetNavigationControllerProvider)
          .goTo(CellSelection.single(CellAddress(2, 2)));

      expect(container.read(selectedCellProvider)?.label, 'C3');
      expect(container.read(formulaReferencePreviewProvider), isEmpty);
      expect(container.read(formulaReferencePreviewContextProvider), isNull);

      container.read(formulaReferencePreviewProvider.notifier).state = [
        CellSelection.single(CellAddress(0, 0)),
      ];
      container
          .read(formulaReferencePreviewContextProvider.notifier)
          .state = const SheetFormulaPreviewContext(
        source: SheetFormulaPreviewSource.formulaIssue,
        originLabel: 'A1',
        targetCount: 1,
      );

      container
          .read(sheetNavigationControllerProvider)
          .goTo(
            CellSelection.single(CellAddress(3, 3)),
            clearFormulaPreview: false,
          );

      expect(container.read(selectedCellProvider)?.label, 'D4');
      expect(
        container
            .read(formulaReferencePreviewProvider)
            .map((selection) => selection.label),
        ['A1'],
      );
      expect(
        container.read(formulaReferencePreviewContextProvider)?.statusValue,
        'A1: 1 range',
      );
    });
  });

  group('RecentWorkbookSheetNotifier', () {
    test('resolves recent visible sheets newest first', () {
      final recent = RecentWorkbookSheetNotifier();

      recent.record('sheet-1');
      recent.record('sheet-2');
      recent.record('sheet-3');
      recent.record('sheet-2');

      final sheets = [
        const WorkbookSheet(id: 'sheet-1', name: 'Input'),
        const WorkbookSheet(id: 'sheet-2', name: 'Report'),
        const WorkbookSheet(id: 'sheet-3', name: 'Archive', hidden: true),
      ];

      expect(recent.state, ['sheet-2', 'sheet-3', 'sheet-1']);
      expect(
        recent
            .resolve(sheets: sheets, activeSheetId: 'sheet-1')
            .map((sheet) => sheet.name),
        ['Report'],
      );
    });
  });

  group('SheetFormulaEngine', () {
    const engine = SheetFormulaEngine();

    test('evaluates nested functions without changing quoted text case', () {
      final cells = {
        CellAddress(0, 0): CellData(value: '10'),
        CellAddress(1, 0): CellData(value: '15'),
      };

      expect(
        engine.evaluate('=IF(SUM(A1:A2)>20,"Mixed Case","small")', cells),
        'Mixed Case',
      );
    });

    test('supports absolute references, arithmetic precedence, and ranges', () {
      final cells = {
        CellAddress(0, 0): CellData(value: '10'),
        CellAddress(1, 0): CellData(value: '5'),
        CellAddress(2, 0): CellData(value: '1'),
      };

      expect(engine.evaluate(r'=$A$1*2+SUM(A2:A3)/3', cells), '22.00');
      expect(engine.evaluate('=(A1+A2)^2', cells), '225.00');
    });

    test('supports COUNT and COUNTA with spreadsheet-like semantics', () {
      final cells = {
        CellAddress(0, 0): CellData(value: '10'),
        CellAddress(1, 0): CellData(value: 'Text'),
        CellAddress(2, 0): CellData(value: ''),
        CellAddress(3, 0): CellData(value: '5.5'),
      };

      expect(engine.evaluate('=COUNT(A1:A4)', cells), '2');
      expect(engine.evaluate('=COUNTA(A1:A4)', cells), '3');
    });

    test('supports named ranges as ranges and single-cell values', () {
      final cells = {
        CellAddress(0, 0): CellData(value: '10'),
        CellAddress(1, 0): CellData(value: '15'),
        CellAddress(0, 2): CellData(value: '0.08'),
      };
      final namedRanges = [
        SheetNamedRange(
          id: 'range-1',
          name: 'Revenue_Table',
          selection: CellSelection(CellAddress(0, 0), CellAddress(1, 0)),
        ),
        SheetNamedRange(
          id: 'range-2',
          name: 'Tax.Rate',
          selection: CellSelection(CellAddress(0, 2)),
        ),
      ];

      expect(
        engine.evaluate('=SUM(revenue_table)', cells, namedRanges: namedRanges),
        '25.00',
      );
      expect(
        engine.evaluate('=Tax.Rate*100', cells, namedRanges: namedRanges),
        '8.00',
      );
      expect(
        engine.evaluate('=SUM(Missing_Name)', cells, namedRanges: namedRanges),
        '#NAME',
      );
    });

    test('supports SUMIF and COUNTIF operator criteria', () {
      final cells = {
        CellAddress(0, 0): CellData(value: '8'),
        CellAddress(1, 0): CellData(value: '12'),
        CellAddress(2, 0): CellData(value: '20'),
        CellAddress(0, 1): CellData(value: '80'),
        CellAddress(1, 1): CellData(value: '120'),
        CellAddress(2, 1): CellData(value: '200'),
      };

      expect(engine.evaluate('=SUMIF(A1:A3,">=10",B1:B3)', cells), '320.00');
      expect(engine.evaluate('=COUNTIF(A1:A3,">=10")', cells), '2');
    });

    test('supports exact VLOOKUP over rectangular ranges', () {
      final cells = {
        CellAddress(0, 0): CellData(value: 'SKU-1'),
        CellAddress(0, 1): CellData(value: 'Paper'),
        CellAddress(1, 0): CellData(value: 'SKU-2'),
        CellAddress(1, 1): CellData(value: 'Pencil'),
      };
      final namedRanges = [
        SheetNamedRange(
          id: 'products',
          name: 'Product_Table',
          selection: CellSelection(CellAddress(0, 0), CellAddress(1, 1)),
        ),
      ];

      expect(
        engine.evaluate('=VLOOKUP("SKU-2",A1:B2,2,FALSE)', cells),
        'Pencil',
      );
      expect(
        engine.evaluate(
          '=VLOOKUP("SKU-2",Product_Table,2,FALSE)',
          cells,
          namedRanges: namedRanges,
        ),
        'Pencil',
      );
      expect(engine.evaluate('=VLOOKUP("SKU-3",A1:B2,2,FALSE)', cells), '#N/A');
    });
  });

  group('SheetFormulaCatalog', () {
    test('searches functions by name and alias', () {
      final suggestions = SheetFormulaAutocomplete.suggestions(
        '=avg',
        caretOffset: 4,
      );

      expect(suggestions.first.name, 'AVERAGE');
      expect(SheetFormulaCatalog.find('avg')?.name, 'AVERAGE');
    });

    test('applies formula suggestions at the active token', () {
      final sum = SheetFormulaCatalog.find('SUM')!;
      final insertion = SheetFormulaAutocomplete.applySuggestion(
        '=su',
        sum,
        caretOffset: 3,
      );

      expect(insertion.text, '=SUM(');
      expect(insertion.caretOffset, 5);
    });

    test('does not suggest functions inside quoted text', () {
      expect(
        SheetFormulaAutocomplete.suggestions('=IF(A1="su', caretOffset: 10),
        isEmpty,
      );
    });
  });

  group('SheetFunctionInsertBuilder', () {
    test('builds aggregate formulas from adjacent vertical ranges', () {
      final cells = {
        CellAddress(0, 0): CellData(value: '10'),
        CellAddress(1, 0): CellData(value: '15'),
        CellAddress(2, 0): CellData(value: '20'),
      };

      final formula = SheetFunctionInsertBuilder.buildFormula(
        functionName: 'sum',
        target: CellAddress(3, 0),
        cells: cells,
      );

      expect(formula, '=SUM(A1:A3)');
    });

    test('uses horizontal ranges when no vertical range exists', () {
      final cells = {
        CellAddress(0, 0): CellData(value: '10'),
        CellAddress(0, 1): CellData(value: '15'),
      };

      final formula = SheetFunctionInsertBuilder.buildFormula(
        functionName: 'AVERAGE',
        target: CellAddress(0, 2),
        cells: cells,
      );

      expect(formula, '=AVERAGE(A1:B1)');
    });

    test('falls back to catalog templates when no adjacent range applies', () {
      expect(
        SheetFunctionInsertBuilder.buildFormula(
          functionName: 'LEN',
          target: CellAddress(4, 4),
          cells: const {},
        ),
        '=LEN()',
      );
      expect(
        SheetFunctionInsertBuilder.buildFormula(
          functionName: 'SUM',
          target: CellAddress(4, 4),
          cells: const {},
        ),
        '=SUM()',
      );
    });
  });

  group('SpreadsheetNotifier formulas', () {
    test('recalculates nested formula expressions through the notifier', () {
      final sheet = SpreadsheetNotifier();

      sheet.updateCellValue(CellAddress(0, 0), '10');
      sheet.updateCellValue(CellAddress(1, 0), '15');
      sheet.updateCellValue(CellAddress(2, 0), '=IF(SUM(A1:A2)>=30,A1*A2,0)');

      expect(sheet.state[CellAddress(2, 0)]?.value, '0.00');

      sheet.updateCellValue(CellAddress(1, 0), '20');

      expect(sheet.state[CellAddress(2, 0)]?.value, '200.00');
    });

    test('inserts aggregate functions with inferred nearby ranges', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final sheet = container.read(spreadsheetProvider.notifier);
      sheet.updateCellValue(CellAddress(0, 0), '10');
      sheet.updateCellValue(CellAddress(1, 0), '15');

      container
          .read(toolbarControllerProvider)
          .insertFunction(CellAddress(2, 0), 'SUM');

      expect(
        container.read(spreadsheetProvider)[CellAddress(2, 0)]?.formula,
        '=SUM(A1:A2)',
      );
      expect(
        container.read(spreadsheetProvider)[CellAddress(2, 0)]?.value,
        '25.00',
      );
    });
  });

  group('CellStyle', () {
    test('serializes border flags for history and persistence', () {
      const style = CellStyle(
        borderTop: true,
        borderBottom: true,
        borderLeft: true,
        borderRight: true,
      );

      final restored = CellStyle.fromJson(style.toJson());

      expect(restored.borderTop, isTrue);
      expect(restored.borderBottom, isTrue);
      expect(restored.borderLeft, isTrue);
      expect(restored.borderRight, isTrue);
    });
  });

  group('CellData', () {
    test('clears optional comment and hyperlink metadata', () {
      final data = CellData(
        value: 'Docs',
        comment: 'Review this',
        hyperlink: 'https://example.com',
      );

      final cleared = data.copyWith(clearComment: true, clearHyperlink: true);

      expect(cleared.comment, isNull);
      expect(cleared.hyperlink, isNull);
      expect(cleared.toJson().containsKey('comment'), isFalse);
      expect(cleared.toJson().containsKey('hyperlink'), isFalse);
    });
  });

  group('ConditionalFormatRule', () {
    test('serializes rule data for future persistence', () {
      final rule = ConditionalFormatRule(
        id: 'rule-1',
        selection: CellSelection(CellAddress(0, 0), CellAddress(2, 1)),
        condition: ConditionalFormatCondition.greaterThan,
        operand: '10',
        backgroundColor: Color(0xFFDCFCE7),
        textColor: Color(0xFF166534),
      );

      final restored = ConditionalFormatRule.fromJson(rule.toJson());

      expect(restored.id, 'rule-1');
      expect(restored.selection.label, 'A1:B3');
      expect(restored.condition, ConditionalFormatCondition.greaterThan);
      expect(restored.operand, '10');
      expect(restored.backgroundColor, const Color(0xFFDCFCE7));
      expect(restored.textColor, const Color(0xFF166534));
    });
  });

  group('SheetClipboardCodec', () {
    test('encodes and decodes tabular clipboard text', () {
      final rows = [
        ['Name', 'Notes'],
        ['Kaysir', 'line 1\nline 2'],
        ['Quote', 'A "quoted" value'],
      ];

      final encoded = SheetClipboardCodec.encodeRows(rows);

      expect(encoded, contains('"line 1\nline 2"'));
      expect(encoded, contains('"A ""quoted"" value"'));
      expect(SheetClipboardCodec.decodeRows(encoded), rows);
    });

    test('encodes selected cells as a rectangular range', () {
      final selection = CellSelection(CellAddress(0, 0), CellAddress(1, 1));
      final cells = {
        CellAddress(0, 0): CellData(value: 'A'),
        CellAddress(1, 1): CellData(value: 'D'),
      };

      expect(SheetClipboardCodec.encodeSelection(selection, cells), 'A\t\n\tD');
    });
  });

  group('SheetConditionalFormatEvaluator', () {
    test('applies matching rule style inside its range', () {
      final rule = ConditionalFormatRule(
        id: 'rule-1',
        selection: CellSelection(CellAddress(0, 0), CellAddress(0, 1)),
        condition: ConditionalFormatCondition.greaterThan,
        operand: '10',
        backgroundColor: Color(0xFFDCFCE7),
        textColor: Color(0xFF166534),
      );

      final style = SheetConditionalFormatEvaluator.effectiveStyle(
        address: CellAddress(0, 1),
        cellData: CellData(value: '12'),
        rules: [rule],
      );

      expect(style.backgroundColor, const Color(0xFFDCFCE7));
      expect(style.textColor, const Color(0xFF166534));
      expect(style.bold, isTrue);
    });

    test('ignores non-matching and out-of-range cells', () {
      final rule = ConditionalFormatRule(
        id: 'rule-1',
        selection: CellSelection(CellAddress(0, 0), CellAddress(0, 1)),
        condition: ConditionalFormatCondition.containsText,
        operand: 'paid',
        backgroundColor: Color(0xFFDBEAFE),
        textColor: Color(0xFF1D4ED8),
      );

      final outOfRangeStyle = SheetConditionalFormatEvaluator.effectiveStyle(
        address: CellAddress(1, 0),
        cellData: CellData(value: 'paid'),
        rules: [rule],
      );
      final nonMatchingStyle = SheetConditionalFormatEvaluator.effectiveStyle(
        address: CellAddress(0, 0),
        cellData: CellData(value: 'pending'),
        rules: [rule],
      );

      expect(outOfRangeStyle.backgroundColor, isNull);
      expect(nonMatchingStyle.backgroundColor, isNull);
    });
  });

  group('SheetValidationStatus', () {
    test('reports invalid values with helpful messages', () {
      final status = SheetValidationStatus.fromCell(
        CellData(
          value: 'not-an-email',
          validation: CellValidation(
            type: ValidationType.email,
            errorMessage: 'Enter a valid email',
          ),
        ),
      );

      expect(status.hasValidation, isTrue);
      expect(status.isInvalid, isTrue);
      expect(status.tooltip, 'Enter a valid email');
    });

    test('exposes list validation options', () {
      final status = SheetValidationStatus.fromCell(
        CellData(
          value: 'Open',
          validation: CellValidation(
            type: ValidationType.list,
            options: ['Open', 'Closed'],
          ),
        ),
      );

      expect(status.isValid, isTrue);
      expect(status.hasListOptions, isTrue);
      expect(status.options, ['Open', 'Closed']);
    });
  });

  group('SheetFormulaErrorStatus', () {
    test('describes formula errors with spreadsheet-friendly labels', () {
      final status = SheetFormulaErrorStatus.fromCell(
        CellData(value: '#DIV/0', formula: '=A1/0'),
      );

      expect(status.hasError, isTrue);
      expect(status.code, '#DIV/0');
      expect(status.title, 'Division by zero');
      expect(status.tooltip, contains('blank value'));
    });

    test('ignores literal error-like values without a formula', () {
      final status = SheetFormulaErrorStatus.fromCell(
        CellData(value: '#VALUE'),
      );

      expect(status.hasError, isFalse);
      expect(status.tooltip, isEmpty);
    });
  });

  group('SheetCellFormatter', () {
    test('formats numeric display values without changing raw cell value', () {
      final currencyCell = CellData(
        value: '1234.5',
        style: const CellStyle(numberFormat: SheetNumberFormatId.currency),
      );
      final percentCell = CellData(
        value: '0.125',
        style: const CellStyle(numberFormat: SheetNumberFormatId.percent),
      );
      final numberCell = CellData(
        value: '1234.5',
        style: const CellStyle(numberFormat: SheetNumberFormatId.number),
      );

      expect(SheetCellFormatter.displayValue(currencyCell), r'$1,234.50');
      expect(SheetCellFormatter.displayValue(percentCell), '12.5%');
      expect(SheetCellFormatter.displayValue(numberCell), '1,234.5');
      expect(currencyCell.value, '1234.5');
    });

    test('formats dates and preserves unsupported values', () {
      final dateCell = CellData(
        value: '2026-06-07',
        style: const CellStyle(numberFormat: SheetNumberFormatId.date),
      );
      final textCell = CellData(
        value: 'not-a-number',
        style: const CellStyle(numberFormat: SheetNumberFormatId.currency),
      );

      expect(SheetCellFormatter.displayValue(dateCell), 'Jun 7, 2026');
      expect(SheetCellFormatter.displayValue(textCell), 'not-a-number');
    });
  });

  group('SheetFilterEvaluator', () {
    test('filters rows using active column queries', () {
      final cells = {
        CellAddress(0, 0): CellData(value: 'Amina'),
        CellAddress(0, 1): CellData(value: 'Paid'),
        CellAddress(1, 0): CellData(value: 'Budi'),
        CellAddress(1, 1): CellData(value: 'Pending'),
        CellAddress(2, 0): CellData(value: 'Aminah'),
        CellAddress(2, 1): CellData(value: 'Paid'),
      };

      final visibleRows = SheetFilterEvaluator.visibleRows(
        rows: [0, 1, 2],
        filters: {0: 'amin', 1: 'paid'},
        cells: cells,
      );

      expect(visibleRows, [0, 2]);
      expect(SheetFilterEvaluator.hasActiveFilters({0: ''}), isFalse);
      expect(SheetFilterEvaluator.hasActiveFilters({0: 'paid'}), isTrue);
    });

    test('filters rows using rich comparison and blank rules', () {
      final cells = {
        CellAddress(0, 0): CellData(value: '12'),
        CellAddress(1, 0): CellData(value: '4'),
        CellAddress(1, 1): CellData(value: 'Ready'),
        CellAddress(2, 0): CellData(value: '9'),
      };

      final visibleRows = SheetFilterEvaluator.visibleRows(
        rows: [0, 1, 2],
        filters: const {},
        filterRules: const {
          0: SheetFilterRule(
            operator: SheetFilterOperator.greaterThan,
            value: '8',
          ),
          1: SheetFilterRule(operator: SheetFilterOperator.empty),
        },
        cells: cells,
      );

      expect(visibleRows, [0, 2]);
      expect(
        SheetFilterEvaluator.hasActiveRuleForColumn(
          column: 1,
          filters: const {},
          filterRules: const {
            1: SheetFilterRule(operator: SheetFilterOperator.empty),
          },
        ),
        isTrue,
      );
    });

    test('filters rows using checklist value rules', () {
      final cells = {
        CellAddress(0, 0): CellData(value: 'Paid'),
        CellAddress(1, 0): CellData(value: 'Pending'),
        CellAddress(2, 0): CellData(value: 'PAID'),
        CellAddress(3, 0): CellData(value: 'Draft'),
      };

      final rule = SheetFilterRule.oneOf(['Paid', 'Draft']);
      final visibleRows = SheetFilterEvaluator.visibleRows(
        rows: [0, 1, 2, 3],
        filters: const {},
        filterRules: {0: rule},
        cells: cells,
      );

      expect(rule.operator, SheetFilterOperator.oneOf);
      expect(rule.valueList, ['Paid', 'Draft']);
      expect(rule.description, 'Values (2)');
      expect(visibleRows, [0, 2, 3]);
    });
  });

  group('SheetCellQuickFilterRuleBuilder', () {
    test('builds blank-aware keep and exclude filters', () {
      final keepOnlyRule = SheetCellQuickFilterRuleBuilder.build(
        value: ' Open ',
        mode: SheetCellQuickFilterMode.keepOnly,
      );
      final excludeRule = SheetCellQuickFilterRuleBuilder.build(
        value: ' Open ',
        mode: SheetCellQuickFilterMode.exclude,
      );
      final keepBlankRule = SheetCellQuickFilterRuleBuilder.build(
        value: '   ',
        mode: SheetCellQuickFilterMode.keepOnly,
      );
      final excludeBlankRule = SheetCellQuickFilterRuleBuilder.build(
        value: '',
        mode: SheetCellQuickFilterMode.exclude,
      );

      expect(keepOnlyRule.operator, SheetFilterOperator.equals);
      expect(keepOnlyRule.value, 'Open');
      expect(excludeRule.operator, SheetFilterOperator.notEquals);
      expect(excludeRule.value, 'Open');
      expect(keepBlankRule.operator, SheetFilterOperator.empty);
      expect(excludeBlankRule.operator, SheetFilterOperator.notEmpty);
    });
  });

  group('SheetColumnFilterSummaryBuilder', () {
    test('prefers rich filter descriptions for active column filters', () {
      final summary = SheetColumnFilterSummaryBuilder.forColumn(
        column: 1,
        filters: const {1: 'legacy'},
        filterRules: const {
          1: SheetFilterRule(
            operator: SheetFilterOperator.greaterThanOrEqual,
            value: '25',
          ),
        },
      );

      expect(summary.hasFilter, isTrue);
      expect(summary.detailLabel, 'Greater than or equal "25"');
    });

    test('falls back to legacy text filters and reports inactive columns', () {
      final legacySummary = SheetColumnFilterSummaryBuilder.forColumn(
        column: 0,
        filters: const {0: ' paid '},
        filterRules: const {},
      );
      final inactiveSummary = SheetColumnFilterSummaryBuilder.forColumn(
        column: 1,
        filters: const {0: 'paid'},
        filterRules: const {},
      );

      expect(legacySummary.hasFilter, isTrue);
      expect(legacySummary.detailLabel, 'Contains "paid"');
      expect(inactiveSummary.hasFilter, isFalse);
      expect(inactiveSummary.detailLabel, 'No active filter');
    });
  });

  group('SheetTableFilterSummaryBuilder', () {
    test('summarizes active filters scoped to table columns', () {
      final table = SheetTable.fromSelection(
        id: 'table-1',
        name: 'Sales',
        selection: CellSelection(CellAddress(0, 0), CellAddress(2, 2)),
      );

      final summary = SheetTableFilterSummaryBuilder.forTable(
        table: table,
        filters: const {0: 'paid', 5: 'outside'},
        filterRules: const {
          1: SheetFilterRule(
            operator: SheetFilterOperator.greaterThanOrEqual,
            value: '25',
          ),
          4: SheetFilterRule(operator: SheetFilterOperator.empty),
        },
      );
      final emptySummary = SheetTableFilterSummaryBuilder.forTable(
        table: table,
        filters: const {5: 'outside'},
        filterRules: const {
          4: SheetFilterRule(operator: SheetFilterOperator.empty),
        },
      );

      expect(summary.hasFilters, isTrue);
      expect(summary.activeFilterCount, 2);
      expect(summary.activeColumns, containsAll([0, 1]));
      expect(summary.detailLabel, '2 filtered columns');
      expect(emptySummary.hasFilters, isFalse);
      expect(emptySummary.detailLabel, 'No table filters active');
    });
  });

  group('SheetTableFilterVisibilitySummaryBuilder', () {
    test('counts visible body rows after scoped table filters', () {
      final table = SheetTable.fromSelection(
        id: 'table-1',
        name: 'Sales',
        selection: CellSelection(CellAddress(0, 0), CellAddress(3, 1)),
      ).copyWith(showTotalsRow: true);
      final filterSummary = SheetTableFilterSummaryBuilder.forTable(
        table: table,
        filters: const {0: 'EMEA', 5: 'outside'},
        filterRules: const {},
      );
      final visibilitySummary =
          SheetTableFilterVisibilitySummaryBuilder.forTable(
            filterSummary: filterSummary,
            cells: {
              CellAddress(0, 0): CellData(value: 'Region'),
              CellAddress(1, 0): CellData(value: 'EMEA'),
              CellAddress(2, 0): CellData(value: 'APAC'),
              CellAddress(3, 0): CellData(value: 'EMEA total'),
            },
          );
      final headerOnlySummary =
          SheetTableFilterVisibilitySummaryBuilder.forTable(
            filterSummary: SheetTableFilterSummaryBuilder.forTable(
              table: SheetTable.fromSelection(
                id: 'table-2',
                name: 'Empty',
                selection: CellSelection(CellAddress(0, 0), CellAddress(0, 1)),
              ),
              filters: const {0: 'EMEA'},
              filterRules: const {},
            ),
            cells: const {},
          );

      expect(visibilitySummary.totalBodyRows, 2);
      expect(visibilitySummary.visibleBodyRows, 1);
      expect(visibilitySummary.hiddenBodyRows, 1);
      expect(visibilitySummary.detailLabel, '1 of 2 rows shown');
      expect(headerOnlySummary.hasBodyRows, isFalse);
      expect(headerOnlySummary.detailLabel, 'No data rows');
    });
  });

  group('SheetTableFilterImpactLabelBuilder', () {
    test('combines active table filter count and visible row impact', () {
      final table = SheetTable.fromSelection(
        id: 'table-1',
        name: 'Sales',
        selection: CellSelection(CellAddress(0, 0), CellAddress(2, 1)),
      );
      final filterSummary = SheetTableFilterSummaryBuilder.forTable(
        table: table,
        filters: const {1: '5'},
        filterRules: const {},
      );
      final visibilitySummary =
          SheetTableFilterVisibilitySummaryBuilder.forTable(
            filterSummary: filterSummary,
            cells: {
              CellAddress(1, 1): CellData(value: '2'),
              CellAddress(2, 1): CellData(value: '5'),
            },
          );
      final emptyFilterSummary = SheetTableFilterSummaryBuilder.forTable(
        table: table,
        filters: const {},
        filterRules: const {},
      );
      final emptyVisibilitySummary =
          SheetTableFilterVisibilitySummaryBuilder.forTable(
            filterSummary: emptyFilterSummary,
            cells: const {},
          );

      expect(
        SheetTableFilterImpactLabelBuilder.build(
          filterSummary: filterSummary,
          visibilitySummary: visibilitySummary,
        ),
        '1 filtered column · 1 of 2 rows shown',
      );
      expect(
        SheetTableFilterImpactLabelBuilder.build(
          filterSummary: emptyFilterSummary,
          visibilitySummary: emptyVisibilitySummary,
        ),
        'No table filters active',
      );
    });
  });

  group('SheetTableHeaderActionTooltipBuilder', () {
    test('builds actionable header tooltip details', () {
      final table = SheetTable.fromSelection(
        id: 'table-1',
        name: 'Sales',
        selection: CellSelection(CellAddress(0, 0), CellAddress(2, 1)),
      );
      final rule = const SheetFilterRule(
        operator: SheetFilterOperator.greaterThanOrEqual,
        value: '5',
      );
      final columnFilterSummary = SheetColumnFilterSummaryBuilder.forColumn(
        column: 1,
        filters: const {},
        filterRules: {1: rule},
      );
      final tableFilterSummary = SheetTableFilterSummaryBuilder.forTable(
        table: table,
        filters: const {},
        filterRules: {1: rule},
      );
      final tableFilterVisibilitySummary =
          SheetTableFilterVisibilitySummaryBuilder.forTable(
            filterSummary: tableFilterSummary,
            cells: {
              CellAddress(1, 1): CellData(value: '2'),
              CellAddress(2, 1): CellData(value: '5'),
            },
          );

      expect(
        SheetTableHeaderActionTooltipBuilder.build(
          isSorted: true,
          sortAscending: false,
          columnFilterSummary: columnFilterSummary,
          tableFilterSummary: tableFilterSummary,
          tableFilterVisibilitySummary: tableFilterVisibilitySummary,
          formulaSummary: const SheetTableCalculatedColumnSummary(
            state: SheetTableCalculatedColumnState.none,
            bodyCellCount: 2,
            formulaCellCount: 0,
            bodySelection: null,
          ),
        ),
        'Table column sorted, filtered · Sort: Z to A · '
        'Filter: Greater than or equal "5" · '
        '1 filtered column · 1 of 2 rows shown',
      );
    });
  });

  group('SheetColumnFilterValueBuilder', () {
    test('builds sorted unique values for a column and optional row scope', () {
      final cells = {
        CellAddress(0, 1): CellData(value: 'Header'),
        CellAddress(1, 1): CellData(value: ' Beta '),
        CellAddress(2, 1): CellData(value: 'Alpha'),
        CellAddress(3, 1): CellData(value: 'beta'),
        CellAddress(4, 1): CellData(value: ''),
        CellAddress(2, 0): CellData(value: 'Ignored'),
      };

      expect(SheetColumnFilterValueBuilder.build(column: 1, cells: cells), [
        'Alpha',
        'Beta',
        'beta',
        'Header',
      ]);
      expect(
        SheetColumnFilterValueBuilder.build(
          column: 1,
          cells: cells,
          rows: [1, 2, 4],
        ),
        ['Alpha', 'Beta'],
      );
    });
  });

  group('SheetFillSeries', () {
    test('continues numeric series downward', () {
      final cells = {
        CellAddress(0, 0): CellData(value: '1'),
        CellAddress(1, 0): CellData(value: '3'),
      };

      final filled = SheetFillSeries.buildFill(
        sourceSelection: CellSelection(CellAddress(0, 0), CellAddress(1, 0)),
        targetSelection: CellSelection(CellAddress(0, 0), CellAddress(4, 0)),
        cells: cells,
      );

      expect(filled[CellAddress(2, 0)]?.value, '5');
      expect(filled[CellAddress(3, 0)]?.value, '7');
      expect(filled[CellAddress(4, 0)]?.value, '9');
    });

    test('copies text patterns to the right', () {
      final cells = {
        CellAddress(0, 0): CellData(value: 'Open'),
        CellAddress(0, 1): CellData(value: 'Closed'),
      };

      final filled = SheetFillSeries.buildFill(
        sourceSelection: CellSelection(CellAddress(0, 0), CellAddress(0, 1)),
        targetSelection: CellSelection(CellAddress(0, 0), CellAddress(0, 5)),
        cells: cells,
      );

      expect(filled[CellAddress(0, 2)]?.value, 'Open');
      expect(filled[CellAddress(0, 3)]?.value, 'Closed');
      expect(filled[CellAddress(0, 4)]?.value, 'Open');
      expect(filled[CellAddress(0, 5)]?.value, 'Closed');
    });

    test('shifts formulas downward during fill', () {
      final cells = {
        CellAddress(1, 1): CellData(formula: '=SUM(A1:B2)', value: '10'),
      };

      final filled = SheetFillSeries.buildFill(
        sourceSelection: CellSelection(CellAddress(1, 1)),
        targetSelection: CellSelection(CellAddress(1, 1), CellAddress(3, 1)),
        cells: cells,
      );

      expect(filled[CellAddress(2, 1)]?.formula, '=SUM(A2:B3)');
      expect(filled[CellAddress(3, 1)]?.formula, '=SUM(A3:B4)');
      expect(filled[CellAddress(2, 1)]?.value, '');
    });

    test('shifts formulas right while preserving absolute references', () {
      final cells = {
        CellAddress(0, 1): CellData(formula: r'=A1+$B1+C$1+$D$1', value: '10'),
      };

      final filled = SheetFillSeries.buildFill(
        sourceSelection: CellSelection(CellAddress(0, 1)),
        targetSelection: CellSelection(CellAddress(0, 1), CellAddress(0, 3)),
        cells: cells,
      );

      expect(filled[CellAddress(0, 2)]?.formula, r'=B1+$B1+D$1+$D$1');
      expect(filled[CellAddress(0, 3)]?.formula, r'=C1+$B1+E$1+$D$1');
    });
  });

  group('SheetFormulaReference', () {
    test('shifts relative cell and range references', () {
      final shifted = SheetFormulaReference.shiftFormula(
        '=A1+SUM(B2:C3)',
        rowDelta: 2,
        colDelta: 1,
      );

      expect(shifted, '=B3+SUM(C4:D5)');
    });

    test('preserves absolute reference axes and quoted text', () {
      final shifted = SheetFormulaReference.shiftFormula(
        r'=A1+$B1+C$1+$D$1+"A1"',
        rowDelta: 1,
        colDelta: 2,
      );

      expect(shifted, r'=C2+$B2+E$1+$D$1+"A1"');
    });

    test('extracts referenced cells and ranges outside quoted text', () {
      final selections = SheetFormulaReference.referencedSelections(
        r'=SUM(A1:B2)+$C$3+"D4"',
      );

      expect(selections, hasLength(2));
      expect(selections[0].label, 'A1:B2');
      expect(selections[1].label, 'C3');
    });

    test('extracts named range references outside quoted text', () {
      final selections = SheetFormulaReference.referencedSelections(
        '=SUM(Revenue_Table)+Tax.Rate+"Revenue_Table"',
        namedRanges: [
          SheetNamedRange(
            id: 'range-1',
            name: 'Revenue_Table',
            selection: CellSelection(CellAddress(0, 0), CellAddress(2, 1)),
          ),
          SheetNamedRange(
            id: 'range-2',
            name: 'Tax.Rate',
            selection: CellSelection(CellAddress(0, 4)),
          ),
        ],
      );

      expect(
        selections.map((selection) => selection.label),
        containsAll(['A1:B3', 'E1']),
      );
    });
  });

  group('SheetFormulaAutocomplete', () {
    test('filters formula suggestions from the active token', () {
      final suggestions = SheetFormulaAutocomplete.suggestions('=su');

      expect(suggestions.map((suggestion) => suggestion.name), contains('SUM'));
      expect(
        suggestions.map((suggestion) => suggestion.name),
        contains('SUMIF'),
      );
      expect(SheetFormulaAutocomplete.suggestions('plain text'), isEmpty);
      expect(SheetFormulaAutocomplete.suggestions('="su'), isEmpty);
    });

    test('suggests and inserts named ranges from the active token', () {
      final suggestions = SheetFormulaAutocomplete.suggestions(
        '=SUM(Rev',
        namedRanges: [
          SheetNamedRange(
            id: 'range-1',
            name: 'Revenue_Table',
            selection: CellSelection(CellAddress(0, 0), CellAddress(2, 1)),
          ),
        ],
      );

      expect(suggestions.first.kind, SheetFormulaSuggestionKind.namedRange);
      expect(suggestions.first.name, 'Revenue_Table');
      expect(suggestions.first.signature, 'A1:B3');

      final insertion = SheetFormulaAutocomplete.applySuggestion(
        '=SUM(Rev',
        suggestions.first,
      );

      expect(insertion.text, '=SUM(Revenue_Table');
      expect(insertion.caretOffset, insertion.text.length);
    });

    test('inserts a selected function at the current formula token', () {
      final suggestion = SheetFormulaCatalog.functions.firstWhere(
        (suggestion) => suggestion.name == 'SUM',
      );

      final insertion = SheetFormulaAutocomplete.applySuggestion(
        '=A1+su',
        suggestion,
      );

      expect(insertion.text, '=A1+SUM(');
      expect(insertion.caretOffset, insertion.text.length);
    });
  });

  group('SheetFormulaAuditor', () {
    test('finds references and dependents for the selected formula cell', () {
      final cells = {
        CellAddress(0, 0): CellData(value: '10'),
        CellAddress(1, 0): CellData(value: '20'),
        CellAddress(0, 1): CellData(
          value: '30.00',
          formula: '=SUM(Source_Block)',
        ),
        CellAddress(0, 3): CellData(value: '60.00', formula: '=B1*2'),
      };
      final namedRanges = [
        SheetNamedRange(
          id: 'source-block',
          name: 'Source_Block',
          selection: CellSelection(CellAddress(0, 0), CellAddress(1, 0)),
        ),
      ];

      final audit = SheetFormulaAuditor.inspect(
        selection: CellSelection(CellAddress(0, 1)),
        cells: cells,
        namedRanges: namedRanges,
      );

      expect(audit.formula, '=SUM(Source_Block)');
      expect(audit.references.map((reference) => reference.label), ['A1:A2']);
      expect(audit.dependents.map((dependent) => dependent.label), ['D1']);
      expect(audit.dependents.single.matchedReferences.single.label, 'B1');
    });
  });

  group('SheetFormulaTraceBuilder', () {
    test('builds reusable trace selections from formula audit results', () {
      final audit = SheetFormulaAudit(
        selection: CellSelection(CellAddress(0, 1)),
        address: CellAddress(0, 1),
        formula: '=SUM(A1:A2)',
        result: '30.00',
        references: [
          SheetFormulaAuditReference(
            selection: CellSelection(CellAddress(0, 0), CellAddress(1, 0)),
          ),
        ],
        dependents: [
          SheetFormulaAuditDependent(
            address: CellAddress(0, 3),
            formula: '=B1*2',
            result: '60.00',
            matchedReferences: [CellSelection.single(CellAddress(0, 1))],
          ),
        ],
      );

      expect(
        SheetFormulaTraceBuilder.build(
          audit,
          SheetFormulaTraceMode.references,
        ).map((selection) => selection.label),
        ['A1:A2'],
      );
      expect(
        SheetFormulaTraceBuilder.build(
          audit,
          SheetFormulaTraceMode.dependents,
        ).map((selection) => selection.label),
        ['D1'],
      );
      expect(
        SheetFormulaTraceBuilder.build(
          audit,
          SheetFormulaTraceMode.all,
        ).map((selection) => selection.label),
        ['A1:A2', 'D1'],
      );
    });
  });

  group('SheetFormulaPreviewContext', () {
    test('formats compact status labels for active formula highlights', () {
      const context = SheetFormulaPreviewContext(
        source: SheetFormulaPreviewSource.traceReferences,
        originLabel: 'B1',
        targetCount: 1,
      );

      expect(context.statusLabel, 'Trace References');
      expect(context.statusValue, 'B1: 1 range');

      const allContext = SheetFormulaPreviewContext(
        source: SheetFormulaPreviewSource.traceAll,
        originLabel: 'B1',
        targetCount: 2,
      );

      expect(allContext.statusLabel, 'Trace All');
      expect(allContext.statusValue, 'B1: 2 ranges');

      const issueContext = SheetFormulaPreviewContext(
        source: SheetFormulaPreviewSource.formulaIssue,
        originLabel: 'C1',
        targetCount: 1,
      );

      expect(issueContext.statusLabel, 'Formula Issue');
      expect(issueContext.statusValue, 'C1: 1 range');

      const issuesContext = SheetFormulaPreviewContext(
        source: SheetFormulaPreviewSource.formulaIssues,
        originLabel: '#CYCLE',
        targetCount: 2,
      );

      expect(issuesContext.statusLabel, 'Formula Issues');
      expect(issuesContext.statusValue, '#CYCLE: 2 ranges');
    });
  });

  group('SheetFormulaHealthScanner', () {
    test('counts formulas and sorted formula issues', () {
      final health = SheetFormulaHealthScanner.scan({
        CellAddress(0, 0): CellData(value: '2.00', formula: '=1+1'),
        CellAddress(0, 1): CellData(value: '#DIV/0', formula: '=A1/0'),
        CellAddress(0, 2): CellData(value: '#VALUE'),
        CellAddress(0, 3): CellData(value: '#NAME', formula: '=Missing_Name'),
      });

      expect(health.formulaCount, 3);
      expect(health.healthyCount, 1);
      expect(health.issueCount, 2);
      expect(health.issues.map((issue) => issue.label), ['B1', 'D1']);
      expect(health.issueCountsByCode, {'#DIV/0': 1, '#NAME': 1});
      expect(
        health.issues.first.relatedSelections.map(
          (selection) => selection.label,
        ),
        ['B1', 'A1'],
      );
    });

    test('detects self and multi-cell circular references', () {
      final health = SheetFormulaHealthScanner.scan({
        CellAddress(0, 0): CellData(value: '1.00', formula: '=B1+1'),
        CellAddress(0, 1): CellData(value: '2.00', formula: '=A1+1'),
        CellAddress(0, 2): CellData(value: '3.00', formula: '=SUM(C1:C1)'),
        CellAddress(0, 3): CellData(value: '6.00', formula: '=A1+B1'),
      });

      final cycleIssues = health.issues
          .where((issue) => issue.code == '#CYCLE')
          .toList();

      expect(health.formulaCount, 4);
      expect(health.healthyCount, 1);
      expect(cycleIssues.map((issue) => issue.label), ['A1', 'B1', 'C1']);
      expect(health.issueCountsByCode, {'#CYCLE': 3});
      expect(cycleIssues.first.suggestion, 'Break the loop: A1 -> B1 -> A1.');
      expect(
        cycleIssues.first.relatedSelections.map((selection) => selection.label),
        ['A1', 'B1'],
      );
      expect(cycleIssues.last.suggestion, 'Break the loop: C1 -> C1.');
      expect(
        cycleIssues.last.relatedSelections.map((selection) => selection.label),
        ['C1'],
      );
    });

    test('detects circular references through named ranges', () {
      final health = SheetFormulaHealthScanner.scan(
        {
          CellAddress(0, 0): CellData(value: '1.00', formula: '=Source_Cell'),
          CellAddress(0, 1): CellData(value: '2.00', formula: '=A1+1'),
        },
        namedRanges: [
          SheetNamedRange(
            id: 'source-cell',
            name: 'Source_Cell',
            selection: CellSelection.single(CellAddress(0, 1)),
          ),
        ],
      );

      expect(
        health.issues
            .where((issue) => issue.code == '#CYCLE')
            .map((issue) => issue.label),
        ['A1', 'B1'],
      );
    });
  });

  group('SheetFormulaHealthFilter', () {
    test(
      'filters formula issues by code and search query without mutation',
      () {
        final issues = [
          SheetFormulaIssue(
            address: CellAddress(0, 0),
            formula: '=A1/0',
            result: '#DIV/0',
            code: '#DIV/0',
            title: 'Division by zero',
            message: 'A formula is dividing by zero.',
            suggestion: 'Check denominators.',
          ),
          SheetFormulaIssue(
            address: CellAddress(0, 1),
            formula: '=B1',
            result: '#CYCLE',
            code: '#CYCLE',
            title: 'Circular reference',
            message: 'This formula participates in a circular dependency.',
            suggestion: 'Break the loop.',
          ),
          SheetFormulaIssue(
            address: CellAddress(0, 2),
            formula: '=Missing_Name',
            result: '#NAME',
            code: '#NAME',
            title: 'Formula error',
            message: 'The formula returned an unknown error code.',
            suggestion: 'Review the formula and referenced cells.',
          ),
        ];

        expect(
          SheetFormulaHealthFilter.apply(
            issues,
            issueCode: '#CYCLE',
          ).map((issue) => issue.label),
          ['B1'],
        );
        expect(
          SheetFormulaHealthFilter.apply(
            issues,
            query: 'missing',
          ).map((issue) => issue.label),
          ['C1'],
        );
        expect(
          SheetFormulaHealthFilter.apply(
            issues,
            issueCode: '#CYCLE',
            query: 'division',
          ),
          isEmpty,
        );
        expect(SheetFormulaHealthFilter.apply(issues), hasLength(3));
        expect(issues, hasLength(3));
      },
    );
  });

  group('SheetFormulaIssueSorter', () {
    test('sorts formula issues by cell and type without mutation', () {
      final issues = [
        SheetFormulaIssue(
          address: CellAddress(0, 2),
          formula: '=Missing_Name',
          result: '#NAME',
          code: '#NAME',
          title: 'Formula error',
          message: 'The formula returned an unknown error code.',
          suggestion: 'Review the formula.',
        ),
        SheetFormulaIssue(
          address: CellAddress(1, 0),
          formula: '=A1/0',
          result: '#DIV/0',
          code: '#DIV/0',
          title: 'Division by zero',
          message: 'A formula is dividing by zero.',
          suggestion: 'Check denominators.',
        ),
        SheetFormulaIssue(
          address: CellAddress(0, 1),
          formula: '=B1',
          result: '#CYCLE',
          code: '#CYCLE',
          title: 'Circular reference',
          message: 'This formula participates in a circular dependency.',
          suggestion: 'Break the loop.',
        ),
      ];

      expect(SheetFormulaIssueSorter.sort(issues).map((issue) => issue.label), [
        'B1',
        'C1',
        'A2',
      ]);
      expect(
        SheetFormulaIssueSorter.sort(
          issues,
          mode: SheetFormulaIssueSortMode.code,
        ).map((issue) => issue.label),
        ['B1', 'A2', 'C1'],
      );
      expect(issues.map((issue) => issue.label), ['C1', 'A2', 'B1']);
    });
  });

  group('SheetFormulaIssueCodeCatalog', () {
    test('describes known formula issue codes with friendly labels', () {
      final division = SheetFormulaIssueCodeCatalog.describe('#div/0');
      final cycle = SheetFormulaIssueCodeCatalog.describe('#CYCLE');
      final fallback = SheetFormulaIssueCodeCatalog.describe('#SPILL');

      expect(division.shortLabel, 'Division');
      expect(division.compactLabel, 'Division (#DIV/0)');
      expect(cycle.label, 'Circular reference');
      expect(fallback.shortLabel, 'Error');
      expect(fallback.compactLabel, 'Error (#SPILL)');
    });
  });

  group('SheetFormulaIssueViewState', () {
    test('describes visible formula issue refinements', () {
      const defaultView = SheetFormulaIssueViewState(
        visibleIssueCount: 3,
        totalIssueCount: 3,
      );
      const refinedView = SheetFormulaIssueViewState(
        visibleIssueCount: 1,
        totalIssueCount: 3,
        activeCode: '#CYCLE',
        searchQuery: ' missing ',
        sortMode: SheetFormulaIssueSortMode.code,
      );
      const singleView = SheetFormulaIssueViewState(
        visibleIssueCount: 1,
        totalIssueCount: 1,
      );

      expect(defaultView.countLabel, 'Showing 3 issues');
      expect(defaultView.activeBadges, isEmpty);
      expect(defaultView.canReset, isFalse);
      expect(refinedView.countLabel, 'Showing 1 of 3 issues');
      expect(refinedView.activeBadges, [
        'Type: Circular (#CYCLE)',
        'Search: missing',
        'Sort: Type',
      ]);
      expect(refinedView.canReset, isTrue);
      expect(singleView.countLabel, 'Showing 1 issue');
    });
  });

  group('SheetFormulaIssueCodeBadge', () {
    testWidgets('shows friendly label, normalized code, and tooltip', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: SheetFormulaIssueCodeBadge(code: '#div/0')),
        ),
      );

      expect(find.text('Division'), findsOneWidget);
      expect(find.text('#DIV/0'), findsOneWidget);
      expect(
        find.byTooltip(
          'Division by zero (#DIV/0). A formula divides by zero, blank, or invalid data.',
        ),
        findsOneWidget,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SheetFormulaIssueCodeBadge(code: '#CYCLE', showLabel: false),
          ),
        ),
      );

      expect(find.text('Circular'), findsNothing);
      expect(find.text('#CYCLE'), findsOneWidget);
    });
  });

  group('SheetFormulaIssueTraceBuilder', () {
    test('uses related selections and falls back to the issue address', () {
      final issueWithContext = SheetFormulaIssue(
        address: CellAddress(0, 1),
        formula: '=A1/0',
        result: '#DIV/0',
        code: '#DIV/0',
        title: 'Division by zero',
        message: 'A formula is dividing by zero.',
        suggestion: 'Check denominators.',
        relatedSelections: [
          CellSelection.single(CellAddress(0, 1)),
          CellSelection.single(CellAddress(0, 0)),
        ],
      );
      final issueWithoutContext = SheetFormulaIssue(
        address: CellAddress(2, 2),
        formula: '=Missing_Name',
        result: '#NAME',
        code: '#NAME',
        title: 'Formula error',
        message: 'The formula returned an unknown error code.',
        suggestion: 'Review the formula.',
      );

      expect(
        SheetFormulaIssueTraceBuilder.build(
          issueWithContext,
        ).map((selection) => selection.label),
        ['B1', 'A1'],
      );
      expect(
        SheetFormulaIssueTraceBuilder.build(
          issueWithoutContext,
        ).map((selection) => selection.label),
        ['C3'],
      );
      expect(
        SheetFormulaIssueTraceBuilder.buildAll([
          issueWithContext,
          issueWithoutContext,
        ]).map((selection) => selection.label),
        ['B1', 'A1', 'C3'],
      );
    });
  });

  group('SheetFormulaIssueGuidanceBuilder', () {
    test('builds code-specific investigation checks', () {
      final divisionIssue = SheetFormulaIssue(
        address: CellAddress(0, 1),
        formula: '=A1/0',
        result: '#DIV/0',
        code: '#DIV/0',
        title: 'Division by zero',
        message: 'A formula is dividing by zero.',
        suggestion: 'Check denominators.',
        relatedSelections: [
          CellSelection.single(CellAddress(0, 1)),
          CellSelection.single(CellAddress(0, 0)),
        ],
      );
      final cycleIssue = SheetFormulaIssue(
        address: CellAddress(0, 2),
        formula: '=C1+1',
        result: '1.00',
        code: '#CYCLE',
        title: 'Circular reference',
        message: 'This formula participates in a circular dependency.',
        suggestion: 'Break the loop.',
      );

      final divisionGuidance = SheetFormulaIssueGuidanceBuilder.build(
        divisionIssue,
      );
      final cycleGuidance = SheetFormulaIssueGuidanceBuilder.build(cycleIssue);

      expect(divisionGuidance.title, 'Check the denominator');
      expect(
        divisionGuidance.checks.first,
        'Trace denominator references: A1.',
      );
      expect(cycleGuidance.title, 'Break the dependency loop');
      expect(
        cycleGuidance.checks.first,
        'Trace the related cells and find which formula points back to C1.',
      );
    });
  });

  group('SheetFormulaIssueReportBuilder', () {
    test('builds spreadsheet-friendly visible issue reports', () {
      final issue = SheetFormulaIssue(
        address: CellAddress(0, 1),
        formula: '=A1/\n0',
        result: '#DIV/0',
        code: '#DIV/0',
        title: 'Division by zero',
        message: 'A formula is dividing by zero.',
        suggestion: 'Check\tdenominators.',
        relatedSelections: [
          CellSelection.single(CellAddress(0, 1)),
          CellSelection.single(CellAddress(0, 0)),
        ],
      );

      expect(
        SheetFormulaIssueReportBuilder.buildTsv([issue]),
        'Cell\tCode\tTitle\tFormula\tSuggestion\tNext Check\tAdditional Checks\n'
        'B1\t#DIV/0\tDivision by zero\t=A1/ 0\tCheck denominators.\t'
        'Trace denominator references: A1.\t'
        'Look for zero, blank, or text values where the divisor is expected. | '
        'Use IF to guard the division once the source data is understood.',
      );
    });
  });

  group('SheetFormulaIssueFocus', () {
    test('clamps and wraps focused formula issue indexes', () {
      final issues = [
        SheetFormulaIssue(
          address: CellAddress(0, 0),
          formula: '=A1',
          result: '#CYCLE',
          code: '#CYCLE',
          title: 'Circular reference',
          message: 'This formula participates in a circular dependency.',
          suggestion: 'Break the loop.',
        ),
        SheetFormulaIssue(
          address: CellAddress(0, 1),
          formula: '=A1/0',
          result: '#DIV/0',
          code: '#DIV/0',
          title: 'Division by zero',
          message: 'A formula is dividing by zero.',
          suggestion: 'Check denominators.',
        ),
      ];

      expect(SheetFormulaIssueFocus.clampIndex(-2, issues.length), 0);
      expect(SheetFormulaIssueFocus.clampIndex(8, issues.length), 1);
      expect(SheetFormulaIssueFocus.nextIndex(1, issues.length), 0);
      expect(SheetFormulaIssueFocus.previousIndex(0, issues.length), 1);
      expect(SheetFormulaIssueFocus.issueAt(issues, 8)?.label, 'B1');
      expect(SheetFormulaIssueFocus.issueAt(const [], 8), isNull);
    });
  });

  group('SheetGoToSpecialScanner', () {
    test('finds formulas, metadata, and blanks inside the used range', () {
      final cells = {
        CellAddress(0, 0): CellData(value: 'Name'),
        CellAddress(0, 1): CellData(value: '2.00', formula: '=1+1'),
        CellAddress(1, 0): CellData(
          value: '',
          comment: 'Needs owner',
          validation: CellValidation(type: ValidationType.required),
        ),
        CellAddress(1, 2): CellData(
          value: '#DIV/0',
          formula: '=A1/0',
          hyperlink: 'https://example.com',
        ),
      };

      expect(
        SheetGoToSpecialScanner.scan(
          kind: SheetGoToSpecialKind.formulas,
          cells: cells,
        ).matches.map((match) => match.label),
        ['B1', 'C2'],
      );
      expect(
        SheetGoToSpecialScanner.scan(
          kind: SheetGoToSpecialKind.formulaErrors,
          cells: cells,
        ).matches.single.label,
        'C2',
      );
      expect(
        SheetGoToSpecialScanner.scan(
          kind: SheetGoToSpecialKind.blanks,
          cells: cells,
        ).matches.map((match) => match.label),
        ['C1', 'B2'],
      );
      expect(
        SheetGoToSpecialScanner.scan(
          kind: SheetGoToSpecialKind.validations,
          cells: cells,
        ).matches.single.detail,
        'Required field',
      );
    });
  });

  group('SheetReviewScanner', () {
    test('finds comments and hyperlinks in sheet order', () {
      final summary = SheetReviewScanner.scan({
        CellAddress(1, 1): CellData(
          value: 'Docs',
          hyperlink: 'https://example.com/docs',
        ),
        CellAddress(0, 0): CellData(value: 'Owner', comment: 'Needs owner'),
        CellAddress(0, 2): CellData(
          value: 'Budget',
          comment: 'Check amount',
          hyperlink: 'https://example.com/budget',
        ),
      });

      expect(summary.totalCount, 4);
      expect(summary.commentCount, 2);
      expect(summary.hyperlinkCount, 2);
      expect(summary.items.map((item) => item.address.label), [
        'A1',
        'C1',
        'C1',
        'B2',
      ]);
      expect(summary.items.first.kind, SheetReviewItemKind.comment);
      expect(summary.items.last.kind, SheetReviewItemKind.hyperlink);
      expect(summary.items.first.preview, 'Needs owner');
      expect(summary.items.first.valueLabel, 'Owner');
    });
  });

  group('SheetCleanupEngine', () {
    test('builds text cleanup plans while skipping formulas', () {
      final selection = CellSelection(CellAddress(0, 0), CellAddress(1, 1));
      final cells = {
        CellAddress(0, 0): CellData(value: '  Alpha  '),
        CellAddress(0, 1): CellData(value: 'Beta', formula: '=A1'),
        CellAddress(1, 0): CellData(value: 'two   spaces'),
        CellAddress(1, 1): CellData(value: 'Clean'),
      };

      final trimPlan = SheetCleanupEngine.buildPlan(
        operation: SheetCleanupOperation.trimWhitespace,
        selection: selection,
        cells: cells,
      );
      final normalizePlan = SheetCleanupEngine.buildPlan(
        operation: SheetCleanupOperation.normalizeWhitespace,
        selection: selection,
        cells: cells,
      );

      expect(trimPlan.scannedCellCount, 4);
      expect(trimPlan.changedCellCount, 1);
      expect(trimPlan.replacements[CellAddress(0, 0)]?.value, 'Alpha');
      expect(trimPlan.replacements.containsKey(CellAddress(0, 1)), isFalse);
      expect(
        normalizePlan.replacements[CellAddress(1, 0)]?.value,
        'two spaces',
      );
    });

    test('clears duplicate rows inside the selected range', () {
      final plan = SheetCleanupEngine.buildPlan(
        operation: SheetCleanupOperation.clearDuplicateRows,
        selection: CellSelection(CellAddress(0, 0), CellAddress(3, 1)),
        cells: {
          CellAddress(0, 0): CellData(value: 'A'),
          CellAddress(0, 1): CellData(value: '1'),
          CellAddress(1, 0): CellData(value: 'B'),
          CellAddress(1, 1): CellData(value: '2'),
          CellAddress(2, 0): CellData(value: 'A'),
          CellAddress(2, 1): CellData(value: '1'),
          CellAddress(3, 0): CellData(value: ''),
        },
      );

      expect(plan.affectedRowCount, 1);
      expect(plan.changedCellCount, 2);
      expect(plan.replacements[CellAddress(2, 0)], isNull);
      expect(plan.replacements[CellAddress(2, 1)], isNull);
      expect(plan.replacements.containsKey(CellAddress(3, 0)), isFalse);
    });
  });

  group('SheetSelectionSummary', () {
    test('summarizes mixed selections for status metrics', () {
      final cells = {
        CellAddress(0, 0): CellData(value: '10'),
        CellAddress(0, 1): CellData(value: 'Kaysir'),
        CellAddress(1, 0): CellData(value: '-2.5'),
        CellAddress(1, 1): CellData(value: '7.25'),
      };

      final summary = SheetSelectionSummary.fromSelection(
        selection: CellSelection(CellAddress(0, 0), CellAddress(1, 1)),
        cells: cells,
      );

      expect(summary.label, 'A1:B2');
      expect(summary.selectedCellCount, 4);
      expect(summary.nonEmptyCellCount, 4);
      expect(summary.numericCellCount, 3);
      expect(summary.sum, 14.75);
      expect(summary.average, closeTo(4.916, 0.001));
      expect(summary.min, -2.5);
      expect(summary.max, 10);
    });

    test('formats footer numbers without noisy decimals', () {
      expect(SheetSelectionSummary.formatNumber(42), '42');
      expect(SheetSelectionSummary.formatNumber(1234.5), '1,234.5');
      expect(SheetSelectionSummary.formatNumber(2.345), '2.35');
    });
  });

  group('SheetStatusIndicatorSummary', () {
    test('builds workbook, mode, filter, and sort labels', () {
      final summary = SheetStatusIndicatorSummary.fromState(
        workbook: const SheetWorkbook(
          activeSheetId: 'sheet-2',
          sheets: [
            WorkbookSheet(id: 'sheet-1', name: 'Input'),
            WorkbookSheet(id: 'sheet-2', name: 'Report'),
            WorkbookSheet(id: 'sheet-3', name: 'Archive'),
          ],
        ),
        filters: const {0: 'paid', 3: ''},
        filterRules: {
          0: SheetFilterRule.contains('paid'),
          1: const SheetFilterRule(operator: SheetFilterOperator.empty),
          2: SheetFilterRule.contains(''),
        },
        sortColumn: 1,
        sortAscending: false,
        editingCell: CellAddress(3, 2),
      );

      expect(summary.modeValue, 'Editing C4');
      expect(summary.sheetValue, '2/3');
      expect(summary.sheetTooltip, 'Active sheet Report (2 of 3)');
      expect(summary.activeFilterCount, 2);
      expect(summary.filterValue, '2 active');
      expect(summary.sortValue, 'B Z-A');
      expect(summary.sortTooltip, 'Sorted by column B descending');
    });
  });

  group('SheetDataProfiler', () {
    test('profiles selected range composition and quality signals', () {
      final profile = SheetDataProfiler.profile(
        selection: CellSelection(CellAddress(0, 0), CellAddress(1, 2)),
        cells: {
          CellAddress(0, 0): CellData(value: '10'),
          CellAddress(1, 0): CellData(value: '20'),
          CellAddress(0, 1): CellData(value: 'East'),
          CellAddress(1, 1): CellData(value: 'East'),
          CellAddress(0, 2): CellData(value: '30', formula: '=SUM(A1:A2)'),
          CellAddress(1, 2): CellData(
            value: 'not-email',
            validation: CellValidation(type: ValidationType.email),
          ),
        },
      );

      expect(profile.label, 'A1:C2');
      expect(profile.totalCells, 6);
      expect(profile.filledCells, 6);
      expect(profile.numericCells, 3);
      expect(profile.textCells, 3);
      expect(profile.formulaCells, 1);
      expect(profile.invalidCells, 1);
      expect(profile.duplicateValueCells, 2);
      expect(profile.average, 20);
      expect(profile.topValues.first.value, 'East');
      expect(profile.topValues.first.count, 2);
      expect(profile.topValues.first.firstAddress, CellAddress(0, 1));
      expect(
        profile.histogram.fold<int>(0, (sum, bucket) => sum + bucket.count),
        3,
      );
    });

    test('profiles the used range when there is no active selection', () {
      final profile = SheetDataProfiler.profile(
        selection: null,
        cells: {
          CellAddress(2, 1): CellData(value: 'A'),
          CellAddress(4, 3): CellData(value: '4'),
        },
      );

      expect(profile.fromSelection, isFalse);
      expect(profile.label, 'B3:D5');
      expect(profile.totalCells, 9);
      expect(profile.filledCells, 2);
      expect(profile.blankCells, 7);
    });
  });

  group('SheetChartDataBuilder', () {
    test('builds chart series from headers and row labels', () {
      final data = SheetChartDataBuilder.build(
        selection: CellSelection(CellAddress(0, 0), CellAddress(2, 2)),
        spec: const SheetChartSpec(),
        cells: {
          CellAddress(0, 0): CellData(value: 'Month'),
          CellAddress(0, 1): CellData(value: 'Revenue'),
          CellAddress(0, 2): CellData(value: 'Cost'),
          CellAddress(1, 0): CellData(value: 'Jan'),
          CellAddress(1, 1): CellData(value: '10'),
          CellAddress(1, 2): CellData(value: '4'),
          CellAddress(2, 0): CellData(value: 'Feb'),
          CellAddress(2, 1): CellData(value: '20'),
          CellAddress(2, 2): CellData(value: '8'),
        },
      );

      expect(data.selectionLabel, 'A1:C3');
      expect(data.series.map((series) => series.label), ['Revenue', 'Cost']);
      expect(data.series.first.points.map((point) => point.label), [
        'Jan',
        'Feb',
      ]);
      expect(data.series.first.points.map((point) => point.value), [10, 20]);
      expect(data.series.first.points.first.address, CellAddress(1, 1));
      expect(data.pointCount, 4);
      expect(data.maxValue, 20);
    });

    test(
      'uses fallback labels when headers and label columns are disabled',
      () {
        final data = SheetChartDataBuilder.build(
          selection: CellSelection(CellAddress(0, 0), CellAddress(1, 1)),
          spec: const SheetChartSpec(
            useFirstRowAsHeaders: false,
            useFirstColumnAsLabels: false,
          ),
          cells: {
            CellAddress(0, 0): CellData(value: '1'),
            CellAddress(0, 1): CellData(value: '2'),
            CellAddress(1, 0): CellData(value: '3'),
            CellAddress(1, 1): CellData(value: '4'),
          },
        );

        expect(data.series.map((series) => series.label), ['A', 'B']);
        expect(data.series.first.points.map((point) => point.label), [
          'Row 1',
          'Row 2',
        ]);
      },
    );
  });

  group('SheetViewportMetrics', () {
    test('filters hidden rows and columns and clamps column widths', () {
      final rows = {
        1: RowConfig(index: 1, hidden: true),
        2: RowConfig(index: 2, height: 48),
        3: RowConfig(index: 3, height: 8),
      };
      final columns = {
        0: ColumnConfig(index: 0, width: 20),
        1: ColumnConfig(index: 1, hidden: true),
      };

      expect(SheetViewportMetrics.visibleRows(4, rows), [0, 2, 3]);
      expect(SheetViewportMetrics.visibleColumns(3, columns), [0, 2]);
      expect(SheetViewportMetrics.rowHeight(2, rows, 1.25), 60);
      expect(
        SheetViewportMetrics.rowHeight(3, rows, 1),
        KySheetMetrics.minRowHeight,
      );
      expect(
        SheetViewportMetrics.columnWidth(0, columns, 1),
        KySheetMetrics.minColumnWidth,
      );
    });

    test('calculates a buffered viewport slice from scroll offsets', () {
      final slice = SheetViewportMetrics.viewportSlice(
        indexes: List.generate(20, (index) => index),
        scrollOffset: 50,
        viewportExtent: 100,
        extentFor: (_) => 10,
        leadingBuffer: 1,
        trailingBuffer: 2,
      );

      expect(slice.indexes.first, 4);
      expect(slice.indexes.last, 16);
      expect(slice.leadingExtent, 40);
      expect(slice.renderedExtent, 130);
      expect(slice.contentExtent, 200);
      expect(slice.trailingExtent, 30);
      expect(slice.renderedCount, 13);
      expect(slice.sourceCount, 20);
    });
  });

  group('SheetFreezePaneLayout', () {
    test('splits visible rows and columns at the freeze address', () {
      final layout = SheetFreezePaneLayout.from(
        freezePane: CellAddress(2, 1),
        visibleRows: [0, 1, 3],
        visibleColumns: [0, 2, 3],
      );

      expect(layout.frozenRows, [0, 1]);
      expect(layout.scrollingRows, [3]);
      expect(layout.frozenColumns, [0]);
      expect(layout.scrollingColumns, [2, 3]);
      expect(layout.hasFrozenPanes, isTrue);
    });

    test('keeps all visible cells scrollable without a freeze address', () {
      final layout = SheetFreezePaneLayout.from(
        freezePane: null,
        visibleRows: [0, 2],
        visibleColumns: [1, 3],
      );

      expect(layout.frozenRows, isEmpty);
      expect(layout.scrollingRows, [0, 2]);
      expect(layout.frozenColumns, isEmpty);
      expect(layout.scrollingColumns, [1, 3]);
      expect(layout.hasFrozenPanes, isFalse);
    });
  });

  group('SheetViewStateSummary', () {
    test('describes freeze and zoom state with spreadsheet labels', () {
      final custom = SheetViewStateSummary(
        freezePane: CellAddress(2, 1),
        zoom: 1.25,
      );

      expect(custom.freezeLabel, '2 rows, 1 column');
      expect(custom.freezeDetail, 'Freeze before B3');
      expect(custom.zoomLabel, '125%');
      expect(custom.hasFrozenRows, isTrue);
      expect(custom.hasFrozenColumns, isTrue);

      final firstRow = SheetViewStateSummary(
        freezePane: CellAddress(1, 0),
        zoom: 1,
      );
      expect(firstRow.freezeLabel, 'First row');

      const none = SheetViewStateSummary(freezePane: null, zoom: 0.75);
      expect(none.freezeLabel, 'None');
      expect(none.freezeDetail, 'No frozen panes');
      expect(none.zoomLabel, '75%');
    });
  });

  group('SheetFindReplaceEngine', () {
    test('finds matches by scope and respects case options', () {
      final cells = {
        CellAddress(0, 0): CellData(value: 'Revenue Total'),
        CellAddress(1, 0): CellData(value: '42', formula: '=SUM(A1:A1)'),
      };

      final valueMatches = SheetFindReplaceEngine.findMatches(
        cells: cells,
        query: 'total',
        options: const SheetSearchOptions(scope: SheetSearchScope.cellValues),
      );
      final formulaMatches = SheetFindReplaceEngine.findMatches(
        cells: cells,
        query: 'SUM',
        options: const SheetSearchOptions(
          matchCase: true,
          scope: SheetSearchScope.formulas,
        ),
      );
      final caseSensitiveMiss = SheetFindReplaceEngine.findMatches(
        cells: cells,
        query: 'sum',
        options: const SheetSearchOptions(
          matchCase: true,
          scope: SheetSearchScope.formulas,
        ),
      );

      expect(valueMatches.map((match) => match.address.label), ['A1']);
      expect(formulaMatches.single.target, SheetSearchTarget.formula);
      expect(caseSensitiveMiss, isEmpty);
    });

    test('replaces text without treating replacement as a regex pattern', () {
      final replaced = SheetFindReplaceEngine.replaceText(
        source: 'a.b a.b',
        find: 'a.b',
        replacement: r'$1',
        matchCase: true,
      );

      expect(replaced, r'$1 $1');
    });
  });

  group('InlineCellEditor', () {
    testWidgets('commits text with enter', (tester) async {
      String? committedValue;
      CellEditCommitIntent? committedIntent;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: InlineCellEditor(
              initialValue: 'old',
              width: 120,
              height: 40,
              textStyle: KySheetTextStyles.cell,
              textAlign: TextAlign.left,
              onCommit: (value, intent) {
                committedValue = value;
                committedIntent = intent;
              },
              onCancel: () {},
            ),
          ),
        ),
      );
      await tester.pump();

      await tester.enterText(find.byType(TextField), '42');
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);

      expect(committedValue, '42');
      expect(committedIntent, CellEditCommitIntent.nextRow);
    });

    testWidgets('cancels text with escape', (tester) async {
      var canceled = false;
      var committed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: InlineCellEditor(
              initialValue: 'old',
              width: 120,
              height: 40,
              textStyle: KySheetTextStyles.cell,
              textAlign: TextAlign.left,
              onCommit: (_, _) => committed = true,
              onCancel: () => canceled = true,
            ),
          ),
        ),
      );
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);

      expect(canceled, isTrue);
      expect(committed, isFalse);
    });
  });

  group('FormulaBar', () {
    testWidgets('suggests and inserts formulas while editing', (tester) async {
      final formulaInputFinder = find.byKey(
        const ValueKey('ky-sheet-formula-input'),
      );
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(selectedCellProvider.notifier).state = CellSelection(
        CellAddress(0, 0),
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: Scaffold(body: FormulaBar())),
        ),
      );

      await tester.enterText(formulaInputFinder, '=su');
      await tester.pumpAndSettle();

      expect(find.text('SUM'), findsOneWidget);

      await tester.tap(find.text('SUM'));
      await tester.pumpAndSettle();

      final field = tester.widget<TextField>(formulaInputFinder);
      expect(field.controller?.text, '=SUM(');
    });
  });

  group('Sheet headers', () {
    testWidgets('column resize handle emits horizontal deltas', (tester) async {
      var totalDelta = 0.0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SheetColumnHeader(
              column: 0,
              width: 120,
              height: 34,
              isActive: false,
              onTap: () {},
              onResize: (delta) => totalDelta += delta,
            ),
          ),
        ),
      );

      final headerRect = tester.getRect(find.byType(SheetColumnHeader));
      await tester.dragFrom(
        Offset(headerRect.right - 2, headerRect.center.dy),
        const Offset(24, 0),
      );

      expect(totalDelta, greaterThan(0));
    });

    testWidgets('column header menu emits selected actions', (tester) async {
      SheetColumnHeaderAction? selectedAction;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SheetColumnHeader(
              column: 0,
              width: 120,
              height: 34,
              isActive: false,
              hasFilter: true,
              onTap: () {},
              onMenuAction: (action) => selectedAction = action,
            ),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.filter_alt));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sort Z-A'));
      await tester.pumpAndSettle();

      expect(selectedAction, SheetColumnHeaderAction.sortDescending);
    });

    testWidgets('column header menu tooltip describes sort and filter state', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SheetColumnHeader(
              column: 0,
              width: 120,
              height: 34,
              isActive: false,
              hasFilter: true,
              filterDescription: 'Equals "Paid"',
              isSorted: true,
              sortAscending: false,
              onTap: () {},
              onMenuAction: (_) {},
            ),
          ),
        ),
      );

      expect(find.byTooltip('Sorted Z-A\nFilter: Equals "Paid"'), findsOne);
    });

    testWidgets('row header menu emits selected actions', (tester) async {
      SheetRowHeaderAction? selectedAction;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SheetRowHeader(
              row: 0,
              width: 56,
              height: 38,
              isActive: false,
              onTap: () {},
              onMenuAction: (action) => selectedAction = action,
            ),
          ),
        ),
      );

      await tester.tap(find.byKey(const ValueKey('ky-sheet-row-menu-0')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Insert row below'));
      await tester.pumpAndSettle();

      expect(selectedAction, SheetRowHeaderAction.insertBelow);
    });

    testWidgets('column filter dialog returns applied text rule', (
      tester,
    ) async {
      SheetColumnFilterDialogResult? result;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: Center(
                  child: ElevatedButton(
                    onPressed: () async {
                      result = await showDialog<SheetColumnFilterDialogResult>(
                        context: context,
                        builder: (context) => const SheetColumnFilterDialog(
                          column: 1,
                          initialValue: '',
                        ),
                      );
                    },
                    child: const Text('Open'),
                  ),
                ),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('ky-sheet-filter-value')),
        'Paid',
      );
      await tester.ensureVisible(find.text('Apply'));
      await tester.tap(find.text('Apply'));
      await tester.pumpAndSettle();

      expect(result?.clear, isFalse);
      expect(result?.rule?.operator, SheetFilterOperator.contains);
      expect(result?.rule?.value, 'Paid');
    });

    testWidgets('column filter dialog returns condition rule', (tester) async {
      SheetColumnFilterDialogResult? result;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: Center(
                  child: ElevatedButton(
                    onPressed: () async {
                      result = await showDialog<SheetColumnFilterDialogResult>(
                        context: context,
                        builder: (context) =>
                            const SheetColumnFilterDialog(column: 1),
                      );
                    },
                    child: const Text('Open'),
                  ),
                ),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('ky-sheet-filter-operator')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Equals').last);
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('ky-sheet-filter-value')),
        'Paid',
      );
      await tester.ensureVisible(find.text('Apply'));
      await tester.tap(find.text('Apply'));
      await tester.pumpAndSettle();

      expect(result?.action, SheetColumnFilterDialogAction.applyFilter);
      expect(result?.rule?.operator, SheetFilterOperator.equals);
      expect(result?.rule?.value, 'Paid');
    });

    testWidgets('column filter dialog summarizes active sort and filter', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SheetColumnFilterDialog(
              column: 1,
              initialRule: SheetFilterRule(
                operator: SheetFilterOperator.equals,
                value: 'Paid',
              ),
              isSorted: true,
              sortAscending: false,
            ),
          ),
        ),
      );

      expect(
        find.byKey(const ValueKey('ky-sheet-column-filter-state-summary')),
        findsOneWidget,
      );
      expect(find.text('Sorted Z-A'), findsOneWidget);
      expect(find.text('Equals "Paid"'), findsOneWidget);
    });

    testWidgets('column filter dialog returns checklist value rule', (
      tester,
    ) async {
      SheetColumnFilterDialogResult? result;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: Center(
                  child: ElevatedButton(
                    onPressed: () async {
                      result = await showDialog<SheetColumnFilterDialogResult>(
                        context: context,
                        builder: (context) => const SheetColumnFilterDialog(
                          column: 1,
                          values: ['Paid', 'Open', 'Paid'],
                        ),
                      );
                    },
                    child: const Text('Open'),
                  ),
                ),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(
        find.byKey(const ValueKey('ky-sheet-column-filter-clear-values')),
      );
      await tester.tap(
        find.byKey(const ValueKey('ky-sheet-column-filter-clear-values')),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(
        find.byKey(const ValueKey('ky-sheet-column-filter-value-1')),
      );
      await tester.tap(
        find.byKey(const ValueKey('ky-sheet-column-filter-value-1')),
      );
      await tester.ensureVisible(find.text('Apply'));
      await tester.tap(find.text('Apply'));
      await tester.pumpAndSettle();

      expect(result?.clear, isFalse);
      expect(result?.rule?.operator, SheetFilterOperator.oneOf);
      expect(result?.rule?.valueList, ['Paid']);
    });

    testWidgets('column filter dialog selects searched checklist matches', (
      tester,
    ) async {
      SheetColumnFilterDialogResult? result;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: Center(
                  child: ElevatedButton(
                    onPressed: () async {
                      result = await showDialog<SheetColumnFilterDialogResult>(
                        context: context,
                        builder: (context) => const SheetColumnFilterDialog(
                          column: 1,
                          values: ['Paid', 'Draft', 'Closed'],
                        ),
                      );
                    },
                    child: const Text('Open'),
                  ),
                ),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(
        find.byKey(const ValueKey('ky-sheet-column-filter-clear-values')),
      );
      await tester.tap(
        find.byKey(const ValueKey('ky-sheet-column-filter-clear-values')),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(
        find.byKey(const ValueKey('ky-sheet-column-filter-search')),
      );
      await tester.enterText(
        find.byKey(const ValueKey('ky-sheet-column-filter-search')),
        'Paid',
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('ky-sheet-column-filter-select-all')),
      );
      await tester.ensureVisible(find.text('Apply'));
      await tester.tap(find.text('Apply'));
      await tester.pumpAndSettle();

      expect(result?.rule?.operator, SheetFilterOperator.oneOf);
      expect(result?.rule?.valueList, ['Paid']);
    });

    testWidgets('column filter dialog returns sort actions', (tester) async {
      SheetColumnFilterDialogResult? result;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: Center(
                  child: ElevatedButton(
                    onPressed: () async {
                      result = await showDialog<SheetColumnFilterDialogResult>(
                        context: context,
                        builder: (context) => const SheetColumnFilterDialog(
                          column: 1,
                          isSorted: true,
                          sortAscending: true,
                        ),
                      );
                    },
                    child: const Text('Open'),
                  ),
                ),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('ky-sheet-column-filter-sort-desc')),
      );
      await tester.pumpAndSettle();

      expect(result?.action, SheetColumnFilterDialogAction.sortDescending);
    });

    testWidgets('column filter dialog returns clear sort actions', (
      tester,
    ) async {
      SheetColumnFilterDialogResult? result;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: Center(
                  child: ElevatedButton(
                    onPressed: () async {
                      result = await showDialog<SheetColumnFilterDialogResult>(
                        context: context,
                        builder: (context) => const SheetColumnFilterDialog(
                          column: 1,
                          isSorted: true,
                          sortAscending: false,
                        ),
                      );
                    },
                    child: const Text('Open'),
                  ),
                ),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('ky-sheet-column-filter-clear-sort')),
      );
      await tester.pumpAndSettle();

      expect(result?.action, SheetColumnFilterDialogAction.clearSort);
    });
  });

  group('SpreadsheetGrid', () {
    testWidgets('shows a selection mini toolbar with contextual actions', (
      tester,
    ) async {
      final container = ProviderContainer();
      final horizontal = ScrollController();
      final vertical = ScrollController();
      addTearDown(container.dispose);
      addTearDown(horizontal.dispose);
      addTearDown(vertical.dispose);

      container.read(selectedCellProvider.notifier).state = CellSelection(
        CellAddress(0, 0),
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 640,
                height: 260,
                child: SpreadsheetGrid(
                  horizontalController: horizontal,
                  verticalController: vertical,
                  rows: 30,
                  cols: 12,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('ky-sheet-mini-toolbar')),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const ValueKey('ky-sheet-mini-bold')));
      await tester.pumpAndSettle();
      expect(
        container.read(spreadsheetProvider)[CellAddress(0, 0)]?.style.bold,
        isTrue,
      );

      await tester.tap(
        find.byKey(const ValueKey('ky-sheet-mini-format-painter')),
      );
      await tester.pumpAndSettle();
      expect(container.read(sheetFormatPainterSnapshotProvider), isNotNull);

      await tester.tap(find.byKey(const ValueKey('ky-sheet-mini-chart')));
      await tester.pumpAndSettle();
      expect(
        container.read(activeSidebarPanelProvider),
        SheetSidebarPanel.chartBuilder,
      );

      await tester.tap(find.byKey(const ValueKey('ky-sheet-mini-validation')));
      await tester.pumpAndSettle();
      expect(
        container.read(activeSidebarPanelProvider),
        SheetSidebarPanel.dataValidation,
      );
    });

    testWidgets('applies text formatting from keyboard shortcuts', (
      tester,
    ) async {
      final container = ProviderContainer();
      final horizontal = ScrollController();
      final vertical = ScrollController();
      addTearDown(container.dispose);
      addTearDown(horizontal.dispose);
      addTearDown(vertical.dispose);

      container.read(selectedCellProvider.notifier).state = CellSelection(
        CellAddress(0, 0),
        CellAddress(0, 1),
      );
      final sheet = container.read(spreadsheetProvider.notifier);
      sheet.updateCellValue(CellAddress(0, 0), 'A');
      sheet.updateCellValue(CellAddress(0, 1), 'B');

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 640,
                height: 260,
                child: SpreadsheetGrid(
                  horizontalController: horizontal,
                  verticalController: vertical,
                  rows: 30,
                  cols: 12,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      Future<void> sendControlShortcut(LogicalKeyboardKey key) async {
        await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
        await tester.sendKeyEvent(key);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
        await tester.pumpAndSettle();
      }

      await sendControlShortcut(LogicalKeyboardKey.keyB);
      await sendControlShortcut(LogicalKeyboardKey.keyI);
      await sendControlShortcut(LogicalKeyboardKey.keyU);

      final cells = container.read(spreadsheetProvider);
      expect(cells[CellAddress(0, 0)]?.style.bold, isTrue);
      expect(cells[CellAddress(0, 1)]?.style.bold, isTrue);
      expect(cells[CellAddress(0, 0)]?.style.italic, isTrue);
      expect(cells[CellAddress(0, 1)]?.style.italic, isTrue);
      expect(cells[CellAddress(0, 0)]?.style.underline, isTrue);
      expect(cells[CellAddress(0, 1)]?.style.underline, isTrue);
    });

    testWidgets('hides the selection mini toolbar while editing', (
      tester,
    ) async {
      final container = ProviderContainer();
      final horizontal = ScrollController();
      final vertical = ScrollController();
      addTearDown(container.dispose);
      addTearDown(horizontal.dispose);
      addTearDown(vertical.dispose);

      container.read(selectedCellProvider.notifier).state = CellSelection(
        CellAddress(0, 0),
      );
      container.read(editingCellProvider.notifier).state = CellAddress(0, 0);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 640,
                height: 260,
                child: SpreadsheetGrid(
                  horizontalController: horizontal,
                  verticalController: vertical,
                  rows: 30,
                  cols: 12,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('ky-sheet-mini-toolbar')), findsNothing);
    });

    testWidgets('applies structural actions from header menus', (tester) async {
      final container = ProviderContainer();
      final horizontal = ScrollController();
      final vertical = ScrollController();
      addTearDown(container.dispose);
      addTearDown(horizontal.dispose);
      addTearDown(vertical.dispose);

      container
          .read(spreadsheetProvider.notifier)
          .updateCellValue(CellAddress(0, 0), 'Alpha');

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 640,
                height: 260,
                child: SpreadsheetGrid(
                  horizontalController: horizontal,
                  verticalController: vertical,
                  rows: 30,
                  cols: 12,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('ky-sheet-column-menu-0')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Insert column left'));
      await tester.pumpAndSettle();

      expect(container.read(spreadsheetProvider)[CellAddress(0, 0)], isNull);
      expect(
        container.read(spreadsheetProvider)[CellAddress(0, 1)]?.value,
        'Alpha',
      );
      expect(container.read(selectedCellProvider)?.label, 'A1:A30');

      await tester.tap(find.byKey(const ValueKey('ky-sheet-row-menu-0')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Hide row'));
      await tester.pumpAndSettle();

      expect(container.read(rowConfigProvider)[0]?.hidden, isTrue);
    });

    testWidgets('applies checklist filters from column menus', (tester) async {
      final container = ProviderContainer();
      final horizontal = ScrollController();
      final vertical = ScrollController();
      addTearDown(container.dispose);
      addTearDown(horizontal.dispose);
      addTearDown(vertical.dispose);

      final sheet = container.read(spreadsheetProvider.notifier);
      sheet.updateCellValue(CellAddress(0, 0), 'Paid');
      sheet.updateCellValue(CellAddress(1, 0), 'Open');
      sheet.updateCellValue(CellAddress(2, 0), 'Paid');

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 640,
                height: 260,
                child: SpreadsheetGrid(
                  horizontalController: horizontal,
                  verticalController: vertical,
                  rows: 30,
                  cols: 12,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('ky-sheet-column-menu-0')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sort & filter'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(
        find.byKey(const ValueKey('ky-sheet-column-filter-clear-values')),
      );
      await tester.tap(
        find.byKey(const ValueKey('ky-sheet-column-filter-clear-values')),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(
        find.byKey(const ValueKey('ky-sheet-column-filter-value-1')),
      );
      await tester.tap(
        find.byKey(const ValueKey('ky-sheet-column-filter-value-1')),
      );
      await tester.ensureVisible(find.text('Apply'));
      await tester.tap(find.text('Apply'));
      await tester.pumpAndSettle();

      final rule = container.read(sheetFilterRulesProvider)[0];
      expect(rule?.operator, SheetFilterOperator.oneOf);
      expect(rule?.valueList, ['Paid']);
      expect(
        SheetFilterEvaluator.visibleRows(
          rows: [0, 1, 2],
          filters: container.read(filterProvider),
          filterRules: container.read(sheetFilterRulesProvider),
          cells: container.read(spreadsheetProvider),
        ),
        [0, 2],
      );
      expect(container.read(selectedCellProvider)?.label, 'A1:A30');
    });

    testWidgets('sorts from the combined column filter panel', (tester) async {
      final container = ProviderContainer();
      final horizontal = ScrollController();
      final vertical = ScrollController();
      addTearDown(container.dispose);
      addTearDown(horizontal.dispose);
      addTearDown(vertical.dispose);

      final sheet = container.read(spreadsheetProvider.notifier);
      sheet.updateCellValue(CellAddress(0, 0), 'Beta');
      sheet.updateCellValue(CellAddress(1, 0), 'Alpha');
      sheet.updateCellValue(CellAddress(2, 0), 'Gamma');

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 640,
                height: 260,
                child: SpreadsheetGrid(
                  horizontalController: horizontal,
                  verticalController: vertical,
                  rows: 30,
                  cols: 12,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('ky-sheet-column-menu-0')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sort & filter'));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('ky-sheet-column-filter-sort-desc')),
      );
      await tester.pumpAndSettle();

      expect(container.read(sortColumnProvider), 0);
      expect(container.read(sortAscendingProvider), isFalse);
      expect(
        container.read(spreadsheetProvider)[CellAddress(0, 0)]?.value,
        'Gamma',
      );
      expect(
        container.read(spreadsheetProvider)[CellAddress(1, 0)]?.value,
        'Beta',
      );
      expect(
        container.read(spreadsheetProvider)[CellAddress(2, 0)]?.value,
        'Alpha',
      );

      await tester.tap(find.byKey(const ValueKey('ky-sheet-column-menu-0')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sort & filter'));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('ky-sheet-column-filter-clear-sort')),
      );
      await tester.pumpAndSettle();

      expect(container.read(sortColumnProvider), isNull);
      expect(container.read(sortAscendingProvider), isTrue);
      expect(
        container.read(spreadsheetProvider)[CellAddress(0, 0)]?.value,
        'Gamma',
      );
    });

    testWidgets('sorts from cell context menus by clicked column', (
      tester,
    ) async {
      final container = ProviderContainer();
      final horizontal = ScrollController();
      final vertical = ScrollController();
      addTearDown(container.dispose);
      addTearDown(horizontal.dispose);
      addTearDown(vertical.dispose);

      final sheet = container.read(spreadsheetProvider.notifier);
      sheet.updateCellValue(CellAddress(0, 0), 'Beta');
      sheet.updateCellValue(CellAddress(0, 1), '20');
      sheet.updateCellValue(CellAddress(1, 0), 'Gamma');
      sheet.updateCellValue(CellAddress(1, 1), '30');
      sheet.updateCellValue(CellAddress(2, 0), 'Alpha');
      sheet.updateCellValue(CellAddress(2, 1), '10');

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 640,
                height: 260,
                child: SpreadsheetGrid(
                  horizontalController: horizontal,
                  verticalController: vertical,
                  rows: 30,
                  cols: 12,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tapAt(
        tester.getCenter(find.text('20')),
        buttons: kSecondaryButton,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sort Z to A'));
      await tester.pumpAndSettle();

      expect(container.read(sortColumnProvider), 1);
      expect(container.read(sortAscendingProvider), isFalse);
      expect(
        container.read(spreadsheetProvider)[CellAddress(0, 0)]?.value,
        'Gamma',
      );
      expect(
        container.read(spreadsheetProvider)[CellAddress(0, 1)]?.value,
        '30',
      );
      expect(
        container.read(spreadsheetProvider)[CellAddress(1, 0)]?.value,
        'Beta',
      );
      expect(
        container.read(spreadsheetProvider)[CellAddress(1, 1)]?.value,
        '20',
      );
      expect(
        container.read(spreadsheetProvider)[CellAddress(2, 0)]?.value,
        'Alpha',
      );
      expect(
        container.read(spreadsheetProvider)[CellAddress(2, 1)]?.value,
        '10',
      );

      await tester.tapAt(
        tester.getCenter(find.text('30')),
        buttons: kSecondaryButton,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sort A to Z'));
      await tester.pumpAndSettle();

      expect(container.read(sortColumnProvider), 1);
      expect(container.read(sortAscendingProvider), isTrue);
      expect(
        container.read(spreadsheetProvider)[CellAddress(0, 0)]?.value,
        'Alpha',
      );
      expect(
        container.read(spreadsheetProvider)[CellAddress(0, 1)]?.value,
        '10',
      );
      expect(
        container.read(spreadsheetProvider)[CellAddress(1, 0)]?.value,
        'Beta',
      );
      expect(
        container.read(spreadsheetProvider)[CellAddress(1, 1)]?.value,
        '20',
      );
      expect(
        container.read(spreadsheetProvider)[CellAddress(2, 0)]?.value,
        'Gamma',
      );
      expect(
        container.read(spreadsheetProvider)[CellAddress(2, 1)]?.value,
        '30',
      );
    });

    testWidgets('applies quick filters from cell context menus', (
      tester,
    ) async {
      final container = ProviderContainer();
      final horizontal = ScrollController();
      final vertical = ScrollController();
      addTearDown(container.dispose);
      addTearDown(horizontal.dispose);
      addTearDown(vertical.dispose);

      final sheet = container.read(spreadsheetProvider.notifier);
      sheet.updateCellValue(CellAddress(0, 0), 'Paid');
      sheet.updateCellValue(CellAddress(1, 0), 'Open');
      sheet.updateCellValue(CellAddress(2, 0), 'Paid');

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 640,
                height: 260,
                child: SpreadsheetGrid(
                  horizontalController: horizontal,
                  verticalController: vertical,
                  rows: 30,
                  cols: 12,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tapAt(
        tester.getCenter(find.text('Open')),
        buttons: kSecondaryButton,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Keep Only This Value'));
      await tester.pumpAndSettle();

      var rule = container.read(sheetFilterRulesProvider)[0];
      expect(rule?.operator, SheetFilterOperator.equals);
      expect(rule?.value, 'Open');
      expect(
        SheetFilterEvaluator.visibleRows(
          rows: [0, 1, 2],
          filters: container.read(filterProvider),
          filterRules: container.read(sheetFilterRulesProvider),
          cells: container.read(spreadsheetProvider),
        ),
        [1],
      );

      await tester.tapAt(
        tester.getCenter(find.text('Open')),
        buttons: kSecondaryButton,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Exclude This Value'));
      await tester.pumpAndSettle();

      rule = container.read(sheetFilterRulesProvider)[0];
      expect(rule?.operator, SheetFilterOperator.notEquals);
      expect(rule?.value, 'Open');
      expect(
        SheetFilterEvaluator.visibleRows(
          rows: [0, 1, 2],
          filters: container.read(filterProvider),
          filterRules: container.read(sheetFilterRulesProvider),
          cells: container.read(spreadsheetProvider),
        ),
        [0, 2],
      );

      await tester.tapAt(
        tester.getCenter(find.text('Paid').first),
        buttons: kSecondaryButton,
      );
      await tester.pumpAndSettle();
      expect(find.text('Clear Column Filter'), findsOneWidget);
      expect(find.text('Does not equal "Open"'), findsOneWidget);
      await tester.tap(find.text('Clear Column Filter'));
      await tester.pumpAndSettle();

      expect(container.read(filterProvider), isEmpty);
      expect(container.read(sheetFilterRulesProvider), isEmpty);
      expect(
        SheetFilterEvaluator.visibleRows(
          rows: [0, 1, 2],
          filters: container.read(filterProvider),
          filterRules: container.read(sheetFilterRulesProvider),
          cells: container.read(spreadsheetProvider),
        ),
        [0, 1, 2],
      );
    });

    testWidgets('opens sort filter panel for the clicked context column', (
      tester,
    ) async {
      final container = ProviderContainer();
      final horizontal = ScrollController();
      final vertical = ScrollController();
      addTearDown(container.dispose);
      addTearDown(horizontal.dispose);
      addTearDown(vertical.dispose);

      final sheet = container.read(spreadsheetProvider.notifier);
      sheet.updateCellValue(CellAddress(0, 0), 'Region');
      sheet.updateCellValue(CellAddress(0, 1), 'Status');
      sheet.updateCellValue(CellAddress(1, 0), 'EMEA');
      sheet.updateCellValue(CellAddress(1, 1), 'Open');

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 640,
                height: 260,
                child: SpreadsheetGrid(
                  horizontalController: horizontal,
                  verticalController: vertical,
                  rows: 30,
                  cols: 12,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tapAt(
        tester.getCenter(find.text('Open')),
        buttons: kSecondaryButton,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Open Sort & Filter'));
      await tester.pumpAndSettle();

      expect(
        container.read(activeSidebarPanelProvider),
        SheetSidebarPanel.sortFilter,
      );
      expect(container.read(selectedCellProvider)?.label, 'B1:B30');
    });

    testWidgets('opens cell side panels from context menus', (tester) async {
      final container = ProviderContainer();
      final horizontal = ScrollController();
      final vertical = ScrollController();
      addTearDown(container.dispose);
      addTearDown(horizontal.dispose);
      addTearDown(vertical.dispose);

      final sheet = container.read(spreadsheetProvider.notifier);
      sheet.updateCellValue(CellAddress(0, 0), 'Owner');

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 640,
                height: 260,
                child: SpreadsheetGrid(
                  horizontalController: horizontal,
                  verticalController: vertical,
                  rows: 30,
                  cols: 12,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      Future<void> openCellMenuAndTap(String label) async {
        await tester.tapAt(
          tester.getCenter(find.text('Owner')),
          buttons: kSecondaryButton,
        );
        await tester.pumpAndSettle();
        final item = find.text(label);
        await tester.ensureVisible(item);
        await tester.pumpAndSettle();
        await tester.tap(item);
        await tester.pumpAndSettle();
      }

      await openCellMenuAndTap('Inspect Cell');

      expect(
        container.read(activeSidebarPanelProvider),
        SheetSidebarPanel.cellInspector,
      );
      expect(container.read(selectedCellProvider)?.label, 'A1');

      container.read(activeSidebarPanelProvider.notifier).state = null;
      container.read(findReplaceReplacementProvider.notifier).state = 'stale';

      await openCellMenuAndTap('Find This Value');

      expect(
        container.read(activeSidebarPanelProvider),
        SheetSidebarPanel.findReplace,
      );
      expect(container.read(findReplaceQueryProvider), 'Owner');
      expect(container.read(findReplaceReplacementProvider), isEmpty);
      expect(
        container.read(findReplaceScopeProvider),
        SheetSearchScope.cellValues,
      );
      expect(container.read(findReplaceCurrentIndexProvider), 0);

      container.read(activeSidebarPanelProvider.notifier).state = null;

      await openCellMenuAndTap('Data Validation');

      expect(
        container.read(activeSidebarPanelProvider),
        SheetSidebarPanel.dataValidation,
      );
      expect(container.read(selectedCellProvider)?.label, 'A1');

      await openCellMenuAndTap('Chart Builder');

      expect(
        container.read(activeSidebarPanelProvider),
        SheetSidebarPanel.chartBuilder,
      );
      expect(container.read(selectedCellProvider)?.label, 'A1');

      await openCellMenuAndTap('Conditional Formatting');

      expect(
        container.read(activeSidebarPanelProvider),
        SheetSidebarPanel.conditionalFormat,
      );
      expect(container.read(selectedCellProvider)?.label, 'A1');
    });

    testWidgets('freezes and unfreezes panes from cell context menus', (
      tester,
    ) async {
      final container = ProviderContainer();
      final horizontal = ScrollController();
      final vertical = ScrollController();
      addTearDown(container.dispose);
      addTearDown(horizontal.dispose);
      addTearDown(vertical.dispose);

      final sheet = container.read(spreadsheetProvider.notifier);
      sheet.updateCellValue(CellAddress(2, 2), 'Anchor');

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 640,
                height: 260,
                child: SpreadsheetGrid(
                  horizontalController: horizontal,
                  verticalController: vertical,
                  rows: 30,
                  cols: 12,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tapAt(
        tester.getCenter(find.text('Anchor')),
        buttons: kSecondaryButton,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Freeze Panes Here'));
      await tester.pumpAndSettle();

      expect(container.read(freezePanesProvider), CellAddress(2, 2));
      expect(container.read(selectedCellProvider)?.label, 'C3');

      await tester.tapAt(
        tester.getCenter(find.text('Anchor')),
        buttons: kSecondaryButton,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Unfreeze Panes'));
      await tester.pumpAndSettle();

      expect(container.read(freezePanesProvider), isNull);
    });

    testWidgets('unhides adjacent hidden rows and columns from header menus', (
      tester,
    ) async {
      final container = ProviderContainer();
      final horizontal = ScrollController();
      final vertical = ScrollController();
      addTearDown(container.dispose);
      addTearDown(horizontal.dispose);
      addTearDown(vertical.dispose);

      container.read(rowConfigProvider.notifier).state = {
        1: RowConfig(index: 1, hidden: true),
      };
      container.read(columnConfigProvider.notifier).state = {
        1: ColumnConfig(index: 1, hidden: true),
      };

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 640,
                height: 260,
                child: SpreadsheetGrid(
                  horizontalController: horizontal,
                  verticalController: vertical,
                  rows: 30,
                  cols: 12,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('ky-sheet-column-menu-0')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Unhide adjacent columns'));
      await tester.pumpAndSettle();

      expect(container.read(columnConfigProvider)[1]?.hidden, isFalse);

      await tester.tap(find.byKey(const ValueKey('ky-sheet-row-menu-0')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Unhide adjacent rows'));
      await tester.pumpAndSettle();

      expect(container.read(rowConfigProvider)[1]?.hidden, isFalse);
    });

    testWidgets('keeps frozen pane cells visible while scrolled', (
      tester,
    ) async {
      final container = ProviderContainer();
      final horizontal = ScrollController();
      final vertical = ScrollController();
      addTearDown(container.dispose);
      addTearDown(horizontal.dispose);
      addTearDown(vertical.dispose);

      container
          .read(spreadsheetProvider.notifier)
          .updateCell(CellAddress(0, 0), CellData(value: 'Pinned'));
      container
          .read(spreadsheetProvider.notifier)
          .updateCell(CellAddress(10, 6), CellData(value: 'Scrolled'));
      container.read(freezePanesProvider.notifier).state = CellAddress(1, 1);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 260,
                height: 180,
                child: SpreadsheetGrid(
                  horizontalController: horizontal,
                  verticalController: vertical,
                  rows: 30,
                  cols: 12,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Pinned'), findsOneWidget);

      horizontal.jumpTo(horizontal.position.maxScrollExtent);
      vertical.jumpTo(vertical.position.maxScrollExtent);
      await tester.pumpAndSettle();

      expect(find.text('Pinned'), findsOneWidget);
    });
  });

  group('SheetCellContextMenu', () {
    test('exposes common spreadsheet actions', () {
      final defaultItems = SheetCellContextMenu.items()
          .whereType<PopupMenuItem<SheetCellContextAction>>()
          .toList();
      final values = defaultItems.map((item) => item.value).toSet();
      final defaultClearFilterItem = defaultItems.firstWhere(
        (item) => item.value == SheetCellContextAction.clearColumnFilter,
      );
      final defaultFreezePanesItem = defaultItems.firstWhere(
        (item) => item.value == SheetCellContextAction.freezePanesHere,
      );
      final defaultUnfreezePanesItem = defaultItems.firstWhere(
        (item) => item.value == SheetCellContextAction.unfreezePanes,
      );
      final defaultFindThisValueItem = defaultItems.firstWhere(
        (item) => item.value == SheetCellContextAction.findThisValue,
      );
      final searchableFindThisValueItem =
          SheetCellContextMenu.items(
            state: const SheetCellContextMenuState(canFindThisValue: true),
          ).whereType<PopupMenuItem<SheetCellContextAction>>().firstWhere(
            (item) => item.value == SheetCellContextAction.findThisValue,
          );
      final filteredClearFilterItem =
          SheetCellContextMenu.items(
            state: const SheetCellContextMenuState(
              hasColumnFilter: true,
              columnFilterDetail: 'Equals "Open"',
            ),
          ).whereType<PopupMenuItem<SheetCellContextAction>>().firstWhere(
            (item) => item.value == SheetCellContextAction.clearColumnFilter,
          );
      final activeFreezeItem =
          SheetCellContextMenu.items(
            state: const SheetCellContextMenuState(
              canFreezePanesHere: false,
              hasFreezePane: true,
            ),
          ).whereType<PopupMenuItem<SheetCellContextAction>>().firstWhere(
            (item) => item.value == SheetCellContextAction.freezePanesHere,
          );
      final activeUnfreezeItem =
          SheetCellContextMenu.items(
            state: const SheetCellContextMenuState(
              canFreezePanesHere: false,
              hasFreezePane: true,
            ),
          ).whereType<PopupMenuItem<SheetCellContextAction>>().firstWhere(
            (item) => item.value == SheetCellContextAction.unfreezePanes,
          );
      final rangeState = SheetCellContextMenuState.forCell(
        clickedCell: CellAddress(1, 1),
        hasColumnFilter: true,
        columnFilterDetail: 'Equals "Open"',
        hasFreezePane: true,
        canFindThisValue: true,
      );

      expect(values, contains(SheetCellContextAction.edit));
      expect(values, contains(SheetCellContextAction.copy));
      expect(values, contains(SheetCellContextAction.paste));
      expect(values, contains(SheetCellContextAction.clearContents));
      expect(values, contains(SheetCellContextAction.insertRowAbove));
      expect(values, contains(SheetCellContextAction.insertColumnRight));
      expect(values, contains(SheetCellContextAction.sortAscending));
      expect(values, contains(SheetCellContextAction.sortDescending));
      expect(values, contains(SheetCellContextAction.keepOnlyValue));
      expect(values, contains(SheetCellContextAction.excludeValue));
      expect(values, contains(SheetCellContextAction.clearColumnFilter));
      expect(values, contains(SheetCellContextAction.findThisValue));
      expect(values, contains(SheetCellContextAction.openSortFilter));
      expect(values, contains(SheetCellContextAction.openInspector));
      expect(values, contains(SheetCellContextAction.openDataValidation));
      expect(values, contains(SheetCellContextAction.openChartBuilder));
      expect(values, contains(SheetCellContextAction.openConditionalFormat));
      expect(values, contains(SheetCellContextAction.freezePanesHere));
      expect(values, contains(SheetCellContextAction.unfreezePanes));
      expect(defaultClearFilterItem.enabled, isFalse);
      expect(filteredClearFilterItem.enabled, isTrue);
      expect(defaultFindThisValueItem.enabled, isFalse);
      expect(searchableFindThisValueItem.enabled, isTrue);
      expect(defaultFreezePanesItem.enabled, isTrue);
      expect(defaultUnfreezePanesItem.enabled, isFalse);
      expect(activeFreezeItem.enabled, isFalse);
      expect(activeUnfreezeItem.enabled, isTrue);
      expect(rangeState.canFreezePanesHere, isTrue);
      expect(rangeState.hasColumnFilter, isTrue);
      expect(rangeState.canFindThisValue, isTrue);
    });

    testWidgets('renders shortcut hints for high-frequency commands', (
      tester,
    ) async {
      final items =
          SheetCellContextMenu.items(
                state: const SheetCellContextMenuState(canFindThisValue: true),
              )
              .whereType<PopupMenuItem<SheetCellContextAction>>()
              .map((item) => item.child)
              .whereType<Widget>()
              .toList();

      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: SingleChildScrollView(child: Column(children: items)),
          ),
        ),
      );

      expect(find.text('F2'), findsOneWidget);
      expect(find.text('Ctrl+F'), findsOneWidget);
      expect(find.text('Ctrl+C'), findsOneWidget);
      expect(find.text('Ctrl+X'), findsOneWidget);
      expect(find.text('Ctrl+V'), findsOneWidget);
      expect(find.text('Del'), findsOneWidget);
    });

    testWidgets('renders section labels and destructive delete actions', (
      tester,
    ) async {
      final items = SheetCellContextMenu.items()
          .whereType<PopupMenuItem<SheetCellContextAction>>()
          .map((item) => item.child)
          .whereType<Widget>()
          .toList();

      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: SingleChildScrollView(child: Column(children: items)),
          ),
        ),
      );

      expect(find.text('CELL'), findsOneWidget);
      expect(find.text('SORT & FIND'), findsOneWidget);
      expect(find.text('FILTER'), findsOneWidget);
      expect(find.text('ANALYZE'), findsOneWidget);
      expect(find.text('DELETE'), findsOneWidget);
      expect(find.text('No frozen panes'), findsOneWidget);
      expect(find.text('Empty cell'), findsOneWidget);

      final deleteRowText = tester.widget<Text>(find.text('Delete row'));
      final deleteColumnText = tester.widget<Text>(find.text('Delete column'));

      expect(deleteRowText.style?.color, KySheetColors.validationError);
      expect(deleteColumnText.style?.color, KySheetColors.validationError);
    });
  });

  group('SortFilterPanel', () {
    testWidgets('applies a rich comparison filter from the sidebar panel', (
      tester,
    ) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final sheet = container.read(spreadsheetProvider.notifier);
      sheet.updateCellValue(CellAddress(0, 0), '10');
      sheet.updateCellValue(CellAddress(1, 0), '5');
      sheet.updateCellValue(CellAddress(2, 0), '8');
      container.read(selectedCellProvider.notifier).state = CellSelection(
        CellAddress(0, 0),
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: Scaffold(body: SortFilterPanel())),
        ),
      );

      expect(
        find.byKey(
          const ValueKey('ky-sheet-sidebar-panel-surface-Sort & Filter'),
        ),
        findsOneWidget,
      );
      expect(find.text('Sort ranges and filter rows'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('ky-sheet-filter-operator')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Greater than').last);
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('ky-sheet-filter-value')),
        '7',
      );
      await tester.tap(find.byKey(const ValueKey('ky-sheet-filter-apply')));
      await tester.pumpAndSettle();

      final rule = container.read(sheetFilterRulesProvider)[0];
      expect(rule?.operator, SheetFilterOperator.greaterThan);
      expect(rule?.value, '7');
      expect(container.read(filterProvider), {0: '7'});
      expect(find.text('2 of 3 rows visible'), findsOneWidget);
    });
  });

  group('SheetViewPanel', () {
    testWidgets('updates freeze panes and zoom controls', (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(selectedCellProvider.notifier).state = CellSelection(
        CellAddress(2, 2),
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: Scaffold(body: SheetViewPanel())),
        ),
      );

      await tester.tap(
        find.byKey(const ValueKey('ky-sheet-view-freeze-first-row')),
      );
      await tester.pumpAndSettle();
      expect(container.read(freezePanesProvider), CellAddress(1, 0));
      expect(find.text('First row'), findsWidgets);

      await tester.tap(
        find.byKey(const ValueKey('ky-sheet-view-freeze-selection')),
      );
      await tester.pumpAndSettle();
      expect(container.read(freezePanesProvider), CellAddress(2, 2));
      expect(find.text('2 rows, 2 columns'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('ky-sheet-view-unfreeze')));
      await tester.pumpAndSettle();
      expect(container.read(freezePanesProvider), isNull);

      await tester.tap(find.byTooltip('Zoom In'));
      await tester.pumpAndSettle();
      expect(container.read(zoomLevelProvider), greaterThan(1));

      await tester.tap(find.byKey(const ValueKey('ky-sheet-view-reset-zoom')));
      await tester.pumpAndSettle();
      expect(container.read(zoomLevelProvider), 1);
    });
  });

  group('SheetHistoryPanel', () {
    testWidgets('shows history, navigates to changes, and runs actions', (
      tester,
    ) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final sheet = container.read(spreadsheetProvider.notifier);
      sheet.updateCellValue(CellAddress(0, 0), 'Alpha');
      sheet.updateCellValue(CellAddress(0, 1), 'Beta');
      sheet.undo();

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: Scaffold(body: SheetHistoryPanel())),
        ),
      );

      expect(
        find.byKey(const ValueKey('ky-sheet-sidebar-panel-surface-History')),
        findsOneWidget,
      );
      expect(find.text('History'), findsOneWidget);
      expect(find.text('Undo and redo timeline'), findsOneWidget);
      expect(find.text('Undo Timeline'), findsOneWidget);
      expect(find.text('Redo Timeline'), findsOneWidget);
      expect(find.text('Edit A1'), findsOneWidget);
      expect(find.text('Edit B1'), findsOneWidget);

      await tester.tap(find.text('Edit A1'));
      await tester.pumpAndSettle();
      expect(container.read(selectedCellProvider)?.label, 'A1');

      await tester.tap(find.byKey(const ValueKey('ky-sheet-history-redo')));
      await tester.pumpAndSettle();
      expect(
        container.read(spreadsheetProvider)[CellAddress(0, 1)]?.value,
        'Beta',
      );
      expect(container.read(redoStackProvider), isEmpty);

      await tester.tap(find.byKey(const ValueKey('ky-sheet-history-undo')));
      await tester.pumpAndSettle();
      expect(container.read(spreadsheetProvider)[CellAddress(0, 1)], isNull);
      expect(container.read(redoStackProvider), hasLength(1));

      await tester.tap(find.byKey(const ValueKey('ky-sheet-history-clear')));
      await tester.pumpAndSettle();
      expect(container.read(undoStackProvider), isEmpty);
      expect(container.read(redoStackProvider), isEmpty);
      expect(find.text('No history yet'), findsOneWidget);
    });
  });

  group('SheetEngineOperationPanel', () {
    testWidgets('shows, copies, and clears Waraq operation logs', (
      tester,
    ) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      String? clipboardText;
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
        if (call.method == 'Clipboard.setData') {
          final data = Map<String, Object?>.from(call.arguments as Map);
          clipboardText = data['text'] as String?;
        }
        return null;
      });
      addTearDown(
        () => messenger.setMockMethodCallHandler(SystemChannels.platform, null),
      );

      final sheet = container.read(spreadsheetProvider.notifier);
      sheet.updateCellValue(CellAddress(0, 0), '10');
      sheet.updateCellStyle(CellAddress(0, 0), const CellStyle(bold: true));

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(body: SheetEngineOperationPanel()),
          ),
        ),
      );

      expect(
        find.byKey(
          const ValueKey('ky-sheet-sidebar-panel-surface-Waraq Operations'),
        ),
        findsOneWidget,
      );
      expect(find.text('Waraq Operations'), findsOneWidget);
      expect(find.text('Sheet engine sync log'), findsOneWidget);
      expect(find.text('Document'), findsOneWidget);
      expect(find.text('sheet-1'), findsOneWidget);
      expect(find.text('SetCell'), findsOneWidget);
      expect(find.text('SetCellFormat'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('ky-sheet-operations-copy')));
      await tester.pumpAndSettle();

      expect(clipboardText, contains('"schema_version": 1'));
      expect(clipboardText, contains('"document_id": "sheet-1"'));
      expect(clipboardText, contains('"raw_content": "10"'));

      await tester.tap(find.byKey(const ValueKey('ky-sheet-operations-clear')));
      await tester.pumpAndSettle();

      expect(
        container.read(sheetEngineOperationLogProvider).operations,
        isEmpty,
      );
      expect(find.text('No Waraq operations yet'), findsOneWidget);
    });

    testWidgets('applies pasted Waraq operation JSON from the dialog', (
      tester,
    ) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(body: SheetEngineOperationPanel()),
          ),
        ),
      );

      await tester.tap(find.byKey(const ValueKey('ky-sheet-operations-apply')));
      await tester.pumpAndSettle();

      final operationLog = SheetEngineEditCodec.operationLog([
        SheetEngineEditCodec.operation(
          operationId: 'remote-op-1',
          documentId: 'sheet-1',
          actorId: 'remote',
          sequence: 1,
          timestampMs: 100,
          edit: SheetEngineEditCodec.setCellRaw(CellAddress(0, 0), '42'),
        ),
      ]);

      await tester.enterText(
        find.byKey(const ValueKey('ky-sheet-operations-import-input')),
        jsonEncode(operationLog),
      );
      await tester.pump();

      expect(
        find.descendant(
          of: find.byKey(const ValueKey('ky-sheet-operations-import-kind')),
          matching: find.text('Operation log'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('ky-sheet-operations-import-matching')),
          matching: find.text('1'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('ky-sheet-operations-import-skipped')),
          matching: find.text('0'),
        ),
        findsOneWidget,
      );
      expect(
        tester
            .widget<Text>(
              find.byKey(const ValueKey('ky-sheet-operations-import-targets')),
            )
            .data,
        'sheet-1',
      );

      await tester.tap(
        find.byKey(const ValueKey('ky-sheet-operations-import-apply')),
      );
      await tester.pumpAndSettle();

      expect(
        container.read(spreadsheetProvider)[CellAddress(0, 0)]?.value,
        '42',
      );
      expect(
        container.read(sheetEngineOperationLogProvider).operations,
        isEmpty,
      );
      expect(container.read(undoStackProvider), isEmpty);
      expect(find.text('Applied 1 Waraq edit'), findsOneWidget);
    });

    testWidgets('reports skipped Waraq operations from other documents', (
      tester,
    ) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(body: SheetEngineOperationPanel()),
          ),
        ),
      );

      await tester.tap(find.byKey(const ValueKey('ky-sheet-operations-apply')));
      await tester.pumpAndSettle();

      final operationLog = SheetEngineEditCodec.operationLog([
        SheetEngineEditCodec.operation(
          operationId: 'remote-op-1',
          documentId: 'other-sheet',
          actorId: 'remote',
          sequence: 1,
          timestampMs: 100,
          edit: SheetEngineEditCodec.setCellRaw(CellAddress(0, 0), '42'),
        ),
      ]);

      await tester.enterText(
        find.byKey(const ValueKey('ky-sheet-operations-import-input')),
        jsonEncode(operationLog),
      );
      await tester.pump();

      expect(
        find.descendant(
          of: find.byKey(const ValueKey('ky-sheet-operations-import-matching')),
          matching: find.text('0'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('ky-sheet-operations-import-skipped')),
          matching: find.text('1'),
        ),
        findsOneWidget,
      );
      expect(
        tester
            .widget<Text>(
              find.byKey(const ValueKey('ky-sheet-operations-import-targets')),
            )
            .data,
        'other-sheet',
      );

      await tester.tap(
        find.byKey(const ValueKey('ky-sheet-operations-import-apply')),
      );
      await tester.pumpAndSettle();

      expect(container.read(spreadsheetProvider)[CellAddress(0, 0)], isNull);
      expect(
        find.text('Applied 0 Waraq edits, skipped 1 operation'),
        findsOneWidget,
      );
    });
  });

  group('SheetReviewPanel', () {
    testWidgets('filters, navigates, and clears review metadata', (
      tester,
    ) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final sheet = container.read(spreadsheetProvider.notifier);
      sheet.updateCell(
        CellAddress(0, 0),
        CellData(value: 'Owner', comment: 'Needs owner'),
      );
      sheet.updateCell(
        CellAddress(0, 1),
        CellData(value: 'Docs', hyperlink: 'https://example.com/docs'),
      );
      sheet.updateCell(
        CellAddress(0, 2),
        CellData(
          value: 'Budget',
          comment: 'Check amount',
          hyperlink: 'https://example.com/budget',
        ),
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: Scaffold(body: SheetReviewPanel())),
        ),
      );

      expect(
        find.byKey(const ValueKey('ky-sheet-sidebar-panel-surface-Review')),
        findsOneWidget,
      );
      expect(find.text('Review'), findsOneWidget);
      expect(find.text('Comments and links'), findsOneWidget);
      expect(find.text('Needs owner'), findsOneWidget);
      expect(find.text('https://example.com/docs'), findsOneWidget);

      await tester.tap(find.text('Needs owner'));
      await tester.pumpAndSettle();
      expect(container.read(selectedCellProvider)?.label, 'A1');

      await tester.tap(find.byKey(const ValueKey('ky-sheet-review-filter')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Comments').last);
      await tester.pumpAndSettle();

      expect(find.text('Needs owner'), findsOneWidget);
      expect(find.text('Check amount'), findsOneWidget);
      expect(find.text('https://example.com/docs'), findsNothing);

      await tester.tap(find.byTooltip('Clear Comment').first);
      await tester.pumpAndSettle();

      expect(
        container.read(spreadsheetProvider)[CellAddress(0, 0)]?.comment,
        isNull,
      );
      expect(find.text('Needs owner'), findsNothing);

      await tester.tap(find.byTooltip('Open Inspector').first);
      await tester.pumpAndSettle();

      expect(
        container.read(activeSidebarPanelProvider),
        SheetSidebarPanel.cellInspector,
      );
    });
  });

  group('SheetDataCleanupPanel', () {
    testWidgets('applies selected cleanup operation to the selected range', (
      tester,
    ) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final sheet = container.read(spreadsheetProvider.notifier);
      sheet.updateCell(CellAddress(0, 0), CellData(value: '  alpha  '));
      sheet.updateCell(CellAddress(0, 1), CellData(value: 'Beta'));
      sheet.updateCell(CellAddress(1, 0), CellData(value: '  gamma  '));
      container.read(selectedCellProvider.notifier).state = CellSelection(
        CellAddress(0, 0),
        CellAddress(1, 1),
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(body: SheetDataCleanupPanel()),
          ),
        ),
      );

      expect(
        find.byKey(
          const ValueKey('ky-sheet-sidebar-panel-surface-Data Cleanup'),
        ),
        findsOneWidget,
      );
      expect(find.text('Data Cleanup'), findsOneWidget);
      expect(find.text('Clean selected data'), findsOneWidget);
      expect(find.text('alpha'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('ky-sheet-cleanup-apply')));
      await tester.pumpAndSettle();

      expect(
        container.read(spreadsheetProvider)[CellAddress(0, 0)]?.value,
        'alpha',
      );
      expect(
        container.read(spreadsheetProvider)[CellAddress(1, 0)]?.value,
        'gamma',
      );
      expect(
        container.read(undoStackProvider).last.description,
        'Trim Whitespace',
      );

      await tester.tap(
        find.byKey(const ValueKey('ky-sheet-cleanup-operation')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Uppercase').last);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('ky-sheet-cleanup-apply')));
      await tester.pumpAndSettle();

      expect(
        container.read(spreadsheetProvider)[CellAddress(0, 0)]?.value,
        'ALPHA',
      );
      expect(
        container.read(spreadsheetProvider)[CellAddress(0, 1)]?.value,
        'BETA',
      );
    });
  });

  group('SheetFunctionLibraryPanel', () {
    testWidgets('searches, filters, and inserts a function', (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(selectedCellProvider.notifier).state = CellSelection(
        CellAddress(2, 2),
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(body: SheetFunctionLibraryPanel()),
          ),
        ),
      );

      expect(find.text('Function Library'), findsOneWidget);
      expect(find.text('Browse formulas'), findsOneWidget);
      expect(
        find.byKey(
          const ValueKey('ky-sheet-sidebar-panel-surface-Function Library'),
        ),
        findsOneWidget,
      );

      await tester.enterText(
        find.byKey(const ValueKey('ky-sheet-function-search')),
        'avg',
      );
      await tester.pumpAndSettle();

      expect(find.text('AVERAGE'), findsOneWidget);
      await tester.tap(
        find.byKey(const ValueKey('ky-sheet-function-insert-AVERAGE')),
      );
      await tester.pumpAndSettle();

      expect(
        container.read(spreadsheetProvider)[CellAddress(2, 2)]?.formula,
        '=AVERAGE()',
      );
    });

    testWidgets('filters functions by category', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: Scaffold(body: SheetFunctionLibraryPanel())),
        ),
      );

      await tester.tap(
        find.byKey(const ValueKey('ky-sheet-function-category')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Text').last);
      await tester.pumpAndSettle();

      expect(find.text('CONCAT'), findsOneWidget);
      expect(find.text('LOWER'), findsOneWidget);
      expect(find.text('VLOOKUP'), findsNothing);
    });
  });

  group('ToolbarWidget', () {
    test('ribbon tab catalog exposes spreadsheet sections', () {
      expect(SheetRibbonTabCatalog.all.map((spec) => spec.tab), [
        SheetRibbonTab.home,
        SheetRibbonTab.insert,
        SheetRibbonTab.data,
        SheetRibbonTab.formulas,
        SheetRibbonTab.view,
        SheetRibbonTab.review,
      ]);
    });

    test('ribbon panel launcher catalog groups sidebar destinations', () {
      expect(
        SheetRibbonPanelLauncherCatalog.formulas.map((action) => action.panel),
        [
          SheetSidebarPanel.functionLibrary,
          SheetSidebarPanel.formulaAudit,
          SheetSidebarPanel.formulaHealth,
        ],
      );
      expect(
        SheetRibbonPanelLauncherCatalog.data.map((action) => action.panel),
        containsAll([
          SheetSidebarPanel.dataInsights,
          SheetSidebarPanel.dataCleanup,
          SheetSidebarPanel.sortFilter,
          SheetSidebarPanel.dataValidation,
        ]),
      );
      expect(
        SheetRibbonPanelLauncherCatalog.review.map((action) => action.panel),
        [
          SheetSidebarPanel.review,
          SheetSidebarPanel.sheetEngineOperations,
          SheetSidebarPanel.history,
        ],
      );
    });

    testWidgets('ribbon panel launcher group opens selected panels', (
      tester,
    ) async {
      SheetSidebarPanel? openedPanel;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SheetRibbonPanelLauncherGroup(
              actions: SheetRibbonPanelLauncherCatalog.review,
              onOpenPanel: (panel) => openedPanel = panel,
            ),
          ),
        ),
      );

      await tester.tap(find.byTooltip('Waraq Operations'));
      await tester.pump();

      expect(openedPanel, SheetSidebarPanel.sheetEngineOperations);
    });

    testWidgets('ribbon menu button runs enabled actions', (tester) async {
      var actionCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SheetRibbonMenuButton(
              icon: Icons.more_horiz,
              tooltip: 'More Actions',
              actions: [
                const SheetRibbonMenuAction(label: 'Unavailable'),
                SheetRibbonMenuAction(
                  label: 'Available',
                  onSelected: () => actionCount++,
                ),
              ],
            ),
          ),
        ),
      );

      await tester.tap(find.byTooltip('More Actions').last);
      await tester.pumpAndSettle();

      expect(find.text('Unavailable'), findsOneWidget);
      expect(find.text('Available'), findsOneWidget);

      await tester.tap(find.text('Available'));
      await tester.pumpAndSettle();

      expect(actionCount, 1);
    });

    testWidgets('ribbon tab groups composes insert tab content', (
      tester,
    ) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      SheetSidebarPanel? openedPanel;

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: Row(
                children: SheetRibbonTabGroups.build(
                  tab: SheetRibbonTab.insert,
                  controller: container.read(toolbarControllerProvider),
                  selection: CellSelection(CellAddress(0, 0)),
                  zoom: container.read(zoomLevelProvider),
                  onOpenPanel: (panel) => openedPanel = panel,
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Rows & Columns'), findsOneWidget);
      expect(find.text('Insert'), findsOneWidget);

      await tester.tap(find.byTooltip('Chart Builder'));
      await tester.pump();

      expect(openedPanel, SheetSidebarPanel.chartBuilder);
    });

    testWidgets('home ribbon groups apply formatting to the selection', (
      tester,
    ) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      tester.view.physicalSize = const Size(1400, 600);
      tester.view.devicePixelRatio = 1;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      final selection = CellSelection(CellAddress(0, 0));
      final controller = container.read(toolbarControllerProvider);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SheetRibbonHomeGroups(
                  controller: controller,
                  selection: selection,
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byTooltip('Bold (Ctrl+B)'));
      await tester.pumpAndSettle();

      expect(find.byTooltip('Fill Yellow'), findsOneWidget);
      expect(find.byTooltip('Text Red'), findsOneWidget);

      expect(
        container.read(spreadsheetProvider)[CellAddress(0, 0)]?.style.bold,
        isTrue,
      );

      await tester.tap(find.byTooltip('Number Format').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Currency').last);
      await tester.pumpAndSettle();

      expect(
        container
            .read(spreadsheetProvider)[CellAddress(0, 0)]
            ?.style
            .numberFormat,
        SheetNumberFormatId.currency,
      );
    });

    testWidgets('structure ribbon group applies row and column actions', (
      tester,
    ) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final selection = CellSelection(CellAddress(0, 0));
      final controller = container.read(toolbarControllerProvider);
      container
          .read(spreadsheetProvider.notifier)
          .updateCellValue(CellAddress(0, 0), 'Alpha');

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: SheetRibbonStructureGroup(
                controller: controller,
                selection: selection,
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byTooltip('Insert Columns').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Insert Column Left'));
      await tester.pumpAndSettle();

      expect(container.read(spreadsheetProvider)[CellAddress(0, 0)], isNull);
      expect(
        container.read(spreadsheetProvider)[CellAddress(0, 1)]?.value,
        'Alpha',
      );
    });

    testWidgets('data ribbon group applies data actions from ribbon menus', (
      tester,
    ) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      SheetSidebarPanel? openedPanel;
      final selection = CellSelection(CellAddress(0, 0), CellAddress(1, 0));
      final controller = container.read(toolbarControllerProvider);
      container
          .read(spreadsheetProvider.notifier)
          .updateCellValue(CellAddress(0, 0), 'Alpha');
      container
          .read(spreadsheetProvider.notifier)
          .updateCellValue(CellAddress(1, 0), 'Bravo');
      container.read(filterProvider.notifier).state = {0: 'Alpha'};
      container.read(sheetFilterRulesProvider.notifier).state = {
        0: SheetFilterRule.contains('Alpha'),
      };

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: SheetRibbonDataGroup(
                controller: controller,
                selection: selection,
                onOpenPanel: (panel) => openedPanel = panel,
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byTooltip('Find and Replace'));
      await tester.pump();

      expect(openedPanel, SheetSidebarPanel.findReplace);

      await tester.tap(find.byTooltip('Table Studio'));
      await tester.pump();

      expect(openedPanel, SheetSidebarPanel.tables);

      await tester.tap(find.byTooltip('Format as Table'));
      await tester.pump();

      expect(container.read(sheetTablesProvider), hasLength(1));
      expect(
        container.read(sheetTablesProvider).single.selection.label,
        'A1:A2',
      );

      await tester.tap(find.byTooltip('Data Validation').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('List of Values'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Yes, No, Maybe');
      await tester.tap(find.text('Apply'));
      await tester.pumpAndSettle();

      final validation = container
          .read(spreadsheetProvider)[CellAddress(0, 0)]
          ?.validation;
      expect(validation?.type, ValidationType.list);
      expect(validation?.options, ['Yes', 'No', 'Maybe']);

      await tester.tap(find.byTooltip('Sort').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sort Z to A'));
      await tester.pumpAndSettle();

      expect(container.read(sortColumnProvider), 0);
      expect(container.read(sortAscendingProvider), isFalse);
      expect(
        container.read(spreadsheetProvider)[CellAddress(0, 0)]?.value,
        'Bravo',
      );

      await tester.tap(find.byTooltip('Filters').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Remove Filter'));
      await tester.pumpAndSettle();

      expect(container.read(filterProvider), isEmpty);
      expect(container.read(sheetFilterRulesProvider), isEmpty);
    });

    testWidgets('data ribbon sorts active table body without moving headers', (
      tester,
    ) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final controller = container.read(toolbarControllerProvider);
      final table = SheetTable.fromSelection(
        id: 'table-sales',
        name: 'Sales',
        selection: CellSelection(CellAddress(0, 0), CellAddress(2, 1)),
      );
      final sheet = container.read(spreadsheetProvider.notifier);
      sheet.updateCellValue(CellAddress(0, 0), 'Region');
      sheet.updateCellValue(CellAddress(0, 1), 'Value');
      sheet.updateCellValue(CellAddress(1, 0), 'EMEA');
      sheet.updateCellValue(CellAddress(1, 1), '2');
      sheet.updateCellValue(CellAddress(2, 0), 'APAC');
      sheet.updateCellValue(CellAddress(2, 1), '5');

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: SheetRibbonDataGroup(
                controller: controller,
                selection: CellSelection(CellAddress(1, 0)),
                activeTable: table,
                onOpenPanel: (_) {},
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byTooltip('Sort').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sort A to Z'));
      await tester.pumpAndSettle();

      final cells = container.read(spreadsheetProvider);
      expect(cells[CellAddress(0, 0)]?.value, 'Region');
      expect(cells[CellAddress(0, 1)]?.value, 'Value');
      expect(cells[CellAddress(1, 0)]?.value, 'APAC');
      expect(cells[CellAddress(1, 1)]?.value, '5');
      expect(cells[CellAddress(2, 0)]?.value, 'EMEA');
      expect(cells[CellAddress(2, 1)]?.value, '2');
      expect(container.read(sortColumnProvider), 0);
      expect(container.read(sortAscendingProvider), isTrue);
    });

    test('toolbar controller keeps totals rows out of table sorts', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final controller = container.read(toolbarControllerProvider);
      final table = SheetTable.fromSelection(
        id: 'table-sales',
        name: 'Sales',
        selection: CellSelection(CellAddress(0, 0), CellAddress(3, 1)),
      ).copyWith(showTotalsRow: true);
      final sheet = container.read(spreadsheetProvider.notifier);
      sheet.updateCellValue(CellAddress(0, 0), 'Region');
      sheet.updateCellValue(CellAddress(0, 1), 'Value');
      sheet.updateCellValue(CellAddress(1, 0), 'EMEA');
      sheet.updateCellValue(CellAddress(1, 1), '2');
      sheet.updateCellValue(CellAddress(2, 0), 'APAC');
      sheet.updateCellValue(CellAddress(2, 1), '5');
      sheet.updateCellValue(CellAddress(3, 0), 'Total');
      sheet.updateCellValue(CellAddress(3, 1), '7');

      controller.sortTableColumn(table, 0);

      final cells = container.read(spreadsheetProvider);
      expect(cells[CellAddress(0, 0)]?.value, 'Region');
      expect(cells[CellAddress(1, 0)]?.value, 'APAC');
      expect(cells[CellAddress(2, 0)]?.value, 'EMEA');
      expect(cells[CellAddress(3, 0)]?.value, 'Total');
      expect(cells[CellAddress(3, 1)]?.value, '7');
    });

    testWidgets('formula ribbon group inserts functions and traces formulas', (
      tester,
    ) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      SheetSidebarPanel? openedPanel;
      final selection = CellSelection(CellAddress(2, 0));
      final controller = container.read(toolbarControllerProvider);
      container
          .read(spreadsheetProvider.notifier)
          .updateCellValue(CellAddress(0, 0), '10');
      container
          .read(spreadsheetProvider.notifier)
          .updateCellValue(CellAddress(1, 0), '15');

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: SheetRibbonFormulaGroup(
                controller: controller,
                selection: selection,
                onOpenPanel: (panel) => openedPanel = panel,
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byTooltip('AutoSum'));
      await tester.pumpAndSettle();

      expect(
        container.read(spreadsheetProvider)[CellAddress(2, 0)]?.formula,
        '=SUM(A1:A2)',
      );

      await tester.tap(find.byTooltip('Function Library'));
      await tester.pump();

      expect(openedPanel, SheetSidebarPanel.functionLibrary);

      await tester.tap(find.byTooltip('Trace Formula').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Trace References'));
      await tester.pumpAndSettle();

      expect(
        container
            .read(formulaReferencePreviewProvider)
            .map((selection) => selection.label),
        ['A1:A2'],
      );
      expect(
        container.read(formulaReferencePreviewContextProvider)?.source,
        SheetFormulaPreviewSource.traceReferences,
      );
    });

    testWidgets('review ribbon group opens review panels and shows counts', (
      tester,
    ) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      SheetSidebarPanel? openedPanel;
      final sheet = container.read(spreadsheetProvider.notifier);
      sheet.updateCell(
        CellAddress(0, 0),
        CellData(value: 'Owner', comment: 'Needs owner'),
      );
      sheet.updateCell(
        CellAddress(0, 1),
        CellData(value: 'Docs', hyperlink: 'https://example.com/docs'),
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: SheetRibbonReviewGroup(
                onOpenPanel: (panel) => openedPanel = panel,
              ),
            ),
          ),
        ),
      );

      expect(find.text('1 Comment'), findsOneWidget);
      expect(find.text('1 Link'), findsOneWidget);
      expect(find.text('2 Undo'), findsOneWidget);
      expect(find.text('0 Redo'), findsOneWidget);

      await tester.tap(find.text('1 Comment'));
      await tester.pump();

      expect(openedPanel, SheetSidebarPanel.review);

      await tester.tap(find.text('2 Undo'));
      await tester.pump();

      expect(openedPanel, SheetSidebarPanel.history);

      await tester.tap(find.byTooltip('Waraq Operations'));
      await tester.pump();

      expect(openedPanel, SheetSidebarPanel.sheetEngineOperations);
    });

    testWidgets('view ribbon group applies freeze and zoom actions', (
      tester,
    ) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      SheetSidebarPanel? openedPanel;
      final selection = CellSelection(CellAddress(3, 2));
      final controller = container.read(toolbarControllerProvider);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: SheetRibbonViewGroup(
                controller: controller,
                selection: selection,
                zoom: container.read(zoomLevelProvider),
                onOpenPanel: (panel) => openedPanel = panel,
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byTooltip('Sheet View'));
      await tester.pump();

      expect(openedPanel, SheetSidebarPanel.sheetView);

      await tester.tap(find.byTooltip('Freeze Panes').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Freeze First Row'));
      await tester.pumpAndSettle();

      expect(container.read(freezePanesProvider), CellAddress(1, 0));

      await tester.tap(find.byTooltip('Freeze Panes').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Freeze at Selection'));
      await tester.pumpAndSettle();

      expect(container.read(freezePanesProvider), CellAddress(3, 2));

      await tester.tap(find.byTooltip('Zoom In'));
      await tester.pump();

      expect(container.read(zoomLevelProvider), greaterThan(1));

      await tester.tap(find.byTooltip('Reset Zoom'));
      await tester.pump();

      expect(container.read(zoomLevelProvider), 1);
    });

    testWidgets('ribbon overflow scroller shows edge fades while scrolling', (
      tester,
    ) async {
      final controller = ScrollController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 120,
              child: SheetRibbonOverflowScroller(
                controller: controller,
                child: Row(
                  children: [
                    for (var index = 0; index < 4; index++)
                      SizedBox(width: 90, child: Text('Group $index')),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(controller.hasClients, isTrue);
      expect(
        find.byKey(const ValueKey('ky-sheet-ribbon-overflow-start-fade')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('ky-sheet-ribbon-overflow-end-fade')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('ky-sheet-ribbon-overflow-scroll-next')),
        findsOneWidget,
      );

      await tester.tap(
        find.byKey(const ValueKey('ky-sheet-ribbon-overflow-scroll-next')),
      );
      await tester.pumpAndSettle();

      expect(controller.offset, greaterThan(0));
      expect(
        find.byKey(const ValueKey('ky-sheet-ribbon-overflow-start-fade')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('ky-sheet-ribbon-overflow-scroll-previous')),
        findsOneWidget,
      );

      await tester.tap(
        find.byKey(const ValueKey('ky-sheet-ribbon-overflow-scroll-previous')),
      );
      await tester.pumpAndSettle();

      expect(controller.offset, 0);
      await tester.drag(
        find.byKey(const ValueKey('ky-sheet-ribbon-overflow-scroll')),
        const Offset(-160, 0),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('ky-sheet-ribbon-overflow-start-fade')),
        findsOneWidget,
      );
    });

    testWidgets('ribbon overflow controls follow active density', (
      tester,
    ) async {
      const nextControlKey = ValueKey(
        'ky-sheet-ribbon-overflow-scroll-next-control',
      );

      Widget buildScroller(SheetRibbonDensity density) {
        return MaterialApp(
          home: Scaffold(
            body: SheetRibbonDensityScope(
              density: density,
              child: SizedBox(
                width: 120,
                child: SheetRibbonOverflowScroller(
                  child: Row(
                    children: [
                      for (var index = 0; index < 4; index++)
                        SizedBox(width: 90, child: Text('Group $index')),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      }

      await tester.pumpWidget(buildScroller(SheetRibbonDensity.compact));
      await tester.pumpAndSettle();
      final compactButtonSize = tester.getSize(find.byKey(nextControlKey));

      await tester.pumpWidget(buildScroller(SheetRibbonDensity.comfortable));
      await tester.pumpAndSettle();
      final comfortableButtonSize = tester.getSize(find.byKey(nextControlKey));

      expect(compactButtonSize.width, lessThan(comfortableButtonSize.width));
    });

    testWidgets('ribbon tab strip supports overflow and keyboard navigation', (
      tester,
    ) async {
      var selectedTab = SheetRibbonTab.home;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 220,
              child: StatefulBuilder(
                builder: (context, setState) => SheetRibbonTabStrip(
                  selectedTab: selectedTab,
                  onSelected: (tab) => setState(() => selectedTab = tab),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('ky-sheet-ribbon-overflow-end-fade')),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const ValueKey('ky-sheet-ribbon-tab-home')));
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();

      expect(selectedTab, SheetRibbonTab.insert);

      await tester.sendKeyEvent(LogicalKeyboardKey.end);
      await tester.pumpAndSettle();

      expect(selectedTab, SheetRibbonTab.review);
      expect(
        find.byKey(const ValueKey('ky-sheet-ribbon-overflow-start-fade')),
        findsOneWidget,
      );
    });

    testWidgets('ribbon surface renders context and emits tab selections', (
      tester,
    ) async {
      SheetRibbonTab? selectedTab;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SheetRibbonSurface(
              selectedTab: SheetRibbonTab.home,
              selectionLabel: 'C3:D4',
              groups: const [
                SheetRibbonGroup(
                  label: 'Demo',
                  icon: Icons.grid_view,
                  children: [Text('Demo command')],
                ),
              ],
              onTabSelected: (tab) => selectedTab = tab,
            ),
          ),
        ),
      );

      expect(
        find.byKey(const ValueKey('ky-sheet-ribbon-surface')),
        findsOneWidget,
      );
      expect(find.text('C3:D4 selected'), findsOneWidget);
      expect(find.text('Demo command'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('ky-sheet-ribbon-tab-data')));
      await tester.pump();

      expect(selectedTab, SheetRibbonTab.data);
    });

    testWidgets('ribbon surface resolves compact density for narrow layouts', (
      tester,
    ) async {
      const groupKey = ValueKey('ky-sheet-density-group');

      Widget buildSurface(double width) {
        return MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: width,
                child: SheetRibbonSurface(
                  selectedTab: SheetRibbonTab.home,
                  onTabSelected: (_) {},
                  groups: const [
                    SheetRibbonGroup(
                      key: groupKey,
                      label: 'Density',
                      icon: Icons.tune,
                      children: [Text('Command')],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }

      await tester.pumpWidget(buildSurface(520));
      await tester.pumpAndSettle();
      final compactHeight = tester.getSize(find.byKey(groupKey)).height;

      await tester.pumpWidget(buildSurface(980));
      await tester.pumpAndSettle();
      final comfortableHeight = tester.getSize(find.byKey(groupKey)).height;

      expect(compactHeight, lessThan(comfortableHeight));
    });

    testWidgets('ribbon command controls follow active density', (
      tester,
    ) async {
      const toolKey = ValueKey('ky-sheet-density-tool-button');
      const popupKey = ValueKey('ky-sheet-density-popup-button');

      Widget buildControls(SheetRibbonDensity density) {
        return MaterialApp(
          home: Scaffold(
            body: SheetRibbonDensityScope(
              density: density,
              child: Row(
                children: [
                  ToolButton(
                    key: toolKey,
                    icon: Icons.format_bold,
                    tooltip: 'Bold',
                    onPressed: () {},
                  ),
                  ToolPopupButton<String>(
                    key: popupKey,
                    icon: Icons.more_horiz,
                    tooltip: 'More',
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'more', child: Text('More')),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      }

      await tester.pumpWidget(buildControls(SheetRibbonDensity.compact));
      await tester.pumpAndSettle();
      final compactToolSize = tester.getSize(find.byKey(toolKey));
      final compactPopupSize = tester.getSize(find.byKey(popupKey));

      await tester.pumpWidget(buildControls(SheetRibbonDensity.comfortable));
      await tester.pumpAndSettle();
      final comfortableToolSize = tester.getSize(find.byKey(toolKey));
      final comfortablePopupSize = tester.getSize(find.byKey(popupKey));

      expect(compactToolSize.width, lessThan(comfortableToolSize.width));
      expect(compactPopupSize.width, lessThan(comfortablePopupSize.width));
    });

    testWidgets('color button follows active density and custom tooltip', (
      tester,
    ) async {
      const colorKey = ValueKey('ky-sheet-density-color-button');

      Widget buildColorButton(SheetRibbonDensity density) {
        return MaterialApp(
          home: Scaffold(
            body: SheetRibbonDensityScope(
              density: density,
              child: ColorButton(
                key: colorKey,
                color: Colors.red,
                tooltip: 'Text Red',
                onPressed: () {},
              ),
            ),
          ),
        );
      }

      await tester.pumpWidget(buildColorButton(SheetRibbonDensity.compact));
      await tester.pumpAndSettle();
      final compactColorSize = tester.getSize(find.byKey(colorKey));

      await tester.pumpWidget(buildColorButton(SheetRibbonDensity.comfortable));
      await tester.pumpAndSettle();
      final comfortableColorSize = tester.getSize(find.byKey(colorKey));

      expect(compactColorSize.width, lessThan(comfortableColorSize.width));
      expect(find.byTooltip('Text Red'), findsOneWidget);
    });

    testWidgets('ribbon command row follows active density spacing', (
      tester,
    ) async {
      const rowKey = ValueKey('ky-sheet-density-command-row');

      Widget buildRow(SheetRibbonDensity density) {
        return MaterialApp(
          home: Scaffold(
            body: SheetRibbonDensityScope(
              density: density,
              child: const SheetRibbonCommandRow(
                key: rowKey,
                children: [
                  SizedBox(width: 20, height: 10),
                  SizedBox(width: 20, height: 10),
                  SizedBox(width: 20, height: 10),
                ],
              ),
            ),
          ),
        );
      }

      await tester.pumpWidget(buildRow(SheetRibbonDensity.compact));
      await tester.pumpAndSettle();
      final compactRowWidth = tester.getSize(find.byKey(rowKey)).width;

      await tester.pumpWidget(buildRow(SheetRibbonDensity.comfortable));
      await tester.pumpAndSettle();
      final comfortableRowWidth = tester.getSize(find.byKey(rowKey)).width;

      expect(compactRowWidth, lessThan(comfortableRowWidth));
    });

    testWidgets('ribbon tab strip follows active density', (tester) async {
      const tabKey = ValueKey('ky-sheet-ribbon-tab-home');

      Widget buildTabStrip(SheetRibbonDensity density) {
        return MaterialApp(
          home: Scaffold(
            body: SheetRibbonDensityScope(
              density: density,
              child: SheetRibbonTabStrip(
                selectedTab: SheetRibbonTab.home,
                onSelected: (_) {},
              ),
            ),
          ),
        );
      }

      await tester.pumpWidget(buildTabStrip(SheetRibbonDensity.compact));
      await tester.pumpAndSettle();
      final compactTabSize = tester.getSize(find.byKey(tabKey));

      await tester.pumpWidget(buildTabStrip(SheetRibbonDensity.comfortable));
      await tester.pumpAndSettle();
      final comfortableTabSize = tester.getSize(find.byKey(tabKey));

      expect(compactTabSize.height, lessThan(comfortableTabSize.height));
      expect(compactTabSize.width, lessThan(comfortableTabSize.width));
    });

    testWidgets('ribbon context bar follows active density', (tester) async {
      const barKey = ValueKey('ky-sheet-ribbon-context-bar');

      Widget buildContextBar(SheetRibbonDensity density) {
        return MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 320,
              child: SheetRibbonDensityScope(
                density: density,
                child: const SheetRibbonContextBar(
                  tab: SheetRibbonTab.data,
                  selectionLabel: 'A1:B2',
                ),
              ),
            ),
          ),
        );
      }

      await tester.pumpWidget(buildContextBar(SheetRibbonDensity.compact));
      await tester.pumpAndSettle();
      final compactBarSize = tester.getSize(find.byKey(barKey));

      await tester.pumpWidget(buildContextBar(SheetRibbonDensity.comfortable));
      await tester.pumpAndSettle();
      final comfortableBarSize = tester.getSize(find.byKey(barKey));

      expect(compactBarSize.height, lessThan(comfortableBarSize.height));
      expect(find.text('A1:B2 selected'), findsOneWidget);
    });

    testWidgets('ribbon context bar surfaces active table controls', (
      tester,
    ) async {
      var openedTableStudio = false;
      final table = SheetTable.fromSelection(
        id: 'table-sales',
        name: 'Sales',
        selection: CellSelection(CellAddress(0, 0), CellAddress(2, 1)),
        styleId: SheetTableStyleId.mint,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 720,
              child: SheetRibbonDensityScope(
                density: SheetRibbonDensity.comfortable,
                child: SheetRibbonContextBar(
                  tab: SheetRibbonTab.data,
                  selectionLabel: 'A2',
                  activeTable: table,
                  onOpenTableStudio: () => openedTableStudio = true,
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Sales table'), findsOneWidget);
      expect(
        find.text('A2 in A1:B3 · Mint style · headers + banding enabled'),
        findsOneWidget,
      );

      await tester.tap(find.byTooltip('Open Table Studio'));
      await tester.pump();

      expect(openedTableStudio, isTrue);
    });

    testWidgets('zoom control follows active density', (tester) async {
      const zoomControlKey = ValueKey('ky-sheet-status-zoom-control');

      Widget buildZoomControl(SheetRibbonDensity density) {
        return MaterialApp(
          home: Scaffold(
            body: SheetRibbonDensityScope(
              density: density,
              child: SheetZoomControl(
                zoom: 1,
                onChanged: (_) {},
                onZoomOut: () {},
                onZoomIn: () {},
                onReset: () {},
              ),
            ),
          ),
        );
      }

      await tester.pumpWidget(buildZoomControl(SheetRibbonDensity.compact));
      await tester.pumpAndSettle();
      final compactZoomSize = tester.getSize(find.byKey(zoomControlKey));

      await tester.pumpWidget(buildZoomControl(SheetRibbonDensity.comfortable));
      await tester.pumpAndSettle();
      final comfortableZoomSize = tester.getSize(find.byKey(zoomControlKey));

      expect(compactZoomSize.height, lessThan(comfortableZoomSize.height));
      expect(compactZoomSize.width, lessThan(comfortableZoomSize.width));
    });

    testWidgets('switches ribbon tabs and opens panels from the toolbar', (
      tester,
    ) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: Scaffold(body: ToolbarWidget())),
        ),
      );

      expect(find.byKey(const ValueKey('ky-sheet-ribbon-tab-home')), findsOne);
      expect(
        find.byKey(const ValueKey('ky-sheet-ribbon-tab-insert')),
        findsOne,
      );
      expect(find.byKey(const ValueKey('ky-sheet-ribbon-tab-data')), findsOne);
      expect(
        find.byKey(const ValueKey('ky-sheet-ribbon-tab-formulas')),
        findsOne,
      );
      expect(find.byKey(const ValueKey('ky-sheet-ribbon-tab-view')), findsOne);
      expect(
        find.byKey(const ValueKey('ky-sheet-ribbon-tab-review')),
        findsOne,
      );
      expect(
        find.byKey(const ValueKey('ky-sheet-ribbon-context-bar')),
        findsOneWidget,
      );
      expect(find.text('No range selected'), findsOneWidget);
      expect(
        find.text(
          'Select cells to enable formatting, clipboard, alignment, and number tools.',
        ),
        findsOneWidget,
      );
      expect(find.text('Clipboard'), findsOneWidget);
      expect(find.text('Format'), findsOneWidget);
      expect(find.text('Rows & Columns'), findsNothing);

      await tester.tap(
        find.byKey(const ValueKey('ky-sheet-ribbon-tab-formulas')),
      );
      await tester.pumpAndSettle();

      expect(find.text('Formula'), findsOneWidget);
      expect(
        find.text(
          'Select a cell to insert, audit, trace, or inspect formulas.',
        ),
        findsOneWidget,
      );
      await tester.ensureVisible(find.byTooltip('Function Library'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Function Library'));
      await tester.pump();

      expect(
        container.read(activeSidebarPanelProvider),
        SheetSidebarPanel.functionLibrary,
      );

      await tester.ensureVisible(find.byTooltip('Formula Health'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Formula Health'));
      await tester.pump();

      expect(
        container.read(activeSidebarPanelProvider),
        SheetSidebarPanel.formulaHealth,
      );

      await tester.tap(find.byKey(const ValueKey('ky-sheet-ribbon-tab-view')));
      await tester.pumpAndSettle();

      expect(find.text('View'), findsWidgets);
      expect(
        find.text(
          'Use view presets anytime, or select a range to freeze at selection.',
        ),
        findsOneWidget,
      );
      await tester.ensureVisible(find.byTooltip('Sheet View'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Sheet View'));
      await tester.pump();

      expect(
        container.read(activeSidebarPanelProvider),
        SheetSidebarPanel.sheetView,
      );
    });

    testWidgets('summarizes selected ranges in the active ribbon tab', (
      tester,
    ) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(selectedCellProvider.notifier).state = CellSelection(
        CellAddress(0, 0),
        CellAddress(1, 1),
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: Scaffold(body: ToolbarWidget())),
        ),
      );

      expect(find.text('A1:B2 selected'), findsOneWidget);
      expect(
        find.text('Home tools ready for formatting and clipboard actions.'),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const ValueKey('ky-sheet-ribbon-tab-data')));
      await tester.pumpAndSettle();

      expect(find.text('A1:B2 selected'), findsOneWidget);
      expect(
        find.text(
          'Data tools ready for sorting, filtering, cleanup, and validation.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('summarizes the active table in the ribbon context bar', (
      tester,
    ) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container
          .read(sheetTablesProvider.notifier)
          .createFromSelection(
            CellSelection(CellAddress(0, 0), CellAddress(2, 1)),
            styleId: SheetTableStyleId.graphite,
          );
      container.read(selectedCellProvider.notifier).state = CellSelection(
        CellAddress(1, 0),
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: Scaffold(body: ToolbarWidget())),
        ),
      );

      expect(find.text('Table1 table'), findsOneWidget);
      expect(
        find.text('A2 in A1:B3 · Graphite style · headers + banding enabled'),
        findsOneWidget,
      );

      await tester.tap(find.byTooltip('Open Table Studio'));
      await tester.pump();

      expect(
        container.read(activeSidebarPanelProvider),
        SheetSidebarPanel.tables,
      );
    });

    testWidgets('summarizes active table filters in the ribbon context bar', (
      tester,
    ) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container
          .read(sheetTablesProvider.notifier)
          .createFromSelection(
            CellSelection(CellAddress(0, 0), CellAddress(2, 1)),
            styleId: SheetTableStyleId.mint,
          );
      final sheet = container.read(spreadsheetProvider.notifier);
      sheet.updateCellValue(CellAddress(0, 0), 'Region');
      sheet.updateCellValue(CellAddress(0, 1), 'Sales');
      sheet.updateCellValue(CellAddress(1, 0), 'EMEA');
      sheet.updateCellValue(CellAddress(1, 1), '24');
      sheet.updateCellValue(CellAddress(2, 0), 'APAC');
      sheet.updateCellValue(CellAddress(2, 1), '18');
      final toolbar = container.read(toolbarControllerProvider);
      toolbar.setFilterRule(0, SheetFilterRule.contains('EMEA'));
      toolbar.setFilterRule(4, SheetFilterRule.contains('Outside'));
      container.read(selectedCellProvider.notifier).state = CellSelection(
        CellAddress(1, 0),
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: Scaffold(body: ToolbarWidget())),
        ),
      );

      expect(find.text('Table1 table'), findsOneWidget);
      expect(
        find.text(
          'A2 in A1:B3 · Mint style · 1 filtered column · 1 of 2 rows shown · headers + banding enabled',
        ),
        findsOneWidget,
      );
      expect(find.byTooltip('Clear table filters'), findsOneWidget);
      expect(find.textContaining('2 filtered columns'), findsNothing);

      await tester.tap(find.byTooltip('Clear table filters'));
      await tester.pump();

      expect(container.read(filterProvider), {4: 'Outside'});
      expect(container.read(sheetFilterRulesProvider).keys.toList(), [4]);
      expect(
        find.text('A2 in A1:B3 · Mint style · headers + banding enabled'),
        findsOneWidget,
      );
      expect(find.byTooltip('Clear table filters'), findsNothing);
    });
  });

  group('SheetSidebar', () {
    test('menu configuration covers every sidebar panel exactly once', () {
      final panels = SheetSidebarMenu.items.map((item) => item.panel).toList();

      expect(panels, hasLength(SheetSidebarPanel.values.length));
      expect(panels.toSet(), containsAll(SheetSidebarPanel.values));
      expect(panels.toSet(), hasLength(panels.length));
      expect(SheetSidebarMenu.sections.map((section) => section.id), [
        'core',
        'review-sync',
        'data',
        'view-rules',
      ]);
      expect(
        SheetSidebarMenu.items
            .singleWhere((item) => item.panel == SheetSidebarPanel.shortcuts)
            .shortcutLabel,
        SheetShortcutLabels.shortcuts,
      );
      expect(
        SheetSidebarMenu.items
            .singleWhere((item) => item.panel == SheetSidebarPanel.findReplace)
            .shortcutLabel,
        SheetShortcutLabels.findReplace,
      );
      expect(
        SheetSidebarMenu.items
            .singleWhere((item) => item.panel == SheetSidebarPanel.sortFilter)
            .shortcutLabel,
        SheetShortcutLabels.sortFilter,
      );
    });

    testWidgets('renders grouped rail sections and closes active panel', (
      tester,
    ) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(activeSidebarPanelProvider.notifier).state =
          SheetSidebarPanel.dataInsights;

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: Scaffold(body: SheetSidebar())),
        ),
      );

      expect(
        find.byKey(const ValueKey('ky-sheet-sidebar-section-review-sync')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('ky-sheet-sidebar-section-data')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('ky-sheet-sidebar-section-view-rules')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('ky-sheet-sidebar-dataInsights')),
        findsOneWidget,
      );
      expect(find.byTooltip('Close Sidebar (Esc)'), findsOneWidget);

      await tester.tap(find.byTooltip('Close Sidebar (Esc)'));
      await tester.pumpAndSettle();

      expect(container.read(activeSidebarPanelProvider), isNull);
    });

    testWidgets('opens the cell inspector panel from the sidebar menu', (
      tester,
    ) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: Scaffold(body: SheetSidebar())),
        ),
      );

      await tester.tap(find.byTooltip('Cell Inspector'));
      await tester.pumpAndSettle();

      expect(find.text('Cell Inspector'), findsOneWidget);
      expect(
        find.text('Select a cell to inspect its content and metadata'),
        findsOneWidget,
      );
    });

    testWidgets('opens the shortcuts panel from the sidebar menu', (
      tester,
    ) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: Scaffold(body: SheetSidebar())),
        ),
      );

      await tester.tap(find.byTooltip('Shortcuts (Ctrl+/)'));
      await tester.pumpAndSettle();

      expect(find.text('Shortcuts'), findsOneWidget);
      expect(find.text('Keyboard reference'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('ky-sheet-sidebar-panel-surface-Shortcuts')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('ky-sheet-shortcuts-search')),
        findsOneWidget,
      );
      expect(find.text(SheetShortcutLabels.bold), findsOneWidget);

      await tester.tap(
        find.byKey(const ValueKey('ky-sheet-shortcut-category-tools')),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('ky-sheet-shortcut-tools.findReplace')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('ky-sheet-shortcut-format.bold')),
        findsNothing,
      );

      await tester.tap(
        find.byKey(const ValueKey('ky-sheet-shortcut-category-all')),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const ValueKey('ky-sheet-shortcuts-search')),
        'paste',
      );
      await tester.pumpAndSettle();

      expect(find.text('Paste'), findsOneWidget);
      expect(find.text(SheetShortcutLabels.paste), findsOneWidget);
      expect(find.text('Copy'), findsNothing);

      await tester.tap(find.byTooltip('Close Shortcuts panel'));
      await tester.pumpAndSettle();

      expect(container.read(activeSidebarPanelProvider), isNull);
    });

    testWidgets('opens the function library panel from the sidebar menu', (
      tester,
    ) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: Scaffold(body: SheetSidebar())),
        ),
      );

      await tester.tap(find.byTooltip('Function Library'));
      await tester.pumpAndSettle();

      expect(find.text('Function Library'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('ky-sheet-function-search')),
        findsOneWidget,
      );

      await tester.tap(find.byTooltip('Close Function Library panel'));
      await tester.pumpAndSettle();

      expect(container.read(activeSidebarPanelProvider), isNull);
    });

    testWidgets('opens the formula audit panel from the sidebar menu', (
      tester,
    ) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: Scaffold(body: SheetSidebar())),
        ),
      );

      await tester.tap(find.byTooltip('Formula Audit'));
      await tester.pumpAndSettle();

      expect(find.text('Formula Audit'), findsOneWidget);
      expect(find.text('Select a cell to audit formulas'), findsOneWidget);

      await tester.tap(find.byTooltip('Close Formula Audit panel'));
      await tester.pumpAndSettle();

      expect(container.read(activeSidebarPanelProvider), isNull);
    });

    testWidgets('opens the formula health panel from the sidebar menu', (
      tester,
    ) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: Scaffold(body: SheetSidebar())),
        ),
      );

      await tester.tap(find.byTooltip('Formula Health'));
      await tester.pumpAndSettle();

      expect(find.text('Formula Health'), findsOneWidget);
      expect(find.text('Find formula issues'), findsOneWidget);
      expect(find.text('No formula issues found'), findsOneWidget);

      await tester.tap(find.byTooltip('Close Formula Health panel'));
      await tester.pumpAndSettle();

      expect(container.read(activeSidebarPanelProvider), isNull);
    });

    testWidgets('opens the go to special panel from the sidebar menu', (
      tester,
    ) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: Scaffold(body: SheetSidebar())),
        ),
      );

      await tester.tap(find.byTooltip('Go To Special'));
      await tester.pumpAndSettle();

      expect(
        find.byKey(
          const ValueKey('ky-sheet-sidebar-panel-surface-Go To Special'),
        ),
        findsOneWidget,
      );
      expect(find.text('Go To Special'), findsOneWidget);
      expect(find.text('Find cells by type'), findsOneWidget);
      expect(find.text('No formulas found'), findsOneWidget);

      await tester.tap(find.byTooltip('Close Go To Special panel'));
      await tester.pumpAndSettle();

      expect(container.read(activeSidebarPanelProvider), isNull);
    });

    testWidgets('opens the history panel from the sidebar menu', (
      tester,
    ) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: Scaffold(body: SheetSidebar())),
        ),
      );

      await tester.tap(find.byTooltip('History'));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('ky-sheet-sidebar-panel-surface-History')),
        findsOneWidget,
      );
      expect(find.text('History'), findsOneWidget);
      expect(find.text('Undo and redo timeline'), findsOneWidget);
      expect(find.text('No history yet'), findsOneWidget);

      await tester.tap(find.byTooltip('Close History panel'));
      await tester.pumpAndSettle();

      expect(container.read(activeSidebarPanelProvider), isNull);
    });

    testWidgets('opens the Waraq operations panel from the sidebar menu', (
      tester,
    ) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: Scaffold(body: SheetSidebar())),
        ),
      );

      await tester.ensureVisible(find.byTooltip('Waraq Operations'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Waraq Operations'));
      await tester.pumpAndSettle();

      expect(
        find.byKey(
          const ValueKey('ky-sheet-sidebar-panel-surface-Waraq Operations'),
        ),
        findsOneWidget,
      );
      expect(find.text('Waraq Operations'), findsOneWidget);
      expect(find.text('Sheet engine sync log'), findsOneWidget);
      expect(find.text('No Waraq operations yet'), findsOneWidget);

      await tester.tap(find.byTooltip('Close Waraq Operations panel'));
      await tester.pumpAndSettle();

      expect(container.read(activeSidebarPanelProvider), isNull);
    });

    testWidgets('opens the review panel from the sidebar menu', (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: Scaffold(body: SheetSidebar())),
        ),
      );

      await tester.tap(find.byTooltip('Review'));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('ky-sheet-sidebar-panel-surface-Review')),
        findsOneWidget,
      );
      expect(find.text('Review'), findsOneWidget);
      expect(find.text('Comments and links'), findsOneWidget);
      expect(find.text('No comments or hyperlinks yet'), findsOneWidget);

      await tester.tap(find.byTooltip('Close Review panel'));
      await tester.pumpAndSettle();

      expect(container.read(activeSidebarPanelProvider), isNull);
    });

    testWidgets('opens the chart builder panel from the sidebar menu', (
      tester,
    ) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: Scaffold(body: SheetSidebar())),
        ),
      );

      await tester.tap(find.byTooltip('Chart Builder'));
      await tester.pumpAndSettle();

      expect(
        find.byKey(
          const ValueKey('ky-sheet-sidebar-panel-surface-Chart Builder'),
        ),
        findsOneWidget,
      );
      expect(find.text('Chart Builder'), findsOneWidget);
      expect(find.text('Visualize selection'), findsOneWidget);
      expect(find.text('No numeric chart data'), findsOneWidget);

      await tester.tap(find.byTooltip('Close Chart Builder panel'));
      await tester.pumpAndSettle();

      expect(container.read(activeSidebarPanelProvider), isNull);
    });

    testWidgets('opens the named ranges panel from the sidebar menu', (
      tester,
    ) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: Scaffold(body: SheetSidebar())),
        ),
      );

      await tester.tap(find.byTooltip('Named Ranges'));
      await tester.pumpAndSettle();

      expect(
        find.byKey(
          const ValueKey('ky-sheet-sidebar-panel-surface-Named Ranges'),
        ),
        findsOneWidget,
      );
      expect(find.text('Named Ranges'), findsOneWidget);
      expect(find.text('Reusable ranges'), findsOneWidget);
      expect(find.text('No named ranges yet'), findsOneWidget);

      await tester.tap(find.byTooltip('Close Named Ranges panel'));
      await tester.pumpAndSettle();

      expect(container.read(activeSidebarPanelProvider), isNull);
    });

    testWidgets('opens the table studio panel from the sidebar menu', (
      tester,
    ) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: Scaffold(body: SheetSidebar())),
        ),
      );

      await tester.ensureVisible(find.byTooltip('Table Studio'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Table Studio'));
      await tester.pumpAndSettle();

      expect(
        find.byKey(
          const ValueKey('ky-sheet-sidebar-panel-surface-Table Studio'),
        ),
        findsOneWidget,
      );
      expect(find.text('Table Studio'), findsOneWidget);
      expect(find.text('Structured ranges'), findsOneWidget);
      expect(find.text('No structured tables yet'), findsOneWidget);

      await tester.tap(find.byTooltip('Close Table Studio panel'));
      await tester.pumpAndSettle();

      expect(container.read(activeSidebarPanelProvider), isNull);
    });

    testWidgets('creates and edits structured tables from the sidebar panel', (
      tester,
    ) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(activeSidebarPanelProvider.notifier).state =
          SheetSidebarPanel.tables;
      container.read(selectedCellProvider.notifier).state = CellSelection(
        CellAddress(0, 0),
        CellAddress(2, 1),
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: Scaffold(body: SheetSidebar())),
        ),
      );

      expect(
        find.byKey(
          const ValueKey('ky-sheet-sidebar-panel-surface-Table Studio'),
        ),
        findsOneWidget,
      );
      expect(find.text('Structured ranges'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('ky-sheet-tables-create')));
      await tester.pumpAndSettle();

      var table = container.read(sheetTablesProvider).single;
      final tableId = table.id;
      expect(table.selection.label, 'A1:B3');

      container.read(selectedCellProvider.notifier).state = CellSelection(
        CellAddress(1, 1),
        CellAddress(3, 3),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(ValueKey('ky-sheet-table-use-selection-$tableId')),
      );
      await tester.pumpAndSettle();

      expect(
        container.read(sheetTablesProvider).single.selection.label,
        'B2:D4',
      );

      container
          .read(spreadsheetProvider.notifier)
          .updateCellValue(CellAddress(4, 3), 'Tail');
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(ValueKey('ky-sheet-table-expand-data-$tableId')),
      );
      await tester.pumpAndSettle();

      expect(
        container.read(sheetTablesProvider).single.selection.label,
        'B2:D5',
      );

      await tester.enterText(
        find.byKey(ValueKey('ky-sheet-table-name-$tableId')),
        'Pipeline',
      );
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(ValueKey('ky-sheet-table-style-$tableId')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Mint').last);
      await tester.pumpAndSettle();

      await tester.ensureVisible(
        find.byKey(ValueKey('ky-sheet-table-header-$tableId')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(ValueKey('ky-sheet-table-header-$tableId')));
      await tester.pumpAndSettle();
      await tester.ensureVisible(
        find.byKey(ValueKey('ky-sheet-table-banding-$tableId')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(ValueKey('ky-sheet-table-banding-$tableId')));
      await tester.pumpAndSettle();
      await tester.ensureVisible(
        find.byKey(ValueKey('ky-sheet-table-totals-$tableId')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(ValueKey('ky-sheet-table-totals-$tableId')));
      await tester.pumpAndSettle();

      table = container.read(sheetTablesProvider).single;
      expect(table.name, 'Pipeline');
      expect(table.styleId, SheetTableStyleId.mint);
      expect(table.showHeaderRow, isFalse);
      expect(table.showBandedRows, isFalse);
      expect(table.showTotalsRow, isTrue);

      await tester.tap(find.byKey(ValueKey('ky-sheet-table-remove-$tableId')));
      await tester.pumpAndSettle();

      expect(container.read(sheetTablesProvider), isEmpty);
    });

    testWidgets('opens the data insights panel from the sidebar menu', (
      tester,
    ) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: Scaffold(body: SheetSidebar())),
        ),
      );

      await tester.ensureVisible(find.byTooltip('Data Insights'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Data Insights'));
      await tester.pumpAndSettle();

      expect(
        find.byKey(
          const ValueKey('ky-sheet-sidebar-panel-surface-Data Insights'),
        ),
        findsOneWidget,
      );
      expect(find.text('Data Insights'), findsOneWidget);
      expect(find.text('Profile selected data'), findsOneWidget);
      expect(
        find.text('Select cells or add data to see insights'),
        findsOneWidget,
      );

      await tester.tap(find.byTooltip('Close Data Insights panel'));
      await tester.pumpAndSettle();

      expect(container.read(activeSidebarPanelProvider), isNull);
    });

    testWidgets('opens the data cleanup panel from the sidebar menu', (
      tester,
    ) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: Scaffold(body: SheetSidebar())),
        ),
      );

      await tester.ensureVisible(find.byTooltip('Data Cleanup'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Data Cleanup'));
      await tester.pumpAndSettle();

      expect(
        find.byKey(
          const ValueKey('ky-sheet-sidebar-panel-surface-Data Cleanup'),
        ),
        findsOneWidget,
      );
      expect(find.text('Data Cleanup'), findsOneWidget);
      expect(find.text('Clean selected data'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('ky-sheet-cleanup-operation')),
        findsOneWidget,
      );

      await tester.tap(find.byTooltip('Close Data Cleanup panel'));
      await tester.pumpAndSettle();

      expect(container.read(activeSidebarPanelProvider), isNull);
    });

    testWidgets('opens the find replace panel from the sidebar menu', (
      tester,
    ) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: Scaffold(body: SheetSidebar())),
        ),
      );

      await tester.ensureVisible(find.byTooltip('Find & Replace (Ctrl+F)'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Find & Replace (Ctrl+F)'));
      await tester.pumpAndSettle();

      expect(
        find.byKey(
          const ValueKey('ky-sheet-sidebar-panel-surface-Find & Replace'),
        ),
        findsOneWidget,
      );
      expect(find.text('Find & Replace'), findsOneWidget);
      expect(find.text('Search and replace'), findsOneWidget);
      expect(find.byKey(const ValueKey('ky-sheet-find-input')), findsOneWidget);

      await tester.tap(find.byTooltip('Close Find & Replace panel'));
      await tester.pumpAndSettle();

      expect(container.read(activeSidebarPanelProvider), isNull);
    });

    testWidgets('opens the sort filter panel from the sidebar menu', (
      tester,
    ) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: Scaffold(body: SheetSidebar())),
        ),
      );

      await tester.ensureVisible(
        find.byTooltip('Sort & Filter (Ctrl+Shift+L)'),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Sort & Filter (Ctrl+Shift+L)'));
      await tester.pumpAndSettle();

      expect(
        find.byKey(
          const ValueKey('ky-sheet-sidebar-panel-surface-Sort & Filter'),
        ),
        findsOneWidget,
      );
      expect(find.text('Sort & Filter'), findsOneWidget);
      expect(find.text('Sort ranges and filter rows'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('ky-sheet-filter-operator')),
        findsOneWidget,
      );

      await tester.tap(find.byTooltip('Close Sort & Filter panel'));
      await tester.pumpAndSettle();

      expect(container.read(activeSidebarPanelProvider), isNull);
    });

    testWidgets('opens the sheet view panel from the sidebar menu', (
      tester,
    ) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: Scaffold(body: SheetSidebar())),
        ),
      );

      await tester.ensureVisible(find.byTooltip('Sheet View'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Sheet View'));
      await tester.pumpAndSettle();

      expect(find.text('Sheet View'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('ky-sheet-view-freeze-first-row')),
        findsOneWidget,
      );
    });

    testWidgets('opens the performance panel from the sidebar menu', (
      tester,
    ) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: Scaffold(body: SheetSidebar())),
        ),
      );

      await tester.ensureVisible(find.byTooltip('Performance'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Performance'));
      await tester.pumpAndSettle();

      expect(find.text('Rendered Cells'), findsOneWidget);
      expect(find.text('Virtualized'), findsOneWidget);
    });

    testWidgets('opens the data validation panel from the sidebar menu', (
      tester,
    ) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: Scaffold(body: SheetSidebar())),
        ),
      );

      await tester.ensureVisible(find.byTooltip('Data Validation'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Data Validation'));
      await tester.pumpAndSettle();

      expect(find.text('Data Validation'), findsOneWidget);
      expect(find.text('Apply Validation'), findsOneWidget);
    });
  });

  group('SheetChartBuilderPanel', () {
    testWidgets('renders selected range chart data and updates chart type', (
      tester,
    ) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(selectedCellProvider.notifier).state = CellSelection(
        CellAddress(0, 0),
        CellAddress(2, 2),
      );
      final sheet = container.read(spreadsheetProvider.notifier);
      sheet.updateCell(CellAddress(0, 0), CellData(value: 'Month'));
      sheet.updateCell(CellAddress(0, 1), CellData(value: 'Revenue'));
      sheet.updateCell(CellAddress(0, 2), CellData(value: 'Cost'));
      sheet.updateCell(CellAddress(1, 0), CellData(value: 'Jan'));
      sheet.updateCell(CellAddress(1, 1), CellData(value: '10'));
      sheet.updateCell(CellAddress(1, 2), CellData(value: '4'));
      sheet.updateCell(CellAddress(2, 0), CellData(value: 'Feb'));
      sheet.updateCell(CellAddress(2, 1), CellData(value: '20'));
      sheet.updateCell(CellAddress(2, 2), CellData(value: '8'));

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(body: SheetChartBuilderPanel()),
          ),
        ),
      );

      expect(
        find.byKey(
          const ValueKey('ky-sheet-sidebar-panel-surface-Chart Builder'),
        ),
        findsOneWidget,
      );
      expect(find.text('Chart Builder'), findsOneWidget);
      expect(find.text('Visualize selection'), findsOneWidget);
      expect(find.text('A1:C3'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('ky-sheet-chart-preview-canvas')),
        findsOneWidget,
      );
      expect(find.text('Revenue'), findsWidgets);
      expect(find.text('Cost'), findsWidgets);

      await tester.tap(find.text('Line'));
      await tester.pumpAndSettle();

      expect(container.read(sheetChartSpecProvider).type, SheetChartType.line);
    });
  });

  group('SheetFormulaAuditPanel', () {
    testWidgets('renders references and dependents with navigation', (
      tester,
    ) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(selectedCellProvider.notifier).state = CellSelection(
        CellAddress(0, 1),
      );
      container
          .read(sheetNamedRangesProvider.notifier)
          .save(
            name: 'Source_Block',
            selection: CellSelection(CellAddress(0, 0), CellAddress(1, 0)),
          );
      final sheet = container.read(spreadsheetProvider.notifier);
      sheet.updateCell(CellAddress(0, 0), CellData(value: '10'));
      sheet.updateCell(CellAddress(1, 0), CellData(value: '20'));
      sheet.updateCell(
        CellAddress(0, 1),
        CellData(value: '30.00', formula: '=SUM(Source_Block)'),
      );
      sheet.updateCell(
        CellAddress(0, 3),
        CellData(value: '60.00', formula: '=B1*2'),
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(body: SheetFormulaAuditPanel()),
          ),
        ),
      );

      expect(find.text('Formula Audit'), findsOneWidget);
      expect(find.text('Trace formulas'), findsOneWidget);
      expect(
        find.byKey(
          const ValueKey('ky-sheet-sidebar-panel-surface-Formula Audit'),
        ),
        findsOneWidget,
      );
      expect(find.text('=SUM(Source_Block)'), findsOneWidget);
      expect(find.text('A1:A2'), findsOneWidget);
      expect(find.text('D1'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('ky-sheet-trace-references')));
      await tester.pump();

      expect(
        container
            .read(formulaReferencePreviewProvider)
            .map((selection) => selection.label),
        ['A1:A2'],
      );
      expect(
        container.read(formulaReferencePreviewContextProvider)?.source,
        SheetFormulaPreviewSource.traceReferences,
      );
      expect(
        container.read(formulaReferencePreviewContextProvider)?.statusValue,
        'B1: 1 range',
      );
      expect(container.read(selectedCellProvider)?.label, 'B1');

      await tester.tap(find.byKey(const ValueKey('ky-sheet-trace-dependents')));
      await tester.pump();

      expect(
        container
            .read(formulaReferencePreviewProvider)
            .map((selection) => selection.label),
        ['D1'],
      );
      expect(
        container.read(formulaReferencePreviewContextProvider)?.source,
        SheetFormulaPreviewSource.traceDependents,
      );

      await tester.tap(find.byKey(const ValueKey('ky-sheet-trace-all')));
      await tester.pump();

      expect(
        container
            .read(formulaReferencePreviewProvider)
            .map((selection) => selection.label),
        ['A1:A2', 'D1'],
      );
      expect(
        container.read(formulaReferencePreviewContextProvider)?.source,
        SheetFormulaPreviewSource.traceAll,
      );
      expect(
        container.read(formulaReferencePreviewContextProvider)?.statusValue,
        'B1: 2 ranges',
      );

      await tester.tap(
        find.byKey(const ValueKey('ky-sheet-clear-formula-trace')),
      );
      await tester.pump();

      expect(container.read(formulaReferencePreviewProvider), isEmpty);
      expect(container.read(formulaReferencePreviewContextProvider), isNull);

      await tester.tap(find.text('D1'));
      await tester.pump();

      expect(container.read(selectedCellProvider)?.label, 'D1');
    });
  });

  group('StatusBar', () {
    testWidgets('status metric chip follows active density', (tester) async {
      const chipKey = ValueKey('ky-sheet-density-status-chip');

      Widget buildChip(SheetRibbonDensity density) {
        return MaterialApp(
          home: Scaffold(
            body: SheetRibbonDensityScope(
              density: density,
              child: const StatusMetricChip(
                key: chipKey,
                label: 'Range',
                value: 'A1:B2',
                icon: Icons.select_all,
                emphasized: true,
              ),
            ),
          ),
        );
      }

      await tester.pumpWidget(buildChip(SheetRibbonDensity.compact));
      await tester.pumpAndSettle();
      final compactChipSize = tester.getSize(find.byKey(chipKey));

      await tester.pumpWidget(buildChip(SheetRibbonDensity.comfortable));
      await tester.pumpAndSettle();
      final comfortableChipSize = tester.getSize(find.byKey(chipKey));

      expect(compactChipSize.height, lessThan(comfortableChipSize.height));
      expect(compactChipSize.width, lessThan(comfortableChipSize.width));
    });

    testWidgets('status metric chip invokes optional actions', (tester) async {
      var pressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatusMetricChip(
              key: const ValueKey('ky-sheet-action-status-chip'),
              label: 'Filters',
              value: '2 active',
              onPressed: () => pressed = true,
            ),
          ),
        ),
      );

      await tester.tap(
        find.byKey(const ValueKey('ky-sheet-action-status-chip')),
      );
      await tester.pump();

      expect(pressed, isTrue);
    });

    testWidgets('status metric section follows active density spacing', (
      tester,
    ) async {
      const firstKey = ValueKey('ky-sheet-density-status-first');
      const secondKey = ValueKey('ky-sheet-density-status-second');

      Widget buildSection(SheetRibbonDensity density) {
        return MaterialApp(
          home: Scaffold(
            body: SheetRibbonDensityScope(
              density: density,
              child: const StatusMetricSection(
                children: [
                  SizedBox(key: firstKey, width: 20, height: 10),
                  SizedBox(key: secondKey, width: 20, height: 10),
                ],
              ),
            ),
          ),
        );
      }

      await tester.pumpWidget(buildSection(SheetRibbonDensity.compact));
      await tester.pumpAndSettle();
      final compactGap =
          tester.getTopLeft(find.byKey(secondKey)).dx -
          tester.getTopRight(find.byKey(firstKey)).dx;

      await tester.pumpWidget(buildSection(SheetRibbonDensity.comfortable));
      await tester.pumpAndSettle();
      final comfortableGap =
          tester.getTopLeft(find.byKey(secondKey)).dx -
          tester.getTopRight(find.byKey(firstKey)).dx;

      expect(compactGap, lessThan(comfortableGap));
    });

    testWidgets('resolves compact density for narrow status bar widths', (
      tester,
    ) async {
      const zoomControlKey = ValueKey('ky-sheet-status-zoom-control');
      final container = ProviderContainer();
      addTearDown(container.dispose);
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      Widget buildStatusBar(double width) {
        return UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: Align(
                alignment: Alignment.topLeft,
                child: SizedBox(width: width, child: const StatusBar()),
              ),
            ),
          ),
        );
      }

      await tester.pumpWidget(buildStatusBar(520));
      await tester.pumpAndSettle();
      final compactZoomSize = tester.getSize(find.byKey(zoomControlKey));

      await tester.pumpWidget(buildStatusBar(980));
      await tester.pumpAndSettle();
      final comfortableZoomSize = tester.getSize(find.byKey(zoomControlKey));

      expect(compactZoomSize.width, lessThan(comfortableZoomSize.width));
    });

    testWidgets('renders workbook mode filter and sort indicators', (
      tester,
    ) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(workbookProvider.notifier).addSheet();
      container.read(editingCellProvider.notifier).state = CellAddress(0, 0);
      container.read(filterProvider.notifier).state = {0: 'paid'};
      container.read(sheetFilterRulesProvider.notifier).state = {
        1: const SheetFilterRule(operator: SheetFilterOperator.empty),
      };
      container.read(sortColumnProvider.notifier).state = 1;
      container.read(sortAscendingProvider.notifier).state = false;

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: Scaffold(body: StatusBar())),
        ),
      );

      expect(find.text('Mode'), findsOneWidget);
      expect(find.text('Editing A1'), findsOneWidget);
      expect(find.text('Sheet'), findsOneWidget);
      expect(find.text('2/2'), findsOneWidget);
      expect(find.text('Filters'), findsOneWidget);
      expect(find.text('2 active'), findsOneWidget);
      expect(find.text('Sort'), findsOneWidget);
      expect(find.text('B Z-A'), findsOneWidget);
      expect(
        find.byTooltip('Active sheet Sheet2 (2 of 2). Switch sheets'),
        findsOneWidget,
      );
      expect(
        find.byTooltip('2 active filters. Open Sort and Filter'),
        findsOneWidget,
      );
      expect(
        find.byTooltip('Sorted by column B descending. Open Sort and Filter'),
        findsOneWidget,
      );

      await tester.tap(find.text('Filters'));
      await tester.pump();
      expect(
        container.read(activeSidebarPanelProvider),
        SheetSidebarPanel.sortFilter,
      );

      container.read(activeSidebarPanelProvider.notifier).state = null;
      await tester.tap(find.text('Sort'));
      await tester.pump();
      expect(
        container.read(activeSidebarPanelProvider),
        SheetSidebarPanel.sortFilter,
      );

      container.read(activeSidebarPanelProvider.notifier).state = null;
      await tester.ensureVisible(find.text('Sheet'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sheet'));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('ky-sheet-status-sheet-sheet-1')),
      );
      await tester.pumpAndSettle();
      expect(container.read(workbookProvider).activeSheet.name, 'Sheet1');
    });

    testWidgets('shows active formula highlights and clears them', (
      tester,
    ) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(formulaReferencePreviewProvider.notifier).state = [
        CellSelection(CellAddress(0, 0), CellAddress(1, 0)),
      ];
      container
          .read(formulaReferencePreviewContextProvider.notifier)
          .state = const SheetFormulaPreviewContext(
        source: SheetFormulaPreviewSource.traceReferences,
        originLabel: 'B1',
        targetCount: 1,
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: Scaffold(body: StatusBar())),
        ),
      );

      expect(find.text('Trace References'), findsOneWidget);
      expect(find.text('B1: 1 range'), findsOneWidget);

      await tester.tap(
        find.byKey(const ValueKey('ky-sheet-clear-formula-highlight')),
      );
      await tester.pump();

      expect(container.read(formulaReferencePreviewProvider), isEmpty);
      expect(container.read(formulaReferencePreviewContextProvider), isNull);
    });

    testWidgets('updates zoom from the bottom status control', (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: Scaffold(body: StatusBar())),
        ),
      );

      expect(
        find.byKey(const ValueKey('ky-sheet-status-zoom-control')),
        findsOneWidget,
      );
      expect(find.text('100%'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('ky-sheet-status-zoom-in')));
      await tester.pumpAndSettle();

      expect(container.read(zoomLevelProvider), greaterThan(1));

      await tester.tap(find.byKey(const ValueKey('ky-sheet-status-zoom-out')));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('ky-sheet-status-zoom-reset')),
      );
      await tester.pumpAndSettle();

      expect(container.read(zoomLevelProvider), 1);
      expect(find.text('100%'), findsOneWidget);
    });
  });

  group('SheetFormulaHealthPanel', () {
    testWidgets('renders formula issues and navigates to selected issue', (
      tester,
    ) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      String? clipboardText;
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
        if (call.method == 'Clipboard.setData') {
          final data = Map<String, Object?>.from(call.arguments as Map);
          clipboardText = data['text'] as String?;
        }
        return null;
      });
      addTearDown(
        () => messenger.setMockMethodCallHandler(SystemChannels.platform, null),
      );
      final sheet = container.read(spreadsheetProvider.notifier);
      sheet.updateCell(
        CellAddress(0, 0),
        CellData(value: '2.00', formula: '=1+1'),
      );
      sheet.updateCell(
        CellAddress(0, 1),
        CellData(value: '#DIV/0', formula: '=A1/0'),
      );
      sheet.updateCell(
        CellAddress(0, 3),
        CellData(value: '#NAME', formula: '=Missing_Name'),
      );
      sheet.updateCell(
        CellAddress(0, 2),
        CellData(value: '1.00', formula: '=C1+1'),
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(body: SheetFormulaHealthPanel()),
          ),
        ),
      );

      expect(find.text('Formula Health'), findsOneWidget);
      expect(find.text('Find formula issues'), findsOneWidget);
      expect(
        find.byKey(
          const ValueKey('ky-sheet-sidebar-panel-surface-Formula Health'),
        ),
        findsOneWidget,
      );
      expect(find.text('Formulas'), findsOneWidget);
      expect(find.text('Issues'), findsOneWidget);
      expect(find.text('B1'), findsWidgets);
      expect(find.text('#DIV/0'), findsWidgets);
      expect(find.text('C1'), findsWidgets);
      expect(find.text('#CYCLE'), findsWidgets);
      expect(find.text('Circular reference'), findsOneWidget);
      expect(find.text('D1'), findsOneWidget);
      expect(find.text('Circular 1'), findsOneWidget);
      expect(find.text('Division 1'), findsOneWidget);
      expect(find.text('Name 1'), findsOneWidget);
      expect(find.text('Showing 3 issues'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('ky-sheet-formula-health-view-reset')),
        findsNothing,
      );
      expect(find.text('Issue 1 of 3'), findsOneWidget);
      expect(find.text('Selected Issue'), findsOneWidget);
      expect(find.text('=A1/0'), findsOneWidget);
      expect(find.text('Check the denominator'), findsOneWidget);
      expect(find.text('Trace denominator references: A1.'), findsOneWidget);
      expect(
        find.text('A formula is dividing by zero or a blank value.'),
        findsOneWidget,
      );

      await tester.tap(
        find.descendant(
          of: find.byKey(
            const ValueKey('ky-sheet-formula-health-sort-control'),
          ),
          matching: find.text('Type'),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        container.read(sheetFormulaHealthSortModeProvider),
        SheetFormulaIssueSortMode.code,
      );
      expect(container.read(sheetFormulaHealthFocusedIssueIndexProvider), 0);
      expect(find.text('Issue 1 of 3'), findsOneWidget);
      expect(find.text('=C1+1'), findsOneWidget);
      expect(find.text('Sort: Type'), findsOneWidget);

      await tester.tap(
        find.byKey(const ValueKey('ky-sheet-formula-health-view-reset')),
      );
      await tester.pumpAndSettle();

      expect(
        container.read(sheetFormulaHealthSortModeProvider),
        SheetFormulaIssueSortMode.cell,
      );
      expect(
        find.byKey(const ValueKey('ky-sheet-formula-health-view-reset')),
        findsNothing,
      );
      expect(find.text('Sort: Type'), findsNothing);
      expect(find.text('=A1/0'), findsOneWidget);

      await tester.enterText(
        find.byKey(const ValueKey('ky-sheet-formula-health-search')),
        'missing',
      );
      await tester.pumpAndSettle();

      expect(container.read(sheetFormulaHealthSearchQueryProvider), 'missing');
      expect(container.read(sheetFormulaHealthFocusedIssueIndexProvider), 0);
      expect(find.text('Showing 1 of 3 issues'), findsOneWidget);
      expect(find.text('Search: missing'), findsOneWidget);
      expect(find.text('D1'), findsWidgets);
      expect(find.text('B1'), findsNothing);
      expect(find.text('C1'), findsNothing);

      await tester.tap(
        find.byKey(const ValueKey('ky-sheet-formula-health-search-clear')),
      );
      await tester.pumpAndSettle();

      expect(container.read(sheetFormulaHealthSearchQueryProvider), '');
      expect(find.text('Search: missing'), findsNothing);
      expect(find.text('Showing 3 issues'), findsOneWidget);
      expect(find.text('Issue 1 of 3'), findsOneWidget);

      await tester.tap(
        find.byKey(const ValueKey('ky-sheet-formula-health-next-issue')),
      );
      await tester.pump();

      expect(container.read(sheetFormulaHealthFocusedIssueIndexProvider), 1);
      expect(container.read(selectedCellProvider)?.label, 'C1');
      expect(
        container
            .read(formulaReferencePreviewProvider)
            .map((selection) => selection.label),
        ['C1'],
      );
      expect(
        container.read(formulaReferencePreviewContextProvider)?.statusValue,
        'C1: 1 range',
      );
      expect(find.text('Issue 2 of 3'), findsOneWidget);
      expect(find.text('=C1+1'), findsOneWidget);
      expect(find.text('Break the dependency loop'), findsOneWidget);
      expect(
        find.text('This formula participates in a circular dependency.'),
        findsOneWidget,
      );

      await tester.tap(
        find.byKey(const ValueKey('ky-sheet-formula-health-previous-issue')),
      );
      await tester.pump();

      expect(container.read(sheetFormulaHealthFocusedIssueIndexProvider), 0);
      expect(container.read(selectedCellProvider)?.label, 'B1');
      expect(
        container
            .read(formulaReferencePreviewProvider)
            .map((selection) => selection.label),
        ['B1', 'A1'],
      );
      expect(
        container.read(formulaReferencePreviewContextProvider)?.statusValue,
        'B1: 2 ranges',
      );
      expect(find.text('Issue 1 of 3'), findsOneWidget);
      expect(find.text('=A1/0'), findsOneWidget);

      await tester.ensureVisible(
        find.byKey(const ValueKey('ky-sheet-copy-selected-formula-issue')),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('ky-sheet-copy-selected-formula-issue')),
      );
      await tester.pump();

      expect(
        clipboardText,
        'Cell\tCode\tTitle\tFormula\tSuggestion\tNext Check\tAdditional Checks\n'
        'B1\t#DIV/0\tDivision by zero\t=A1/0\tCheck denominators and referenced blank cells.\t'
        'Trace denominator references: A1.\t'
        'Look for zero, blank, or text values where the divisor is expected. | '
        'Use IF to guard the division once the source data is understood.',
      );
      expect(find.text('Copied B1 formula issue'), findsOneWidget);
      ScaffoldMessenger.of(
        tester.element(find.byType(SheetFormulaHealthPanel)),
      ).clearSnackBars();
      await tester.pumpAndSettle();

      await tester.drag(find.byType(ListView), const Offset(0, 1600));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('ky-sheet-formula-health-filter-#CYCLE')),
      );
      await tester.pumpAndSettle();

      expect(find.text('Type: Circular (#CYCLE)'), findsOneWidget);
      expect(find.text('Showing 1 of 3 issues'), findsOneWidget);
      expect(find.text('C1'), findsWidgets);
      expect(find.text('B1'), findsNothing);
      expect(find.text('D1'), findsNothing);
      expect(find.text('Issue 1 of 1'), findsOneWidget);

      await tester.tap(
        find.byKey(const ValueKey('ky-sheet-formula-health-next-issue')),
      );
      await tester.pump();

      expect(container.read(sheetFormulaHealthFocusedIssueIndexProvider), 0);
      expect(container.read(selectedCellProvider)?.label, 'C1');

      await tester.ensureVisible(
        find.byKey(const ValueKey('ky-sheet-copy-visible-formula-issues')),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('ky-sheet-copy-visible-formula-issues')),
      );
      await tester.pump();

      expect(
        clipboardText,
        'Cell\tCode\tTitle\tFormula\tSuggestion\tNext Check\tAdditional Checks\n'
        'C1\t#CYCLE\tCircular reference\t=C1+1\tBreak the loop: C1 -> C1.\t'
        'Trace the related cells and find which formula points back to C1.\t'
        'Move one dependency into an input cell or replace one circular reference. | '
        'Recalculate after each change to confirm the loop is gone.',
      );
      expect(find.text('Copied 1 visible formula issue'), findsOneWidget);
      ScaffoldMessenger.of(
        tester.element(find.byType(SheetFormulaHealthPanel)),
      ).clearSnackBars();
      await tester.pumpAndSettle();

      await tester.ensureVisible(
        find.byKey(const ValueKey('ky-sheet-trace-visible-formula-issues')),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('ky-sheet-trace-visible-formula-issues')),
      );
      await tester.pump();

      expect(
        container
            .read(formulaReferencePreviewProvider)
            .map((selection) => selection.label),
        ['C1'],
      );
      expect(
        container.read(formulaReferencePreviewContextProvider)?.source,
        SheetFormulaPreviewSource.formulaIssues,
      );
      expect(
        container.read(formulaReferencePreviewContextProvider)?.statusValue,
        '#CYCLE: 1 range',
      );

      await tester.drag(find.byType(ListView), const Offset(0, 1600));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('ky-sheet-formula-health-filter-clear')),
      );
      await tester.pumpAndSettle();

      expect(find.text('Type: Circular (#CYCLE)'), findsNothing);
      expect(find.text('B1'), findsWidgets);
      expect(find.text('D1'), findsOneWidget);

      await tester.ensureVisible(
        find.byKey(const ValueKey('ky-sheet-trace-formula-issue-C1')),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('ky-sheet-trace-formula-issue-C1')),
      );
      await tester.pump();

      expect(
        container
            .read(formulaReferencePreviewProvider)
            .map((selection) => selection.label),
        ['C1'],
      );
      expect(
        container.read(formulaReferencePreviewContextProvider)?.source,
        SheetFormulaPreviewSource.formulaIssue,
      );
      expect(
        container.read(formulaReferencePreviewContextProvider)?.statusValue,
        'C1: 1 range',
      );

      await tester.ensureVisible(
        find.byKey(const ValueKey('ky-sheet-formula-issue-tile-B1')),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('ky-sheet-formula-issue-tile-B1')),
      );
      await tester.pump();

      expect(container.read(selectedCellProvider)?.label, 'B1');
      expect(
        container
            .read(formulaReferencePreviewProvider)
            .map((selection) => selection.label),
        ['B1', 'A1'],
      );
      expect(
        container.read(formulaReferencePreviewContextProvider)?.source,
        SheetFormulaPreviewSource.formulaIssue,
      );
      expect(
        container.read(formulaReferencePreviewContextProvider)?.statusValue,
        'B1: 2 ranges',
      );
    });
  });

  group('SheetGoToSpecialPanel', () {
    testWidgets('switches match kinds and navigates to a match', (
      tester,
    ) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final sheet = container.read(spreadsheetProvider.notifier);
      sheet.updateCell(CellAddress(0, 0), CellData(value: 'Name'));
      sheet.updateCell(
        CellAddress(0, 1),
        CellData(value: '#DIV/0', formula: '=A1/0'),
      );
      sheet.updateCell(
        CellAddress(1, 0),
        CellData(value: '', comment: 'Needs owner'),
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(body: SheetGoToSpecialPanel()),
          ),
        ),
      );

      expect(
        find.byKey(
          const ValueKey('ky-sheet-sidebar-panel-surface-Go To Special'),
        ),
        findsOneWidget,
      );
      expect(find.text('Go To Special'), findsOneWidget);
      expect(find.text('Find cells by type'), findsOneWidget);
      expect(find.text('B1'), findsOneWidget);

      await tester.tap(
        find.byType(DropdownButtonFormField<SheetGoToSpecialKind>),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Comments').last);
      await tester.pumpAndSettle();

      expect(find.text('A2'), findsOneWidget);
      expect(find.text('Needs owner'), findsOneWidget);

      await tester.tap(find.text('A2'));
      await tester.pump();

      expect(container.read(selectedCellProvider)?.label, 'A2');
    });
  });

  group('SheetNamedRangesPanel', () {
    testWidgets('creates, navigates to, and removes named ranges', (
      tester,
    ) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(selectedCellProvider.notifier).state = CellSelection(
        CellAddress(0, 0),
        CellAddress(1, 1),
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(body: SheetNamedRangesPanel()),
          ),
        ),
      );

      expect(
        find.byKey(
          const ValueKey('ky-sheet-sidebar-panel-surface-Named Ranges'),
        ),
        findsOneWidget,
      );
      expect(find.text('Named Ranges'), findsOneWidget);
      expect(find.text('Reusable ranges'), findsOneWidget);
      expect(find.text('A1:B2'), findsWidgets);

      await tester.enterText(
        find.byKey(const ValueKey('ky-sheet-named-range-name')),
        'Revenue_Block',
      );
      await tester.tap(find.byKey(const ValueKey('ky-sheet-named-range-save')));
      await tester.pumpAndSettle();

      final saved = container.read(sheetNamedRangesProvider).single;
      expect(saved.name, 'Revenue_Block');
      expect(find.text('Revenue_Block'), findsWidgets);

      container.read(selectedCellProvider.notifier).state = CellSelection(
        CellAddress(5, 5),
      );
      await tester.pump();

      await tester.tap(
        find.byKey(ValueKey('ky-sheet-named-range-go-${saved.id}')),
      );
      await tester.pump();

      expect(container.read(selectedCellProvider)?.label, 'A1:B2');

      await tester.tap(
        find.byKey(ValueKey('ky-sheet-named-range-delete-${saved.id}')),
      );
      await tester.pump();

      expect(container.read(sheetNamedRangesProvider), isEmpty);
      expect(find.text('No named ranges yet'), findsOneWidget);
    });
  });

  group('SheetCellInspectorPanel', () {
    testWidgets('updates content and metadata for the selected cell', (
      tester,
    ) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(selectedCellProvider.notifier).state = CellSelection(
        CellAddress(0, 0),
      );
      container
          .read(spreadsheetProvider.notifier)
          .updateCell(
            CellAddress(0, 0),
            CellData(
              value: 'Initial',
              style: const CellStyle(
                bold: true,
                numberFormat: SheetNumberFormatId.currency,
              ),
              validation: CellValidation(type: ValidationType.email),
              comment: 'Old comment',
              hyperlink: 'https://old.example',
            ),
          );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(body: SheetCellInspectorPanel()),
          ),
        ),
      );

      expect(find.text('Cell Inspector'), findsOneWidget);
      expect(find.text('A1'), findsWidgets);
      expect(find.text('Email address'), findsOneWidget);
      expect(find.text('Bold'), findsOneWidget);

      await tester.enterText(
        find.byKey(const ValueKey('ky-sheet-inspector-value')),
        'updated@example.com',
      );
      await tester.tap(
        find.byKey(const ValueKey('ky-sheet-inspector-save-content')),
      );
      await tester.pump();

      expect(
        container.read(spreadsheetProvider)[CellAddress(0, 0)]?.value,
        'updated@example.com',
      );

      await tester.ensureVisible(
        find.byKey(const ValueKey('ky-sheet-inspector-comment')),
      );
      await tester.enterText(
        find.byKey(const ValueKey('ky-sheet-inspector-comment')),
        'Review this',
      );
      await tester.enterText(
        find.byKey(const ValueKey('ky-sheet-inspector-hyperlink')),
        'https://example.com',
      );
      await tester.tap(
        find.byKey(const ValueKey('ky-sheet-inspector-save-metadata')),
      );
      await tester.pump();

      expect(
        container.read(spreadsheetProvider)[CellAddress(0, 0)]?.comment,
        'Review this',
      );
      expect(
        container.read(spreadsheetProvider)[CellAddress(0, 0)]?.hyperlink,
        'https://example.com',
      );

      await tester.tap(
        find.byKey(const ValueKey('ky-sheet-inspector-clear-metadata')),
      );
      await tester.pump();

      expect(
        container.read(spreadsheetProvider)[CellAddress(0, 0)]?.comment,
        isNull,
      );
      expect(
        container.read(spreadsheetProvider)[CellAddress(0, 0)]?.hyperlink,
        isNull,
      );
    });

    testWidgets('surfaces formula errors for the selected cell', (
      tester,
    ) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(selectedCellProvider.notifier).state = CellSelection(
        CellAddress(0, 0),
      );
      container
          .read(spreadsheetProvider.notifier)
          .updateCell(
            CellAddress(0, 0),
            CellData(value: '#DIV/0', formula: '=A1/0'),
          );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(body: SheetCellInspectorPanel()),
          ),
        ),
      );

      expect(find.text('Division by zero #DIV/0'), findsOneWidget);
      expect(
        find.text('A formula is dividing by zero or a blank value.'),
        findsOneWidget,
      );
      expect(
        find.text('Check denominators and referenced blank cells.'),
        findsOneWidget,
      );
    });
  });

  group('SheetDataInsightsPanel', () {
    testWidgets('renders profile metrics for the selected range', (
      tester,
    ) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(selectedCellProvider.notifier).state = CellSelection(
        CellAddress(0, 0),
        CellAddress(1, 1),
      );
      container
          .read(spreadsheetProvider.notifier)
          .updateCell(CellAddress(0, 0), CellData(value: '10'));
      container
          .read(spreadsheetProvider.notifier)
          .updateCell(CellAddress(1, 0), CellData(value: '20'));
      container
          .read(spreadsheetProvider.notifier)
          .updateCell(CellAddress(0, 1), CellData(value: 'East'));
      container
          .read(spreadsheetProvider.notifier)
          .updateCell(CellAddress(1, 1), CellData(value: 'East'));

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(body: SheetDataInsightsPanel()),
          ),
        ),
      );

      expect(
        find.byKey(
          const ValueKey('ky-sheet-sidebar-panel-surface-Data Insights'),
        ),
        findsOneWidget,
      );
      expect(find.text('Data Insights'), findsOneWidget);
      expect(find.text('Profile selected data'), findsOneWidget);
      expect(find.text('A1:B2'), findsOneWidget);
      expect(find.text('Filled'), findsWidgets);
      expect(find.text('4/4'), findsOneWidget);
      expect(find.text('Numeric Summary'), findsOneWidget);

      await tester.drag(find.byType(ListView), const Offset(0, -360));
      await tester.pumpAndSettle();

      expect(find.text('Top Values'), findsOneWidget);
      expect(find.text('East'), findsOneWidget);

      await tester.tap(find.text('East'));
      await tester.pumpAndSettle();

      expect(container.read(selectedCellProvider)?.start, CellAddress(0, 1));
    });
  });

  group('SheetFindReplacePanel', () {
    testWidgets('selects and replaces the current match', (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container
          .read(spreadsheetProvider.notifier)
          .updateCell(CellAddress(0, 0), CellData(value: 'alpha beta'));
      container
          .read(spreadsheetProvider.notifier)
          .updateCell(CellAddress(1, 0), CellData(value: 'beta gamma'));

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(body: SheetFindReplacePanel()),
          ),
        ),
      );

      expect(
        find.byKey(
          const ValueKey('ky-sheet-sidebar-panel-surface-Find & Replace'),
        ),
        findsOneWidget,
      );
      expect(find.text('Find & Replace'), findsOneWidget);
      expect(find.text('Search and replace'), findsOneWidget);

      await tester.enterText(
        find.byKey(const ValueKey('ky-sheet-find-input')),
        'beta',
      );
      await tester.enterText(
        find.byKey(const ValueKey('ky-sheet-replace-input')),
        'done',
      );
      await tester.pumpAndSettle();

      expect(find.text('A1'), findsOneWidget);
      expect(find.text('A2'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('ky-sheet-replace-current')));
      await tester.pumpAndSettle();

      expect(
        container.read(spreadsheetProvider)[CellAddress(0, 0)]?.value,
        'alpha done',
      );
      expect(
        container.read(spreadsheetProvider)[CellAddress(1, 0)]?.value,
        'beta gamma',
      );
      expect(container.read(selectedCellProvider)?.start, CellAddress(0, 0));
    });

    testWidgets('focuses the requested find or replace input', (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(findReplaceFocusTargetProvider.notifier).state =
          SheetFindReplaceFocusTarget.replace;

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(body: SheetFindReplacePanel()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      TextField replaceField() {
        return tester.widget<TextField>(
          find.byKey(const ValueKey('ky-sheet-replace-input')),
        );
      }

      TextField findField() {
        return tester.widget<TextField>(
          find.byKey(const ValueKey('ky-sheet-find-input')),
        );
      }

      expect(replaceField().focusNode?.hasFocus, isTrue);
      expect(container.read(findReplaceFocusTargetProvider), isNull);

      container.read(findReplaceFocusTargetProvider.notifier).state =
          SheetFindReplaceFocusTarget.find;
      await tester.pumpAndSettle();

      expect(findField().focusNode?.hasFocus, isTrue);
      expect(container.read(findReplaceFocusTargetProvider), isNull);
    });
  });

  group('SheetDataValidationPanel', () {
    testWidgets('applies and clears list validation for the selection', (
      tester,
    ) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(selectedCellProvider.notifier).state = CellSelection(
        CellAddress(0, 0),
        CellAddress(0, 1),
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(body: SheetDataValidationPanel()),
          ),
        ),
      );

      await tester.tap(find.byType(DropdownButtonFormField<ValidationType>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Dropdown List').last);
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('ky-sheet-validation-options')),
        'Open, Closed',
      );
      await tester.tap(find.byKey(const ValueKey('ky-sheet-validation-apply')));
      await tester.pump();

      expect(
        container
            .read(spreadsheetProvider)[CellAddress(0, 0)]
            ?.validation
            ?.type,
        ValidationType.list,
      );
      expect(
        container
            .read(spreadsheetProvider)[CellAddress(0, 1)]
            ?.validation
            ?.options,
        ['Open', 'Closed'],
      );

      await tester.tap(find.byKey(const ValueKey('ky-sheet-validation-clear')));
      await tester.pump();

      expect(
        container.read(spreadsheetProvider)[CellAddress(0, 0)]?.validation,
        isNull,
      );
      expect(
        container.read(spreadsheetProvider)[CellAddress(0, 1)]?.validation,
        isNull,
      );
    });
  });

  group('SheetWorkbookShortcuts', () {
    testWidgets('switches visible sheets from workbook keyboard shortcuts', (
      tester,
    ) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final workbook = container.read(workbookProvider.notifier);
      final firstSheetId = container.read(workbookProvider).activeSheetId;
      workbook.addSheet();
      final secondSheetId = container.read(workbookProvider).activeSheetId;
      workbook.addSheet();
      final thirdSheetId = container.read(workbookProvider).activeSheetId;
      workbook.hideSheet(secondSheetId);
      workbook.switchToSheet(firstSheetId);

      var commandPaletteOpenCount = 0;
      var findReplaceOpenCount = 0;
      var replaceOpenCount = 0;
      var sortFilterOpenCount = 0;
      var shortcutsOpenCount = 0;
      var closePanelCount = 0;
      var hasOpenPanel = true;

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: SheetWorkbookShortcuts(
                onOpenFindReplace: () => findReplaceOpenCount += 1,
                onOpenReplace: () => replaceOpenCount += 1,
                onOpenSortFilter: () => sortFilterOpenCount += 1,
                onOpenCommandPalette: () => commandPaletteOpenCount += 1,
                onOpenShortcuts: () => shortcutsOpenCount += 1,
                onCloseActivePanel: () {
                  if (!hasOpenPanel) return false;
                  hasOpenPanel = false;
                  closePanelCount += 1;
                  return true;
                },
                onPreviousSheet: () => container
                    .read(workbookProvider.notifier)
                    .switchToAdjacentVisibleSheet(-1),
                onNextSheet: () => container
                    .read(workbookProvider.notifier)
                    .switchToAdjacentVisibleSheet(1),
                child: const SizedBox.expand(),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.pageDown);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pump();

      expect(container.read(workbookProvider).activeSheetId, thirdSheetId);

      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.pageDown);
      await tester.sendKeyEvent(LogicalKeyboardKey.pageUp);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pump();

      expect(container.read(workbookProvider).activeSheetId, thirdSheetId);

      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyK);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pump();

      expect(commandPaletteOpenCount, 1);

      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyF);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pump();

      expect(findReplaceOpenCount, 1);

      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyH);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pump();

      expect(replaceOpenCount, 1);

      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyL);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pump();

      expect(sortFilterOpenCount, 1);

      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.slash);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pump();

      expect(shortcutsOpenCount, 1);

      await tester.sendKeyEvent(LogicalKeyboardKey.f1);
      await tester.pump();

      expect(shortcutsOpenCount, 2);

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pump();

      expect(closePanelCount, 1);
    });
  });

  group('SheetTabsBar', () {
    testWidgets('adds a new sheet from the tab footer', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: Scaffold(body: SheetTabsBar())),
        ),
      );

      expect(find.text('Sheet1'), findsOneWidget);

      await tester.tap(find.byTooltip('Add Sheet'));
      await tester.pumpAndSettle();

      expect(find.text('Sheet2'), findsOneWidget);
    });

    testWidgets('switches sheets from the tab navigator menu', (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final workbook = container.read(workbookProvider.notifier);
      final firstSheetId = container.read(workbookProvider).activeSheetId;
      container
          .read(spreadsheetProvider.notifier)
          .updateCellValue(CellAddress(0, 0), 'First');

      workbook.addSheet();
      final secondSheetId = container.read(workbookProvider).activeSheetId;
      container
          .read(spreadsheetProvider.notifier)
          .updateCellValue(CellAddress(0, 0), 'Second');

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: Scaffold(body: SheetTabsBar())),
        ),
      );

      expect(
        find.byKey(const ValueKey('ky-sheet-tabs-navigator')),
        findsOneWidget,
      );
      expect(find.byTooltip('All Sheets: 2 sheets'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('ky-sheet-tabs-navigator-count')),
        findsOneWidget,
      );
      expect(find.byType(SheetNavigatorDialog), findsNothing);
      expect(
        container.read(spreadsheetProvider)[CellAddress(0, 0)]?.value,
        'Second',
      );

      await tester.tap(find.byKey(const ValueKey('ky-sheet-tabs-navigator')));
      await tester.pumpAndSettle();
      expect(find.byType(SheetNavigatorDialog), findsOneWidget);
      expect(find.byType(WorkbookSheetMenuItem), findsNWidgets(2));
      await tester.tap(
        find.byKey(ValueKey('ky-sheet-tabs-navigator-$firstSheetId')),
      );
      await tester.pumpAndSettle();

      expect(container.read(workbookProvider).activeSheetId, firstSheetId);
      expect(
        container.read(spreadsheetProvider)[CellAddress(0, 0)]?.value,
        'First',
      );

      await tester.tap(find.byKey(const ValueKey('ky-sheet-tabs-navigator')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('ky-sheet-navigator-search')),
        'sheet2',
      );
      await tester.pumpAndSettle();
      expect(find.byType(WorkbookSheetMenuItem), findsOneWidget);

      await tester.enterText(
        find.byKey(const ValueKey('ky-sheet-navigator-search')),
        'sheet',
      );
      await tester.pumpAndSettle();
      expect(find.byType(WorkbookSheetMenuItem), findsNWidgets(2));

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();

      expect(container.read(workbookProvider).activeSheetId, secondSheetId);
      expect(
        container.read(spreadsheetProvider)[CellAddress(0, 0)]?.value,
        'Second',
      );
    });

    testWidgets('shows recent sheets in the tab navigator', (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final workbook = container.read(workbookProvider.notifier);
      final firstSheetId = container.read(workbookProvider).activeSheetId;
      workbook.addSheet();
      final secondSheetId = container.read(workbookProvider).activeSheetId;
      workbook.addSheet();
      final thirdSheetId = container.read(workbookProvider).activeSheetId;
      workbook.switchToSheet(firstSheetId);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: Scaffold(body: SheetTabsBar())),
        ),
      );

      await tester.tap(find.byKey(const ValueKey('ky-sheet-tabs-navigator')));
      await tester.pumpAndSettle();

      expect(find.text('Recent'), findsOneWidget);
      expect(find.text('All'), findsOneWidget);
      expect(
        find.byKey(ValueKey('ky-sheet-tabs-navigator-$thirdSheetId')),
        findsOneWidget,
      );

      final recentSheetTop = tester.getTopLeft(
        find.byKey(ValueKey('ky-sheet-tabs-navigator-$thirdSheetId')),
      );
      final activeSheetTop = tester.getTopLeft(
        find.byKey(ValueKey('ky-sheet-tabs-navigator-$firstSheetId')),
      );
      expect(recentSheetTop.dy, lessThan(activeSheetTop.dy));

      await tester.tap(
        find.byKey(ValueKey('ky-sheet-tabs-navigator-$thirdSheetId')),
      );
      await tester.pumpAndSettle();

      expect(container.read(workbookProvider).activeSheetId, thirdSheetId);
      expect(container.read(recentWorkbookSheetIdsProvider), [
        thirdSheetId,
        firstSheetId,
        secondSheetId,
      ]);
    });

    testWidgets('keeps keyboard-highlighted navigator result visible', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(640, 360);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final sheets = [
        for (var index = 0; index < 18; index += 1)
          WorkbookSheet(id: 'sheet-${index + 1}', name: 'Sheet${index + 1}'),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SheetNavigatorDialog(
              sheets: sheets,
              activeSheetId: sheets.first.id,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      for (var index = 0; index < 11; index += 1) {
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      }
      await tester.pumpAndSettle();

      final resultsRect = tester.getRect(
        find.byKey(const ValueKey('ky-sheet-navigator-results')),
      );
      final highlightedRect = tester.getRect(
        find.byKey(const ValueKey('ky-sheet-tabs-navigator-sheet-12')),
      );

      expect(highlightedRect.top, greaterThanOrEqualTo(resultsRect.top - 1));
      expect(highlightedRect.bottom, lessThanOrEqualTo(resultsRect.bottom + 1));
    });

    testWidgets('searches the sheet navigator by sheet position', (
      tester,
    ) async {
      final names = [
        'Overview',
        'Revenue',
        'Costs',
        'Payroll',
        'Inventory',
        'Forecast',
        'Pipeline',
        'Taxes',
        'Cashflow',
        'Summary',
        'Archive',
        'Board Pack',
      ];
      final sheets = [
        for (final entry in names.indexed)
          WorkbookSheet(id: 'sheet-${entry.$1 + 1}', name: entry.$2),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SheetNavigatorDialog(
              sheets: sheets,
              activeSheetId: sheets.first.id,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      for (final query in ['#12', 's12', 'sheet 12', 'tab 12']) {
        await tester.enterText(
          find.byKey(const ValueKey('ky-sheet-navigator-search')),
          query,
        );
        await tester.pumpAndSettle();

        expect(find.byType(WorkbookSheetMenuItem), findsOneWidget);
        expect(find.text('Board Pack'), findsOneWidget);
        expect(find.text('Overview'), findsNothing);
      }
    });

    testWidgets('keeps active sheet visible in an overflowed tab strip', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(520, 220);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final container = ProviderContainer();
      addTearDown(container.dispose);

      final workbook = container.read(workbookProvider.notifier);
      final firstSheetId = container.read(workbookProvider).activeSheetId;
      for (var i = 0; i < 8; i += 1) {
        workbook.addSheet();
      }

      final lastSheetId = container.read(workbookProvider).activeSheetId;

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: Scaffold(body: SheetTabsBar())),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('ky-sheet-tabs-overflow-start-fade')),
        findsOneWidget,
      );
      expect(
        find.byKey(
          const ValueKey('ky-sheet-tabs-overflow-scroll-previous-control'),
        ),
        findsOneWidget,
      );

      await tester.tap(
        find.byKey(
          const ValueKey('ky-sheet-tabs-overflow-scroll-previous-control'),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('ky-sheet-tabs-overflow-end-fade')),
        findsOneWidget,
      );

      container.read(workbookProvider.notifier).switchToSheet(firstSheetId);
      await tester.pumpAndSettle();

      expect(container.read(workbookProvider).activeSheetId, firstSheetId);
      expect(
        find.byKey(const ValueKey('ky-sheet-tabs-overflow-start-fade')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('ky-sheet-tabs-overflow-end-fade')),
        findsOneWidget,
      );

      container.read(workbookProvider.notifier).switchToSheet(lastSheetId);
      await tester.pumpAndSettle();

      expect(container.read(workbookProvider).activeSheetId, lastSheetId);
      expect(
        find.byKey(const ValueKey('ky-sheet-tabs-overflow-start-fade')),
        findsOneWidget,
      );
    });

    testWidgets('confirms before deleting a sheet tab', (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final workbook = container.read(workbookProvider.notifier);
      workbook.addSheet();
      final secondSheetId = container.read(workbookProvider).activeSheetId;

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: Scaffold(body: SheetTabsBar())),
        ),
      );

      expect(container.read(workbookProvider).sheets, hasLength(2));

      await tester.tap(
        find.byKey(ValueKey('ky-sheet-tab-actions-$secondSheetId')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete').last);
      await tester.pumpAndSettle();

      expect(find.text('Delete Sheet'), findsOneWidget);
      expect(find.textContaining('Sheet2'), findsWidgets);

      await tester.tap(
        find.byKey(const ValueKey('ky-sheet-delete-sheet-cancel')),
      );
      await tester.pumpAndSettle();

      expect(container.read(workbookProvider).sheets, hasLength(2));

      await tester.tap(
        find.byKey(ValueKey('ky-sheet-tab-actions-$secondSheetId')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete').last);
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('ky-sheet-delete-sheet-confirm')),
      );
      await tester.pumpAndSettle();

      expect(container.read(workbookProvider).sheets, hasLength(1));
      expect(
        container
            .read(workbookProvider)
            .sheets
            .any((sheet) => sheet.id == secondSheetId),
        isFalse,
      );
    });

    testWidgets('renames a sheet tab inline from double tap', (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final sheetId = container.read(workbookProvider).activeSheetId;

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: Scaffold(body: SheetTabsBar())),
        ),
      );

      final tabFinder = find.byKey(ValueKey('ky-sheet-tab-$sheetId'));
      await tester.tap(tabFinder);
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tap(tabFinder);
      await tester.pumpAndSettle();

      expect(find.byKey(ValueKey('ky-sheet-tab-rename-$sheetId')), findsOne);
      expect(find.text('Rename Sheet'), findsNothing);

      await tester.enterText(
        find.byKey(ValueKey('ky-sheet-tab-rename-$sheetId')),
        'Forecast',
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();

      expect(container.read(workbookProvider).activeSheet.name, 'Forecast');
      expect(find.text('Forecast'), findsOneWidget);
    });

    testWidgets('opens sheet actions from a sheet tab secondary tap', (
      tester,
    ) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final workbook = container.read(workbookProvider.notifier);
      final firstSheetId = container.read(workbookProvider).activeSheetId;
      workbook.addSheet();
      final secondSheetId = container.read(workbookProvider).activeSheetId;

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: Scaffold(body: SheetTabsBar())),
        ),
      );

      expect(container.read(workbookProvider).activeSheetId, secondSheetId);

      await tester.tap(
        find.byKey(ValueKey('ky-sheet-tab-$firstSheetId')),
        buttons: kSecondaryButton,
      );
      await tester.pumpAndSettle();

      expect(find.text('Duplicate'), findsOneWidget);

      await tester.tap(find.text('Duplicate'));
      await tester.pumpAndSettle();

      expect(container.read(workbookProvider).sheets, hasLength(3));
      expect(container.read(workbookProvider).activeSheet.name, 'Sheet1 Copy');
    });

    testWidgets('sets and clears sheet tab color from the tab menu', (
      tester,
    ) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final sheetId = container.read(workbookProvider).activeSheetId;

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: Scaffold(body: SheetTabsBar())),
        ),
      );

      await tester.tap(find.byKey(ValueKey('ky-sheet-tab-actions-$sheetId')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tab Color'));
      await tester.pumpAndSettle();

      expect(find.byType(SheetTabColorDialog), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('ky-sheet-tab-color-green')));
      await tester.pumpAndSettle();

      expect(
        container.read(workbookProvider).activeSheet.tabColor,
        const Color(0xFF16A34A),
      );
      expect(
        find.byKey(ValueKey('ky-sheet-tab-color-indicator-$sheetId')),
        findsOneWidget,
      );

      await tester.tap(find.byKey(ValueKey('ky-sheet-tab-actions-$sheetId')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tab Color'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('ky-sheet-tab-color-none')));
      await tester.pumpAndSettle();

      expect(container.read(workbookProvider).activeSheet.tabColor, isNull);
      expect(
        find.byKey(ValueKey('ky-sheet-tab-color-indicator-$sheetId')),
        findsNothing,
      );
    });

    testWidgets('hides a sheet tab and restores it from the navigator', (
      tester,
    ) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final workbook = container.read(workbookProvider.notifier);
      final firstSheetId = container.read(workbookProvider).activeSheetId;
      workbook.addSheet();
      final secondSheetId = container.read(workbookProvider).activeSheetId;

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: Scaffold(body: SheetTabsBar())),
        ),
      );

      await tester.tap(
        find.byKey(ValueKey('ky-sheet-tab-actions-$secondSheetId')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Hide Sheet'));
      await tester.pumpAndSettle();

      expect(container.read(workbookProvider).activeSheetId, firstSheetId);
      expect(
        container
            .read(workbookProvider)
            .sheets
            .firstWhere((sheet) => sheet.id == secondSheetId)
            .hidden,
        isTrue,
      );
      expect(find.byKey(ValueKey('ky-sheet-tab-$secondSheetId')), findsNothing);
      expect(find.byTooltip('All Sheets: 1 visible, 1 hidden'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('ky-sheet-tabs-navigator')));
      await tester.pumpAndSettle();

      expect(find.byType(SheetHiddenSheetRow), findsOneWidget);
      expect(find.text('Hidden'), findsOneWidget);

      await tester.tap(
        find.byKey(ValueKey('ky-sheet-hidden-unhide-$secondSheetId')),
      );
      await tester.pumpAndSettle();

      expect(container.read(workbookProvider).activeSheetId, secondSheetId);
      expect(
        container
            .read(workbookProvider)
            .sheets
            .firstWhere((sheet) => sheet.id == secondSheetId)
            .hidden,
        isFalse,
      );
      expect(find.byKey(ValueKey('ky-sheet-tab-$secondSheetId')), findsOne);
    });

    testWidgets('reorders sheet tabs by dragging a tab onto another tab', (
      tester,
    ) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final workbook = container.read(workbookProvider.notifier);
      final firstSheetId = container.read(workbookProvider).activeSheetId;
      workbook.addSheet();
      final secondSheetId = container.read(workbookProvider).activeSheetId;
      workbook.addSheet();
      final thirdSheetId = container.read(workbookProvider).activeSheetId;

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: Scaffold(body: SheetTabsBar())),
        ),
      );

      final firstTab = find.byKey(ValueKey('ky-sheet-tab-$firstSheetId'));
      final thirdTab = find.byKey(ValueKey('ky-sheet-tab-$thirdSheetId'));
      final dragOffset =
          tester.getCenter(thirdTab) - tester.getCenter(firstTab);

      await tester.drag(firstTab, dragOffset);
      await tester.pumpAndSettle();

      expect(container.read(workbookProvider).sheets.map((sheet) => sheet.id), [
        secondSheetId,
        thirdSheetId,
        firstSheetId,
      ]);
      expect(container.read(workbookProvider).activeSheetId, thirdSheetId);
    });

    testWidgets('drops sheet tabs before the hovered leading edge', (
      tester,
    ) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final workbook = container.read(workbookProvider.notifier);
      final firstSheetId = container.read(workbookProvider).activeSheetId;
      workbook.addSheet();
      final secondSheetId = container.read(workbookProvider).activeSheetId;
      workbook.addSheet();
      final thirdSheetId = container.read(workbookProvider).activeSheetId;

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: Scaffold(body: SheetTabsBar())),
        ),
      );

      final firstTab = find.byKey(ValueKey('ky-sheet-tab-$firstSheetId'));
      final thirdTab = find.byKey(ValueKey('ky-sheet-tab-$thirdSheetId'));
      final targetPoint = tester.getTopLeft(thirdTab) + const Offset(8, 16);

      await tester.dragFrom(
        tester.getCenter(firstTab),
        targetPoint - tester.getCenter(firstTab),
      );
      await tester.pumpAndSettle();

      expect(container.read(workbookProvider).sheets.map((sheet) => sheet.id), [
        secondSheetId,
        firstSheetId,
        thirdSheetId,
      ]);
    });

    testWidgets('moves sheets left and right from the sheet tab menu', (
      tester,
    ) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final workbook = container.read(workbookProvider.notifier);
      final firstSheetId = container.read(workbookProvider).activeSheetId;
      workbook.addSheet();
      final secondSheetId = container.read(workbookProvider).activeSheetId;
      workbook.addSheet();
      final thirdSheetId = container.read(workbookProvider).activeSheetId;

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: Scaffold(body: SheetTabsBar())),
        ),
      );

      await tester.tap(
        find.byKey(ValueKey('ky-sheet-tab-actions-$thirdSheetId')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Move Left'));
      await tester.pumpAndSettle();

      expect(container.read(workbookProvider).sheets.map((sheet) => sheet.id), [
        firstSheetId,
        thirdSheetId,
        secondSheetId,
      ]);

      await tester.tap(
        find.byKey(ValueKey('ky-sheet-tab-actions-$thirdSheetId')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Move Right'));
      await tester.pumpAndSettle();

      expect(container.read(workbookProvider).sheets.map((sheet) => sheet.id), [
        firstSheetId,
        secondSheetId,
        thirdSheetId,
      ]);
    });
  });

  group('FormulaBar', () {
    testWidgets('shows and applies formula suggestions while editing', (
      tester,
    ) async {
      final formulaInputFinder = find.byKey(
        const ValueKey('ky-sheet-formula-input'),
      );
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(selectedCellProvider.notifier).state = CellSelection(
        CellAddress(0, 0),
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: Scaffold(body: FormulaBar())),
        ),
      );

      await tester.tap(formulaInputFinder);
      await tester.enterText(formulaInputFinder, '=su');
      await tester.pumpAndSettle();

      expect(find.byType(FormulaSuggestionPanel), findsOneWidget);
      expect(find.text('SUM'), findsOneWidget);
      expect(find.text('SUMIF'), findsOneWidget);

      await tester.tap(find.text('SUM'));
      await tester.pumpAndSettle();

      final textField = tester.widget<TextField>(formulaInputFinder);
      expect(textField.controller?.text, '=SUM(');
    });

    testWidgets('publishes formula reference previews while editing', (
      tester,
    ) async {
      final formulaInputFinder = find.byKey(
        const ValueKey('ky-sheet-formula-input'),
      );
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(selectedCellProvider.notifier).state = CellSelection(
        CellAddress(0, 0),
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: Scaffold(body: FormulaBar())),
        ),
      );

      await tester.tap(formulaInputFinder);
      await tester.enterText(formulaInputFinder, '=SUM(A1:B2)+C3');
      await tester.pump();

      final previews = container.read(formulaReferencePreviewProvider);
      expect(previews.map((selection) => selection.label), ['A1:B2', 'C3']);
    });

    testWidgets('commits formula bar edits from the apply action', (
      tester,
    ) async {
      final formulaInputFinder = find.byKey(
        const ValueKey('ky-sheet-formula-input'),
      );
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(selectedCellProvider.notifier).state = CellSelection(
        CellAddress(0, 0),
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: Scaffold(body: FormulaBar())),
        ),
      );

      await tester.tap(formulaInputFinder);
      await tester.enterText(formulaInputFinder, '=SUM(A1:B2)');
      await tester.pump();

      expect(container.read(formulaReferencePreviewProvider), isNotEmpty);

      await tester.tap(find.byKey(const ValueKey('ky-sheet-formula-commit')));
      await tester.pumpAndSettle();

      expect(
        container.read(spreadsheetProvider)[CellAddress(0, 0)]?.formula,
        '=SUM(A1:B2)',
      );
      expect(container.read(formulaReferencePreviewProvider), isEmpty);
    });

    testWidgets('cancels formula bar edits and restores selected cell text', (
      tester,
    ) async {
      final formulaInputFinder = find.byKey(
        const ValueKey('ky-sheet-formula-input'),
      );
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(selectedCellProvider.notifier).state = CellSelection(
        CellAddress(0, 0),
      );
      container
          .read(spreadsheetProvider.notifier)
          .updateCellValue(CellAddress(0, 0), 'Original');

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: Scaffold(body: FormulaBar())),
        ),
      );
      await tester.pump();

      await tester.tap(formulaInputFinder);
      await tester.enterText(formulaInputFinder, 'Changed');
      await tester.pump();

      await tester.tap(find.byKey(const ValueKey('ky-sheet-formula-cancel')));
      await tester.pumpAndSettle();

      final textField = tester.widget<TextField>(formulaInputFinder);
      expect(textField.controller?.text, 'Original');
      expect(
        container.read(spreadsheetProvider)[CellAddress(0, 0)]?.value,
        'Original',
      );
    });

    testWidgets('suggests named ranges and previews their selections', (
      tester,
    ) async {
      final formulaInputFinder = find.byKey(
        const ValueKey('ky-sheet-formula-input'),
      );
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(selectedCellProvider.notifier).state = CellSelection(
        CellAddress(0, 0),
      );
      container
          .read(sheetNamedRangesProvider.notifier)
          .save(
            name: 'Sales_Total',
            selection: CellSelection(CellAddress(1, 0), CellAddress(3, 1)),
          );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: Scaffold(body: FormulaBar())),
        ),
      );

      await tester.tap(formulaInputFinder);
      await tester.enterText(formulaInputFinder, '=SUM(Sa');
      await tester.pumpAndSettle();

      expect(find.byType(FormulaSuggestionPanel), findsOneWidget);
      expect(find.text('Sales_Total'), findsOneWidget);
      expect(find.text('A2:B4'), findsOneWidget);

      await tester.tap(find.text('Sales_Total'));
      await tester.pump();

      final textField = tester.widget<TextField>(formulaInputFinder);
      expect(textField.controller?.text, '=SUM(Sales_Total');
      expect(
        container
            .read(formulaReferencePreviewProvider)
            .map((selection) => selection.label),
        contains('A2:B4'),
      );
    });
  });

  group('SpreadsheetCell', () {
    testWidgets('emits secondary tap details for context menus', (
      tester,
    ) async {
      var secondaryTapped = false;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: SpreadsheetCell(
                address: CellAddress(0, 0),
                onSecondaryTapDown: (_) => secondaryTapped = true,
              ),
            ),
          ),
        ),
      );

      await tester.tap(
        find.byType(SpreadsheetCell),
        buttons: kSecondaryMouseButton,
      );
      await tester.pump();

      expect(secondaryTapped, isTrue);
    });

    testWidgets('renders conditional format text style', (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container
          .read(spreadsheetProvider.notifier)
          .updateCellValue(CellAddress(0, 0), '42');
      container.read(conditionalFormatRulesProvider.notifier).state = [
        ConditionalFormatRule(
          id: 'rule-1',
          selection: CellSelection(CellAddress(0, 0)),
          condition: ConditionalFormatCondition.greaterThan,
          operand: '10',
          backgroundColor: const Color(0xFFDCFCE7),
          textColor: const Color(0xFF166534),
        ),
      ];

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(body: SpreadsheetCell(address: CellAddress(0, 0))),
          ),
        ),
      );

      final text = tester.widget<Text>(find.text('42'));

      expect(text.style?.color, const Color(0xFF166534));
      expect(text.style?.fontWeight, FontWeight.bold);
    });

    testWidgets('renders structured table header and banded row styling', (
      tester,
    ) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container
          .read(spreadsheetProvider.notifier)
          .updateCellValue(CellAddress(0, 0), 'Region');
      container
          .read(spreadsheetProvider.notifier)
          .updateCellValue(CellAddress(2, 0), 'APAC');
      container
          .read(sheetTablesProvider.notifier)
          .createFromSelection(
            CellSelection(CellAddress(0, 0), CellAddress(2, 1)),
            styleId: SheetTableStyleId.mint,
          );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(body: SpreadsheetCell(address: CellAddress(0, 0))),
          ),
        ),
      );

      final headerText = tester.widget<Text>(find.text('Region'));
      final headerContainer = tester.widget<Container>(
        find
            .descendant(
              of: find.byType(SpreadsheetCell),
              matching: find.byType(Container),
            )
            .first,
      );
      final headerDecoration = headerContainer.decoration as BoxDecoration;

      expect(headerText.style?.color, Colors.white);
      expect(headerText.style?.fontWeight, FontWeight.bold);
      expect(headerDecoration.color, const Color(0xFF047857));

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(body: SpreadsheetCell(address: CellAddress(2, 0))),
          ),
        ),
      );

      final bandedContainer = tester.widget<Container>(
        find
            .descendant(
              of: find.byType(SpreadsheetCell),
              matching: find.byType(Container),
            )
            .first,
      );
      final bandedDecoration = bandedContainer.decoration as BoxDecoration;

      expect(find.text('APAC'), findsOneWidget);
      expect(bandedDecoration.color, const Color(0xFFECFDF5));
    });

    testWidgets('renders structured table totals row styling', (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final table = SheetTable.fromSelection(
        id: 'table-sales',
        name: 'Sales',
        selection: CellSelection(CellAddress(0, 0), CellAddress(2, 1)),
        styleId: SheetTableStyleId.mint,
      ).copyWith(showTotalsRow: true);
      container.read(sheetTablesProvider.notifier).replaceAll([table]);
      container
          .read(spreadsheetProvider.notifier)
          .updateCellValue(CellAddress(2, 0), 'Total');

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(body: SpreadsheetCell(address: CellAddress(2, 0))),
          ),
        ),
      );

      final totalText = tester.widget<Text>(find.text('Total'));
      final totalContainer = tester.widget<Container>(
        find
            .descendant(
              of: find.byType(SpreadsheetCell),
              matching: find.byType(Container),
            )
            .first,
      );
      final totalDecoration = totalContainer.decoration as BoxDecoration;

      expect(totalText.style?.color, const Color(0xFF047857));
      expect(totalText.style?.fontWeight, FontWeight.bold);
      expect(totalDecoration.color, const Color(0xFFD1FAE5));
    });

    testWidgets('applies and clears totals formulas from totals row cells', (
      tester,
    ) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      const tableId = 'table-sales';
      final table = SheetTable.fromSelection(
        id: tableId,
        name: 'Sales',
        selection: CellSelection(CellAddress(0, 0), CellAddress(3, 1)),
        styleId: SheetTableStyleId.mint,
      ).copyWith(showTotalsRow: true);
      container.read(sheetTablesProvider.notifier).replaceAll([table]);
      container.read(selectedCellProvider.notifier).state = CellSelection(
        CellAddress(1, 1),
      );
      final sheet = container.read(spreadsheetProvider.notifier);
      sheet.updateCellValue(CellAddress(1, 1), '2');
      sheet.updateCellValue(CellAddress(2, 1), '5');

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(body: SpreadsheetCell(address: CellAddress(3, 1))),
          ),
        ),
      );

      expect(find.byType(SheetTableTotalActionButton), findsOneWidget);

      await tester.tap(
        find.byKey(const ValueKey('ky-sheet-table-total-action-$tableId-1')),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('ky-sheet-table-total-sum-$tableId-1')),
      );
      await tester.pumpAndSettle();

      var totalCell = container.read(spreadsheetProvider)[CellAddress(3, 1)];
      expect(totalCell?.formula, '=SUM(B2:B3)');
      expect(totalCell?.value, '7.00');
      expect(container.read(selectedCellProvider)?.label, 'B4');

      await tester.tap(
        find.byKey(const ValueKey('ky-sheet-table-total-action-$tableId-1')),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('ky-sheet-table-total-clear-$tableId-1')),
      );
      await tester.pumpAndSettle();

      totalCell = container.read(spreadsheetProvider)[CellAddress(3, 1)];
      expect(totalCell?.formula, isNull);
      expect(totalCell?.value, isEmpty);
    });

    testWidgets('applies totals row label presets in the leading cell', (
      tester,
    ) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      const tableId = 'table-sales';
      final table = SheetTable.fromSelection(
        id: tableId,
        name: 'Sales',
        selection: CellSelection(CellAddress(0, 0), CellAddress(3, 1)),
        styleId: SheetTableStyleId.mint,
      ).copyWith(showTotalsRow: true);
      container.read(sheetTablesProvider.notifier).replaceAll([table]);
      container.read(selectedCellProvider.notifier).state = CellSelection(
        CellAddress(1, 0),
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(body: SpreadsheetCell(address: CellAddress(3, 0))),
          ),
        ),
      );

      await tester.tap(
        find.byKey(const ValueKey('ky-sheet-table-total-action-$tableId-0')),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(
          const ValueKey('ky-sheet-table-total-label-grandTotal-$tableId-0'),
        ),
      );
      await tester.pumpAndSettle();

      final totalCell = container.read(spreadsheetProvider)[CellAddress(3, 0)];
      expect(totalCell?.formula, isNull);
      expect(totalCell?.value, 'Grand Total');
      expect(container.read(selectedCellProvider)?.label, 'A4');
    });

    testWidgets('applies suggested totals formulas from totals row cells', (
      tester,
    ) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      const tableId = 'table-sales';
      final table = SheetTable.fromSelection(
        id: tableId,
        name: 'Sales',
        selection: CellSelection(CellAddress(0, 0), CellAddress(3, 1)),
        styleId: SheetTableStyleId.mint,
      ).copyWith(showTotalsRow: true);
      container.read(sheetTablesProvider.notifier).replaceAll([table]);
      container.read(selectedCellProvider.notifier).state = CellSelection(
        CellAddress(1, 1),
      );
      final sheet = container.read(spreadsheetProvider.notifier);
      sheet.updateCellValue(CellAddress(1, 1), '2');
      sheet.updateCellValue(CellAddress(2, 1), '5');

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(body: SpreadsheetCell(address: CellAddress(3, 1))),
          ),
        ),
      );

      await tester.tap(
        find.byKey(const ValueKey('ky-sheet-table-total-action-$tableId-1')),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('ky-sheet-table-total-suggested-$tableId-1')),
      );
      await tester.pumpAndSettle();

      final totalCell = container.read(spreadsheetProvider)[CellAddress(3, 1)];
      expect(totalCell?.formula, '=SUM(B2:B3)');
      expect(totalCell?.value, '7.00');
      expect(container.read(selectedCellProvider)?.label, 'B4');
    });

    testWidgets('renders active table outline on boundary cells', (
      tester,
    ) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final table = SheetTable.fromSelection(
        id: 'table-sales',
        name: 'Sales',
        selection: CellSelection(CellAddress(0, 0), CellAddress(2, 2)),
        styleId: SheetTableStyleId.mint,
      );
      container.read(sheetTablesProvider.notifier).replaceAll([table]);
      container.read(selectedCellProvider.notifier).state = CellSelection(
        CellAddress(1, 1),
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(body: SpreadsheetCell(address: CellAddress(0, 0))),
          ),
        ),
      );

      final overlay = tester.widget<SheetTableOutlineOverlay>(
        find.byType(SheetTableOutlineOverlay),
      );

      expect(overlay.color, const Color(0xFF047857));
      expect(overlay.outline.top, isTrue);
      expect(overlay.outline.left, isTrue);
      expect(overlay.outline.right, isFalse);
      expect(overlay.outline.bottom, isFalse);
      expect(find.byKey(SheetTableOutlineOverlay.topEdgeKey), findsOneWidget);
      expect(find.byKey(SheetTableOutlineOverlay.leftEdgeKey), findsOneWidget);
      expect(find.byKey(SheetTableOutlineOverlay.rightEdgeKey), findsNothing);
      expect(find.byKey(SheetTableOutlineOverlay.bottomEdgeKey), findsNothing);
    });

    testWidgets('hides active table outline away from the active boundary', (
      tester,
    ) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final table = SheetTable.fromSelection(
        id: 'table-sales',
        name: 'Sales',
        selection: CellSelection(CellAddress(0, 0), CellAddress(2, 2)),
        styleId: SheetTableStyleId.mint,
      );
      container.read(sheetTablesProvider.notifier).replaceAll([table]);
      container.read(selectedCellProvider.notifier).state = CellSelection(
        CellAddress(1, 1),
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(body: SpreadsheetCell(address: CellAddress(1, 1))),
          ),
        ),
      );

      expect(find.byType(SheetTableOutlineOverlay), findsNothing);

      container.read(selectedCellProvider.notifier).state = CellSelection(
        CellAddress(4, 4),
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(body: SpreadsheetCell(address: CellAddress(0, 0))),
          ),
        ),
      );

      expect(find.byType(SheetTableOutlineOverlay), findsNothing);
    });

    testWidgets('renders active table identity badge on the table corner', (
      tester,
    ) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final table = SheetTable.fromSelection(
        id: 'table-sales',
        name: 'Sales Orders',
        selection: CellSelection(CellAddress(0, 0), CellAddress(2, 2)),
        styleId: SheetTableStyleId.mint,
      );
      container.read(sheetTablesProvider.notifier).replaceAll([table]);
      container.read(selectedCellProvider.notifier).state = CellSelection(
        CellAddress(1, 1),
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(body: SpreadsheetCell(address: CellAddress(0, 0))),
          ),
        ),
      );

      final badge = tester.widget<SheetTableCornerBadge>(
        find.byType(SheetTableCornerBadge),
      );

      expect(badge.table.name, 'Sales Orders');
      expect(badge.color, const Color(0xFF047857));
      expect(find.byKey(SheetTableCornerBadge.badgeKey), findsOneWidget);
      expect(find.byTooltip('Sales Orders · A1:C3'), findsOneWidget);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(body: SpreadsheetCell(address: CellAddress(1, 1))),
          ),
        ),
      );

      expect(find.byType(SheetTableCornerBadge), findsNothing);
    });

    testWidgets('shows table-scoped filter count on the active table badge', (
      tester,
    ) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final table = SheetTable.fromSelection(
        id: 'table-sales',
        name: 'Sales Orders',
        selection: CellSelection(CellAddress(0, 0), CellAddress(2, 2)),
        styleId: SheetTableStyleId.mint,
      );
      container.read(sheetTablesProvider.notifier).replaceAll([table]);
      final sheet = container.read(spreadsheetProvider.notifier);
      sheet.updateCellValue(CellAddress(0, 0), 'Region');
      sheet.updateCellValue(CellAddress(0, 1), 'Amount');
      sheet.updateCellValue(CellAddress(1, 0), 'EMEA');
      sheet.updateCellValue(CellAddress(1, 1), '30');
      sheet.updateCellValue(CellAddress(2, 0), 'APAC');
      sheet.updateCellValue(CellAddress(2, 1), '10');
      final toolbar = container.read(toolbarControllerProvider);
      toolbar.setFilterRule(0, SheetFilterRule.contains('EMEA'));
      toolbar.setFilterRule(
        1,
        const SheetFilterRule(
          operator: SheetFilterOperator.greaterThanOrEqual,
          value: '25',
        ),
      );
      toolbar.setFilterRule(4, SheetFilterRule.contains('Outside'));
      container.read(selectedCellProvider.notifier).state = CellSelection(
        CellAddress(1, 1),
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(body: SpreadsheetCell(address: CellAddress(0, 0))),
          ),
        ),
      );

      expect(find.byKey(SheetTableCornerBadge.filterBadgeKey), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(SheetTableCornerBadge.filterBadgeKey),
          matching: find.text('2'),
        ),
        findsOneWidget,
      );
      expect(
        find.byTooltip(
          'Sales Orders · A1:C3 · 2 filtered columns · 1 of 2 rows shown',
        ),
        findsOneWidget,
      );
      expect(
        find.byTooltip('2 filtered columns · 1 of 2 rows shown'),
        findsOneWidget,
      );
      expect(find.text('3'), findsNothing);
    });

    testWidgets('shows active table corner actions and expands the range', (
      tester,
    ) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      const tableId = 'table-sales';
      final table = SheetTable.fromSelection(
        id: tableId,
        name: 'Sales',
        selection: CellSelection(CellAddress(0, 0), CellAddress(2, 2)),
        styleId: SheetTableStyleId.mint,
      );
      container.read(sheetTablesProvider.notifier).replaceAll([table]);
      container
          .read(spreadsheetProvider.notifier)
          .updateCellValue(CellAddress(4, 4), 'Tail');
      container.read(selectedCellProvider.notifier).state = CellSelection(
        CellAddress(1, 1),
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(body: SpreadsheetCell(address: CellAddress(2, 2))),
          ),
        ),
      );

      expect(find.byType(SheetTableCornerActionButton), findsOneWidget);
      expect(
        find.byKey(const ValueKey('ky-sheet-table-corner-action-$tableId')),
        findsOneWidget,
      );

      await tester.tap(
        find.byKey(const ValueKey('ky-sheet-table-corner-action-$tableId')),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('ky-sheet-table-corner-select-$tableId')),
      );
      await tester.pumpAndSettle();

      expect(container.read(selectedCellProvider)?.label, 'A1:C3');

      await tester.tap(
        find.byKey(const ValueKey('ky-sheet-table-corner-action-$tableId')),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('ky-sheet-table-corner-expand-$tableId')),
      );
      await tester.pumpAndSettle();

      expect(
        container.read(sheetTablesProvider).single.selection.label,
        'A1:E5',
      );
      expect(container.read(selectedCellProvider)?.label, 'A1:E5');
    });

    testWidgets('clears active table filters from the corner action', (
      tester,
    ) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      const tableId = 'table-sales';
      final table = SheetTable.fromSelection(
        id: tableId,
        name: 'Sales',
        selection: CellSelection(CellAddress(0, 0), CellAddress(2, 2)),
        styleId: SheetTableStyleId.mint,
      );
      container.read(sheetTablesProvider.notifier).replaceAll([table]);
      final sheet = container.read(spreadsheetProvider.notifier);
      sheet.updateCellValue(CellAddress(0, 0), 'Region');
      sheet.updateCellValue(CellAddress(0, 1), 'Amount');
      sheet.updateCellValue(CellAddress(1, 0), 'EMEA');
      sheet.updateCellValue(CellAddress(1, 1), '30');
      sheet.updateCellValue(CellAddress(2, 0), 'APAC');
      sheet.updateCellValue(CellAddress(2, 1), '10');
      final toolbar = container.read(toolbarControllerProvider);
      toolbar.setFilterRule(0, SheetFilterRule.contains('EMEA'));
      toolbar.setFilterRule(
        1,
        const SheetFilterRule(
          operator: SheetFilterOperator.greaterThanOrEqual,
          value: '25',
        ),
      );
      toolbar.setFilterRule(4, SheetFilterRule.contains('Outside'));
      container.read(selectedCellProvider.notifier).state = CellSelection(
        CellAddress(1, 1),
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(body: SpreadsheetCell(address: CellAddress(2, 2))),
          ),
        ),
      );

      await tester.tap(
        find.byKey(const ValueKey('ky-sheet-table-corner-action-$tableId')),
      );
      await tester.pumpAndSettle();

      expect(find.text('Clear Table Filters'), findsOneWidget);
      expect(
        find.text('2 filtered columns · 1 of 2 rows shown'),
        findsOneWidget,
      );

      await tester.tap(
        find.byKey(
          const ValueKey('ky-sheet-table-corner-clear-filters-$tableId'),
        ),
      );
      await tester.pumpAndSettle();

      expect(container.read(filterProvider), {4: 'Outside'});
      expect(container.read(sheetFilterRulesProvider).keys, [4]);
      expect(container.read(selectedCellProvider)?.label, 'A1:C3');
    });

    testWidgets('adds table rows and columns from the active corner action', (
      tester,
    ) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      const tableId = 'table-sales';
      final table = SheetTable.fromSelection(
        id: tableId,
        name: 'Sales',
        selection: CellSelection(CellAddress(0, 0), CellAddress(2, 2)),
        styleId: SheetTableStyleId.mint,
      );
      container.read(sheetTablesProvider.notifier).replaceAll([table]);
      container.read(selectedCellProvider.notifier).state = CellSelection(
        CellAddress(1, 1),
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(body: SpreadsheetCell(address: CellAddress(2, 2))),
          ),
        ),
      );

      await tester.tap(
        find.byKey(const ValueKey('ky-sheet-table-corner-action-$tableId')),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('ky-sheet-table-corner-add-row-$tableId')),
      );
      await tester.pumpAndSettle();

      expect(
        container.read(sheetTablesProvider).single.selection.label,
        'A1:C4',
      );
      expect(container.read(selectedCellProvider)?.label, 'A4:C4');

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(body: SpreadsheetCell(address: CellAddress(3, 2))),
          ),
        ),
      );

      await tester.tap(
        find.byKey(const ValueKey('ky-sheet-table-corner-action-$tableId')),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('ky-sheet-table-corner-add-column-$tableId')),
      );
      await tester.pumpAndSettle();

      expect(
        container.read(sheetTablesProvider).single.selection.label,
        'A1:D4',
      );
      expect(container.read(selectedCellProvider)?.label, 'D1:D4');
      expect(
        container.read(spreadsheetProvider)[CellAddress(0, 3)]?.value,
        'Column 4',
      );
      expect(
        container.read(undoStackProvider).last.description,
        'Add table column',
      );
    });

    testWidgets('extends totals formulas when adding table columns', (
      tester,
    ) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      const tableId = 'table-sales';
      final table = SheetTable.fromSelection(
        id: tableId,
        name: 'Sales',
        selection: CellSelection(CellAddress(0, 0), CellAddress(3, 2)),
        styleId: SheetTableStyleId.mint,
      ).copyWith(showTotalsRow: true);
      container.read(sheetTablesProvider.notifier).replaceAll([table]);
      container.read(selectedCellProvider.notifier).state = CellSelection(
        CellAddress(1, 1),
      );
      final sheet = container.read(spreadsheetProvider.notifier);
      sheet.updateCellValue(CellAddress(0, 0), 'Region');
      sheet.updateCellValue(CellAddress(0, 1), 'Sales');
      sheet.updateCellValue(CellAddress(0, 2), 'Units');
      sheet.updateCellValue(CellAddress(1, 1), '1');
      sheet.updateCell(
        CellAddress(1, 2),
        CellData(
          value: '2',
          formula: '=B2+1',
          style: const CellStyle(numberFormat: SheetNumberFormatId.number),
          validation: CellValidation(type: ValidationType.number),
        ),
      );
      sheet.updateCellValue(CellAddress(2, 2), '5');
      sheet.updateCellValue(CellAddress(3, 0), 'Total');
      sheet.updateCellValue(CellAddress(3, 2), '=SUM(C2:C3)');
      sheet.clearHistory();

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(body: SpreadsheetCell(address: CellAddress(3, 2))),
          ),
        ),
      );

      await tester.tap(
        find.byKey(const ValueKey('ky-sheet-table-corner-action-$tableId')),
      );
      await tester.pumpAndSettle();
      expect(
        find.text('Smart fill: header, formulas, formatting and totals'),
        findsOneWidget,
      );
      await tester.tap(
        find.byKey(const ValueKey('ky-sheet-table-corner-add-column-$tableId')),
      );
      await tester.pumpAndSettle();

      final cells = container.read(spreadsheetProvider);
      expect(
        container.read(sheetTablesProvider).single.selection.label,
        'A1:D4',
      );
      expect(container.read(selectedCellProvider)?.label, 'D1:D4');
      expect(cells[CellAddress(0, 3)]?.value, 'Column 4');
      expect(
        cells[CellAddress(1, 3)]?.style.numberFormat,
        SheetNumberFormatId.number,
      );
      expect(cells[CellAddress(1, 3)]?.validation?.type, ValidationType.number);
      expect(cells[CellAddress(1, 3)]?.formula, '=C2+1');
      expect(cells[CellAddress(3, 3)]?.formula, '=SUM(D2:D3)');
      expect(
        container.read(undoStackProvider).last.description,
        'Add table column',
      );
    });

    testWidgets('adds blank columns from the active corner action', (
      tester,
    ) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      const tableId = 'table-sales';
      final table = SheetTable.fromSelection(
        id: tableId,
        name: 'Sales',
        selection: CellSelection(CellAddress(0, 0), CellAddress(3, 2)),
        styleId: SheetTableStyleId.mint,
      ).copyWith(showTotalsRow: true);
      container.read(sheetTablesProvider.notifier).replaceAll([table]);
      container.read(selectedCellProvider.notifier).state = CellSelection(
        CellAddress(1, 1),
      );
      final sheet = container.read(spreadsheetProvider.notifier);
      sheet.updateCellValue(CellAddress(0, 0), 'Region');
      sheet.updateCellValue(CellAddress(0, 1), 'Sales');
      sheet.updateCellValue(CellAddress(0, 2), 'Units');
      sheet.updateCellValue(CellAddress(1, 1), '1');
      sheet.updateCell(
        CellAddress(1, 2),
        CellData(
          value: '2',
          formula: '=B2+1',
          style: const CellStyle(numberFormat: SheetNumberFormatId.number),
          validation: CellValidation(type: ValidationType.number),
        ),
      );
      sheet.updateCellValue(CellAddress(3, 2), '=SUM(C2:C3)');
      sheet.clearHistory();

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(body: SpreadsheetCell(address: CellAddress(3, 2))),
          ),
        ),
      );

      await tester.tap(
        find.byKey(const ValueKey('ky-sheet-table-corner-action-$tableId')),
      );
      await tester.pumpAndSettle();
      expect(find.text('Add Blank Column Right'), findsOneWidget);
      expect(
        find.text('Header only; no formulas or totals copied'),
        findsOneWidget,
      );

      await tester.tap(
        find.byKey(
          const ValueKey('ky-sheet-table-corner-add-blank-column-$tableId'),
        ),
      );
      await tester.pumpAndSettle();

      final cells = container.read(spreadsheetProvider);
      expect(
        container.read(sheetTablesProvider).single.selection.label,
        'A1:D4',
      );
      expect(container.read(selectedCellProvider)?.label, 'D1:D4');
      expect(cells[CellAddress(0, 3)]?.value, 'Column 4');
      expect(cells.containsKey(CellAddress(1, 3)), isFalse);
      expect(cells.containsKey(CellAddress(3, 3)), isFalse);
      expect(
        container.read(undoStackProvider).last.description,
        'Add blank table column',
      );
    });

    testWidgets('disables row and column appends near occupied cells', (
      tester,
    ) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      const tableId = 'table-sales';
      final table = SheetTable.fromSelection(
        id: tableId,
        name: 'Sales',
        selection: CellSelection(CellAddress(0, 0), CellAddress(2, 2)),
        styleId: SheetTableStyleId.mint,
      );
      container.read(sheetTablesProvider.notifier).replaceAll([table]);
      container.read(selectedCellProvider.notifier).state = CellSelection(
        CellAddress(1, 1),
      );
      final sheet = container.read(spreadsheetProvider.notifier);
      sheet.updateCellValue(CellAddress(3, 0), 'Below');
      sheet.updateCellValue(CellAddress(1, 3), 'Right side');
      sheet.clearHistory();

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(body: SpreadsheetCell(address: CellAddress(2, 2))),
          ),
        ),
      );

      await tester.tap(
        find.byKey(const ValueKey('ky-sheet-table-corner-action-$tableId')),
      );
      await tester.pumpAndSettle();

      final rowItem = tester.widget<PopupMenuItem>(
        find.byKey(const ValueKey('ky-sheet-table-corner-add-row-$tableId')),
      );
      final columnItem = tester.widget<PopupMenuItem>(
        find.byKey(const ValueKey('ky-sheet-table-corner-add-column-$tableId')),
      );

      expect(find.text('Cannot Add Row: A4 has data'), findsOneWidget);
      expect(find.text('Cannot Add Column: D2 has data'), findsOneWidget);
      expect(rowItem.enabled, isFalse);
      expect(columnItem.enabled, isFalse);
      expect(
        container.read(sheetTablesProvider).single.selection.label,
        'A1:C3',
      );
      expect(container.read(undoStackProvider), isEmpty);
    });

    testWidgets('adds data rows above active table totals rows', (
      tester,
    ) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      const tableId = 'table-sales';
      final table = SheetTable.fromSelection(
        id: tableId,
        name: 'Sales',
        selection: CellSelection(CellAddress(0, 0), CellAddress(3, 2)),
        styleId: SheetTableStyleId.mint,
      ).copyWith(showTotalsRow: true);
      container.read(sheetTablesProvider.notifier).replaceAll([table]);
      container.read(selectedCellProvider.notifier).state = CellSelection(
        CellAddress(1, 1),
      );
      final sheet = container.read(spreadsheetProvider.notifier);
      sheet.updateCellValue(CellAddress(1, 0), 'EMEA');
      sheet.updateCellValue(CellAddress(2, 0), 'APAC');
      sheet.updateCellValue(CellAddress(1, 1), '2');
      sheet.updateCell(
        CellAddress(2, 1),
        CellData(
          value: '5',
          formula: '=B2+3',
          style: const CellStyle(numberFormat: SheetNumberFormatId.number),
          validation: CellValidation(type: ValidationType.number),
        ),
      );
      sheet.updateCellValue(CellAddress(1, 2), 'Open');
      sheet.updateCellValue(CellAddress(2, 2), 'Closed');
      sheet.updateCellValue(CellAddress(3, 0), 'Total');
      sheet.updateCellValue(CellAddress(3, 1), '=SUM(B2:B3)');
      sheet.updateCellValue(CellAddress(3, 2), '=COUNTA(C2:C3)');

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(body: SpreadsheetCell(address: CellAddress(3, 2))),
          ),
        ),
      );

      await tester.tap(
        find.byKey(const ValueKey('ky-sheet-table-corner-action-$tableId')),
      );
      await tester.pumpAndSettle();
      expect(find.text('Add Data Row'), findsOneWidget);
      expect(
        find.text('Smart fill: formulas, formatting and totals'),
        findsOneWidget,
      );

      await tester.tap(
        find.byKey(const ValueKey('ky-sheet-table-corner-add-row-$tableId')),
      );
      await tester.pumpAndSettle();

      final updatedTable = container.read(sheetTablesProvider).single;
      final cells = container.read(spreadsheetProvider);

      expect(updatedTable.selection.label, 'A1:C5');
      expect(updatedTable.showTotalsRow, isTrue);
      expect(cells.containsKey(CellAddress(3, 0)), isFalse);
      expect(cells[CellAddress(3, 1)]?.formula, '=B3+3');
      expect(
        cells[CellAddress(3, 1)]?.style.numberFormat,
        SheetNumberFormatId.number,
      );
      expect(cells[CellAddress(3, 1)]?.validation?.type, ValidationType.number);
      expect(cells[CellAddress(4, 0)]?.value, 'Total');
      expect(cells[CellAddress(4, 1)]?.formula, '=SUM(B2:B4)');
      expect(cells[CellAddress(4, 1)]?.value, '15.00');
      expect(cells[CellAddress(4, 2)]?.formula, '=COUNTA(C2:C4)');
      expect(container.read(selectedCellProvider)?.label, 'A4:C4');
      expect(
        container.read(undoStackProvider).last.description,
        'Add data row',
      );
    });

    testWidgets('adds blank data rows above active table totals rows', (
      tester,
    ) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      const tableId = 'table-sales';
      final table = SheetTable.fromSelection(
        id: tableId,
        name: 'Sales',
        selection: CellSelection(CellAddress(0, 0), CellAddress(3, 2)),
        styleId: SheetTableStyleId.mint,
      ).copyWith(showTotalsRow: true);
      container.read(sheetTablesProvider.notifier).replaceAll([table]);
      container.read(selectedCellProvider.notifier).state = CellSelection(
        CellAddress(1, 1),
      );
      final sheet = container.read(spreadsheetProvider.notifier);
      sheet.updateCellValue(CellAddress(1, 0), 'EMEA');
      sheet.updateCellValue(CellAddress(2, 0), 'APAC');
      sheet.updateCellValue(CellAddress(1, 1), '2');
      sheet.updateCell(
        CellAddress(2, 1),
        CellData(
          value: '5',
          formula: '=B2+3',
          style: const CellStyle(numberFormat: SheetNumberFormatId.number),
          validation: CellValidation(type: ValidationType.number),
        ),
      );
      sheet.updateCellValue(CellAddress(1, 2), 'Open');
      sheet.updateCellValue(CellAddress(2, 2), 'Closed');
      sheet.updateCellValue(CellAddress(3, 0), 'Total');
      sheet.updateCellValue(CellAddress(3, 1), '=SUM(B2:B3)');
      sheet.updateCellValue(CellAddress(3, 2), '=COUNTA(C2:C3)');
      sheet.clearHistory();

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(body: SpreadsheetCell(address: CellAddress(3, 2))),
          ),
        ),
      );

      await tester.tap(
        find.byKey(const ValueKey('ky-sheet-table-corner-action-$tableId')),
      );
      await tester.pumpAndSettle();
      expect(find.text('Add Blank Data Row'), findsOneWidget);
      expect(
        find.text('Moves totals down; leaves row cells empty'),
        findsOneWidget,
      );

      await tester.tap(
        find.byKey(
          const ValueKey('ky-sheet-table-corner-add-blank-row-$tableId'),
        ),
      );
      await tester.pumpAndSettle();

      final updatedTable = container.read(sheetTablesProvider).single;
      final cells = container.read(spreadsheetProvider);

      expect(updatedTable.selection.label, 'A1:C5');
      expect(updatedTable.showTotalsRow, isTrue);
      expect(cells.containsKey(CellAddress(3, 0)), isFalse);
      expect(cells.containsKey(CellAddress(3, 1)), isFalse);
      expect(cells.containsKey(CellAddress(3, 2)), isFalse);
      expect(cells[CellAddress(4, 0)]?.value, 'Total');
      expect(cells[CellAddress(4, 1)]?.formula, '=SUM(B2:B4)');
      expect(cells[CellAddress(4, 1)]?.value, '7.00');
      expect(cells[CellAddress(4, 2)]?.formula, '=COUNTA(C2:C4)');
      expect(container.read(selectedCellProvider)?.label, 'A4:C4');
      expect(
        container.read(undoStackProvider).last.description,
        'Add blank data row',
      );
    });

    testWidgets('toggles a totals row from the active corner action', (
      tester,
    ) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      const tableId = 'table-sales';
      final table = SheetTable.fromSelection(
        id: tableId,
        name: 'Sales',
        selection: CellSelection(CellAddress(0, 0), CellAddress(2, 2)),
        styleId: SheetTableStyleId.mint,
      );
      container.read(sheetTablesProvider.notifier).replaceAll([table]);
      container.read(selectedCellProvider.notifier).state = CellSelection(
        CellAddress(1, 1),
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(body: SpreadsheetCell(address: CellAddress(2, 2))),
          ),
        ),
      );

      await tester.tap(
        find.byKey(const ValueKey('ky-sheet-table-corner-action-$tableId')),
      );
      await tester.pumpAndSettle();
      expect(find.text('Use Last Row as Totals'), findsOneWidget);
      await tester.tap(
        find.byKey(const ValueKey('ky-sheet-table-corner-totals-$tableId')),
      );
      await tester.pumpAndSettle();

      expect(container.read(sheetTablesProvider).single.showTotalsRow, isTrue);
      expect(container.read(selectedCellProvider)?.label, 'A3:C3');

      await tester.tap(
        find.byKey(const ValueKey('ky-sheet-table-corner-action-$tableId')),
      );
      await tester.pumpAndSettle();
      expect(find.text('Hide Totals Row'), findsOneWidget);
      await tester.tap(
        find.byKey(const ValueKey('ky-sheet-table-corner-totals-$tableId')),
      );
      await tester.pumpAndSettle();

      expect(container.read(sheetTablesProvider).single.showTotalsRow, isFalse);
      expect(container.read(selectedCellProvider)?.label, 'A1:C3');
    });

    testWidgets('adds and fills a fresh totals row below existing data', (
      tester,
    ) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      const tableId = 'table-sales';
      final table = SheetTable.fromSelection(
        id: tableId,
        name: 'Sales',
        selection: CellSelection(CellAddress(0, 0), CellAddress(2, 2)),
        styleId: SheetTableStyleId.mint,
      );
      container.read(sheetTablesProvider.notifier).replaceAll([table]);
      container.read(selectedCellProvider.notifier).state = CellSelection(
        CellAddress(1, 1),
      );
      final sheet = container.read(spreadsheetProvider.notifier);
      sheet.updateCellValue(CellAddress(1, 0), 'EMEA');
      sheet.updateCellValue(CellAddress(2, 0), 'APAC');
      sheet.updateCellValue(CellAddress(1, 1), '2');
      sheet.updateCellValue(CellAddress(2, 1), '5');
      sheet.updateCellValue(CellAddress(1, 2), 'Open');
      sheet.updateCellValue(CellAddress(2, 2), 'Closed');

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(body: SpreadsheetCell(address: CellAddress(2, 2))),
          ),
        ),
      );

      await tester.tap(
        find.byKey(const ValueKey('ky-sheet-table-corner-action-$tableId')),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(
          const ValueKey('ky-sheet-table-corner-add-totals-row-$tableId'),
        ),
      );
      await tester.pumpAndSettle();

      final updatedTable = container.read(sheetTablesProvider).single;
      final cells = container.read(spreadsheetProvider);

      expect(updatedTable.selection.label, 'A1:C4');
      expect(updatedTable.showTotalsRow, isTrue);
      expect(cells[CellAddress(3, 0)]?.value, 'Total');
      expect(cells[CellAddress(3, 1)]?.formula, '=SUM(B2:B3)');
      expect(cells[CellAddress(3, 1)]?.value, '7.00');
      expect(cells[CellAddress(3, 2)]?.formula, '=COUNTA(C2:C3)');
      expect(container.read(selectedCellProvider)?.label, 'A4:C4');
      expect(
        container.read(undoStackProvider).last.description,
        'Add totals row',
      );
    });

    testWidgets('disables adding totals row when the row below has data', (
      tester,
    ) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      const tableId = 'table-sales';
      final table = SheetTable.fromSelection(
        id: tableId,
        name: 'Sales',
        selection: CellSelection(CellAddress(0, 0), CellAddress(2, 1)),
        styleId: SheetTableStyleId.mint,
      );
      container.read(sheetTablesProvider.notifier).replaceAll([table]);
      container.read(selectedCellProvider.notifier).state = CellSelection(
        CellAddress(1, 1),
      );
      final sheet = container.read(spreadsheetProvider.notifier);
      sheet.updateCellValue(CellAddress(1, 1), '2');
      sheet.updateCellValue(CellAddress(2, 1), '5');
      sheet.updateCellValue(CellAddress(3, 0), 'Existing row');
      sheet.clearHistory();

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(body: SpreadsheetCell(address: CellAddress(2, 1))),
          ),
        ),
      );

      await tester.tap(
        find.byKey(const ValueKey('ky-sheet-table-corner-action-$tableId')),
      );
      await tester.pumpAndSettle();

      expect(find.text('Cannot Add Row: A4 has data'), findsOneWidget);
      expect(find.text('Cannot Add Totals Row: A4 has data'), findsOneWidget);

      await tester.tap(find.text('Cannot Add Totals Row: A4 has data'));
      await tester.pumpAndSettle();

      expect(
        container.read(sheetTablesProvider).single.selection.label,
        'A1:B3',
      );
      expect(container.read(sheetTablesProvider).single.showTotalsRow, isFalse);
      expect(
        container.read(spreadsheetProvider)[CellAddress(3, 0)]?.value,
        'Existing row',
      );
      expect(container.read(undoStackProvider), isEmpty);
    });

    testWidgets('auto-fills suggested totals from the active corner action', (
      tester,
    ) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      const tableId = 'table-sales';
      final table = SheetTable.fromSelection(
        id: tableId,
        name: 'Sales',
        selection: CellSelection(CellAddress(0, 0), CellAddress(3, 2)),
        styleId: SheetTableStyleId.mint,
      ).copyWith(showTotalsRow: true);
      container.read(sheetTablesProvider.notifier).replaceAll([table]);
      container.read(selectedCellProvider.notifier).state = CellSelection(
        CellAddress(1, 1),
      );
      final sheet = container.read(spreadsheetProvider.notifier);
      sheet.updateCellValue(CellAddress(1, 0), 'EMEA');
      sheet.updateCellValue(CellAddress(2, 0), 'APAC');
      sheet.updateCellValue(CellAddress(1, 1), '2');
      sheet.updateCellValue(CellAddress(2, 1), '5');
      sheet.updateCellValue(CellAddress(1, 2), 'Open');
      sheet.updateCellValue(CellAddress(2, 2), 'Closed');

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(body: SpreadsheetCell(address: CellAddress(3, 2))),
          ),
        ),
      );

      await tester.tap(
        find.byKey(const ValueKey('ky-sheet-table-corner-action-$tableId')),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(
          const ValueKey('ky-sheet-table-corner-autofill-totals-$tableId'),
        ),
      );
      await tester.pumpAndSettle();

      final cells = container.read(spreadsheetProvider);
      expect(cells[CellAddress(3, 0)]?.value, 'Total');
      expect(cells[CellAddress(3, 0)]?.formula, isNull);
      expect(cells[CellAddress(3, 1)]?.formula, '=SUM(B2:B3)');
      expect(cells[CellAddress(3, 1)]?.value, '7.00');
      expect(cells[CellAddress(3, 2)]?.formula, '=COUNTA(C2:C3)');
      expect(container.read(selectedCellProvider)?.label, 'A4:C4');
      expect(
        container.read(undoStackProvider).last.description,
        'Auto-fill totals row',
      );
    });

    testWidgets('opens Table Studio from the active table corner action', (
      tester,
    ) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      const tableId = 'table-sales';
      final table = SheetTable.fromSelection(
        id: tableId,
        name: 'Sales',
        selection: CellSelection(CellAddress(0, 0), CellAddress(2, 2)),
        styleId: SheetTableStyleId.prism,
      );
      container.read(sheetTablesProvider.notifier).replaceAll([table]);
      container.read(selectedCellProvider.notifier).state = CellSelection(
        CellAddress(1, 1),
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(body: SpreadsheetCell(address: CellAddress(2, 2))),
          ),
        ),
      );

      await tester.tap(
        find.byKey(const ValueKey('ky-sheet-table-corner-action-$tableId')),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('ky-sheet-table-corner-studio-$tableId')),
      );
      await tester.pumpAndSettle();

      expect(
        container.read(activeSidebarPanelProvider),
        SheetSidebarPanel.tables,
      );
    });

    testWidgets('shows table header actions for sort and filter workflows', (
      tester,
    ) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      const tableId = 'table-sales';
      final table = SheetTable.fromSelection(
        id: tableId,
        name: 'Sales',
        selection: CellSelection(CellAddress(0, 0), CellAddress(2, 1)),
        styleId: SheetTableStyleId.prism,
      );
      container.read(sheetTablesProvider.notifier).replaceAll([table]);
      final sheet = container.read(spreadsheetProvider.notifier);
      sheet.updateCellValue(CellAddress(0, 0), 'Region');
      sheet.updateCellValue(CellAddress(0, 1), 'Sales');
      sheet.updateCellValue(CellAddress(1, 0), 'EMEA');
      sheet.updateCellValue(CellAddress(1, 1), '2');
      sheet.updateCellValue(CellAddress(2, 0), 'APAC');
      sheet.updateCellValue(CellAddress(2, 1), '5');

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(body: SpreadsheetCell(address: CellAddress(0, 0))),
          ),
        ),
      );

      await tester.tap(
        find.byKey(const ValueKey('ky-sheet-table-header-action-$tableId-0')),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('ky-sheet-table-header-sort-asc-$tableId-0')),
      );
      await tester.pumpAndSettle();

      final cells = container.read(spreadsheetProvider);
      expect(cells[CellAddress(0, 0)]?.value, 'Region');
      expect(cells[CellAddress(1, 0)]?.value, 'APAC');
      expect(cells[CellAddress(1, 1)]?.value, '5');
      expect(container.read(sortColumnProvider), 0);
      expect(container.read(sortAscendingProvider), isTrue);

      await tester.tap(
        find.byKey(const ValueKey('ky-sheet-table-header-action-$tableId-0')),
      );
      await tester.pumpAndSettle();
      expect(find.text('Current sort: A to Z'), findsOneWidget);
      await tester.tap(
        find.byKey(
          const ValueKey('ky-sheet-table-header-clear-sort-$tableId-0'),
        ),
      );
      await tester.pumpAndSettle();

      expect(container.read(sortColumnProvider), isNull);
      expect(container.read(sortAscendingProvider), isTrue);

      await tester.tap(
        find.byKey(const ValueKey('ky-sheet-table-header-action-$tableId-0')),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('ky-sheet-table-header-filter-$tableId-0')),
      );
      await tester.pumpAndSettle();

      expect(find.text('Sort & Filter Sales[Region]'), findsOneWidget);
      expect(find.text('Table body values only'), findsOneWidget);
      expect(find.text('2 of 2 selected'), findsOneWidget);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(container.read(activeSidebarPanelProvider), isNull);
    });

    testWidgets('surfaces calculated column status from table header actions', (
      tester,
    ) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      const tableId = 'table-sales';
      final table = SheetTable.fromSelection(
        id: tableId,
        name: 'Sales',
        selection: CellSelection(CellAddress(0, 0), CellAddress(2, 1)),
        styleId: SheetTableStyleId.prism,
      );
      container.read(sheetTablesProvider.notifier).replaceAll([table]);
      final sheet = container.read(spreadsheetProvider.notifier);
      sheet.updateCellValue(CellAddress(0, 0), 'Region');
      sheet.updateCellValue(CellAddress(0, 1), 'Sales');
      sheet.updateCellValue(CellAddress(1, 0), 'EMEA');
      sheet.updateCell(
        CellAddress(1, 1),
        CellData(value: '4', formula: '=2*2'),
      );
      sheet.updateCellValue(CellAddress(2, 0), 'APAC');
      sheet.updateCell(
        CellAddress(2, 1),
        CellData(value: '8', formula: '=4*2'),
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(body: SpreadsheetCell(address: CellAddress(0, 1))),
          ),
        ),
      );

      expect(find.byIcon(Icons.functions), findsOneWidget);

      await tester.tap(
        find.byKey(const ValueKey('ky-sheet-table-header-action-$tableId-1')),
      );
      await tester.pumpAndSettle();

      expect(find.text('Calculated Column'), findsOneWidget);
      expect(find.text('2 formula rows'), findsOneWidget);
      expect(find.text('Select Column Body'), findsOneWidget);

      await tester.tap(
        find.byKey(
          const ValueKey('ky-sheet-table-header-select-body-$tableId-1'),
        ),
      );
      await tester.pumpAndSettle();

      expect(container.read(selectedCellProvider)?.label, 'B2:B3');
    });

    testWidgets('surfaces active filter details from table header actions', (
      tester,
    ) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      const tableId = 'table-sales';
      final table = SheetTable.fromSelection(
        id: tableId,
        name: 'Sales',
        selection: CellSelection(CellAddress(0, 0), CellAddress(2, 1)),
        styleId: SheetTableStyleId.prism,
      );
      container.read(sheetTablesProvider.notifier).replaceAll([table]);
      final sheet = container.read(spreadsheetProvider.notifier);
      sheet.updateCellValue(CellAddress(0, 0), 'Region');
      sheet.updateCellValue(CellAddress(0, 1), 'Sales');
      sheet.updateCellValue(CellAddress(1, 0), 'EMEA');
      sheet.updateCellValue(CellAddress(1, 1), '2');
      sheet.updateCellValue(CellAddress(2, 0), 'APAC');
      sheet.updateCellValue(CellAddress(2, 1), '5');
      container
          .read(toolbarControllerProvider)
          .setFilterRule(
            1,
            const SheetFilterRule(
              operator: SheetFilterOperator.greaterThanOrEqual,
              value: '5',
            ),
          );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(body: SpreadsheetCell(address: CellAddress(0, 1))),
          ),
        ),
      );

      expect(
        find.byTooltip(
          'Table column filtered · Filter: Greater than or equal "5" · '
          '1 filtered column · 1 of 2 rows shown',
        ),
        findsOneWidget,
      );

      await tester.tap(
        find.byKey(const ValueKey('ky-sheet-table-header-action-$tableId-1')),
      );
      await tester.pumpAndSettle();

      expect(find.text('Active Filter'), findsOneWidget);
      expect(find.text('Greater than or equal "5"'), findsNWidgets(2));
      expect(find.text('Filter Impact'), findsOneWidget);
      expect(
        find.text('1 filtered column · 1 of 2 rows shown'),
        findsNWidgets(2),
      );
      expect(find.text('Edit Greater than or equal "5"'), findsOneWidget);

      await tester.tap(
        find.byKey(
          const ValueKey('ky-sheet-table-header-clear-filter-$tableId-1'),
        ),
      );
      await tester.pumpAndSettle();

      expect(container.read(filterProvider), isEmpty);
      expect(container.read(sheetFilterRulesProvider), isEmpty);
    });

    testWidgets('clears table-wide filters from table header actions', (
      tester,
    ) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      const tableId = 'table-sales';
      final table = SheetTable.fromSelection(
        id: tableId,
        name: 'Sales',
        selection: CellSelection(CellAddress(0, 0), CellAddress(2, 1)),
        styleId: SheetTableStyleId.prism,
      );
      container.read(sheetTablesProvider.notifier).replaceAll([table]);
      final sheet = container.read(spreadsheetProvider.notifier);
      sheet.updateCellValue(CellAddress(0, 0), 'Region');
      sheet.updateCellValue(CellAddress(0, 1), 'Sales');
      sheet.updateCellValue(CellAddress(1, 0), 'EMEA');
      sheet.updateCellValue(CellAddress(1, 1), '2');
      sheet.updateCellValue(CellAddress(2, 0), 'APAC');
      sheet.updateCellValue(CellAddress(2, 1), '5');
      final toolbar = container.read(toolbarControllerProvider);
      toolbar.setFilterRule(0, SheetFilterRule.contains('APAC'));
      toolbar.setFilterRule(
        1,
        const SheetFilterRule(
          operator: SheetFilterOperator.greaterThanOrEqual,
          value: '5',
        ),
      );
      toolbar.setFilterRule(4, SheetFilterRule.contains('Outside'));

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(body: SpreadsheetCell(address: CellAddress(0, 0))),
          ),
        ),
      );

      await tester.tap(
        find.byKey(const ValueKey('ky-sheet-table-header-action-$tableId-0')),
      );
      await tester.pumpAndSettle();

      expect(find.text('Clear Table Filters'), findsOneWidget);
      expect(
        find.text('2 filtered columns · 1 of 2 rows shown'),
        findsNWidgets(2),
      );

      await tester.tap(
        find.byKey(
          const ValueKey(
            'ky-sheet-table-header-clear-table-filters-$tableId-0',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(container.read(filterProvider), {4: 'Outside'});
      expect(container.read(sheetFilterRulesProvider).keys, [4]);
      expect(container.read(selectedCellProvider)?.label, 'A1:B3');
    });

    testWidgets('opens the column filter dialog from table header actions', (
      tester,
    ) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      const tableId = 'table-sales';
      final table = SheetTable.fromSelection(
        id: tableId,
        name: 'Sales',
        selection: CellSelection(CellAddress(0, 0), CellAddress(4, 1)),
        styleId: SheetTableStyleId.prism,
      ).copyWith(showTotalsRow: true);
      container.read(sheetTablesProvider.notifier).replaceAll([table]);
      final sheet = container.read(spreadsheetProvider.notifier);
      sheet.updateCellValue(CellAddress(0, 0), 'Region');
      sheet.updateCellValue(CellAddress(0, 1), 'Status');
      sheet.updateCellValue(CellAddress(1, 0), 'EMEA');
      sheet.updateCellValue(CellAddress(1, 1), 'Paid');
      sheet.updateCellValue(CellAddress(2, 0), 'APAC');
      sheet.updateCellValue(CellAddress(2, 1), 'Open');
      sheet.updateCellValue(CellAddress(3, 0), 'AMER');
      sheet.updateCellValue(CellAddress(3, 1), 'Paid');
      sheet.updateCellValue(CellAddress(4, 0), 'Total');
      sheet.updateCellValue(CellAddress(4, 1), 'Totals');

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(body: SpreadsheetCell(address: CellAddress(0, 1))),
          ),
        ),
      );

      await tester.tap(
        find.byKey(const ValueKey('ky-sheet-table-header-action-$tableId-1')),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('ky-sheet-table-header-filter-$tableId-1')),
      );
      await tester.pumpAndSettle();

      expect(find.text('Sort & Filter Sales[Status]'), findsOneWidget);
      expect(find.text('Table body values only'), findsOneWidget);
      expect(find.text('2 of 2 selected'), findsOneWidget);
      expect(find.text('Totals'), findsNothing);

      await tester.ensureVisible(find.text('Open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Open'));
      await tester.tap(find.text('Apply'));
      await tester.pumpAndSettle();

      final rule = container.read(sheetFilterRulesProvider)[1];
      expect(rule?.operator, SheetFilterOperator.oneOf);
      expect(rule?.valueList, ['Paid']);
      expect(
        SheetFilterEvaluator.visibleRows(
          rows: [1, 2, 3],
          filters: container.read(filterProvider),
          filterRules: container.read(sheetFilterRulesProvider),
          cells: container.read(spreadsheetProvider),
        ),
        [1, 3],
      );
      expect(container.read(selectedCellProvider)?.label, 'B1:B4');
    });

    testWidgets('renames table headers from the header action menu', (
      tester,
    ) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      const tableId = 'table-sales';
      final table = SheetTable.fromSelection(
        id: tableId,
        name: 'Sales',
        selection: CellSelection(CellAddress(0, 0), CellAddress(2, 1)),
        styleId: SheetTableStyleId.prism,
      );
      container.read(sheetTablesProvider.notifier).replaceAll([table]);
      final sheet = container.read(spreadsheetProvider.notifier);
      sheet.updateCellValue(CellAddress(0, 0), 'Region');
      sheet.updateCell(CellAddress(0, 1), CellData(value: '=Sales'));
      sheet.updateCellValue(CellAddress(1, 0), 'EMEA');
      sheet.updateCellValue(CellAddress(1, 1), '2');
      sheet.updateCellValue(CellAddress(2, 0), 'APAC');
      sheet.updateCellValue(CellAddress(2, 1), '5');

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(body: SpreadsheetCell(address: CellAddress(0, 1))),
          ),
        ),
      );

      await tester.tap(
        find.byKey(const ValueKey('ky-sheet-table-header-action-$tableId-1')),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('ky-sheet-table-header-rename-$tableId-1')),
      );
      await tester.pumpAndSettle();

      expect(find.text('Rename Header'), findsOneWidget);
      await tester.enterText(
        find.byKey(const ValueKey('ky-sheet-table-header-rename-name')),
        'Revenue',
      );
      await tester.tap(
        find.byKey(const ValueKey('ky-sheet-table-header-rename-confirm')),
      );
      await tester.pumpAndSettle();

      final renamedHeader = container.read(
        spreadsheetProvider,
      )[CellAddress(0, 1)];
      expect(renamedHeader?.value, 'Revenue');
      expect(renamedHeader?.formula, isNull);
      expect(container.read(selectedCellProvider)?.label, 'B1');
      expect(
        container.read(undoStackProvider).last.description,
        'Rename table header',
      );
    });

    testWidgets('renders comment and hyperlink metadata badges', (
      tester,
    ) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container
          .read(spreadsheetProvider.notifier)
          .updateCell(
            CellAddress(0, 0),
            CellData(
              value: 'Docs',
              comment: 'Needs legal review',
              hyperlink: 'https://example.com/docs',
            ),
          );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(body: SpreadsheetCell(address: CellAddress(0, 0))),
          ),
        ),
      );

      expect(find.byType(SheetCellMetadataBadges), findsOneWidget);
      expect(find.byIcon(Icons.link), findsOneWidget);
      expect(find.byIcon(Icons.comment), findsOneWidget);
      expect(find.byTooltip('https://example.com/docs'), findsOneWidget);
      expect(find.byTooltip('Needs legal review'), findsOneWidget);

      final text = tester.widget<Text>(find.text('Docs'));
      expect(text.style?.color, KySheetColors.accent);
      expect(text.style?.decoration, TextDecoration.underline);
    });

    testWidgets('renders formula reference preview styling', (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(formulaReferencePreviewProvider.notifier).state = [
        CellSelection(CellAddress(0, 0)),
      ];

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(body: SpreadsheetCell(address: CellAddress(0, 0))),
          ),
        ),
      );

      final outerContainer = tester.widget<Container>(
        find
            .descendant(
              of: find.byType(SpreadsheetCell),
              matching: find.byType(Container),
            )
            .first,
      );
      final decoration = outerContainer.decoration as BoxDecoration;
      final border = decoration.border as Border;

      expect(border.top.color, KySheetColors.formula);
      expect(border.top.width, 2);
    });

    testWidgets('renders invalid validation marker', (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container
          .read(spreadsheetProvider.notifier)
          .updateCell(
            CellAddress(0, 0),
            CellData(
              value: 'not-an-email',
              validation: CellValidation(
                type: ValidationType.email,
                errorMessage: 'Enter a valid email',
              ),
            ),
          );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(body: SpreadsheetCell(address: CellAddress(0, 0))),
          ),
        ),
      );

      expect(find.byIcon(Icons.error), findsOneWidget);
    });

    testWidgets('renders formula error marker and tooltip', (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container
          .read(spreadsheetProvider.notifier)
          .updateCell(
            CellAddress(0, 0),
            CellData(value: '#DIV/0', formula: '=A1/0'),
          );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(body: SpreadsheetCell(address: CellAddress(0, 0))),
          ),
        ),
      );

      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is Tooltip &&
              widget.message?.contains('Division by zero') == true,
        ),
        findsOneWidget,
      );
    });

    testWidgets('selects list validation values from dropdown', (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container
          .read(spreadsheetProvider.notifier)
          .updateCell(
            CellAddress(0, 0),
            CellData(
              value: 'Open',
              validation: CellValidation(
                type: ValidationType.list,
                options: ['Open', 'Closed'],
              ),
            ),
          );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(body: SpreadsheetCell(address: CellAddress(0, 0))),
          ),
        ),
      );

      await tester.tap(find.byType(SheetValidationDropdownButton));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Closed').last);
      await tester.pumpAndSettle();

      expect(
        container.read(spreadsheetProvider)[CellAddress(0, 0)]?.value,
        'Closed',
      );
    });
  });
}

class _CommandPaletteSelectionHost extends StatefulWidget {
  const _CommandPaletteSelectionHost({required this.commands});

  final List<SheetCommand> commands;

  @override
  State<_CommandPaletteSelectionHost> createState() =>
      _CommandPaletteSelectionHostState();
}

class _CommandPaletteSelectionHostState
    extends State<_CommandPaletteSelectionHost> {
  String selectedCommandId = 'none';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Text(selectedCommandId),
          ElevatedButton(
            key: const ValueKey('ky-sheet-test-open-palette'),
            onPressed: () async {
              final command = await showDialog<SheetCommand>(
                context: context,
                builder: (context) =>
                    SheetCommandPaletteDialog(commands: widget.commands),
              );
              if (!mounted || command == null) return;
              setState(() => selectedCommandId = command.id);
            },
            child: const Text('Open palette'),
          ),
        ],
      ),
    );
  }
}
