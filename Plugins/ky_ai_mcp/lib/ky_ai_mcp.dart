/// Ky AI MCP - Model Context Protocol Server for Ky Office Suite
/// 
/// Provides AI agents with tools to create, edit, and manage documents
/// across ky_docs, ky_sheet, and ky_slide applications.
library ky_ai_mcp;

export 'src/server/mcp_server.dart';
export 'src/tools/document_tools.dart';
export 'src/tools/sheet_tools.dart';
export 'src/tools/slide_tools.dart';
export 'src/tools/ai_core_tools.dart';
export 'src/resources/document_resource.dart';
export 'src/resources/metadata_resource.dart';
export 'src/models/mcp_message.dart';
export 'src/models/mcp_tool.dart';
