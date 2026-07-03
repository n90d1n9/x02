/// FFI bindings for the Rust document engine.
/// 
/// This library provides Dart/Flutter integration with the docs_engine Rust crate,
/// enabling high-performance document operations similar to MS Word/Google Docs.
library;

import 'dart:ffi';
import 'dart:io';
import 'dart:convert';
import 'package:ffi/ffi.dart';

// ============================================================================
// FFI Function Signatures
// ============================================================================

typedef DocsEngineVersion = Pointer<Utf8> Function();
typedef DocsEngineVersionDart = String Function();

typedef DocsEngineFreeString = Void Function(Pointer<Utf8>);
typedef DocsEngineFreeStringDart = void Function(Pointer<Utf8>);

typedef DocsEngineFreeDocument = Void Function(Pointer<Void>);
typedef DocsEngineFreeDocumentDart = void Function(Pointer<Void>);

typedef CreateDocument = Pointer<Void> Function(Pointer<Utf8>);
typedef CreateDocumentDart = Pointer<Void> Function(Pointer<Utf8>);

typedef SerializeDocument = Pointer<Utf8> Function(Pointer<Void>);
typedef SerializeDocumentDart = Pointer<Utf8> Function(Pointer<Void>);

typedef DeserializeDocument = Pointer<Void> Function(Pointer<Utf8>);
typedef DeserializeDocumentDart = Pointer<Void> Function(Pointer<Utf8>);

typedef AddParagraph = Int32 Function(Pointer<Void>, Pointer<Utf8>);
typedef AddParagraphDart = int Function(Pointer<Void>, Pointer<Utf8>);

typedef AddHeading = Int32 Function(Pointer<Void>, Pointer<Utf8>, Uint8);
typedef AddHeadingDart = int Function(Pointer<Void>, Pointer<Utf8>, int);

typedef AddListItem = Int32 Function(Pointer<Void>, Pointer<Utf8>, Uint8);
typedef AddListItemDart = int Function(Pointer<Void>, Pointer<Utf8>, int);

typedef AddCodeBlock = Int32 Function(
    Pointer<Void>, Pointer<Utf8>, Pointer<Utf8>);
typedef AddCodeBlockDart = int Function(Pointer<Void>, Pointer<Utf8>, Pointer<Utf8>);

typedef AddQuote = Int32 Function(Pointer<Void>, Pointer<Utf8>);
typedef AddQuoteDart = int Function(Pointer<Void>, Pointer<Utf8>);

typedef DeleteBlock = Int32 Function(Pointer<Void>, Int32);
typedef DeleteBlockDart = int Function(Pointer<Void>, int);

typedef InsertText = Int32 Function(
    Pointer<Void>, Int32, Int32, Int32, Pointer<Utf8>);
typedef InsertTextDart = int Function(Pointer<Void>, int, int, int, Pointer<Utf8>);

typedef SplitBlock = Int32 Function(Pointer<Void>, Int32, Int32, Int32);
typedef SplitBlockDart = int Function(Pointer<Void>, int, int, int);

typedef ApplyInsertTextEdit = Pointer<Utf8> Function(
    Pointer<Void>, Uint64, Uint64, Uint64, Pointer<Utf8>);
typedef ApplyInsertTextEditDart = Pointer<Utf8> Function(
    Pointer<Void>, int, int, int, Pointer<Utf8>);

typedef ApplySplitBlockEdit = Pointer<Utf8> Function(
    Pointer<Void>, Uint64, Uint64, Uint64);
typedef ApplySplitBlockEditDart = Pointer<Utf8> Function(Pointer<Void>, int, int, int);

typedef GetBlockCount = Int32 Function(Pointer<Void>);
typedef GetBlockCountDart = int Function(Pointer<Void>);

typedef GetBlockJson = Pointer<Utf8> Function(Pointer<Void>, Int32);
typedef GetBlockJsonDart = Pointer<Utf8> Function(Pointer<Void>, int);

