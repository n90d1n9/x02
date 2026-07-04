# Native Document Engine - Usage Examples

This document provides practical examples of using the native Rust-backed document engine in `ky_docs`.

## Quick Start

### 1. Basic Setup

```dart
import 'package:flutter/material.dart';
import 'package:ky_docs/ky_docs.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize the engine
  await DocumentEngine.instance.initialize();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: ProviderScope(
        child: DocumentEditorScreen(),
      ),
    );
  }
}
```

### 2. Simple Document Editor

```dart
class DocumentEditorScreen extends ConsumerWidget {
  const DocumentEditorScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch document state
    final engine = ref.watch(documentEngineProvider);
    final docState = ref.watch(
      nativeDocumentProvider(engine),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(docState.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: () => _saveDocument(ref),
          ),
          IconButton(
            icon: const Icon(Icons.file_open),
            onPressed: () => _importDocx(context, ref),
          ),
        ],
      ),
      body: NativeDocumentCanvas(
        layout: PageLayout.print,
        onDocumentLoaded: () {
          print('Document loaded successfully');
        },
        onDocumentChanged: (text) {
          print('Document changed: $text');
        },
      ),
    );
  }

  void _saveDocument(WidgetRef ref) {
    final state = ref.read(nativeDocumentProvider(ref.read(documentEngineProvider)));
    // Save logic here
  }

  Future<void> _importDocx(BuildContext context, WidgetRef ref) async {
    final result = await showDialog<DocxContent>(
      context: context,
      builder: (_) => const DocxImportDialog(),
    );

    if (result != null) {
      // Handle imported content
    }
  }
}
```

## Advanced Examples

### Creating a Document Programmatically

```dart
Future<void> createReport(DocumentEngine engine) async {
  // Create new document
  final handle = await engine.createDocument('Monthly Report');

  // Add title
  await engine.addHeading(handle, 'Monthly Sales Report', 1);

  // Add introduction
  await engine.addParagraph(
    handle,
    'This report summarizes the sales performance for the current month.',
  );

  // Add section heading
  await engine.addHeading(handle, 'Key Metrics', 2);

  // Add list of metrics
  await engine.addListItem(handle, 'Total Revenue: \$1.2M', ordered: false);
  await engine.addListItem(handle, 'Units Sold: 15,432', ordered: false);
  await engine.addListItem(handle, 'New Customers: 892', ordered: false);

  // Add code block for data snippet
  await engine.addCodeBlock(
    handle,
    'revenue = 1_200_000\ngrowth = 0.15\nprint(f"Revenue: \${revenue}")',
    language: 'python',
  );

  // Add quote
  await engine.addQuote(
    handle,
    '"The best quarter we\'ve had in three years!" - CEO',
  );

  // Get final document
  final json = await handle.serialize();
  print('Document JSON: $json');

  // Clean up
  handle.dispose();
}
```

### Loading and Editing Existing Document

```dart
Future<void> editExistingDocument(DocumentEngine engine, String documentJson) async {
  // Load from JSON
  final handle = await engine.loadDocument(documentJson);

  // Get current state
  final blockCount = await handle.getBlockCount();
  print('Document has $blockCount blocks');

  // Get specific block
  final blockJson = await handle.getBlock(0);
  print('First block: $blockJson');

  // Insert text at position
  await engine.insertText(handle, 0, 0, 5, 'Updated ');

  // Split a block (simulates pressing Enter)
  await engine.splitBlock(handle, 0, 0, 10);

  // Get updated document
  final updatedJson = await handle.serialize();

  handle.dispose();
}
```

### DOCX Import with Preview

