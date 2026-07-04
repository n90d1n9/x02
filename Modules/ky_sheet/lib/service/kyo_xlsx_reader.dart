<<<<<<< HEAD:Modules/ky_sheet/lib/service/kyo_xlsx_reader.dart
/// FFI bindings for parser-xlsx Rust library
///
=======
/// FFI bindings for ky-of-xlsx Rust library
/// 
>>>>>>> fdcc93050a737f18cc3ba965abd1229d5f2a24f1:Plugins/ky_sheet/lib/service/kyo_xlsx_reader.dart
/// This provides high-performance XLSX parsing for large spreadsheets
/// using the Worksuite Parser ecosystem.

import 'dart:ffi';
import 'dart:io';
import 'dart:convert';
import 'package:ffi/ffi.dart';

/// Workbook handle from the Rust library
class XlsxWorkbook {
  final Pointer<Void> _handle;
  final DynamicLibrary _lib;

  XlsxWorkbook._(this._handle, this._lib);

  static XlsxWorkbook? open(String path) {
    final lib = _loadLibrary();
    if (lib == null) return null;

    try {
<<<<<<< HEAD:Modules/ky_sheet/lib/service/kyo_xlsx_reader.dart
      final openFunc = lib
          .lookupFunction<
            Pointer<Void> Function(Pointer<Utf8>),
            Pointer<Void> Function(Pointer<Utf8>)
          >('xlsx_open');
=======
      final openFunc = lib.lookupFunction<
        Pointer<Void> Function(Pointer<Utf8>),
        Pointer<Void> Function(Pointer<Utf8>)
      >('xlsx_open');
>>>>>>> fdcc93050a737f18cc3ba965abd1229d5f2a24f1:Plugins/ky_sheet/lib/service/kyo_xlsx_reader.dart

      final cPath = path.toNativeUtf8();
      try {
        final handle = openFunc(cPath);
        if (handle == nullptr) return null;
        return XlsxWorkbook._(handle, lib);
      } finally {
        calloc.free(cPath);
      }
    } catch (e) {
      print('Error opening workbook: $e');
      return null;
    }
  }

  static DynamicLibrary? _loadLibrary() {
    try {
      if (Platform.isWindows) {
<<<<<<< HEAD:Modules/ky_sheet/lib/service/kyo_xlsx_reader.dart
        return DynamicLibrary.open('parser-xlsx.dll');
      } else if (Platform.isMacOS) {
        return DynamicLibrary.open('libparser-xlsx.dylib');
      } else {
        return DynamicLibrary.open('libparser-xlsx.so');
      }
    } catch (e) {
      print('Failed to load parser-xlsx library: $e');
=======
        return DynamicLibrary.open('ky-of-xlsx.dll');
      } else if (Platform.isMacOS) {
        return DynamicLibrary.open('libky-of-xlsx.dylib');
      } else {
        return DynamicLibrary.open('libky-of-xlsx.so');
      }
    } catch (e) {
      print('Failed to load ky-of-xlsx library: $e');
>>>>>>> fdcc93050a737f18cc3ba965abd1229d5f2a24f1:Plugins/ky_sheet/lib/service/kyo_xlsx_reader.dart
      return null;
    }
  }

  int get sheetCount {
    try {
<<<<<<< HEAD:Modules/ky_sheet/lib/service/kyo_xlsx_reader.dart
      final func = _lib
          .lookupFunction<
            Int32 Function(Pointer<Void>),
            int Function(Pointer<Void>)
          >('xlsx_sheet_count');
=======
      final func = _lib.lookupFunction<
        Int32 Function(Pointer<Void>),
        int Function(Pointer<Void>)
      >('xlsx_sheet_count');
>>>>>>> fdcc93050a737f18cc3ba965abd1229d5f2a24f1:Plugins/ky_sheet/lib/service/kyo_xlsx_reader.dart
      return func(_handle);
    } catch (e) {
      print('Error getting sheet count: $e');
      return 0;
    }
  }

  String? getSheetName(int index) {
    try {
<<<<<<< HEAD:Modules/ky_sheet/lib/service/kyo_xlsx_reader.dart
      final func = _lib
          .lookupFunction<
            Pointer<Utf8> Function(Pointer<Void>, Int32),
            Pointer<Utf8> Function(Pointer<Void>, int)
          >('xlsx_sheet_name');

=======
      final func = _lib.lookupFunction<
        Pointer<Utf8> Function(Pointer<Void>, Int32),
        Pointer<Utf8> Function(Pointer<Void>, int)
      >('xlsx_sheet_name');
      
>>>>>>> fdcc93050a737f18cc3ba965abd1229d5f2a24f1:Plugins/ky_sheet/lib/service/kyo_xlsx_reader.dart
      final result = func(_handle, index);
      if (result == nullptr) return null;
      return result.toDartString();
    } catch (e) {
      print('Error getting sheet name: $e');
      return null;
    }
  }

  XlsxSheet? getSheet(String name) {
    try {
<<<<<<< HEAD:Modules/ky_sheet/lib/service/kyo_xlsx_reader.dart
      final func = _lib
          .lookupFunction<
            Pointer<Void> Function(Pointer<Void>, Pointer<Utf8>),
            Pointer<Void> Function(Pointer<Void>, Pointer<Utf8>)
          >('xlsx_get_sheet');
=======
      final func = _lib.lookupFunction<
        Pointer<Void> Function(Pointer<Void>, Pointer<Utf8>),
        Pointer<Void> Function(Pointer<Void>, Pointer<Utf8>)
      >('xlsx_get_sheet');
>>>>>>> fdcc93050a737f18cc3ba965abd1229d5f2a24f1:Plugins/ky_sheet/lib/service/kyo_xlsx_reader.dart

      final cName = name.toNativeUtf8();
      try {
        final handle = func(_handle, cName);
        if (handle == nullptr) return null;
        return XlsxSheet._(handle, _lib);
      } finally {
        calloc.free(cName);
      }
    } catch (e) {
      print('Error getting sheet: $e');
      return null;
    }
  }

  void close() {
    try {
<<<<<<< HEAD:Modules/ky_sheet/lib/service/kyo_xlsx_reader.dart
      final func = _lib
          .lookupFunction<
            Void Function(Pointer<Void>),
            void Function(Pointer<Void>)
          >('xlsx_close');
=======
      final func = _lib.lookupFunction<
        Void Function(Pointer<Void>),
        void Function(Pointer<Void>)
      >('xlsx_close');
>>>>>>> fdcc93050a737f18cc3ba965abd1229d5f2a24f1:Plugins/ky_sheet/lib/service/kyo_xlsx_reader.dart
      func(_handle);
    } catch (e) {
      print('Error closing workbook: $e');
    }
  }
}

