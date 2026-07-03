# Ky Sheet MCP Tools

This directory contains Model Context Protocol (MCP) tools for the Ky Sheet spreadsheet application. These tools enable AI agents to interact with and manipulate spreadsheet data programmatically.

## Available Tools

### Spreadsheet Operations
- `create_sheet` - Create a new spreadsheet or worksheet
- `read_cell` - Read data from a specific cell
- `write_cell` - Write data to a specific cell
- `read_range` - Read data from a range of cells
- `write_range` - Write data to a range of cells
- `delete_row` - Delete a row from the sheet
- `delete_column` - Delete a column from the sheet
- `insert_row` - Insert a new row
- `insert_column` - Insert a new column

### Formatting Operations
- `format_cell` - Apply formatting to a cell
- `format_range` - Apply formatting to a range
- `set_column_width` - Set the width of a column
- `set_row_height` - Set the height of a row
- `merge_cells` - Merge multiple cells
- `unmerge_cells` - Unmerge previously merged cells

### Data Operations
- `sort_range` - Sort data in a range
- `filter_data` - Apply filters to data
- `find_replace` - Find and replace text
- `validate_data` - Apply data validation rules
- `get_formulas` - Extract formulas from cells
- `calculate_formula` - Calculate a formula result

### Chart Operations
- `create_chart` - Create a chart from data
- `update_chart` - Update chart properties
- `delete_chart` - Remove a chart

### File Operations
- `open_file` - Open a spreadsheet file
- `save_file` - Save the current spreadsheet
- `export_pdf` - Export spreadsheet to PDF
- `export_csv` - Export sheet to CSV
- `import_csv` - Import CSV data into sheet

## Tool Schema

Each tool follows the MCP standard schema:
```json
{
  "name": "tool_name",
  "description": "Description of what the tool does",
  "inputSchema": {
    "type": "object",
    "properties": {
      // Tool-specific parameters
    },
    "required": ["param1", "param2"]
  }
}
```

## Usage Example

```python
# Example: Reading cell data
{
  "tool": "read_cell",
  "parameters": {
    "sheet_id": "Sheet1",
    "cell_address": "A1"
  }
}

# Example: Writing to a range
{
  "tool": "write_range",
  "parameters": {
    "sheet_id": "Sheet1",
    "range": "A1:C3",
    "values": [
      ["Name", "Age", "City"],
      ["Alice", 30, "NYC"],
      ["Bob", 25, "LA"]
    ]
  }
}
```

## Implementation Notes

- All tools return standardized response formats
- Error handling includes detailed error messages
- Cell addresses use A1 notation (e.g., "A1", "B2:C10")
- Sheet IDs can be names or indices
- Large operations may be batched for performance
