/// Document Resource for MCP
///
/// Provides AI agents access to document content and structure.

import '../models/mcp_tool.dart';

class DocumentResource implements MCPResource {
  @override
  final String uri = 'ky://document/current';

  @override
  final String name = 'Current Document';

  @override
  final String description =
      'Access to the current active document content and metadata';

  @override
  final String mimeType = 'application/json';

  @override
  Future<String> reader() async {
    // TODO: Integrate with ky_docs to get current document state
    return '''
{
  "documentId": "doc_123456",
  "title": "Sample Document",
  "blocks": [
    {"type": "heading1", "content": "Introduction"},
    {"type": "paragraph", "content": "This is a sample document."}
  ],
  "metadata": {
    "wordCount": 1250,
    "pageCount": 5,
    "lastModified": "2024-01-15T10:30:00Z"
  }
}
''';
  }
}
