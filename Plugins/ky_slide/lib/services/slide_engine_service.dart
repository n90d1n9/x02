// lib/services/slide_engine_service.dart
import 'dart:convert';
import 'dart:ffi' as ffi;
import 'dart:io';
import 'dart:typed_data';
import 'package:ffi/ffi.dart';

import '../models/presentation.dart';

// FFI typedefs
typedef _SlideEngineVersionC = ffi.Pointer<Utf8> Function();
typedef _SlideEngineVersionDart = ffi.Pointer<Utf8> Function();

typedef _SlideEngineFreeStringC = ffi.Void Function(ffi.Pointer<Utf8>);
typedef _SlideEngineFreeStringDart = void Function(ffi.Pointer<Utf8>);

typedef _ImportPptxFromBytesC =
    ffi.Pointer<Utf8> Function(ffi.Pointer<ffi.Uint8>, ffi.Size);
typedef _ImportPptxFromBytesDart =
    ffi.Pointer<Utf8> Function(ffi.Pointer<ffi.Uint8>, int);

typedef _SerializePresentationC =
    ffi.Pointer<Utf8> Function(ffi.Pointer<ffi.Void>);
typedef _SerializePresentationDart =
    ffi.Pointer<Utf8> Function(ffi.Pointer<ffi.Void>);

typedef _DeserializePresentationC =
    ffi.Pointer<ffi.Void> Function(ffi.Pointer<Utf8>);
typedef _DeserializePresentationDart =
    ffi.Pointer<ffi.Void> Function(ffi.Pointer<Utf8>);

typedef _ExportPresentationJsonC =
    ffi.Pointer<Utf8> Function(ffi.Pointer<ffi.Void>);
typedef _ExportPresentationJsonDart =
    ffi.Pointer<Utf8> Function(ffi.Pointer<ffi.Void>);

typedef _SlideEngineFreePresentationC =
    ffi.Void Function(ffi.Pointer<ffi.Void>);
typedef _SlideEngineFreePresentationDart = void Function(ffi.Pointer<ffi.Void>);

typedef _AddShapeC =
    ffi.Int32 Function(ffi.Pointer<ffi.Void>, ffi.Pointer<Utf8>);
typedef _AddShapeDart = int Function(ffi.Pointer<ffi.Void>, ffi.Pointer<Utf8>);

typedef _RemoveShapeC =
    ffi.Int32 Function(ffi.Pointer<ffi.Void>, ffi.Pointer<Utf8>);
typedef _RemoveShapeDart =
    int Function(ffi.Pointer<ffi.Void>, ffi.Pointer<Utf8>);

typedef _MoveShapeC =
    ffi.Pointer<Utf8> Function(
      ffi.Pointer<ffi.Void>,
      ffi.Pointer<Utf8>,
      ffi.Double,
      ffi.Double,
    );
typedef _MoveShapeDart =
    ffi.Pointer<Utf8> Function(
      ffi.Pointer<ffi.Void>,
      ffi.Pointer<Utf8>,
      double,
      double,
    );

typedef _ResizeShapeC =
    ffi.Pointer<Utf8> Function(
      ffi.Pointer<ffi.Void>,
      ffi.Pointer<Utf8>,
      ffi.Double,
      ffi.Double,
    );
typedef _ResizeShapeDart =
    ffi.Pointer<Utf8> Function(
      ffi.Pointer<ffi.Void>,
      ffi.Pointer<Utf8>,
      double,
      double,
    );

typedef _UpdateShapeStyleC =
    ffi.Pointer<Utf8> Function(
      ffi.Pointer<ffi.Void>,
      ffi.Pointer<Utf8>,
      ffi.Pointer<Utf8>,
    );
typedef _UpdateShapeStyleDart =
    ffi.Pointer<Utf8> Function(
      ffi.Pointer<ffi.Void>,
      ffi.Pointer<Utf8>,
      ffi.Pointer<Utf8>,
    );

typedef _UndoC = ffi.Int32 Function(ffi.Pointer<ffi.Void>);
typedef _UndoDart = int Function(ffi.Pointer<ffi.Void>);

typedef _RedoC = ffi.Int32 Function(ffi.Pointer<ffi.Void>);
typedef _RedoDart = int Function(ffi.Pointer<ffi.Void>);

class SlideEngineService {
  static SlideEngineService? _instance;
  late final ffi.DynamicLibrary _dylib;

