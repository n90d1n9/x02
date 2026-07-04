import 'package:flutter_test/flutter_test.dart';
import 'package:ky_sheet/src/core/commands/command.dart';
import 'package:ky_sheet/src/core/commands/cell_commands.dart';
import 'package:ky_sheet/src/core/services/command_manager.dart';

void main() {
  group('SetCellValueCommand', () {
    late MockSpreadsheetService mockService;
    late CommandManager commandManager;

    setUp(() {
      mockService = MockSpreadsheetService();
      commandManager = CommandManager(mockService);
    });

    test('executes and sets cell value', () {
      final command = SetCellValueCommand(
        sheetId: 'sheet1',
        row: 0,
        col: 0,
        value: 'Hello',
        service: mockService,
      );

      command.execute();

      expect(mockService.setCellValueCalls, 1);
      expect(mockService.lastSetValue, 'Hello');
    });

    test('undo reverts cell value', () {
      mockService.initialValue = 'Original';
      
      final command = SetCellValueCommand(
        sheetId: 'sheet1',
        row: 0,
        col: 0,
        value: 'New',
        service: mockService,
      );

      command.execute();
      expect(mockService.lastSetValue, 'New');

      command.undo();
      expect(mockService.setCellValueCalls, 2);
      expect(mockService.lastSetValue, 'Original');
    });

    test('redo reapplies the change', () {
      mockService.initialValue = 'Original';
      
      final command = SetCellValueCommand(
        sheetId: 'sheet1',
        row: 0,
        col: 0,
        value: 'New',
        service: mockService,
      );

      command.execute();
      command.undo();
      command.redo();

      expect(mockService.setCellValueCalls, 3);
      expect(mockService.lastSetValue, 'New');
    });

    test('description returns meaningful text', () {
      final command = SetCellValueCommand(
        sheetId: 'sheet1',
        row: 5,
        col: 3,
        value: 'Test',
        service: mockService,
      );

      expect(command.description, contains('D6'));
      expect(command.description, contains('Test'));
    });
  });

  group('CommandManager', () {
    late MockSpreadsheetService mockService;
    late CommandManager commandManager;

    setUp(() {
      mockService = MockSpreadsheetService();
      commandManager = CommandManager(mockService);
    });

    test('maintains undo stack', () {
      for (int i = 0; i < 5; i++) {
        final command = SetCellValueCommand(
          sheetId: 'sheet1',
          row: 0,
          col: i,
          value: 'Value$i',
          service: mockService,
        );
        commandManager.execute(command);
      }

      expect(commandManager.canUndo, isTrue);
      expect(commandManager.undoStackLength, 5);
    });

    test('undo reduces stack and canRedo becomes true', () {
      final command = SetCellValueCommand(
        sheetId: 'sheet1',
        row: 0,
        col: 0,
        value: 'Test',
        service: mockService,
      );
      commandManager.execute(command);

      expect(commandManager.canUndo, isTrue);
      expect(commandManager.canRedo, isFalse);

      commandManager.undo();

      expect(commandManager.canUndo, isFalse);
      expect(commandManager.canRedo, isTrue);
    });

    test('redo restores state', () {
      final command = SetCellValueCommand(
        sheetId: 'sheet1',
        row: 0,
        col: 0,
        value: 'Test',
        service: mockService,
      );
      commandManager.execute(command);
      commandManager.undo();
      commandManager.redo();

      expect(commandManager.canUndo, isTrue);
      expect(commandManager.canRedo, isFalse);
    });

    test('new command clears redo stack', () {
      final command1 = SetCellValueCommand(
        sheetId: 'sheet1',
        row: 0,
        col: 0,
        value: 'First',
        service: mockService,
      );
      final command2 = SetCellValueCommand(
        sheetId: 'sheet1',
        row: 0,
        col: 1,
        value: 'Second',
        service: mockService,
      );

      commandManager.execute(command1);
      commandManager.undo();
      expect(commandManager.canRedo, isTrue);

      commandManager.execute(command2);
      expect(commandManager.canRedo, isFalse);
    });

    test('notifyListeners is called on execute', () {
      int listenerCallCount = 0;
      commandManager.addListener(() => listenerCallCount++);

      final command = SetCellValueCommand(
        sheetId: 'sheet1',
        row: 0,
        col: 0,
        value: 'Test',
        service: mockService,
      );
      commandManager.execute(command);

      expect(listenerCallCount, 1);
    });
  });

  group('BatchCommand', () {
    late MockSpreadsheetService mockService;
    late CommandManager commandManager;

    setUp(() {
      mockService = MockSpreadsheetService();
      commandManager = CommandManager(mockService);
    });

    test('executes all child commands', () {
      final commands = List.generate(
        3,
        (i) => SetCellValueCommand(
          sheetId: 'sheet1',
          row: 0,
          col: i,
          value: 'Value$i',
          service: mockService,
        ),
      );

      final batchCommand = BatchCommand(commands, description: 'Batch Update');
      commandManager.execute(batchCommand);

      expect(mockService.setCellValueCalls, 3);
    });

    test('undo reverts all child commands in reverse order', () {
      final commands = List.generate(
        3,
        (i) => SetCellValueCommand(
          sheetId: 'sheet1',
          row: 0,
          col: i,
          value: 'Value$i',
          service: mockService,
        ),
      );

      final batchCommand = BatchCommand(commands, description: 'Batch Update');
      commandManager.execute(batchCommand);
      commandManager.undo();

      // Each command was executed then undone = 2 calls per command
      expect(mockService.setCellValueCalls, 6);
    });

    test('treated as single unit in history', () {
      final commands = List.generate(
        3,
        (i) => SetCellValueCommand(
          sheetId: 'sheet1',
          row: 0,
          col: i,
          value: 'Value$i',
          service: mockService,
        ),
      );

      final batchCommand = BatchCommand(commands, description: 'Batch Update');
      commandManager.execute(batchCommand);

      expect(commandManager.undoStackLength, 1);
      
      commandManager.undo();
      expect(commandManager.undoStackLength, 0);
      expect(commandManager.canRedo, isTrue);
    });
  });
}

class MockSpreadsheetService {
  String initialValue = '';
  String lastSetValue = '';
  int setCellValueCalls = 0;

  void setCellValue({
    required String sheetId,
    required int row,
    required int col,
    required String value,
  }) {
    setCellValueCalls++;
    lastSetValue = value;
  }

  String getCellValue({
    required String sheetId,
    required int row,
    required int col,
  }) {
    return initialValue;
  }
}
