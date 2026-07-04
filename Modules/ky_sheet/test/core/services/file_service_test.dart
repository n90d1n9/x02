import 'package:flutter_test/flutter_test.dart';
import 'package:ky_sheet/src/core/services/file_service.dart';
import 'package:ky_sheet/src/core/models/workbook.dart';

void main() {
  group('FileService', () {
    late FileService fileService;
    late MockFileStorage mockStorage;

    setUp(() {
      mockStorage = MockFileStorage();
      fileService = FileService(storage: mockStorage);
    });

    test('creates new workbook with default sheet', () {
      final workbook = fileService.createWorkbook('Test Book');

      expect(workbook.title, 'Test Book');
      expect(workbook.sheets.length, 1);
      expect(workbook.activeSheetIndex, 0);
      expect(fileService.state, FileState.ready);
    });

    test('saves workbook to storage', () async {
      final workbook = fileService.createWorkbook('Save Test');
      
      await fileService.saveWorkbook(workbook, path: '/test/path.xlsx');

      expect(mockStorage.saveCalls, 1);
      expect(mockStorage.lastSavedPath, '/test/path.xlsx');
      expect(fileService.state, FileState.ready);
    });

    test('opens workbook from storage', () async {
      mockStorage.mockContent = '{"title":"Opened Book","sheets":[{"id":"s1","name":"Sheet1","data":{}}]}';
      
      final workbook = await fileService.openWorkbook(path: '/test/path.xlsx');

      expect(mockStorage.loadCalls, 1);
      expect(workbook?.title, 'Opened Book');
      expect(fileService.state, FileState.ready);
    });

    test('handles file not found error', () async {
      mockStorage.shouldThrowNotFound = true;

      expect(
        () => fileService.openWorkbook(path: '/nonexistent.xlsx'),
        throwsA(isA<FileNotFoundException>()),
      );
      expect(fileService.state, FileState.error);
    });

    test('exports to CSV format', () async {
      final workbook = fileService.createWorkbook('Export Test');
      workbook.activeSheet.setCellValue(0, 0, 'A1');
      workbook.activeSheet.setCellValue(0, 1, 'B1');
      workbook.activeSheet.setCellValue(1, 0, 'A2');
      
      final csvContent = await fileService.exportToCsv(workbook, sheetIndex: 0);

      expect(csvContent, contains('A1,B1'));
      expect(csvContent, contains('A2,'));
    });

    test('imports from CSV content', () async {
      const csvContent = 'Name,Age,City\nAlice,30,NYC\nBob,25,LA';
      
      final workbook = await fileService.importFromCsv(csvContent, title: 'Imported');

      expect(workbook.title, 'Imported');
      expect(workbook.sheets.length, 1);
      expect(workbook.activeSheet.getCellValue(0, 0), 'Name');
      expect(workbook.activeSheet.getCellValue(1, 1), '25');
    });

    test('state transitions correctly during async operations', () async {
      fileService.createWorkbook('Loading Test');
      
      expect(fileService.state, FileState.ready);
      
      // Simulate save which should transition through loading
      final saveFuture = fileService.saveWorkbook(
        fileService.currentWorkbook!, 
        path: '/test.xlsx'
      );
      
      // State should be ready after completion (mock is instant)
      await saveFuture;
      expect(fileService.state, FileState.ready);
    });

    test('save as creates copy with new name', () async {
      final original = fileService.createWorkbook('Original');
      
      await fileService.saveAs(original, newPath: '/copy.xlsx', newTitle: 'Copy');

      expect(mockStorage.saveCalls, 1);
      expect(fileService.currentWorkbook?.title, 'Copy');
    });

    test('recent files list is maintained', () async {
      mockStorage.mockContent = '{"title":"Book1","sheets":[{"id":"s1","name":"Sheet1","data":{}}]}';
      
      await fileService.openWorkbook(path: '/file1.xlsx');
      await fileService.openWorkbook(path: '/file2.xlsx');

      expect(fileService.recentFiles.length, 2);
      expect(fileService.recentFiles.first.path, '/file2.xlsx');
    });
  });

  group('FileState Enum', () {
    test('has all expected states', () {
      expect(FileState.values.length, 4);
      expect(FileState.values, contains(FileState.idle));
      expect(FileState.values, contains(FileState.loading));
      expect(FileState.values, contains(FileState.ready));
      expect(FileState.values, contains(FileState.error));
    });
  });
}

class MockFileStorage implements IFileStorage {
  int saveCalls = 0;
  int loadCalls = 0;
  String? lastSavedPath;
  String? mockContent;
  bool shouldThrowNotFound = false;

  @override
  Future<void> save(String path, Uint8List content) async {
    saveCalls++;
    lastSavedPath = path;
  }

  @override
  Future<Uint8List> load(String path) async {
    loadCalls++;
    if (shouldThrowNotFound) {
      throw FileNotFoundException(path);
    }
    if (mockContent != null) {
      return Uint8List.fromList(mockContent!.codeUnits);
    }
    throw FileNotFoundException(path);
  }

  @override
  Future<bool> exists(String path) async {
    return !shouldThrowNotFound && mockContent != null;
  }

  @override
  Future<String> getDirectoryName(String path) async {
    return path.substring(0, path.lastIndexOf('/'));
  }

  @override
  Future<List<String>> listFiles(String directory) async {
    return ['/file1.xlsx', '/file2.xlsx'];
  }
}
