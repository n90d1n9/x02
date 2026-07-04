/// Native document canvas renderer that connects directly to the Rust engine.
///
/// This widget provides a MS Word/Google Docs-like editing experience by rendering
/// document blocks from the Rust engine instead of using flutter_quill.
///
/// Features:
/// - Direct rendering of blocks from DocumentEngine
/// - Page layout with margins, headers, footers
/// - Real-time collaboration support via CRDT operations
/// - DOCX import/export via parser-docx parser
library;

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

// TODO: Engine files not yet available
// import '../engine/document_engine.dart';
// import '../engine/docx_parser_service.dart';
import '../../engine/document_engine.dart';
import '../../engine/docx_parser_service.dart';
import '../models/page_layout.dart';
import '../models/page_settings.dart';
import 'document_page_chrome.dart';
import 'document_formatting_toolbar.dart';
import 'ruler/document_page_ruler.dart';
import 'ruler/document_page_vertical_ruler.dart';

// ============================================================================
// State Management
// ============================================================================

/// Provider for the document engine instance
final documentEngineProvider = Provider<DocumentEngine>((ref) {
  return DocumentEngine.instance;
});

/// Provider for DOCX parser service
final docxParserProvider = Provider<DocxParserService>((ref) {
  return DocxParserService();
});

/// State for the native document editor
class NativeDocumentState {
  final NativeDocumentHandle? documentHandle;
  final String title;
  final List<DocumentBlock> blocks;
  final int currentPage;
  final PageSettings pageSettings;
  final PageLayout layout;
  final double zoom;
  final DocumentSelection? selection;
  final bool isLoading;
  final String? error;

  NativeDocumentState({
    this.documentHandle,
    this.title = 'Untitled Document',
    this.blocks = const [],
    this.currentPage = 1,
    this.pageSettings = const PageSettings(),
    this.layout = PageLayout.print,
    this.zoom = 1.0,
    this.selection,
    this.isLoading = false,
    this.error,
  });

  NativeDocumentState copyWith({
    NativeDocumentHandle? documentHandle,
    String? title,
    List<DocumentBlock>? blocks,
    int? currentPage,
    PageSettings? pageSettings,
    PageLayout? layout,
    double? zoom,
    DocumentSelection? selection,
    bool? isLoading,
    String? error,
  }) {
    return NativeDocumentState(
      documentHandle: documentHandle ?? this.documentHandle,
      title: title ?? this.title,
      blocks: blocks ?? this.blocks,
      currentPage: currentPage ?? this.currentPage,
      pageSettings: pageSettings ?? this.pageSettings,
      layout: layout ?? this.layout,
      zoom: zoom ?? this.zoom,
      selection: selection ?? this.selection,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

/// Notifier for managing native document state
class NativeDocumentNotifier extends StateNotifier<NativeDocumentState> {
  final DocumentEngine _engine;
  final DocxParserService? _docxParser;

  NativeDocumentNotifier(this._engine, this._docxParser)
    : super(NativeDocumentState());

  /// Initialize a new document
  Future<void> createNewDocument(String title) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final handle = await _engine.createDocument(title);
      final blocks = await handle.getBlocks();

      state = state.copyWith(
        documentHandle: handle,
        title: title,
        blocks: blocks,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to create document: $e',
      );
    }
  }

  /// Load document from JSON
  Future<void> loadDocument(String json) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final handle = await _engine.loadDocument(json);
      final blocks = await handle.getBlocks();
      final title = await handle.getTitle();

      state = state.copyWith(
        documentHandle: handle,
        title: title,
        blocks: blocks,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load document: $e',
      );
    }
  }

  /// Import DOCX file
  Future<void> importDocx(Uint8List data) async {
    if (_docxParser == null) {
      state = state.copyWith(error: 'DOCX parser not available');
      return;
    }

    state = state.copyWith(isLoading: true, error: null);
    try {
      // Parse DOCX to intermediate format
      final docxContent = await _docxParser.parseDocx(data);

      // Create new document
      final handle = await _engine.createDocument(docxContent.title);

      // Add blocks from parsed content
      for (var block in docxContent.blocks) {
        await _addBlockFromDocx(handle, block);
      }

      final blocks = await handle.getBlocks();
      state = state.copyWith(
        documentHandle: handle,
        title: docxContent.title,
        blocks: blocks,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to import DOCX: $e',
      );
    }
  }

  Future<void> _addBlockFromDocx(
    NativeDocumentHandle handle,
    dynamic blockData,
  ) async {
    // Convert DOCX block to engine block
    // Implementation depends on DOCX parser output format
  }

  /// Add paragraph block
  Future<void> addParagraph(String text) async {
    final handle = state.documentHandle;
    if (handle == null) return;

    final index = await _engine.addParagraph(handle, text);
    final blocks = await handle.getBlocks();

    state = state.copyWith(
      blocks: blocks,
      selection: DocumentSelection(
        blockIndex: index,
        spanIndex: 0,
        offset: text.length,
      ),
    );
  }

  /// Add heading block
  Future<void> addHeading(String text, int level) async {
    final handle = state.documentHandle;
    if (handle == null) return;

    final index = await _engine.addHeading(handle, text, level);
    final blocks = await handle.getBlocks();
    state = state.copyWith(blocks: blocks);
  }

  /// Insert text at position
  Future<void> insertText(
    int blockIndex,
    int spanIndex,
    int offset,
    String text,
  ) async {
    final handle = state.documentHandle;
    if (handle == null) return;

    await _engine.insertText(handle, blockIndex, spanIndex, offset, text);
    final blocks = await handle.getBlocks();
    state = state.copyWith(blocks: blocks);
  }

  /// Apply formatting to selection
  Future<void> applyFormatting(TextStyle style) async {
    // TODO: Implement formatting via engine
  }

  /// Update page settings
  void updatePageSettings(PageSettings settings) {
    state = state.copyWith(pageSettings: settings);
  }

  /// Change zoom level
  void setZoom(double zoom) {
    state = state.copyWith(zoom: zoom.clamp(0.5, 2.0));
  }

  /// Dispose resources
  @override
  void dispose() {
    state.documentHandle?.dispose();
    super.dispose();
  }
}

