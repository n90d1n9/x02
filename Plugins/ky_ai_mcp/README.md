# Ky AI MCP

[![Version](https://img.shields.io/badge/version-1.0.0-blue.svg)](https://pub.dev/packages/ky_ai_mcp)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)

Model Context Protocol (MCP) server for the Ky Office suite, enabling AI agents to create, edit, and manage documents across `ky_docs`, `ky_sheet`, and `ky_slide` applications with advanced AI capabilities via `ky_ai_core`.

## 🎯 Features

### 🔧 Tools (20+)
- **Document Operations**: Create, insert blocks, update styles, find/replace, export, statistics
- **Spreadsheet Operations**: Create sheets, insert cells, calculate formulas, export
- **Presentation Operations**: Create presentations, insert slides, apply themes, export
- **AI Core Operations**: STT, TTS, summarize, rewrite, translate, grammar check

### 📚 Resources
- **Document Content**: Real-time access to document structure and content
- **Metadata**: Document properties, statistics, and custom metadata

### 💬 Prompts
- Pre-built prompt templates for common workflows
- Customizable prompt arguments

## 🏗️ Architecture

```
┌─────────────────────────────────────────┐
│         AI Agent (Claude, etc.)         │
└──────────────┬──────────────────────────┘
               │ MCP Protocol (JSON-RPC 2.0)
               ↓
┌─────────────────────────────────────────┐
│         ky_ai_mcp Server                │
│  ┌─────────────────────────────────┐    │
│  │  Document Tools (6)             │    │
│  │  Sheet Tools (5)                │    │
│  │  Slide Tools (5)                │    │
│  │  AI Core Tools (6)              │    │
│  └─────────────────────────────────┘    │
│  ┌─────────────────────────────────┐    │
│  │  Resources                      │    │
│  │  - Document Content             │    │
│  │  - Metadata                     │    │
│  └─────────────────────────────────┘    │
└──────────────┬──────────────────────────┘
               │ Dart API
               ↓
┌─────────────────────────────────────────┐
│  Ky Office Suite                        │
│  - ky_docs (Document Engine)            │
│  - ky_sheet (Spreadsheet Engine)        │
│  - ky_slide (Presentation Engine)       │
│  - ky_ai_core (STT/TTS/AI)              │
└─────────────────────────────────────────┘
```

## 📦 Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  ky_ai_mcp:
    path: ../ky_ai_mcp
```

## 🚀 Usage

### Basic Server Setup

```dart
import 'package:ky_ai_mcp/ky_ai_mcp.dart';
import 'package:stream_channel/stream_channel.dart';

void main() async {
  // Create communication channel (WebSocket, stdio, etc.)
  final channel = StreamChannel<String>.fromStreamPair(
    stdin,
    stdout,
  );

  // Initialize MCP server
  final server = MCPServer(channel);
  
  // Start listening for requests
  await server.start();
  
  print('MCP Server started');
}
```

### Using with Claude Desktop

Add to your Claude Desktop configuration (`claude_desktop_config.json`):

```json
{
  "mcpServers": {
    "ky-office": {
      "command": "dart",
      "args": ["/path/to/ky_ai_mcp/bin/server.dart"],
      "env": {
        "KY_DOCS_PATH": "/path/to/ky_docs",
        "KY_AI_CORE_PATH": "/path/to/ky_ai_core"
      }
    }
  }
}
```

### Available Tools

#### Document Tools
- `create_document` - Create a new document
- `insert_block` - Insert content blocks
- `update_style` - Update text styling
- `find_replace` - Find and replace text
- `export_document` - Export to DOCX/PDF/TXT
- `get_stats` - Get document statistics

#### AI Core Tools
- `speech_to_text` - Convert audio to text (STT)
- `text_to_speech` - Convert text to audio (TTS)
- `summarize_document` - Generate summaries
- `rewrite_content` - Rewrite with different tone
- `translate_content` - Translate languages
- `grammar_check` - Check and correct grammar

### Example: AI Agent Workflow

```
User: "Create a business report about Q4 sales"

AI Agent → MCP Server:
{
  "method": "tools/call",
  "params": {
    "name": "create_document",
    "arguments": {
      "title": "Q4 Sales Report",
      "template": "report"
    }
  }
}

MCP Server → AI Agent:
{
  "result": {
    "success": true,
    "documentId": "doc_123456",
    "title": "Q4 Sales Report"
  }
}

AI Agent → MCP Server:
{
  "method": "tools/call",
  "params": {
    "name": "insert_block",
    "arguments": {
      "documentId": "doc_123456",
      "blockType": "heading1",
      "content": "Executive Summary"
    }
  }
}
```

## 📁 Project Structure

```
ky_ai_mcp/
├── lib/
│   ├── ky_ai_mcp.dart              # Main export
│   └── src/
│       ├── models/
│       │   ├── mcp_message.dart    # JSON-RPC messages
│       │   └── mcp_tool.dart       # Tool/Resource models
│       ├── server/
│       │   └── mcp_server.dart     # MCP server implementation
│       ├── tools/
│       │   ├── document_tools.dart
│       │   ├── sheet_tools.dart
│       │   ├── slide_tools.dart
│       │   └── ai_core_tools.dart
│       └── resources/
│           ├── document_resource.dart
│           └── metadata_resource.dart
├── example/
│   └── main.dart                   # Usage example
├── test/
│   └── mcp_server_test.dart
├── pubspec.yaml
└── README.md
```

## 🔌 Integration Guide

### Integrating with ky_docs

```dart
// In ky_docs, listen for MCP tool calls
final mcpServer = MCPServer(channel);

// Override default document tools with actual implementations
mcpServer.registerTool(MCPTool(
  name: 'create_document',
  description: 'Create document using ky_docs engine',
  inputSchema: {...},
  handler: (arguments) async {
    // Use actual DocumentEngine
    final doc = await DocumentEngine.create(
      title: arguments['title'],
      template: arguments['template'],
    );
    return {'success': true, 'documentId': doc.id};
  },
));
```

### Integrating with ky_ai_core

```dart
// Override AI tools with ky_ai_core implementations
mcpServer.registerTool(MCPTool(
  name: 'speech_to_text',
  description: 'STT using ky_ai_core',
  inputSchema: {...},
  handler: (arguments) async {
    final stt = KyAICore.stt();
    final result = await stt.transcribe(arguments['audioPath']);
    return {
      'success': true,
      'text': result.text,
      'confidence': result.confidence,
    };
  },
));
```

## 🧪 Testing

```bash
# Run tests
flutter test

# Run example
cd example && dart run main.dart
```

## 📝 License

MIT License - see [LICENSE](LICENSE) for details.

## 🤝 Contributing

Contributions welcome! Please read our [Contributing Guide](CONTRIBUTING.md) first.

## 📞 Support

- Documentation: https://ky-office.dev/docs
- Issues: https://github.com/ky-office/ky_ai_mcp/issues
- Discord: https://discord.gg/ky-office
