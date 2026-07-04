import 'dart:io';
import 'package:ky_sheet/src/core/events/sheet_events.dart';

/// Abstraction for file operations to enable testing and multiple storage backends.
abstract class StorageProvider {
  Future<bool> save(String path, Map<String, dynamic> data);
  Future<Map<String, dynamic>?> load(String path);
  Future<bool> exists(String path);
  Future<void> delete(String path);
  Future<List<String>> listFiles(String directory);
}

/// Local filesystem implementation of StorageProvider.
class LocalFileStorage implements StorageProvider {
  @override
  Future<bool> save(String path, Map<String, dynamic> data) async {
    try {
      final file = File(path);
      await file.create(recursive: true);
      await file.writeAsString(_encodeJson(data));
      return true;
    } catch (e) {
      print('Error saving file: $e');
      return false;
    }
  }

  @override
  Future<Map<String, dynamic>?> load(String path) async {
    try {
      final file = File(path);
      if (!await file.exists()) return null;
      final content = await file.readAsString();
      return _decodeJson(content);
    } catch (e) {
      print('Error loading file: $e');
      return null;
    }
  }

  @override
  Future<bool> exists(String path) async {
    return File(path).exists();
  }

  @override
  Future<void> delete(String path) async {
    await File(path).delete();
  }

  @override
  Future<List<String>> listFiles(String directory) async {
    final dir = Directory(directory);
    if (!await dir.exists()) return [];
    
    return dir
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.kysheet'))
        .map((f) => f.path)
        .toList();
  }

  String _encodeJson(Map<String, dynamic> data) {
    // Use a proper JSON encoder in production
    return ''; // Placeholder - will use dart:convert
  }

  Map<String, dynamic> _decodeJson(String content) {
    // Use a proper JSON decoder in production
    return {}; // Placeholder - will use dart:convert
  }
}

/// Service handling File menu operations: New, Open, Save, Save As, Export, Import.
/// Completely decoupled from UI - uses events for communication.
class FileService {
  final StorageProvider _storage;
  String? _currentFilePath;
  
  final void Function(SheetEvent) _emitEvent;
  final Map<String, dynamic> Function() _getWorkbookData;
  final void Function(Map<String, dynamic>) _loadWorkbookData;

  FileService({
    required StorageProvider storage,
    required void Function(SheetEvent) emitEvent,
    required Map<String, dynamic> Function() getWorkbookData,
    required void Function(Map<String, dynamic>) loadWorkbookData,
  }) : _storage = storage,
       _emitEvent = emitEvent,
       _getWorkbookData = getWorkbookData,
       _loadWorkbookData = loadWorkbookData;

  /// Create a new workbook.
  void newWorkbook() {
    _currentFilePath = null;
    _loadWorkbookData(_createDefaultWorkbook());
    _emitEvent(WorkbookCreatedEvent());
  }

  /// Open a workbook from file.
  Future<bool> openFile(String path) async {
    final data = await _storage.load(path);
    if (data == null) {
      _emitEvent(WorkbookOpenedEvent(path));
      return false;
    }

    _currentFilePath = path;
    _loadWorkbookData(data);
    _emitEvent(WorkbookOpenedEvent(path));
    return true;
  }

  /// Save the current workbook.
  Future<bool> saveFile() async {
    if (_currentFilePath == null) {
      return false; // Should trigger Save As
    }

    final data = _getWorkbookData();
    final success = await _storage.save(_currentFilePath!, data);
    _emitEvent(WorkbookSavedEvent(_currentFilePath!, success));
    return success;
  }

  /// Save the workbook to a specific path.
  Future<bool> saveFileAs(String path) async {
    final data = _getWorkbookData();
    final success = await _storage.save(path, data);
    
    if (success) {
      _currentFilePath = path;
    }
    
    _emitEvent(WorkbookSavedEvent(path, success));
    return success;
  }

  /// Export to CSV format.
  Future<bool> exportToCsv(String sheetId, String outputPath) async {
    // Implementation for CSV export
    return false;
  }

  /// Import from CSV format.
  Future<bool> importFromCsv(String path, String targetSheetId) async {
    // Implementation for CSV import
    return false;
  }

  /// Get the current file path.
  String? get currentFilePath => _currentFilePath;

  /// Check if the current workbook has been saved.
  bool get isSaved => _currentFilePath != null;

  Map<String, dynamic> _createDefaultWorkbook() {
    return {
      'version': '1.0',
      'sheets': [
        {
          'id': 'sheet_1',
          'name': 'Sheet1',
          'data': {},
        }
      ],
      'activeSheet': 'sheet_1',
    };
  }
}