```dart
class DocxImporter extends ConsumerStatefulWidget {
  const DocxImporter({super.key});

  @override
  ConsumerState<DocxImporter> createState() => _DocxImporterState();
}

class _DocxImporterState extends ConsumerState<DocxImporter> {
  Uint8List? _fileBytes;
  DocxContent? _preview;
  bool _isProcessing = false;

  Future<void> pickAndPreviewFile() async {
    // Use file_picker or similar
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['docx'],
    );

    if (result == null) return;

    setState(() {
      _fileBytes = result.files.first.bytes!;
      _isProcessing = true;
    });

    try {
      final parser = ref.read(docxParserProvider);
      final content = await parser.parseDocx(_fileBytes!);

      setState(() {
        _preview = content;
        _isProcessing = false;
      });
    } catch (e) {
      setState(() => _isProcessing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> importToEditor() async {
    if (_preview == null || _fileBytes == null) return;

    final engine = ref.read(documentEngineProvider);
    final notifier = ref.read(nativeDocumentProvider(engine));

    await notifier.importDocx(_fileBytes!);

    if (mounted) {
      Navigator.pop(context); // Close importer
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ElevatedButton.icon(
          onPressed: _isProcessing ? null : pickAndPreviewFile,
          icon: const Icon(Icons.upload_file),
          label: Text(_isProcessing ? 'Processing...' : 'Select DOCX'),
        ),

        if (_preview != null) ...[
          Card(
            child: ListTile(
              title: Text(_preview!.metadata.title),
              subtitle: Text(
                '${_preview!.blocks.length} blocks | '
                '${_preview!.metadata.wordCount} words',
              ),
              trailing: Chip(
                label: Text('${_preview!.metadata.pageCount} pages'),
              ),
            ),
          ),

          ElevatedButton(
            onPressed: importToEditor,
            child: const Text('Import to Editor'),
          ),
        ],
      ],
    );
  }
}
```

### Custom Block Renderer

```dart
class CustomBlockRenderer extends StatelessWidget {
  final DocumentBlock block;
  final int index;
  final bool isActive;
  final ValueChanged<String>? onChanged;

  const CustomBlockRenderer({
    super.key,
    required this.block,
    required this.index,
    this.isActive = false,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    switch (block.type) {
      case 'callout':
        return _buildCallout(block);
      case 'math_equation':
        return _buildMathEquation(block);
      case 'signature':
        return _buildSignature(block);
      default:
        return _buildDefault(block);
    }
  }

  Widget _buildCallout(DocumentBlock block) {
    final text = block.spans.map((s) => s.text).join();

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        border: Border.all(color: Colors.blue),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: Colors.blue.shade700),
          const SizedBox(width: 12),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }

  Widget _buildMathEquation(DocumentBlock block) {
    final text = block.spans.map((s) => s.text).join();

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontFamily: 'monospace',
          fontSize: 16,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildSignature(DocumentBlock block) {
    return Container(
      margin: const EdgeInsets.only(top: 32),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Digitally Signed',
            style: TextStyle(
              color: Colors.green.shade700,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            block.spans.map((s) => s.text).join(),
            style: TextStyle(
              color: Colors.grey.shade600,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDefault(DocumentBlock block) {
    final text = block.spans.map((s) => s.text).join();
    return Text(text);
  }
}
```

### Real-time Collaboration Hook

```dart
/// Example of how to integrate real-time collaboration
class CollaborativeEditor extends ConsumerStatefulWidget {
  final String documentId;

  const CollaborativeEditor({super.key, required this.documentId});

  @override
  ConsumerState<CollaborativeEditor> createState() =>
      _CollaborativeEditorState();
}

class _CollaborativeEditorState extends ConsumerState<CollaborativeEditor> {
  WebSocketChannel? _channel;

  @override
  void initState() {
    super.initState();
    _connectToCollaborationServer();
  }

  void _connectToCollaborationServer() {
    // Connect to WebSocket server
    _channel = WebSocketChannel.connect(
      Uri.parse('ws://collab-server.example.com/ws'),
    );

    // Join document room
    _channel!.sink.add(jsonEncode({
      'type': 'join',
      'documentId': widget.documentId,
    }));

    // Listen for remote edits
    _channel!.stream.listen((message) {
      final data = jsonDecode(message);
      _handleRemoteEdit(data);
    });
  }

  void _handleRemoteEdit(Map<String, dynamic> edit) {
    final engine = ref.read(documentEngineProvider);
    final state = ref.read(nativeDocumentProvider(engine));
    final handle = state.documentHandle;

    if (handle == null) return;

    // Apply remote edit locally
    switch (edit['type']) {
      case 'insert_text':
        engine.insertText(
          handle,
          edit['blockIndex'],
          edit['spanIndex'],
          edit['offset'],
          edit['text'],
        );
        break;
      case 'split_block':
        engine.splitBlock(
          handle,
          edit['blockIndex'],
          edit['spanIndex'],
          edit['offset'],
        );
        break;
    }
  }

  void _sendLocalEdit(String type, Map<String, dynamic> data) {
    _channel?.sink.add(jsonEncode({
      'type': type,
      'documentId': widget.documentId,
      ...data,
    }));
  }

  @override
  void dispose() {
    _channel?.sink.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return NativeDocumentCanvas(
      onDocumentChanged: (text) {
        _sendLocalEdit('text_change', {'text': text});
      },
    );
  }
}
```

