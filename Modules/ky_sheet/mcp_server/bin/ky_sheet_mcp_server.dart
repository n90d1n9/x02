/// MCP Server for KySheet spreadsheet operations.
/// 
/// This server provides tools for creating, reading, updating, and managing
/// spreadsheets through the Model Context Protocol (MCP).

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:json_rpc_2/json_rpc_2.dart';
import 'package:stream_channel/stream_channel.dart';
import 'package:ky_sheet/ky_sheet.dart';

import 'src/handlers/spreadsheet_handler.dart';
import 'src/handlers/formatting_handler.dart';
import 'src/handlers/data_handler.dart';
import 'src/handlers/chart_handler.dart';
import 'src/handlers/file_handler.dart';

void main(List<String> args) async {
  final server = KySheetMCPServer();
  await server.start();
}

/// Main MCP Server class for KySheet operations
class KySheetMCPServer {
  late Peer _peer;
  late StreamChannel<String> _channel;
  
  // Handlers
  late SpreadsheetHandler _spreadsheetHandler;
  late FormattingHandler _formattingHandler;
  late DataHandler _dataHandler;
  late ChartHandler _chartHandler;
  late FileHandler _fileHandler;
  
  // Active workbooks cache
  final Map<String, Workbook> _workbooks = {};
  String? _activeWorkbookId;

  Future<void> start() async {
    // Use stdin/stdout for JSON-RPC communication
    _channel = StreamChannel<String>.fromStream(
      stdin.transform(utf8.decoder).transform(const LineSplitter()),
      StreamSink<String>.fromStream(stdout.addStream),
    );

    _peer = Peer(_channel);
    
    // Initialize handlers
    _spreadsheetHandler = SpreadsheetHandler(this);
    _formattingHandler = FormattingHandler(this);
    _dataHandler = DataHandler(this);
    _chartHandler = ChartHandler(this);
    _fileHandler = FileHandler(this);
    
    // Register all tools
    _registerTools();
    
    // Register methods
    _peer.registerMethod('initialize', _handleInitialize);
    _peer.registerMethod('tools/list', _handleToolsList);
    _peer.registerMethod('tools/call', _handleToolsCall);
    
    // Listen for incoming requests
    await _peer.listen();
  }

  void _registerTools() {
    // Spreadsheet operations
    _peer.registerMethod('create_workbook', _spreadsheetHandler.createWorkbook);
    _peer.registerMethod('create_sheet', _spreadsheetHandler.createSheet);
    _peer.registerMethod('delete_sheet', _spreadsheetHandler.deleteSheet);
    _peer.registerMethod('rename_sheet', _spreadsheetHandler.renameSheet);
    _peer.registerMethod('list_sheets', _spreadsheetHandler.listSheets);
    _peer.registerMethod('get_active_sheet', _spreadsheetHandler.getActiveSheet);
    _peer.registerMethod('set_active_sheet', _spreadsheetHandler.setActiveSheet);
    
    // Cell operations
    _peer.registerMethod('read_cell', _spreadsheetHandler.readCell);
    _peer.registerMethod('write_cell', _spreadsheetHandler.writeCell);
    _peer.registerMethod('read_range', _spreadsheetHandler.readRange);
    _peer.registerMethod('write_range', _spreadsheetHandler.writeRange);
    
    // Formatting operations
    _peer.registerMethod('format_cell', _formattingHandler.formatCell);
    _peer.registerMethod('format_range', _formattingHandler.formatRange);
    _peer.registerMethod('merge_cells', _formattingHandler.mergeCells);
    _peer.registerMethod('unmerge_cells', _formattingHandler.unmergeCells);
    _peer.registerMethod('set_column_width', _formattingHandler.setColumnWidth);
    _peer.registerMethod('set_row_height', _formattingHandler.setRowHeight);
    _peer.registerMethod('set_border', _formattingHandler.setBorder);
    _peer.registerMethod('clear_formatting', _formattingHandler.clearFormatting);
    
    // Data operations
    _peer.registerMethod('sort_range', _dataHandler.sortRange);
    _peer.registerMethod('filter_data', _dataHandler.filterData);
    _peer.registerMethod('find_replace', _dataHandler.findReplace);
    _peer.registerMethod('validate_data', _dataHandler.validateData);
    _peer.registerMethod('calculate_formula', _dataHandler.calculateFormula);
    _peer.registerMethod('get_formula_result', _dataHandler.getFormulaResult);
    
    // Chart operations
    _peer.registerMethod('create_chart', _chartHandler.createChart);
    _peer.registerMethod('update_chart', _chartHandler.updateChart);
    _peer.registerMethod('delete_chart', _chartHandler.deleteChart);
    _peer.registerMethod('list_charts', _chartHandler.listCharts);
    
    // File operations
    _peer.registerMethod('open_file', _fileHandler.openFile);
    _peer.registerMethod('save_file', _fileHandler.saveFile);
    _peer.registerMethod('export_pdf', _fileHandler.exportPdf);
    _peer.registerMethod('export_csv', _fileHandler.exportCsv);
    _peer.registerMethod('import_csv', _fileHandler.importCsv);
    _peer.registerMethod('close_workbook', _fileHandler.closeWorkbook);
  }

  Future<dynamic> _handleInitialize(Request request) async {
    return {
      'protocolVersion': '2024-11-05',
      'capabilities': {
        'tools': {},
      },
      'serverInfo': {
        'name': 'ky-sheet-mcp-server',
        'version': '0.1.0',
      },
    };
  }