typedef GetDocumentTitle = Pointer<Utf8> Function(Pointer<Void>);
typedef GetDocumentTitleDart = Pointer<Utf8> Function(Pointer<Void>);

typedef SetDocumentTitle = Int32 Function(Pointer<Void>, Pointer<Utf8>);
typedef SetDocumentTitleDart = int Function(Pointer<Void>, Pointer<Utf8>);

// ============================================================================
// Document Engine Operation Types
// ============================================================================

enum DocumentOperationType {
  insertText,
  deleteText,
  formatText,
  insertBlock,
  deleteBlock,
  splitBlock,
  mergeBlocks,
}

// ============================================================================
// Document Block Model
// ============================================================================

/// Represents a block in the document (paragraph, heading, list item, etc.)
class DocumentBlock {
  final String id;
  final String type; // 'paragraph', 'heading_1', 'list_item', etc.
  final List<TextSpan> spans;
  
  DocumentBlock({
    required this.id,
    required this.type,
    this.spans = const [],
  });
  
  factory DocumentBlock.fromJson(Map<String, dynamic> json) {
    return DocumentBlock(
      id: json['id'] as String,
      type: _parseBlockType(json['block_type']),
      spans: (json['spans'] as List?)
          ?.map((s) => TextSpan.fromJson(s as Map<String, dynamic>))
          .toList() ?? [],
    );
  }
  
  static String _parseBlockType(dynamic blockType) {
    if (blockType is String) return blockType;
    // Handle Rust enum serialization like "Heading(1)"
    final str = blockType.toString();
    return str.toLowerCase().replaceAll(RegExp(r'[()]'), '_');
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'block_type': type,
      'spans': spans.map((s) => s.toJson()).toList(),
    };
  }
}

// ============================================================================
// Text Span and Style Models
// ============================================================================

/// A span of text with uniform styling
class TextSpan {
  final String text;
  final TextStyle style;
  
  TextSpan({
    required this.text,
    this.style = const TextStyle(),
  });
  
  factory TextSpan.fromJson(Map<String, dynamic> json) {
    return TextSpan(
      text: json['text'] as String,
      style: TextStyle.fromJson(json['style'] as Map<String, dynamic>? ?? {}),
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'style': style.toJson(),
    };
  }
}

/// Text styling attributes
class TextStyle {
  final bool bold;
  final bool italic;
  final bool underline;
  final bool strikethrough;
  final String? fontFamily;
  final double? fontSize;
  final String? color;
  
  const TextStyle({
    this.bold = false,
    this.italic = false,
    this.underline = false,
    this.strikethrough = false,
    this.fontFamily,
    this.fontSize,
    this.color,
  });
  
  factory TextStyle.fromJson(Map<String, dynamic> json) {
    return TextStyle(
      bold: json['bold'] as bool? ?? false,
      italic: json['italic'] as bool? ?? false,
      underline: json['underline'] as bool? ?? false,
      strikethrough: json['strikethrough'] as bool? ?? false,
      fontFamily: json['font_family'] as String?,
      fontSize: (json['font_size'] as num?)?.toDouble(),
      color: json['color'] as String?,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'bold': bold,
      'italic': italic,
      'underline': underline,
      'strikethrough': strikethrough,
      if (fontFamily != null) 'font_family': fontFamily,
      if (fontSize != null) 'font_size': fontSize,
      if (color != null) 'color': color,
    };
  }
  
  TextStyle copyWith({
    bool? bold,
    bool? italic,
    bool? underline,
    bool? strikethrough,
    String? fontFamily,
    double? fontSize,
    String? color,
  }) {
    return TextStyle(
      bold: bold ?? this.bold,
      italic: italic ?? this.italic,
      underline: underline ?? this.underline,
      strikethrough: strikethrough ?? this.strikethrough,
      fontFamily: fontFamily ?? this.fontFamily,
      fontSize: fontSize ?? this.fontSize,
      color: color ?? this.color,
    );
  }
}

// ============================================================================
// Document Selection and Operation Result
// ============================================================================

