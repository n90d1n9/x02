/// MCP Tool Model
/// 
/// Represents a tool that can be invoked by AI agents through the MCP protocol.
class MCPTool {
  final String name;
  final String description;
  final Map<String, dynamic> inputSchema;
  final Function(Map<String, dynamic>) handler;

  MCPTool({
    required this.name,
    required this.description,
    required this.inputSchema,
    required this.handler,
  });

  /// Convert to JSON-RPC compatible format
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'inputSchema': inputSchema,
    };
  }
}

/// MCP Resource Model
/// 
/// Represents a resource that can be accessed by AI agents.
class MCPResource {
  final String uri;
  final String name;
  final String description;
  final String mimeType;
  final Future<String> Function() reader;

  MCPResource({
    required this.uri,
    required this.name,
    required this.description,
    required this.mimeType,
    required this.reader,
  });

  Map<String, dynamic> toJson() {
    return {
      'uri': uri,
      'name': name,
      'description': description,
      'mimeType': mimeType,
    };
  }
}

/// MCP Prompt Model
/// 
/// Represents a reusable prompt template for AI agents.
class MCPPrompt {
  final String name;
  final String description;
  final List<MCPPromptArgument> arguments;
  final Future<List<Map<String, dynamic>>> Function(Map<String, dynamic>) handler;

  MCPPrompt({
    required this.name,
    required this.description,
    required this.arguments,
    required this.handler,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'arguments': arguments.map((a) => a.toJson()).toList(),
    };
  }
}

class MCPPromptArgument {
  final String name;
  final String description;
  final bool required;

  MCPPromptArgument({
    required this.name,
    required this.description,
    this.required = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'required': required,
    };
  }
}
