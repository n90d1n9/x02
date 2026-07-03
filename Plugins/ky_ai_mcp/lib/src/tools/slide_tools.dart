/// Slide Tools for MCP
/// 
/// Tools for creating, editing, and managing presentations in ky_slide.

import '../models/mcp_tool.dart';

class SlideTools {
  static List<MCPTool> getAll() {
    return [
      createPresentationTool(),
      insertSlideTool(),
      addContentToSlideTool(),
      applyThemeTool(),
      exportPresentationTool(),
    ];
  }

  static MCPTool createPresentationTool() {
    return MCPTool(
      name: 'create_presentation',
      description: 'Create a new presentation',
      inputSchema: {
        'type': 'object',
        'properties': {
          'title': {'type': 'string'},
          'theme': {'type': 'string'},
        },
        'required': ['title'],
      },
      handler: (arguments) async {
        return {
          'success': true,
          'presentationId': 'pres_${DateTime.now().millisecondsSinceEpoch}',
        };
      },
    );
  }

  static MCPTool insertSlideTool() {
    return MCPTool(
      name: 'insert_slide',
      description: 'Insert a new slide',
      inputSchema: {
        'type': 'object',
        'properties': {
          'presentationId': {'type': 'string'},
          'position': {'type': 'integer'},
          'layout': {'type': 'string'},
        },
        'required': ['presentationId'],
      },
      handler: (arguments) async {
        return {'success': true, 'slideNumber': 1};
      },
    );
  }

  static MCPTool addContentToSlideTool() {
    return MCPTool(
      name: 'add_content_to_slide',
      description: 'Add content to a slide',
      inputSchema: {
        'type': 'object',
        'properties': {
          'slideId': {'type': 'string'},
          'contentType': {'type': 'string'},
          'content': {'type': 'string'},
        },
        'required': ['slideId', 'contentType', 'content'],
      },
      handler: (arguments) async {
        return {'success': true};
      },
    );
  }

  static MCPTool applyThemeTool() {
    return MCPTool(
      name: 'apply_theme',
      description: 'Apply a theme to presentation',
      inputSchema: {
        'type': 'object',
        'properties': {
          'presentationId': {'type': 'string'},
          'themeName': {'type': 'string'},
        },
        'required': ['presentationId', 'themeName'],
      },
      handler: (arguments) async {
        return {'success': true};
      },
    );
  }

  static MCPTool exportPresentationTool() {
    return MCPTool(
      name: 'export_presentation',
      description: 'Export presentation',
      inputSchema: {
        'type': 'object',
        'properties': {
          'presentationId': {'type': 'string'},
          'format': {'type': 'string', 'enum': ['pptx', 'pdf']},
        },
        'required': ['presentationId', 'format'],
      },
      handler: (arguments) async {
        return {'success': true, 'path': '/tmp/export.pptx'};
      },
    );
  }
}