/// Document selection range
class DocumentSelection {
  final int blockIndex;
  final int spanIndex;
  final int offset;
  
  DocumentSelection({
    required this.blockIndex,
    required this.spanIndex,
    required this.offset,
  });
  
  Map<String, dynamic> toJson() {
    return {
      'block_index': blockIndex,
      'span_index': spanIndex,
      'offset': offset,
    };
  }
}

/// Result of a document operation
class DocumentOperationResult {
  final bool success;
  final String? error;
  final String? documentJson;
  final List<int>? changedBlocks;
  
  DocumentOperationResult({
    required this.success,
    this.error,
    this.documentJson,
    this.changedBlocks,
  });
  
  factory DocumentOperationResult.fromJson(Map<String, dynamic> json) {
    return DocumentOperationResult(
      success: json['success'] as bool,
      error: json['error'] as String?,
      documentJson: json['document_json'] as String?,
      changedBlocks: (json['changed_blocks'] as List?)?.cast<int>(),
    );
  }
  
  factory DocumentOperationResult.fromOutcomeJson(String json) {
    final decoded = jsonDecode(json) as Map<String, dynamic>;
    return DocumentOperationResult(
      success: true,
      changedBlocks: (decoded['changed_blocks'] as List?)?.cast<int>(),
    );
  }
}

// ============================================================================
// Document Engine - FFI Implementation
// ============================================================================

/// High-level interface to the Rust document engine via FFI
class DocumentEngine {
  static DocumentEngine? _instance;
  
  DynamicLibrary? _lib;
  late DocsEngineVersionDart _version;
  late DocsEngineFreeStringDart _freeString;
  late DocsEngineFreeDocumentDart _freeDocument;
  late CreateDocumentDart _createDocument;
  late SerializeDocumentDart _serializeDocument;
  late DeserializeDocumentDart _deserializeDocument;
  late AddParagraphDart _addParagraph;
  late AddHeadingDart _addHeading;
  late AddListItemDart _addListItem;
  late AddCodeBlockDart _addCodeBlock;
  late AddQuoteDart _addQuote;
  late DeleteBlockDart _deleteBlock;
  late InsertTextDart _insertText;
  late SplitBlockDart _splitBlock;
  late ApplyInsertTextEditDart _applyInsertTextEdit;
  late ApplySplitBlockEditDart _applySplitBlockEdit;
  late GetBlockCountDart _getBlockCount;
  late GetBlockJsonDart _getBlockJson;
  late GetDocumentTitleDart _getDocumentTitle;
  late SetDocumentTitleDart _setDocumentTitle;
  
  bool _initialized = false;
  
  /// Get singleton instance
  static DocumentEngine get instance {
    _instance ??= DocumentEngine._();
    return _instance!;
  }
  
  DocumentEngine._();
  
  /// Initialize the FFI library
  Future<void> initialize({String? libraryPath}) async {
    if (_initialized) return;
    
    try {
      if (libraryPath != null) {
        _lib = DynamicLibrary.open(libraryPath);
      } else if (Platform.isAndroid) {
        _lib = DynamicLibrary.open('libdocs_engine_ffi.so');
      } else if (Platform.isIOS) {
        _lib = DynamicLibrary.process();
      } else if (Platform.isLinux) {
        _lib = DynamicLibrary.open('libdocs_engine_ffi.so');
      } else if (Platform.isMacOS) {
        _lib = DynamicLibrary.open('libdocs_engine_ffi.dylib');
      } else if (Platform.isWindows) {
        _lib = DynamicLibrary.open('docs_engine_ffi.dll');
      } else {
        throw UnsupportedError('Platform not supported: ${Platform.operatingSystem}');
      }
      
      _bindFunctions();
      _initialized = true;
    } catch (e) {
      print('Warning: Failed to load native library: $e');
      print('Running in fallback mode without native engine');
      _initialized = false;
    }
  }
  