final nativeDocumentProvider =
    StateNotifierProvider.family<
      NativeDocumentNotifier,
      NativeDocumentState,
      DocumentEngine
    >((ref, engine) {
      final docxParser = ref.watch(docxParserProvider);
      return NativeDocumentNotifier(engine, docxParser);
    });

// ============================================================================
// Main Canvas Widget
// ============================================================================

/// Native document editor canvas with MS Word/Google Docs-like UI
class NativeDocumentCanvas extends ConsumerStatefulWidget {
  final PageLayout layout;
  final PageSettings initialPageSettings;
  final VoidCallback? onDocumentLoaded;
  final ValueChanged<String>? onDocumentChanged;

  const NativeDocumentCanvas({
    super.key,
    this.layout = PageLayout.print,
    this.initialPageSettings = const PageSettings(),
    this.onDocumentLoaded,
    this.onDocumentChanged,
  });

  @override
  ConsumerState<NativeDocumentCanvas> createState() =>
      _NativeDocumentCanvasState();
}

class _NativeDocumentCanvasState extends ConsumerState<NativeDocumentCanvas> {
  late NativeDocumentNotifier _notifier;
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  // Editing state
  int? _activeBlockIndex;
  TextEditingValue? _currentTextValue;
  final Map<int, GlobalKey> _blockKeys = {};

  @override
  void initState() {
    super.initState();
    final engine = ref.read(documentEngineProvider);
    _notifier = ref.read(nativeDocumentProvider(engine));

    // Initialize engine
    _initializeEngine();
  }

  Future<void> _initializeEngine() async {
    final engine = ref.read(documentEngineProvider);
    await engine.initialize();

    // Create new document
    await _notifier.createNewDocument('Untitled Document');

    widget.onDocumentLoaded?.call();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(
      nativeDocumentProvider(ref.read(documentEngineProvider)),
    );

    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red[700]),
            const SizedBox(height: 16),
            Text('Error: ${state.error}', textAlign: TextAlign.center),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Formatting toolbar
        DocumentFormattingToolbar(
          onBoldPressed: () => _applyFormatting(bold: true),
          onItalicPressed: () => _applyFormatting(italic: true),
          onUnderlinePressed: () => _applyFormatting(underline: true),
          onHeadingPressed: (level) => _showHeadingPicker(level),
          onListPressed: (ordered) => _toggleList(ordered),
          onAlignPressed: (alignment) => _setAlignment(alignment),
          controller: null,
        ),