  Future<dynamic> _handleToolsList(Request request) async {
    return {
      'tools': [
        // Spreadsheet operations
        {
          'name': 'create_workbook',
          'description': 'Create a new workbook',
          'inputSchema': {
            'type': 'object',
            'properties': {
              'name': {'type': 'string', 'description': 'Workbook name'},
            },
          },
        },
        {
          'name': 'create_sheet',
          'description': 'Create a new sheet in the active workbook',
          'inputSchema': {
            'type': 'object',
            'properties': {
              'name': {'type': 'string', 'description': 'Sheet name'},
              'index': {'type': 'integer', 'description': 'Sheet index (optional)'},
            },
          },
        },
        {
          'name': 'read_cell',
          'description': 'Read value from a specific cell',
          'inputSchema': {
            'type': 'object',
            'properties': {
              'sheet_name': {'type': 'string', 'description': 'Sheet name'},
              'row': {'type': 'integer', 'description': 'Row number (1-based)'},
              'column': {'type': 'integer', 'description': 'Column number (1-based)'},
            },
            'required': ['sheet_name', 'row', 'column'],
          },
        },
        {
          'name': 'write_cell',
          'description': 'Write value to a specific cell',
          'inputSchema': {
            'type': 'object',
            'properties': {
              'sheet_name': {'type': 'string', 'description': 'Sheet name'},
              'row': {'type': 'integer', 'description': 'Row number (1-based)'},
              'column': {'type': 'integer', 'description': 'Column number (1-based)'},
              'value': {'type': 'string', 'description': 'Value to write'},
              'is_formula': {'type': 'boolean', 'description': 'Whether value is a formula'},
            },
            'required': ['sheet_name', 'row', 'column', 'value'],
          },
        },
        {
          'name': 'read_range',
          'description': 'Read values from a range of cells',
          'inputSchema': {
            'type': 'object',
            'properties': {
              'sheet_name': {'type': 'string', 'description': 'Sheet name'},
              'start_row': {'type': 'integer', 'description': 'Start row (1-based)'},
              'start_column': {'type': 'integer', 'description': 'Start column (1-based)'},
              'end_row': {'type': 'integer', 'description': 'End row (1-based)'},
              'end_column': {'type': 'integer', 'description': 'End column (1-based)'},
            },
            'required': ['sheet_name', 'start_row', 'start_column', 'end_row', 'end_column'],
          },
        },
        {
          'name': 'format_cell',
          'description': 'Apply formatting to a cell',
          'inputSchema': {
            'type': 'object',
            'properties': {
              'sheet_name': {'type': 'string', 'description': 'Sheet name'},
              'row': {'type': 'integer', 'description': 'Row number'},
              'column': {'type': 'integer', 'description': 'Column number'},
              'format': {'type': 'object', 'description': 'Format properties'},
            },
            'required': ['sheet_name', 'row', 'column', 'format'],
          },
        },
        {
          'name': 'create_chart',
          'description': 'Create a chart in the sheet',
          'inputSchema': {
            'type': 'object',
            'properties': {
              'sheet_name': {'type': 'string', 'description': 'Sheet name'},
              'chart_type': {'type': 'string', 'description': 'Type of chart'},
              'data_range': {'type': 'string', 'description': 'Data range (e.g., A1:B10)'},
              'title': {'type': 'string', 'description': 'Chart title'},
            },
            'required': ['sheet_name', 'chart_type', 'data_range'],
          },
        },
        {
          'name': 'open_file',
          'description': 'Open an existing spreadsheet file',
          'inputSchema': {
            'type': 'object',
            'properties': {
              'file_path': {'type': 'string', 'description': 'Path to the file'},
              'file_type': {'type': 'string', 'description': 'File type (xlsx, csv, etc.)'},
            },
            'required': ['file_path'],
          },
        },
        {
          'name': 'save_file',
          'description': 'Save the current workbook to a file',
          'inputSchema': {
            'type': 'object',
            'properties': {
              'file_path': {'type': 'string', 'description': 'Path to save the file'},
              'file_type': {'type': 'string', 'description': 'File type (xlsx, csv, etc.)'},
            },
            'required': ['file_path'],
          },
        },
      ],
    };
  }

  Future<dynamic> _handleToolsCall(Request request) async {
    final params = request.params as Map<String, dynamic>;
    final toolName = params['name'] as String;
    final arguments = params['arguments'] as Map<String, dynamic>?;
    
    try {
      final result = await _peer.callMethod(toolName, arguments ?? {});
      return {
        'content': [
          {
            'type': 'text',
            'text': jsonEncode(result),
          },
        ],
      };
    } catch (e) {
      return {
        'content': [
          {
            'type': 'text',
            'text': 'Error executing tool $toolName: $e',
          },
        ],
        'isError': true,
      };
    }
  }

  // Helper methods for handlers
  Workbook? getActiveWorkbook() {
    if (_activeWorkbookId == null) return null;
    return _workbooks[_activeWorkbookId];
  }

  void setActiveWorkbook(String id, Workbook workbook) {
    _workbooks[id] = workbook;
    _activeWorkbookId = id;
  }

  String generateWorkbookId() {
    return 'wb_${DateTime.now().millisecondsSinceEpoch}';
  }
}