  void _bindFunctions() {
    if (_lib == null) return;
    
    _version = _lib!.lookupFunction<DocsEngineVersion, DocsEngineVersionDart>('docs_engine_version');
    _freeString = _lib!.lookupFunction<DocsEngineFreeString, DocsEngineFreeStringDart>('docs_engine_free_string');
    _freeDocument = _lib!.lookupFunction<DocsEngineFreeDocument, DocsEngineFreeDocumentDart>('docs_engine_free_document');
    _createDocument = _lib!.lookupFunction<CreateDocument, CreateDocumentDart>('create_document');
    _serializeDocument = _lib!.lookupFunction<SerializeDocument, SerializeDocumentDart>('serialize_document');
    _deserializeDocument = _lib!.lookupFunction<DeserializeDocument, DeserializeDocumentDart>('deserialize_document');
    _addParagraph = _lib!.lookupFunction<AddParagraph, AddParagraphDart>('add_paragraph');
    _addHeading = _lib!.lookupFunction<AddHeading, AddHeadingDart>('add_heading');
    _addListItem = _lib!.lookupFunction<AddListItem, AddListItemDart>('add_list_item');
    _addCodeBlock = _lib!.lookupFunction<AddCodeBlock, AddCodeBlockDart>('add_code_block');
    _addQuote = _lib!.lookupFunction<AddQuote, AddQuoteDart>('add_quote');
    _deleteBlock = _lib!.lookupFunction<DeleteBlock, DeleteBlockDart>('delete_block');
    _insertText = _lib!.lookupFunction<InsertText, InsertTextDart>('insert_text');
    _splitBlock = _lib!.lookupFunction<SplitBlock, SplitBlockDart>('split_block');
    _applyInsertTextEdit = _lib!.lookupFunction<ApplyInsertTextEdit, ApplyInsertTextEditDart>('apply_insert_text_edit');
    _applySplitBlockEdit = _lib!.lookupFunction<ApplySplitBlockEdit, ApplySplitBlockEditDart>('apply_split_block_edit');
    _getBlockCount = _lib!.lookupFunction<GetBlockCount, GetBlockCountDart>('get_block_count');
    _getBlockJson = _lib!.lookupFunction<GetBlockJson, GetBlockJsonDart>('get_block_json');
    _getDocumentTitle = _lib!.lookupFunction<GetDocumentTitle, GetDocumentTitleDart>('get_document_title');
    _setDocumentTitle = _lib!.lookupFunction<SetDocumentTitle, SetDocumentTitleDart>('set_document_title');
  }
  
  String _pointerToString(Pointer<Utf8> ptr) {
    final result = ptr.toDartString();
    _freeString(ptr);
    return result;
  }
  
  /// Get engine version
  String get version {
    if (!_initialized || _lib == null) return '0.1.0 (fallback)';
    return _pointerToString(_version());
  }
  
  /// Check if native engine is available
  bool get isNativeEngineAvailable => _initialized && _lib != null;
  
  // ============================================================================
  // Document Management
  // ============================================================================
  
  /// Create a new document (returns native pointer wrapper)
  Future<NativeDocumentHandle> createDocument(String title) async {
    if (!_initialized || _lib == null) {
      // Fallback: return in-memory document
      return NativeDocumentHandle.inMemory(Document(title: title, blocks: []));
    }
    
    final titlePtr = title.toNativeUtf8();
    try {
      final docPtr = _createDocument(titlePtr);
      return NativeDocumentHandle.native(docPtr, this);
    } finally {
      calloc.free(titlePtr);
    }
  }
  
  /// Load document from JSON
  Future<NativeDocumentHandle> loadDocument(String json) async {
    if (!_initialized || _lib == null) {
      // Fallback: parse JSON to in-memory document
      final decoded = jsonDecode(json) as Map<String, dynamic>;
      return NativeDocumentHandle.inMemory(Document.fromJson(decoded));
    }
    
    final jsonPtr = json.toNativeUtf8();
    try {
      final docPtr = _deserializeDocument(jsonPtr);
      if (docPtr.address == 0) {
        throw Exception('Failed to deserialize document');
      }
      return NativeDocumentHandle.native(docPtr, this);
    } finally {
      calloc.free(jsonPtr);
    }
  }
  