  late final _SlideEngineVersionDart _slideEngineVersion;
  late final _SlideEngineFreeStringDart _slideEngineFreeString;
  late final _ImportPptxFromBytesDart _importPptxFromBytes;
  late final _SerializePresentationDart _serializePresentation;
  late final _DeserializePresentationDart _deserializePresentation;
  late final _ExportPresentationJsonDart _exportPresentationJson;
  late final _SlideEngineFreePresentationDart _slideEngineFreePresentation;

  late final _AddShapeDart _addShape;
  late final _RemoveShapeDart _removeShape;
  late final _MoveShapeDart _moveShape;
  late final _ResizeShapeDart _resizeShape;
  late final _UpdateShapeStyleDart _updateShapeStyle;
  late final _UndoDart _undo;
  late final _RedoDart _redo;

  SlideEngineService._internal() {
    String libraryPath;
    if (Platform.isMacOS) {
      libraryPath = 'libslide_engine_ffi.dylib';
    } else if (Platform.isWindows) {
      libraryPath = 'slide_engine_ffi.dll';
    } else {
      libraryPath = 'libslide_engine_ffi.so';
    }

    // In a real flutter app, this is bundled via ffi plugins or loaded from bundle.
    // For demo purposes, we fallback to process if library is static or in same directory.
    try {
      _dylib = ffi.DynamicLibrary.open(libraryPath);
    } catch (_) {
      _dylib = ffi.DynamicLibrary.process();
    }

    _slideEngineVersion = _dylib
        .lookup<ffi.NativeFunction<_SlideEngineVersionC>>(
          'slide_engine_version',
        )
        .asFunction();
    _slideEngineFreeString = _dylib
        .lookup<ffi.NativeFunction<_SlideEngineFreeStringC>>(
          'slide_engine_free_string',
        )
        .asFunction();
    _importPptxFromBytes = _dylib
        .lookup<ffi.NativeFunction<_ImportPptxFromBytesC>>(
          'import_pptx_from_bytes',
        )
        .asFunction();
    _serializePresentation = _dylib
        .lookup<ffi.NativeFunction<_SerializePresentationC>>(
          'serialize_presentation',
        )
        .asFunction();
    _deserializePresentation = _dylib
        .lookup<ffi.NativeFunction<_DeserializePresentationC>>(
          'deserialize_presentation',
        )
        .asFunction();
    _exportPresentationJson = _dylib
        .lookup<ffi.NativeFunction<_ExportPresentationJsonC>>(
          'export_presentation_json',
        )
        .asFunction();
    _slideEngineFreePresentation = _dylib
        .lookup<ffi.NativeFunction<_SlideEngineFreePresentationC>>(
          'slide_engine_free_presentation',
        )
        .asFunction();

    _addShape = _dylib
        .lookup<ffi.NativeFunction<_AddShapeC>>('add_shape')
        .asFunction();
    _removeShape = _dylib
        .lookup<ffi.NativeFunction<_RemoveShapeC>>('remove_shape')
        .asFunction();
    _moveShape = _dylib
        .lookup<ffi.NativeFunction<_MoveShapeC>>('move_shape')
        .asFunction();
    _resizeShape = _dylib
        .lookup<ffi.NativeFunction<_ResizeShapeC>>('resize_shape')
        .asFunction();
    _updateShapeStyle = _dylib
        .lookup<ffi.NativeFunction<_UpdateShapeStyleC>>('update_shape_style')
        .asFunction();
    _undo = _dylib.lookup<ffi.NativeFunction<_UndoC>>('undo').asFunction();
    _redo = _dylib.lookup<ffi.NativeFunction<_RedoC>>('redo').asFunction();
  }

  static SlideEngineService get instance {
    _instance ??= SlideEngineService._internal();
    return _instance!;
  }

  String getVersion() {
    final ptr = _slideEngineVersion();
    if (ptr == ffi.nullptr) return 'unknown';
    final version = ptr.toDartString();
    _slideEngineFreeString(ptr);
    return version;
  }

