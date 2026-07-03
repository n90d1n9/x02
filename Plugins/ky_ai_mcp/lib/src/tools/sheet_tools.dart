/// Sheet Tools for MCP
/// 
/// Tools for creating, editing, and managing spreadsheets in ky_sheet.

import '../models/mcp_tool.dart';

class SheetTools {
  /// Get all sheet-related tools
  static List<MCPTool> getAll() {
    return [
      createSheetTool(),
      insertCellTool(),
      updateCellStyleTool(),
      calculateFormulaTool(),
      exportSheetTool(),
    ];
  }

  static MCPTool createSheetTool() {
    return MCPTool(
      name: 'create_sheet',
      description: 'Create a new spreadsheet',
      inputSchema: {
        'type': 'object',
        'properties': {
          'title': {'type': 'string'},
          'rows': {'type': 'integer'},
          'columns': {'type': 'integer'},
        },
        'required': ['title'],
      },
      handler: (arguments) async {
        return {
          'success': true,
          'sheetId': 'sheet_${DateTime.now().millisecondsSinceEpoch}',
          'title': arguments['title'],
        };
      },
    );
  }

  static MCPTool insertCellTool() {
    return MCPTool(
      name: 'insert_cell',
      description: 'Insert data into a cell',
      inputSchema: {
        'type': 'object',
        'properties': {
          'sheetId': {'type': 'string'},
          'row': {'type': 'integer'},
          'column': {'type': 'integer'},
          'value': {'type': 'string'},
          'dataType': {
            'type': 'string',
            'enum': ['text', 'number', 'date', 'formula'],
          },
        },
        'required': ['sheetId', 'row', 'column', 'value'],
      },
      handler: (arguments) async {
        return {
          'success': true,
          'cell': '${String.fromCharCode(65 + (arguments['column'] as int))}${arguments['row']}',
        };
      },
    );
  }

  static MCPTool updateCellStyleTool() {
    return MCPTool(
      name: 'update_cell_style',
      description: 'Update cell styling',
      inputSchema: {
        'type': 'object',
        'properties': {
          'sheetId': {'type': 'string'},
          'cells': {'type': 'array', 'items': {'type': 'string'}},
          'style': {'type': 'object'},
        },
        'required': ['sheetId', 'style'],
      },
      handler: (arguments) async {
        return {'success': true, 'updatedCells': 1};
      },
    );
  }

  static MCPTool calculateFormulaTool() {
    return MCPTool(
      name: 'calculate_formula',
      description: 'Calculate a formula',
      inputSchema: {
        'type': 'object',
        'properties': {
          'sheetId': {'type': 'string'},
          'formula': {'type': 'string'},
        },
        'required': ['formula'],
      },
      handler: (arguments) async {
        return {'success': true, 'result': 42};
      },
    );
  }

  static MCPTool exportSheetTool() {
    return MCPTool(
      name: 'export_sheet',
      description: 'Export spreadsheet',
      inputSchema: {
        'type': 'object',
        'properties': {
          'sheetId': {'type': 'string'},
          'format': {'type': 'string', 'enum': ['xlsx', 'csv', 'pdf']},
        },
        'required': ['sheetId', 'format'],
      },
      handler: (arguments) async {
        return {'success': true, 'path': '/tmp/export.xlsx'};
      },
    );
  }
}