  // ============================================================================
  // Block Operations
  // ============================================================================
  
  /// Add a paragraph block
  Future<int> addParagraph(NativeDocumentHandle handle, String text) async {
    if (!handle.isNative || !_initialized || _lib == null) {
      // Fallback: modify in-memory document
      final block = DocumentBlock(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        type: 'paragraph',
        spans: [TextSpan(text: text)],
      );
      handle.document.blocks.add(block);
      return handle.document.blocks.length - 1;
    }
    
    final textPtr = text.toNativeUtf8();
    try {
      final index = _addParagraph(handle.nativePtr!, textPtr);
      if (index < 0) throw Exception('Failed to add paragraph');
      return index;
    } finally {
      calloc.free(textPtr);
    }
  }
  
  /// Add a heading block
  Future<int> addHeading(
    NativeDocumentHandle handle,
    String text,
    int level,
  ) async {
    if (!handle.isNative || !_initialized || _lib == null) {
      final block = DocumentBlock(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        type: 'heading_$level',
        spans: [TextSpan(text: text)],
      );
      handle.document.blocks.add(block);
      return handle.document.blocks.length - 1;
    }
    
    final textPtr = text.toNativeUtf8();
    try {
      final index = _addHeading(handle.nativePtr!, textPtr, level.clamp(1, 6));
      if (index < 0) throw Exception('Failed to add heading');
      return index;
    } finally {
      calloc.free(textPtr);
    }
  }
  
  /// Add a list item block
  Future<int> addListItem(
    NativeDocumentHandle handle,
    String text,
    int indentLevel,
  ) async {
    if (!handle.isNative || !_initialized || _lib == null) {
      final block = DocumentBlock(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        type: 'list_item_$indentLevel',
        spans: [TextSpan(text: text)],
      );
      handle.document.blocks.add(block);
      return handle.document.blocks.length - 1;
    }
    
    final textPtr = text.toNativeUtf8();
    try {
      final index = _addListItem(handle.nativePtr!, textPtr, indentLevel);
      if (index < 0) throw Exception('Failed to add list item');
      return index;
    } finally {
      calloc.free(textPtr);
    }
  }
  
  /// Add a code block
  Future<int> addCodeBlock(
    NativeDocumentHandle handle,
    String code,
    String language,
  ) async {
    if (!handle.isNative || !_initialized || _lib == null) {
      final block = DocumentBlock(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        type: 'code_block',
        spans: [TextSpan(text: code, style: const TextStyle(fontFamily: 'monospace'))],
      );
      handle.document.blocks.add(block);
      return handle.document.blocks.length - 1;
    }
    
    final codePtr = code.toNativeUtf8();
    final langPtr = language.toNativeUtf8();
    try {
      final index = _addCodeBlock(handle.nativePtr!, codePtr, langPtr);
      if (index < 0) throw Exception('Failed to add code block');
      return index;
    } finally {
      calloc.free(codePtr);
      calloc.free(langPtr);
    }
  }
  
  /// Add a quote block
  Future<int> addQuote(NativeDocumentHandle handle, String text) async {
    if (!handle.isNative || !_initialized || _lib == null) {
      final block = DocumentBlock(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        type: 'quote',
        spans: [TextSpan(text: text)],
      );
      handle.document.blocks.add(block);
      return handle.document.blocks.length - 1;
    }
    
    final textPtr = text.toNativeUtf8();
    try {
      final index = _addQuote(handle.nativePtr!, textPtr);
      if (index < 0) throw Exception('Failed to add quote');
      return index;
    } finally {
      calloc.free(textPtr);
    }
  }
  
  /// Delete a block
  Future<void> deleteBlock(NativeDocumentHandle handle, int blockIndex) async {
    if (!handle.isNative || !_initialized || _lib == null) {
      if (blockIndex >= 0 && blockIndex < handle.document.blocks.length) {
        handle.document.blocks.removeAt(blockIndex);
      }
      return;
    }
    
    final result = _deleteBlock(handle.nativePtr!, blockIndex);
    if (result < 0) throw Exception('Failed to delete block');
  }
  