/// Sheet handle from the Rust library
class XlsxSheet {
  final Pointer<Void> _handle;
  final DynamicLibrary _lib;

  XlsxSheet._(this._handle, this._lib);

  int get rowCount {
    try {
<<<<<<< HEAD:Modules/ky_sheet/lib/service/kyo_xlsx_reader.dart
      final func = _lib
          .lookupFunction<
            Uint32 Function(Pointer<Void>),
            int Function(Pointer<Void>)
          >('xlsx_row_count');
=======
      final func = _lib.lookupFunction<
        Uint32 Function(Pointer<Void>),
        int Function(Pointer<Void>)
      >('xlsx_row_count');
>>>>>>> fdcc93050a737f18cc3ba965abd1229d5f2a24f1:Plugins/ky_sheet/lib/service/kyo_xlsx_reader.dart
      return func(_handle);
    } catch (e) {
      print('Error getting row count: $e');
      return 0;
    }
  }

  int get colCount {
    try {
<<<<<<< HEAD:Modules/ky_sheet/lib/service/kyo_xlsx_reader.dart
      final func = _lib
          .lookupFunction<
            Uint32 Function(Pointer<Void>),
            int Function(Pointer<Void>)
          >('xlsx_col_count');
=======
      final func = _lib.lookupFunction<
        Uint32 Function(Pointer<Void>),
        int Function(Pointer<Void>)
      >('xlsx_col_count');
>>>>>>> fdcc93050a737f18cc3ba965abd1229d5f2a24f1:Plugins/ky_sheet/lib/service/kyo_xlsx_reader.dart
      return func(_handle);
    } catch (e) {
      print('Error getting column count: $e');
      return 0;
    }
  }

  String? getCellValue(int row, int col) {
    try {
<<<<<<< HEAD:Modules/ky_sheet/lib/service/kyo_xlsx_reader.dart
      final func = _lib
          .lookupFunction<
            Pointer<Utf8> Function(Pointer<Void>, Uint32, Uint32),
            Pointer<Utf8> Function(Pointer<Void>, int, int)
          >('xlsx_cell_value');

      final result = func(_handle, row, col);
      if (result == nullptr) return null;

      final value = result.toDartString();

      // Free the returned string
      final freeFunc = _lib
          .lookupFunction<
            Void Function(Pointer<Utf8>),
            void Function(Pointer<Utf8>)
          >('xlsx_free_string');
      freeFunc(result);

=======
      final func = _lib.lookupFunction<
        Pointer<Utf8> Function(Pointer<Void>, Uint32, Uint32),
        Pointer<Utf8> Function(Pointer<Void>, int, int)
      >('xlsx_cell_value');

      final result = func(_handle, row, col);
      if (result == nullptr) return null;
      
      final value = result.toDartString();
      
      // Free the returned string
      final freeFunc = _lib.lookupFunction<
        Void Function(Pointer<Utf8>),
        void Function(Pointer<Utf8>)
      >('xlsx_free_string');
      freeFunc(result);
      
>>>>>>> fdcc93050a737f18cc3ba965abd1229d5f2a24f1:Plugins/ky_sheet/lib/service/kyo_xlsx_reader.dart
      return value;
    } catch (e) {
      print('Error getting cell value: $e');
      return null;
    }
  }

