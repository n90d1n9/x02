/// MCP Message Models
///
/// JSON-RPC 2.0 message formats for MCP communication.

import 'dart:convert';

/// Base MCP Message
abstract class MCPMessage {
  final String jsonrpc;
  final dynamic id;

  MCPMessage({this.jsonrpc = '2.0', this.id});

  Map<String, dynamic> toJson();

  String encode() => json.encode(toJson());
}

/// MCP Request Message
class MCPRequest extends MCPMessage {
  final String method;
  final Map<String, dynamic>? params;

  MCPRequest({required this.method, this.params, super.id});

  @override
  Map<String, dynamic> toJson() {
    return {
      'jsonrpc': jsonrpc,
      'id': id,
      'method': method,
      if (params != null) 'params': params,
    };
  }

  factory MCPRequest.fromJson(Map<String, dynamic> json) {
    return MCPRequest(
      method: json['method'] as String,
      params: json['params'] as Map<String, dynamic>?,
      id: json['id'],
    );
  }
}

/// MCP Response Message
class MCPResponse extends MCPMessage {
  final dynamic result;
  final MCPError? error;

  MCPResponse({this.result, this.error, super.id});

  @override
  Map<String, dynamic> toJson() {
    return {
      'jsonrpc': jsonrpc,
      'id': id,
      if (result != null) 'result': result,
      if (error != null) 'error': error!.toJson(),
    };
  }
}

/// MCP Error
class MCPError {
  final int code;
  final String message;
  final dynamic data;

  MCPError({required this.code, required this.message, this.data});

  Map<String, dynamic> toJson() {
    return {'code': code, 'message': message, if (data != null) 'data': data};
  }

  static const int ParseError = -32700;
  static const int InvalidRequest = -32600;
  static const int MethodNotFound = -32601;
  static const int InvalidParams = -32602;
  static const int InternalError = -32603;
}

/// MCP Notification Message
class MCPNotification extends MCPMessage {
  final String method;
  final Map<String, dynamic>? params;

  MCPNotification({required this.method, this.params}) : super(id: null);

  @override
  Map<String, dynamic> toJson() {
    return {
      'jsonrpc': jsonrpc,
      'method': method,
      if (params != null) 'params': params,
    };
  }
}