  // ============================================================================
  // Text Editing Operations
  // ============================================================================
  
  /// Insert text at specified position
  Future<DocumentOperationResult> insertText({
    required NativeDocumentHandle handle,
    required int blockIndex,
    required int spanIndex,
    required int charOffset,
    required String text,
  }) async {
    if (!handle.isNative || !_initialized || _lib == null) {
      // Fallback: modify in-memory document
      if (blockIndex >= 0 && blockIndex < handle.document.blocks.length) {
        final block = handle.document.blocks[blockIndex];
        if (spanIndex >= 0 && spanIndex < block.spans.length) {
          final span = block.spans[spanIndex];
          final newText = span.text.substring(0, charOffset) +
              text +
              span.text.substring(charOffset);
          block.spans[spanIndex] = TextSpan(text: newText, style: span.style);
        }
      }
      return DocumentOperationResult(success: true);
    }
    
    final textPtr = text.toNativeUtf8();
    try {
      final result = _insertText(
        handle.nativePtr!,
        blockIndex,
        spanIndex,
        charOffset,
        textPtr,
      );
      if (result < 0) {
        return DocumentOperationResult(
          success: false,
          error: 'Failed to insert text',
        );
      }
      return DocumentOperationResult(success: true);
    } finally {
      calloc.free(textPtr);
    }
  }
  
  /// Split block (e.g., when pressing Enter)
  Future<DocumentOperationResult> splitBlock({
    required NativeDocumentHandle handle,
    required int blockIndex,
    required int spanIndex,
    required int charOffset,
  }) async {
    if (!handle.isNative || !_initialized || _lib == null) {
      // Fallback: split in-memory
      if (blockIndex >= 0 && blockIndex < handle.document.blocks.length) {
        final block = handle.document.blocks[blockIndex];
        if (spanIndex >= 0 && spanIndex < block.spans.length) {
          final span = block.spans[spanIndex];
          if (charOffset > 0 && charOffset < span.text.length) {
            final firstPart = span.text.substring(0, charOffset);
            final secondPart = span.text.substring(charOffset);
            
            // Update current span
            block.spans[spanIndex] = TextSpan(text: firstPart, style: span.style);
            
            // Create new block with remainder
            final newBlock = DocumentBlock(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              type: block.type,
              spans: [
                TextSpan(text: secondPart, style: span.style),
                ...block.spans.skip(spanIndex + 1),
              ],
            );
            
            // Remove old spans after current
            if (spanIndex + 1 < block.spans.length) {
              block.spans.removeRange(spanIndex + 1, block.spans.length);
            }
            
            // Insert new block
            handle.document.blocks.insert(blockIndex + 1, newBlock);
          }
        }
      }
      return DocumentOperationResult(success: true);
    }
    
    final result = _splitBlock(handle.nativePtr!, blockIndex, spanIndex, charOffset);
    if (result < 0) {
      return DocumentOperationResult(
        success: false,
        error: 'Failed to split block',
      );
    }
    return DocumentOperationResult(success: true);
  }
  
  // ============================================================================
  // CRDT-style Edit Operations
  // ============================================================================
  
  /// Apply insert text edit (CRDT-compatible)
  Future<DocumentOperationResult> applyInsertTextEdit({
    required NativeDocumentHandle handle,
    required int blockIndex,
    required int spanIndex,
    required int charOffset,
    required String text,
  }) async {
    if (!handle.isNative || !_initialized || _lib == null) {
      return insertText(
        handle: handle,
        blockIndex: blockIndex,
        spanIndex: spanIndex,
        charOffset: charOffset,
        text: text,
      );
    }
    
    final textPtr = text.toNativeUtf8();
    try {
      final outcomePtr = _applyInsertTextEdit(
        handle.nativePtr!,
        blockIndex,
        spanIndex,
        charOffset,
        textPtr,
      );
      if (outcomePtr.address == 0) {
        return DocumentOperationResult(
          success: false,
          error: 'Failed to apply edit',
        );
      }
      final outcomeJson = _pointerToString(outcomePtr);
      return DocumentOperationResult.fromOutcomeJson(outcomeJson);
    } finally {
      calloc.free(textPtr);
    }
  }
  