  /// Stream all cells in the sheet efficiently
  Stream<Map<String, dynamic>> streamCells() async* {
    final rows = rowCount;
    final cols = colCount;

    for (var row = 0; row < rows; row++) {
      final rowData = <String, dynamic>{};
      var hasData = false;

      for (var col = 0; col < cols; col++) {
        final value = getCellValue(row, col);
        if (value != null && value.isNotEmpty) {
          final colLetter = _columnIndexToLetter(col);
          rowData['$colLetter${row + 1}'] = value;
          hasData = true;
        }
      }

      if (hasData) {
        yield rowData;
      }
    }
  }

  static String _columnIndexToLetter(int index) {
    String letter = '';
    while (index >= 0) {
      letter = String.fromCharCode((index % 26) + 65) + letter;
      index = (index ~/ 26) - 1;
    }
    return letter;
  }
}

<<<<<<< HEAD:Modules/ky_sheet/lib/service/kyo_xlsx_reader.dart
/// High-level XLSX reader using parser-xlsx
=======
/// High-level XLSX reader using ky-of-xlsx
>>>>>>> fdcc93050a737f18cc3ba965abd1229d5f2a24f1:Plugins/ky_sheet/lib/service/kyo_xlsx_reader.dart
class KyoXlsxReader {
  /// Read XLSX file and return workbook data
  static Future<Map<String, dynamic>> readWorkbook(String path) async {
    final workbook = XlsxWorkbook.open(path);
    if (workbook == null) {
      throw Exception('Failed to open XLSX file: $path');
    }

    try {
      final sheets = <Map<String, dynamic>>[];
      final sheetCount = workbook.sheetCount;

      for (var i = 0; i < sheetCount; i++) {
        final sheetName = workbook.getSheetName(i);
        if (sheetName == null) continue;

        final sheet = workbook.getSheet(sheetName);
        if (sheet == null) continue;

        final cells = <String, dynamic>{};
<<<<<<< HEAD:Modules/ky_sheet/lib/service/kyo_xlsx_reader.dart

=======
        
>>>>>>> fdcc93050a737f18cc3ba965abd1229d5f2a24f1:Plugins/ky_sheet/lib/service/kyo_xlsx_reader.dart
        // Stream cells for memory efficiency
        await for (final rowData in sheet.streamCells()) {
          cells.addAll(rowData);
        }

        sheets.add({
          'name': sheetName,
          'cells': cells,
          'rowCount': sheet.rowCount,
          'colCount': sheet.colCount,
        });
      }

      return {
        'sheets': sheets,
        'path': path,
        'loadedAt': DateTime.now().toIso8601String(),
      };
    } finally {
      workbook.close();
    }
  }

  /// Read specific sheet from XLSX file
  static Future<Map<String, dynamic>> readSheet(
    String path,
    String sheetName,
  ) async {
    final workbook = XlsxWorkbook.open(path);
    if (workbook == null) {
      throw Exception('Failed to open XLSX file: $path');
    }

    try {
      final sheet = workbook.getSheet(sheetName);
      if (sheet == null) {
        throw Exception('Sheet not found: $sheetName');
      }

      final cells = <String, dynamic>{};
<<<<<<< HEAD:Modules/ky_sheet/lib/service/kyo_xlsx_reader.dart

=======
      
>>>>>>> fdcc93050a737f18cc3ba965abd1229d5f2a24f1:Plugins/ky_sheet/lib/service/kyo_xlsx_reader.dart
      await for (final rowData in sheet.streamCells()) {
        cells.addAll(rowData);
      }

      return {
        'name': sheetName,
        'cells': cells,
        'rowCount': sheet.rowCount,
        'colCount': sheet.colCount,
      };
    } finally {
      workbook.close();
    }
  }

  /// Get list of sheet names from XLSX file
  static Future<List<String>> getSheetNames(String path) async {
    final workbook = XlsxWorkbook.open(path);
    if (workbook == null) {
      throw Exception('Failed to open XLSX file: $path');
    }

    try {
      final names = <String>[];
      final sheetCount = workbook.sheetCount;

      for (var i = 0; i < sheetCount; i++) {
        final name = workbook.getSheetName(i);
        if (name != null) {
          names.add(name);
        }
      }

      return names;
    } finally {
      workbook.close();
    }
  }
}