  Presentation? importPptx(Uint8List bytes) {
    if (bytes.isEmpty) return null;

    final pointer = malloc.allocate<ffi.Uint8>(bytes.length);
    final nativeBytes = pointer.asTypedList(bytes.length);
    nativeBytes.setAll(0, bytes);

    final resultPtr = _importPptxFromBytes(pointer, bytes.length);
    malloc.free(pointer);

    if (resultPtr == ffi.nullptr) return null;

    final jsonString = resultPtr.toDartString();
    _slideEngineFreeString(resultPtr);

    try {
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      return Presentation.fromJson(json);
    } catch (_) {
      return null;
    }
  }

  ffi.Pointer<ffi.Void> createRustPresentation(Presentation presentation) {
    final jsonString = jsonEncode(presentation.toJson());
    final jsonPtr = jsonString.toNativeUtf8();
    final presPtr = _deserializePresentation(jsonPtr);
    malloc.free(jsonPtr);
    return presPtr;
  }

  String? serializeRustPresentation(ffi.Pointer<ffi.Void> presPtr) {
    if (presPtr == ffi.nullptr) return null;
    final jsonPtr = _serializePresentation(presPtr);
    if (jsonPtr == ffi.nullptr) return null;

    final jsonString = jsonPtr.toDartString();
    _slideEngineFreeString(jsonPtr);
    return jsonString;
  }

  void freeRustPresentation(ffi.Pointer<ffi.Void> presPtr) {
    if (presPtr != ffi.nullptr) {
      _slideEngineFreePresentation(presPtr);
    }
  }

  Presentation? getPresentation(ffi.Pointer<ffi.Void> presPtr) {
    if (presPtr == ffi.nullptr) return null;
    final jsonPtr = _exportPresentationJson(presPtr);
    if (jsonPtr == ffi.nullptr) return null;

    final jsonString = jsonPtr.toDartString();
    _slideEngineFreeString(jsonPtr);

    try {
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      return Presentation.fromJson(json);
    } catch (e) {
      return null;
    }
  }

  bool addShape(ffi.Pointer<ffi.Void> presPtr, String shapeJson) {
    if (presPtr == ffi.nullptr) return false;
    final shapePtr = shapeJson.toNativeUtf8();
    final result = _addShape(presPtr, shapePtr);
    malloc.free(shapePtr);
    return result == 0;
  }

  bool removeShape(ffi.Pointer<ffi.Void> presPtr, String shapeId) {
    if (presPtr == ffi.nullptr) return false;
    final idPtr = shapeId.toNativeUtf8();
    final result = _removeShape(presPtr, idPtr);
    malloc.free(idPtr);
    return result == 0;
  }

  void moveShape(
    ffi.Pointer<ffi.Void> presPtr,
    String shapeId,
    double dx,
    double dy,
  ) {
    if (presPtr == ffi.nullptr) return;
    final idPtr = shapeId.toNativeUtf8();
    final cmdPtr = _moveShape(presPtr, idPtr, dx, dy);
    malloc.free(idPtr);
    if (cmdPtr != ffi.nullptr) {
      _slideEngineFreeString(cmdPtr);
    }
  }

  void resizeShape(
    ffi.Pointer<ffi.Void> presPtr,
    String shapeId,
    double dw,
    double dh,
  ) {
    if (presPtr == ffi.nullptr) return;
    final idPtr = shapeId.toNativeUtf8();
    final cmdPtr = _resizeShape(presPtr, idPtr, dw, dh);
    malloc.free(idPtr);
    if (cmdPtr != ffi.nullptr) {
      _slideEngineFreeString(cmdPtr);
    }
  }

  String? updateShapeStyle(
    ffi.Pointer<ffi.Void> presPtr,
    String shapeId,
    String styleJson,
  ) {
    if (presPtr == ffi.nullptr) return null;
    final idPtr = shapeId.toNativeUtf8();
    final stylePtr = styleJson.toNativeUtf8();
    final resultPtr = _updateShapeStyle(presPtr, idPtr, stylePtr);
    malloc.free(idPtr);
    malloc.free(stylePtr);

    if (resultPtr == ffi.nullptr) return null;
    final result = resultPtr.toDartString();
    _slideEngineFreeString(resultPtr);
    return result;
  }

  bool undo(ffi.Pointer<ffi.Void> presPtr) {
    if (presPtr == ffi.nullptr) return false;
    return _undo(presPtr) == 0;
  }

  bool redo(ffi.Pointer<ffi.Void> presPtr) {
    if (presPtr == ffi.nullptr) return false;
    return _redo(presPtr) == 0;
  }
}