  /// Apply split block edit (CRDT-compatible)
  Future<DocumentOperationResult> applySplitBlockEdit({
    required NativeDocumentHandle handle,
    required int blockIndex,
    required int spanIndex,
    required int charOffset,
  }) async {
    if (!handle.isNative || !_initialized || _lib == null) {
      return splitBlock(
        handle: handle,
        blockIndex: blockIndex,
        spanIndex: spanIndex,
        charOffset: charOffset,
      );
    }
    
    final outcomePtr = _applySplitBlockEdit(
      handle.nativePtr!,
      blockIndex,
      spanIndex,
      charOffset,
    );
    if (outcomePtr.address == 0) {
      return DocumentOperationResult(
        success: false,
        error: 'Failed to apply split',
      );
    }
    final outcomeJson = _pointerToString(outcomePtr);
    return DocumentOperationResult.fromOutcomeJson(outcomeJson);
  }
  
  // ============================================================================
  // Query Operations
  // ============================================================================
  
  /// Get block count
  Future<int> getBlockCount(NativeDocumentHandle handle) async {
    if (!handle.isNative || !_initialized || _lib == null) {
      return handle.document.blocks.length;
    }
    return _getBlockCount(handle.nativePtr!);
  }
  
  /// Get block as JSON
  Future<DocumentBlock?> getBlock(
    NativeDocumentHandle handle,
    int blockIndex,
  ) async {
    if (!handle.isNative || !_initialized || _lib == null) {
      if (blockIndex >= 0 && blockIndex < handle.document.blocks.length) {
        return handle.document.blocks[blockIndex];
      }
      return null;
    }
    
    final jsonPtr = _getBlockJson(handle.nativePtr!, blockIndex);
    if (jsonPtr.address == 0) return null;
    
    try {
      final json = _pointerToString(jsonPtr);
      return DocumentBlock.fromJson(jsonDecode(json) as Map<String, dynamic>);
    } catch (e) {
      return null;
    }
  }
  
  /// Get all blocks
  Future<List<DocumentBlock>> getAllBlocks(NativeDocumentHandle handle) async {
    final count = await getBlockCount(handle);
    final blocks = <DocumentBlock>[];
    
    for (int i = 0; i < count; i++) {
      final block = await getBlock(handle, i);
      if (block != null) blocks.add(block);
    }
    
    return blocks;
  }
  
  /// Get document title
  Future<String> getDocumentTitle(NativeDocumentHandle handle) async {
    if (!handle.isNative || !_initialized || _lib == null) {
      return handle.document.title;
    }
    
    final titlePtr = _getDocumentTitle(handle.nativePtr!);
    return _pointerToString(titlePtr);
  }
  
  /// Set document title
  Future<void> setDocumentTitle(
    NativeDocumentHandle handle,
    String title,
  ) async {
    if (!handle.isNative || !_initialized || _lib == null) {
      handle.document.title = title;
      return;
    }
    
    final titlePtr = title.toNativeUtf8();
    try {
      final result = _setDocumentTitle(handle.nativePtr!, titlePtr);
      if (result < 0) throw Exception('Failed to set title');
    } finally {
      calloc.free(titlePtr);
    }
  }
  
  /// Export document to JSON string
  Future<String> exportToJson(NativeDocumentHandle handle) async {
    if (!handle.isNative || !_initialized || _lib == null) {
      return jsonEncode(handle.document.toJson());
    }
    
    final jsonPtr = _serializeDocument(handle.nativePtr!);
    return _pointerToString(jsonPtr);
  }
  
