# KySheet MCP Server

A Model Context Protocol (MCP) server for KySheet spreadsheet operations, enabling AI agents to create, read, update, and manage spreadsheets programmatically.

## Features

- **Spreadsheet Management**: Create workbooks, add/remove sheets, rename sheets
- **Cell Operations**: Read/write individual cells and ranges
- **Formatting**: Apply cell formatting, borders, merge cells, adjust column/row sizes
- **Data Operations**: Sort, filter, find/replace, data validation
- **Formulas**: Calculate and evaluate formulas
- **Charts**: Create, update, and delete charts
- **File I/O**: Open/save XLSX and CSV files, import/export data

## Installation

### Prerequisites

- Dart SDK >= 3.0.0
- ky_sheet package

### Setup

```bash
cd mcp_server
dart pub get
```

## Usage

### Running the Server

```bash
dart run bin/ky_sheet_mcp_server.dart
```

The server communicates via JSON-RPC 2.0 over stdin/stdout.

### MCP Configuration

Add to your MCP client configuration:

```json
{
  "mcpServers": {
    "ky-sheet": {
      "command": "dart",
      "args": ["run", "bin/ky_sheet_mcp_server.dart"],
      "cwd": "/path/to/ky_sheet/mcp_server"
    }
  }
}
```

## Available Tools

### Spreadsheet Operations

| Tool | Description |
|------|-------------|
| `create_workbook` | Create a new workbook |
| `create_sheet` | Add a new sheet to the active workbook |
| `delete_sheet` | Remove a sheet from the workbook |
| `rename_sheet` | Rename an existing sheet |
| `list_sheets` | List all sheets in the workbook |
| `get_active_sheet` | Get the currently active sheet |
| `set_active_sheet` | Set the active sheet |

### Cell Operations

| Tool | Description |
|------|-------------|
| `read_cell` | Read value from a specific cell |
| `write_cell` | Write value to a specific cell |
| `read_range` | Read values from a range of cells |
| `write_range` | Write values to a range of cells |

### Formatting Operations

| Tool | Description |
|------|-------------|
| `format_cell` | Apply formatting to a single cell |
| `format_range` | Apply formatting to a range of cells |
| `merge_cells` | Merge a range of cells |
| `unmerge_cells` | Unmerge previously merged cells |
| `set_column_width` | Set the width of a column |
| `set_row_height` | Set the height of a row |
| `set_border` | Apply borders to cells |
| `clear_formatting` | Remove formatting from cells |

### Data Operations

| Tool | Description |
|------|-------------|
| `sort_range` | Sort data in a range |
| `filter_data` | Filter data based on criteria |
| `find_replace` | Find and replace text |
| `validate_data` | Validate cell data against rules |
| `calculate_formula` | Calculate a formula |
| `get_formula_result` | Get the result of a formula in a cell |

### Chart Operations

| Tool | Description |
|------|-------------|
| `create_chart` | Create a new chart |
| `update_chart` | Update an existing chart |
| `delete_chart` | Delete a chart |
| `list_charts` | List all charts in a sheet |

### File Operations

| Tool | Description |
|------|-------------|
| `open_file` | Open an existing spreadsheet file |
| `save_file` | Save the current workbook |
| `export_csv` | Export a sheet to CSV |
| `import_csv` | Import data from CSV |
| `close_workbook` | Close a workbook |

## Example Requests

### Create a Workbook

```json
{
  "jsonrpc": "2.0",
  "id": 1,
  "method": "tools/call",
  "params": {
    "name": "create_workbook",
    "arguments": {
      "name": "My Spreadsheet"
    }
  }
}
```

### Write Data to Cells

```json
{
  "jsonrpc": "2.0",
  "id": 2,
  "method": "tools/call",
  "params": {
    "name": "write_range",
    "arguments": {
      "sheet_name": "Sheet1",
      "start_row": 1,
      "start_column": 1,
      "values": [
        ["Name", "Age", "City"],
        ["Alice", 30, "New York"],
        ["Bob", 25, "London"]
      ]
    }
  }
}
```

### Format a Range

```json
{
  "jsonrpc": "2.0",
  "id": 3,
  "method": "tools/call",
  "params": {
    "name": "format_range",
    "arguments": {
      "sheet_name": "Sheet1",
      "start_row": 1,
      "start_column": 1,
      "end_row": 1,
      "end_column": 3,
      "format": {
        "bold": true,
        "background_color": "FFD700",
        "horizontal_alignment": "center"
      }
    }
  }
}
```

### Create a Chart

```json
{
  "jsonrpc": "2.0",
  "id": 4,
  "method": "tools/call",
  "params": {
    "name": "create_chart",
    "arguments": {
      "sheet_name": "Sheet1",
      "chart_type": "column",
      "data_range": "A1:B10",
      "title": "Sales Data"
    }
  }
}
```

## Architecture

```
mcp_server/
├── bin/
│   └── ky_sheet_mcp_server.dart    # Main entry point
├── lib/
│   └── src/
│       ├── handlers/
│       │   ├── spreadsheet_handler.dart
│       │   ├── formatting_handler.dart
│       │   ├── data_handler.dart
│       │   ├── chart_handler.dart
│       │   └── file_handler.dart
│       └── models/
└── pubspec.yaml
```

## Error Handling

All tools return a consistent response format:

```json
{
  "success": true/false,
  "error": "Error message if success is false",
  ...additional data
}
```

## Limitations

- PDF export requires additional setup
- XLSX read/write requires `ky_of_xlsx` integration
- Some advanced Excel features may not be supported

## Development

### Adding New Tools

1. Create handler method in the appropriate handler file
2. Register the method in `ky_sheet_mcp_server.dart`
3. Add tool definition to `_handleToolsList`
4. Update documentation

### Testing

```bash
dart test
```

## License

MIT License - see LICENSE file for details

## Contributing

Contributions are welcome! Please read the contributing guidelines before submitting PRs.