## Testing Examples

### Unit Test for Document Operations

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:ky_docs/ky_docs.dart';

void main() {
  group('DocumentEngine', () {
    late DocumentEngine engine;

    setUp(() async {
      engine = DocumentEngine.instance;
      // Use fallback mode for tests
      await engine.initialize(libraryPath: null);
    });

    test('creates document with title', () async {
      final handle = await engine.createDocument('Test Doc');
      final title = await handle.getTitle();

      expect(title, equals('Test Doc'));
      handle.dispose();
    });

    test('adds paragraph block', () async {
      final handle = await engine.createDocument('Test');
      final index = await engine.addParagraph(handle, 'Hello World');

      expect(index, equals(0));

      final blocks = await handle.getBlocks();
      expect(blocks.length, equals(1));
      expect(blocks[0].type, equals('paragraph'));

      handle.dispose();
    });

    test('serializes and deserializes', () async {
      final handle = await engine.createDocument('Serialize Test');
      await engine.addParagraph(handle, 'Content');
      await engine.addHeading(handle, 'Title', 1);

      final json = await handle.serialize();
      expect(json, isNotEmpty);

      final newHandle = await engine.loadDocument(json);
      final blocks = await newHandle.getBlocks();

      expect(blocks.length, equals(2));

      handle.dispose();
      newHandle.dispose();
    });
  });
}
```

## Performance Tips

1. **Batch operations**: When making multiple changes, batch them together rather than calling engine methods individually.

2. **Lazy loading**: For large documents, load blocks on-demand as the user scrolls.

3. **Dispose handles**: Always call `handle.dispose()` when done with a document to free native resources.

4. **Use fallback mode in tests**: Set `libraryPath: null` to use the Dart fallback implementation in unit tests.

5. **Profile rendering**: Use Flutter DevTools to identify slow frame builds in the canvas.

## Common Patterns

### Auto-save with Debounce

```dart
class AutoSaveDocument extends ConsumerStatefulWidget {
  final String documentId;

  const AutoSaveDocument({super.key, required this.documentId});

  @override
  ConsumerState<AutoSaveDocument> createState() => _AutoSaveDocumentState();
}

class _AutoSaveDocumentState extends ConsumerState<AutoSaveDocument> {
  Timer? _saveTimer;
  bool _isDirty = false;

  void _markDirty() {
    if (_saveTimer?.isActive ?? false) {
      _saveTimer!.cancel();
    }

    setState(() => _isDirty = true);

    _saveTimer = Timer(const Duration(seconds: 2), _save);
  }

  Future<void> _save() async {
    if (!_isDirty) return;

    final state = ref.read(
      nativeDocumentProvider(ref.read(documentEngineProvider)),
    );

    final handle = state.documentHandle;
    if (handle == null) return;

    final json = await handle.serialize();

    // Save to storage
    await localStorage.save(widget.documentId, json);

    setState(() => _isDirty = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Saved'),
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  @override
  void dispose() {
    _saveTimer?.cancel();
    if (_isDirty) {
      _save(); // Final save
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return NativeDocumentCanvas(
      onDocumentChanged: (_) => _markDirty(),
    );
  }
}
```

For more examples, see the test files in the `test/` directory.