  /// Import from DOCX using the Parser engine
  Future<NativeDocumentHandle> importFromDocx(List<int> bytes) async {
    // TODO: Integrate with ky-of-docx parser via FFI
    throw UnimplementedError('DOCX import not yet implemented');
  }
  
  /// Export document to DOCX
  Future<List<int>> exportToDocx(NativeDocumentHandle handle) async {
    // TODO: Integrate with ky-of-docx writer via FFI
    throw UnimplementedError('DOCX export not yet implemented');
  }
}

// ============================================================================
// Native Document Handle
// ============================================================================

/// Wrapper for native document pointer or in-memory document
class NativeDocumentHandle {
  final Pointer<Void>? _nativePtr;
  final Document? _inMemoryDoc;
  final DocumentEngine? _engine;
  
  NativeDocumentHandle._({
    Pointer<Void>? nativePtr,
    Document? inMemoryDoc,
    DocumentEngine? engine,
  })  : _nativePtr = nativePtr,
        _inMemoryDoc = inMemoryDoc,
        _engine = engine;
  
  factory NativeDocumentHandle.native(Pointer<Void> ptr, DocumentEngine engine) {
    return NativeDocumentHandle._(nativePtr: ptr, engine: engine);
  }
  
  factory NativeDocumentHandle.inMemory(Document doc) {
    return NativeDocumentHandle._(inMemoryDoc: doc);
  }
  
  Pointer<Void>? get nativePtr => _nativePtr;
  bool get isNative => _nativePtr != null;
  
  /// Access underlying in-memory document (for fallback mode)
  Document get document {
    if (_inMemoryDoc == null) {
      throw StateError('Cannot access in-memory document from native handle');
    }
    return _inMemoryDoc!;
  }
  
  /// Free native resources
  void dispose() {
    if (_nativePtr != null && _engine != null && _engine!._initialized) {
      _engine!._freeDocument(_nativePtr!);
    }
  }
}

// ============================================================================
// Document Model (In-Memory Fallback)
// ============================================================================

/// Represents a complete document (used in fallback mode without native engine)
class Document {
  final String id;
  final String title;
  final List<DocumentBlock> blocks;
  final DateTime createdAt;
  final DateTime modifiedAt;
  
  Document({
    String? id,
    required this.title,
    this.blocks = const [],
    DateTime? createdAt,
    DateTime? modifiedAt,
  }) : id = id ?? DateTime.now().millisecondsSinceEpoch.toString(),
       createdAt = createdAt ?? DateTime.now(),
       modifiedAt = modifiedAt ?? DateTime.now();
  
  factory Document.fromJson(Map<String, dynamic> json) {
    return Document(
      id: json['id'] as String?,
      title: json['title'] as String,
      blocks: (json['blocks'] as List?)
          ?.map((b) => DocumentBlock.fromJson(b as Map<String, dynamic>))
          .toList() ?? [],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      modifiedAt: json['modified_at'] != null
          ? DateTime.parse(json['modified_at'] as String)
          : null,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'blocks': blocks.map((b) => b.toJson()).toList(),
      'created_at': createdAt.toIso8601String(),
      'modified_at': modifiedAt.toIso8601String(),
    };
  }
  
  Document copyWith({
    String? id,
    String? title,
    List<DocumentBlock>? blocks,
    DateTime? createdAt,
    DateTime? modifiedAt,
  }) {
    return Document(
      id: id ?? this.id,
      title: title ?? this.title,
      blocks: blocks ?? this.blocks,
      createdAt: createdAt ?? this.createdAt,
      modifiedAt: modifiedAt ?? this.modifiedAt,
    );
  }
  
  /// Get total word count
  int get wordCount {
    return blocks.fold<int>(
      0,
      (sum, block) =>
          sum +
          block.spans.fold<int>(
            0,
            (spanSum, span) => spanSum + span.text.split(RegExp(r'\s+')).length,
          ),
    );
  }
  
  /// Get total character count
  int get characterCount {
    return blocks.fold<int>(
      0,
      (sum, block) =>
          sum + block.spans.fold<int>(0, (s, span) => s + span.text.length),
    );
  }
}
