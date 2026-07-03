/// Example MCP Server Usage
/// 
/// Demonstrates how to set up and use the Ky AI MCP server
/// with ky_docs, ky_sheet, ky_slide, and ky_ai_core integration.

import 'dart:io';
import 'package:ky_ai_mcp/ky_ai_mcp.dart';
import 'package:stream_channel/stream_channel.dart';

void main() async {
  print('🚀 Ky AI MCP Server Example');
  print('=' * 50);

  // Example 1: Standard IO Channel (for CLI integration)
  await runStdioExample();

  // Example 2: WebSocket Channel (for network integration)
  // await runWebSocketExample();

  // Example 3: In-memory Channel (for testing)
  await runInMemoryExample();
}

/// Example 1: Standard IO Channel
/// 
/// Use this for integrating with command-line tools or Claude Desktop
Future<void> runStdioExample() async {
  print('\n📌 Example 1: Standard IO Channel');
  
  // Create channel from stdin/stdout
  final channel = StreamChannel<String>.fromStreamPair(
    stdin.transform(Utf8Decoder()),
    stdout,
  );

  // Initialize MCP server
  final server = MCPServer(channel);
  
  print('✅ MCP Server initialized');
  print('📡 Listening for JSON-RPC requests on stdin/stdout...');
  
  // Start server (this will block until connection closes)
  await server.start();
}

/// Example 2: WebSocket Channel
/// 
/// Use this for network-based AI agent connections
Future<void> runWebSocketExample() async {
  print('\n📌 Example 2: WebSocket Channel');
  
  // Import websocket package
  // import 'package:web_socket_channel/web_socket_channel.dart';
  
  // final ws = WebSocketChannel.connect(Uri.parse('ws://localhost:8080/mcp'));
  // final channel = StreamChannel<String>.fromStreamPair(ws.stream, ws.sink);
  
  // final server = MCPServer(channel);
  // await server.start();
  
  print('⚠️ WebSocket example commented out - add web_socket_channel dependency');
}

/// Example 3: In-memory Channel (Testing)
/// 
/// Use this for unit tests or local development
Future<void> runInMemoryExample() async {
  print('\n📌 Example 3: In-memory Channel (Testing)');
  
  // Create in-memory streams
  final controllerOut = StreamController<String>();
  final controllerIn = StreamController<String>();
  
  final channel = StreamChannel<String>(
    controllerOut.stream,
    controllerIn.sink,
  );

  // Initialize server
  final server = MCPServer(channel);
  
  print('✅ Test server initialized');
  
  // Simulate client request
  final initializeRequest = {
    'jsonrpc': '2.0',
    'id': 1,
    'method': 'initialize',
    'params': {
      'protocolVersion': '2024-11-05',
      'capabilities': {},
      'clientInfo': {
        'name': 'test-client',
        'version': '1.0.0',
      },
    },
  };
  
  // Send request
  controllerIn.add(json.encode(initializeRequest));
  
  // Listen for response
  controllerOut.stream.listen((response) {
    print('📨 Response: $response');
  });
  
  // Give time for processing
  await Future.delayed(Duration(milliseconds: 100));
  
  // Cleanup
  await controllerOut.close();
  await controllerIn.close();
  
  print('✅ Test completed');
}

/// Example 4: Custom Tool Registration
/// 
/// Demonstrate adding custom tools to the MCP server
Future<void> runCustomToolExample() async {
  print('\n📌 Example 4: Custom Tool Registration');
  
  final controllerOut = StreamController<String>();
  final controllerIn = StreamController<String>();
  
  final channel = StreamChannel<String>(
    controllerOut.stream,
    controllerIn.sink,
  );

  final server = MCPServer(channel);
  
  // Register custom tool
  server.registerTool(MCPTool(
    name: 'get_weather',
    description: 'Get current weather for a location',
    inputSchema: {
      'type': 'object',
      'properties': {
        'location': {
          'type': 'string',
          'description': 'City name',
        },
      },
      'required': ['location'],
    },
    handler: (arguments) async {
      final location = arguments['location'] as String;
      // Simulate weather API call
      return {
        'location': location,
        'temperature': 22,
        'condition': 'Sunny',
        'humidity': 65,
      };
    },
  ));
  
  print('✅ Custom tool "get_weather" registered');
  
  // List available tools
  final toolsListRequest = {
    'jsonrpc': '2.0',
    'id': 2,
    'method': 'tools/list',
  };
  
  controllerIn.add(json.encode(toolsListRequest));
  
  controllerOut.stream.listen((response) {
    print('📨 Tools list: $response');
  });
  
  await Future.delayed(Duration(milliseconds: 100));
  
  await controllerOut.close();
  await controllerIn.close();
}

/// Example 5: Integration with ky_docs
/// 
/// Show how to integrate MCP with actual ky_docs functionality
Future<void> runKyDocsIntegrationExample() async {
  print('\n📌 Example 5: ky_docs Integration');
  
  // This example shows the pattern for integrating with ky_docs
  // Actual implementation would require ky_docs to be available
  
  /*
  import 'package:ky_docs/ky_docs.dart';
  
  final controllerOut = StreamController<String>();
  final controllerIn = StreamController<String>();
  
  final channel = StreamChannel<String>(
    controllerOut.stream,
    controllerIn.sink,
  );

  final server = MCPServer(channel);
  
  // Override create_document tool with actual ky_docs implementation
  server.registerTool(MCPTool(
    name: 'create_document',
    description: 'Create document using ky_docs engine',
    inputSchema: {...},
    handler: (arguments) async {
      // Use actual DocumentEngine from ky_docs
      final engine = DocumentEngine.instance;
      final doc = await engine.createDocument(
        title: arguments['title'],
        template: arguments['template'],
      );
      
      return {
        'success': true,
        'documentId': doc.id,
        'title': doc.title,
      };
    },
  ));
  
  print('✅ ky_docs integration configured');
  */
  
  print('⚠️ ky_docs integration example commented - requires ky_docs dependency');
}

/// Example 6: Integration with ky_ai_core (STT/TTS)
/// 
/// Show how to integrate MCP with ky_ai_core for AI features
Future<void> runKyAICoreIntegrationExample() async {
  print('\n📌 Example 6: ky_ai_core Integration (STT/TTS)');
  
  /*
  import 'package:ky_ai_core/ky_ai_core.dart';
  
  final server = MCPServer(channel);
  
  // Override speech_to_text tool with actual ky_ai_core implementation
  server.registerTool(MCPTool(
    name: 'speech_to_text',
    description: 'STT using ky_ai_core',
    inputSchema: {...},
    handler: (arguments) async {
      final stt = KyAICore.speechToText();
      final result = await stt.transcribe(arguments['audioPath']);
      
      return {
        'success': true,
        'text': result.transcript,
        'confidence': result.confidence,
        'duration': result.duration,
      };
    },
  ));
  
  // Override text_to_speech tool
  server.registerTool(MCPTool(
    name: 'text_to_speech',
    description: 'TTS using ky_ai_core',
    inputSchema: {...},
    handler: (arguments) async {
      final tts = KyAICore.textToSpeech();
      final audioPath = await tts.synthesize(
        text: arguments['text'],
        voice: arguments['voice'],
      );
      
      return {
        'success': true,
        'audioPath': audioPath,
        'duration': await tts.getDuration(audioPath),
      };
    },
  ));
  
  print('✅ ky_ai_core integration configured');
  */
  
  print('⚠️ ky_ai_core integration example commented - requires ky_ai_core dependency');
}

/// Helper imports
import 'dart:async';
import 'dart:convert';