        const SizedBox(height: 8),

        // Rulers for print layout
        if (widget.layout == PageLayout.print) ...[
          DocumentPageRuler(
            pageSettings: state.pageSettings,
            onMarginsChanged: (margins) {
              _notifier.updatePageSettings(
                state.pageSettings.copyWith(margins: margins),
              );
            },
          ),
          const SizedBox(height: 8),
        ],

        // Document content area
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (widget.layout == PageLayout.print)
                DocumentPageVerticalRuler(
                  pageSettings: state.pageSettings,
                  onMarginsChanged: (margins) {
                    _notifier.updatePageSettings(
                      state.pageSettings.copyWith(margins: margins),
                    );
                  },
                ),

              Expanded(
                child: Container(
                  color: Theme.of(
                    context,
                  ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.38),
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    child: Center(child: _buildDocumentPage(state)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDocumentPage(NativeDocumentState state) {
    final pageWidth = state.pageSettings.pageSize.width;
    final pageHeight = state.pageSettings.pageSize.height;
    final scale = state.zoom;

    return Transform.scale(
      scale: scale,
      child: Container(
        width: pageWidth,
        height: pageHeight,
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: state.pageSettings.margins,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header area
            if (state.pageSettings.showHeader)
              _buildHeaderFooterArea(isHeader: true),

            // Document blocks
            Expanded(
              child: ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: state.blocks.length,
                itemBuilder: (context, index) {
                  return _buildBlockWidget(state.blocks[index], index);
                },
              ),
            ),

            // Footer area
            if (state.pageSettings.showFooter)
              _buildHeaderFooterArea(isHeader: false),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderFooterArea({required bool isHeader}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        border: Border(
          bottom: isHeader
              ? BorderSide(color: Colors.grey.shade300)
              : BorderSide.none,
          top: !isHeader
              ? BorderSide(color: Colors.grey.shade300)
              : BorderSide.none,
        ),
      ),
      child: Text(
        isHeader ? 'Header' : 'Footer',
        style: TextStyle(
          color: Colors.grey.shade600,
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }

  Widget _buildBlockWidget(DocumentBlock block, int index) {
    final key = _blockKeys.putIfAbsent(index, () => GlobalKey());

    switch (block.type) {
      case 'paragraph':
        return _buildParagraphBlock(block, index, key);
      case 'heading_1':
      case 'heading_2':
      case 'heading_3':
        return _buildHeadingBlock(block, index, key);
      case 'list_item':
        return _buildListItemBlock(block, index, key);
      case 'code_block':
        return _buildCodeBlock(block, index, key);
      case 'quote':
        return _buildQuoteBlock(block, index, key);
      default:
        return _buildParagraphBlock(block, index, key);
    }
  }

  Widget _buildParagraphBlock(DocumentBlock block, int index, GlobalKey key) {
    final text = block.spans.map((s) => s.text).join();
    final isActive = _activeBlockIndex == index;

    return Container(
      key: key,
      padding: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        border: isActive
            ? Border.all(color: Theme.of(context).primaryColor, width: 2)
            : null,
      ),
      child: TextField(
        maxLines: null,
        decoration: const InputDecoration(
          border: InputBorder.none,
          contentPadding: EdgeInsets.zero,
          isDense: true,
        ),
        controller: TextEditingController(text: text),
        onTap: () => _onBlockTapped(index),
        onChanged: (value) => _onBlockTextChanged(index, value),
      ),
    );
  }

  Widget _buildHeadingBlock(DocumentBlock block, int index, GlobalKey key) {
    final level = int.tryParse(block.type.split('_').last) ?? 1;
    final text = block.spans.map((s) => s.text).join();

    final fontSize = switch (level) {
      1 => 32.0,
      2 => 24.0,
      3 => 18.0,
      _ => 16.0,
    };

    final fontWeight = switch (level) {
      1 => FontWeight.bold,
      2 => FontWeight.w600,
      _ => FontWeight.w500,
    };

    return Container(
      key: key,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        text,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: fontWeight,
          height: 1.3,
        ),
      ),
    );
  }

  Widget _buildListItemBlock(DocumentBlock block, int index, GlobalKey key) {
    final text = block.spans.map((s) => s.text).join();

    return Padding(
      key: key,
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 24, child: Text('•', style: TextStyle(fontSize: 16))),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }

  Widget _buildCodeBlock(DocumentBlock block, int index, GlobalKey key) {
    final text = block.spans.map((s) => s.text).join();

    return Container(
      key: key,
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Text(
        text,
        style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
      ),
    );
  }

  Widget _buildQuoteBlock(DocumentBlock block, int index, GlobalKey key) {
    final text = block.spans.map((s) => s.text).join();

    return Container(
      key: key,
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.only(left: 16),
      decoration: BoxDecoration(
        border: Border(left: BorderSide(color: Colors.blue, width: 4)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontStyle: FontStyle.italic,
          color: Colors.grey.shade700,
        ),
      ),
    );
  }

  void _onBlockTapped(int index) {
    setState(() {
      _activeBlockIndex = index;
    });
  }

  Future<void> _onBlockTextChanged(int index, String value) async {
    final state = ref.read(
      nativeDocumentProvider(ref.read(documentEngineProvider)),
    );

    if (index < state.blocks.length) {
      // Update block text via engine
      // For now, just update local state
      final blocks = List<DocumentBlock>.from(state.blocks);
      final oldBlock = blocks[index];
      blocks[index] = DocumentBlock(
        id: oldBlock.id,
        type: oldBlock.type,
        spans: [TextSpan(text: value)],
      );

      // In real implementation, call engine to persist change
      // await _notifier.updateBlock(index, value);
    }

    widget.onDocumentChanged?.call(value);
  }

  void _applyFormatting({bool? bold, bool? italic, bool? underline}) {
    // TODO: Apply formatting via engine
  }

  void _showHeadingPicker(int level) async {
    // Show dialog or dropdown for heading selection
  }

  void _toggleList(bool ordered) async {
    // Toggle list item block type
  }

  void _setAlignment(TextAlign alignment) {
    // Set text alignment
  }
}

// ============================================================================
// DOCX Import Dialog
// ============================================================================

/// Dialog for importing DOCX files
class DocxImportDialog extends StatefulWidget {
  const DocxImportDialog({super.key});

  @override
  State<DocxImportDialog> createState() => _DocxImportDialogState();
}

class _DocxImportDialogState extends State<DocxImportDialog> {
  Uint8List? _fileData;
  String? _fileName;
  bool _isParsing = false;
  String? _previewText;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Import DOCX'),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_fileData == null)
              ElevatedButton.icon(
                onPressed: _pickFile,
                icon: const Icon(Icons.upload_file),
                label: const Text('Select DOCX File'),
              )
            else
              Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.description),
                    title: Text(_fileName ?? ''),
                    subtitle: Text(
                      '${(_fileData!.length / 1024).toStringAsFixed(1)} KB',
                    ),
                  ),
                  if (_isParsing)
                    const CircularProgressIndicator()
                  else if (_previewText != null)
                    Container(
                      constraints: const BoxConstraints(maxHeight: 200),
                      child: SingleChildScrollView(child: Text(_previewText!)),
                    ),
                ],
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        if (_fileData != null && !_isParsing)
          ElevatedButton(onPressed: _importFile, child: const Text('Import')),
      ],
    );
  }

  Future<void> _pickFile() async {
    // Use file_picker to select DOCX file
    // For now, simulate with dummy data
    setState(() {
      _fileName = 'example.docx';
      _fileData = Uint8List(1024);
    });
  }

  Future<void> _importFile() async {
    if (_fileData == null) return;

    setState(() => _isParsing = true);

    try {
      final parser = ref.read(docxParserProvider);
      final content = await parser.parseDocx(_fileData!);

      setState(() {
        _previewText = content.blocks
            .map((b) => b.spans.map((s) => s.text).join())
            .join('\n');
        _isParsing = false;
      });

      // Pass document to parent
      if (mounted) {
        Navigator.pop(context, content);
      }
    } catch (e) {
      setState(() {
        _isParsing = false;
        _previewText = 'Error parsing file: $e';
      });
    }
  }
}
