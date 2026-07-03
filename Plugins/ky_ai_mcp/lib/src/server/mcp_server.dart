/// MCP Server Implementation
/// 
/// JSON-RPC 2.0 server implementing the Model Context Protocol (MCP)
/// for AI agent integration with Ky Office suite.

import 'dart:async';
import 'dart:convert';
import 'package:json_rpc_2/json_rpc_2.dart';
import 'package:stream_channel/stream_channel.dart';
import '../models/mcp_message.dart';
import '../models/mcp_tool.dart';
import '../tools/document_tools.dart';
import '../tools/sheet_tools.dart';
import '../tools/slide_tools.dart';
import '../tools/ai_core_tools.dart';
import '../resources/document_resource.dart';
import '../resources/metadata_resource.dart';

class MCPServer {
  final Peer _peer;
  final List<MCPTool> _tools = [];
  final List<MCPResource> _resources = [];
  final List<MCPPrompt> _prompts = [];
  bool _initialized = false;

  MCPServer(StreamChannel<String> channel) : _peer = Peer(channel) {
    _registerHandlers();
  }

  void _registerHandlers() {
    // Initialize handler
    _peer.registerMethod('initialize', _handleInitialize);
    
    // Tool handlers
    _peer.registerMethod('tools/list', _handleToolsList);
    _peer.registerMethod('tools/call', _handleToolsCall);
    
    // Resource handlers
    _peer.registerMethod('resources/list', _handleResourcesList);
    _peer.registerMethod('resources/read', _handleResourcesRead);
    
    // Prompt handlers
    _peer.registerMethod('prompts/list', _handlePromptsList);
    _peer.registerMethod('prompts/get', _handlePromptsGet);
    
    // Notification handlers
    _peer.registerMethod('notifications/cancelled', _handleCancelled);
    _peer.registerMethod('notifications/progress', _handleProgress);
  }

  Future<Map<String, dynamic>> _handleInitialize(Map<String, dynamic>? params) async {
    _initialized = true;
    
    // Register all tools
    _tools.addAll([
      ...DocumentTools.getAll(),
      ...SheetTools.getAll(),
      ...SlideTools.getAll(),
      ...AICoreTools.getAll(),
    ]);

    // Register all resources
    _resources.addAll([
      DocumentResource(),
      MetadataResource(),
    ]);

    return {
      'protocolVersion': '2024-11-05',
      'capabilities': {
        'tools': {'listChanged': true},
        'resources': {'subscribe': true, 'listChanged': true},
        'prompts': {'listChanged': true},
      },
      'serverInfo': {
        'name': 'ky_ai_mcp',
        'version': '1.0.0',
      },
    };
  }

  Future<Map<String, dynamic>> _handleToolsList(Map<String, dynamic>? params) async {
    return {
      'tools': _tools.map((t) => t.toJson()).toList(),
    };
  }

  Future<Map<String, dynamic>> _handleToolsCall(Map<String, dynamic> params) async {
    final name = params['name'] as String;
    final arguments = params['arguments'] as Map<String, dynamic>?;

    final tool = _tools.firstWhere(
      (t) => t.name == name,
      orElse: () => throw RpcError.invalidParams('Tool not found: $name'),
    );

    try {
      final result = await tool.handler(arguments ?? {});
      return {
        'content': [
          {
            'type': 'text',
            'text': json.encode(result),
          },
        ],
      };
    } catch (e) {
      return {
        'content': [
          {
            'type': 'text',
            'text': 'Error: ${e.toString()}',
          },
        ],
        'isError': true,
      };
    }
  }

  Future<Map<String, dynamic>> _handleResourcesList(Map<String, dynamic>? params) async {
    return {
      'resources': _resources.map((r) => r.toJson()).toList(),
    };
  }

  Future<Map<String, dynamic>> _handleResourcesRead(Map<String, dynamic> params) async {
    final uri = params['uri'] as String;

    final resource = _resources.firstWhere(
      (r) => r.uri == uri,
      orElse: () => throw RpcError.invalidParams('Resource not found: $uri'),
    );

    final content = await resource.reader();
    return {
      'contents': [
        {
          'uri': uri,
          'mimeType': resource.mimeType,
          'text': content,
        },
      ],
    };
  }

  Future<Map<String, dynamic>> _handlePromptsList(Map<String, dynamic>? params) async {
    return {
      'prompts': _prompts.map((p) => p.toJson()).toList(),
    };
  }

  Future<Map<String, dynamic>> _handlePromptsGet(Map<String, dynamic> params) async {
    final name = params['name'] as String;
    final arguments = params['arguments'] as Map<String, dynamic>?;

    final prompt = _prompts.firstWhere(
      (p) => p.name == name,
      orElse: () => throw RpcError.invalidParams('Prompt not found: $name'),
    );

    final messages = await prompt.handler(arguments ?? {});
    return {
      'messages': messages,
    };
  }

  void _handleCancelled(Map<String, dynamic>? params) {
    // Handle cancellation notification
  }

  void _handleProgress(Map<String, dynamic>? params) {
    // Handle progress notification
  }

  /// Start the server
  Future<void> start() async {
    await _peer.listen();
  }

  /// Stop the server
  void stop() {
    _peer.close();
  }

  /// Register a custom tool
  void registerTool(MCPTool tool) {
    _tools.add(tool);
    _notifyToolsListChanged();
  }

  /// Unregister a tool
  void unregisterTool(String name) {
    _tools.removeWhere((t) => t.name == name);
    _notifyToolsListChanged();
  }

  /// Notify clients that tools list has changed
  void _notifyToolsListChanged() {
    _peer.sendNotification('notifications/tools/list_changed');
  }
}
