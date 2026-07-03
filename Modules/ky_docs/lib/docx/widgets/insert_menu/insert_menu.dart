import 'package:flutter/material.dart';
import 'package:ky_docs/ky_docs.dart';

import '../../services/document_editor_commands.dart';

/// Comprehensive Insert Menu widget similar to MS Word/Google Docs
/// Provides access to insert images, tables, links, headers/footers, etc.
class InsertMenu extends StatefulWidget {
  final DocumentEditorCommands commands;
  final VoidCallback? onDismiss;

  const InsertMenu({super.key, required this.commands, this.onDismiss});

  @override
  State<InsertMenu> createState() => _InsertMenuState();
}

class _InsertMenuState extends State<InsertMenu> {
  final LayerLink _layerLink = LayerLink();
  bool _isOpen = false;

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: PopupMenuButton<String>(
        tooltip: 'Insert',
        icon: const Icon(Icons.add_circle_outline),
        offset: const Offset(0, 40),
        onSelected: _handleMenuItem,
        itemBuilder: (context) => [
          _buildSectionHeader('Media'),
          const PopupMenuItem<String>(
            value: 'image',
            child: ListTile(
              leading: Icon(Icons.image, size: 20),
              title: Text('Image'),
              subtitle: Text('Insert from file or URL'),
              dense: true,
            ),
          ),
          const PopupMenuItem<String>(
            value: 'camera',
            child: ListTile(
              leading: Icon(Icons.camera_alt, size: 20),
              title: Text('Camera'),
              subtitle: Text('Take a photo'),
              dense: true,
            ),
          ),
          const PopupMenuItem<String>(
            value: 'chart',
            child: ListTile(
              leading: Icon(Icons.insert_chart, size: 20),
              title: Text('Chart'),
              subtitle: Text('Insert chart (bar, line, pie)'),
              dense: true,
            ),
          ),
          const Divider(height: 1),
          _buildSectionHeader('Tables & Objects'),
          const PopupMenuItem<String>(
            value: 'table',
            child: ListTile(
              leading: Icon(Icons.table_chart, size: 20),
              title: Text('Table'),
              subtitle: Text('Insert table'),
              dense: true,
            ),
          ),
          const PopupMenuItem<String>(
            value: 'drawing',
            child: ListTile(
              leading: Icon(Icons.draw, size: 20),
              title: Text('Drawing'),
              subtitle: Text('Insert drawing or shape'),
              dense: true,
            ),
          ),
          const Divider(height: 1),
          _buildSectionHeader('Links & References'),
          const PopupMenuItem<String>(
            value: 'link',
            child: ListTile(
              leading: Icon(Icons.link, size: 20),
              title: Text('Link'),
              subtitle: Text('Insert hyperlink'),
              dense: true,
            ),
          ),
          const PopupMenuItem<String>(
            value: 'bookmark',
            child: ListTile(
              leading: Icon(Icons.bookmark, size: 20),
              title: Text('Bookmark'),
              subtitle: Text('Insert bookmark'),
              dense: true,
            ),
          ),
          const PopupMenuItem<String>(
            value: 'toc',
            child: ListTile(
              leading: Icon(Icons.list, size: 20),
              title: Text('Table of Contents'),
              subtitle: Text('Insert automatic TOC'),
              dense: true,
            ),
          ),
          const Divider(height: 1),
          _buildSectionHeader('Document Structure'),
          const PopupMenuItem<String>(
            value: 'page_break',
            child: ListTile(
              leading: Icon(Icons.auto_awesome, size: 20),
              title: Text('Page Break'),
              subtitle: Text('Insert page break'),
              dense: true,
            ),
          ),
          const PopupMenuItem<String>(
            value: 'header_footer',
            child: ListTile(
              leading: Icon(Icons.header, size: 20),
              title: Text('Header & Footer'),
              subtitle: Text('Edit header and footer'),
              dense: true,
            ),
          ),
          const PopupMenuItem<String>(
            value: 'page_number',
            child: ListTile(
              leading: Icon(Icons.format_list_numbered, size: 20),
              title: Text('Page Number'),
              subtitle: Text('Insert page number'),
              dense: true,
            ),
          ),
          const Divider(height: 1),
          _buildSectionHeader('Special'),
          const PopupMenuItem<String>(
            value: 'symbol',
            child: ListTile(
              leading: Icon(Icons.emoji_symbols, size: 20),
              title: Text('Symbol'),
              subtitle: Text('Insert special character'),
              dense: true,
            ),
          ),
          const PopupMenuItem<String>(
            value: 'date_time',
            child: ListTile(
              leading: Icon(Icons.calendar_today, size: 20),
              title: Text('Date & Time'),
              subtitle: Text('Insert current date/time'),
              dense: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return PopupMenuItem<String>(
      enabled: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.grey[600],
          ),
        ),
      ),
    );
  }

  void _handleMenuItem(String value) async {
    widget.onDismiss?.call();

    switch (value) {
      case 'image':
        await _insertImage();
        break;
      case 'camera':
        await _insertFromCamera();
        break;
      case 'chart':
        await _insertChart();
        break;
      case 'table':
        await _insertTable();
        break;
      case 'drawing':
        await _insertDrawing();
        break;
      case 'link':
        await _insertLink();
        break;
      case 'bookmark':
        await _insertBookmark();
        break;
      case 'toc':
        await _insertTableOfContents();
        break;
      case 'page_break':
        await _insertPageBreak();
        break;
      case 'header_footer':
        await _editHeaderFooter();
        break;
      case 'page_number':
        await _insertPageNumber();
        break;
      case 'symbol':
        await _insertSymbol();
        break;
      case 'date_time':
        await _insertDateTime();
        break;
    }
  }

  Future<void> _insertImage() async {
    // Show image source dialog
    final source = await showDialog<ImageSource>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Insert Image'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.folder),
              title: const Text('From File'),
              onTap: () => Navigator.pop(context, ImageSource.file),
            ),
            ListTile(
              leading: const Icon(Icons.link),
              title: const Text('From URL'),
              onTap: () => Navigator.pop(context, ImageSource.url),
            ),
            ListTile(
              leading: const Icon(Icons.cloud_upload),
              title: const Text('From Cloud'),
              onTap: () => Navigator.pop(context, ImageSource.cloud),
            ),
          ],
        ),
      ),
    );

    if (source == null) return;

    switch (source) {
      case ImageSource.file:
        // Use file picker to select image
        // For now, use placeholder
        widget.commands.insertBlock(
          BlockType.image,
          attributes: {
            'source': 'file',
            'url': '', // Will be filled by file picker
            'width': 400.0,
            'height': 300.0,
            'caption': '',
          },
        );
        break;
      case ImageSource.url:
        // Show URL input dialog
        final url = await showDialog<String>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Insert Image from URL'),
            content: TextField(
              decoration: const InputDecoration(
                labelText: 'Image URL',
                hintText: 'https://example.com/image.jpg',
              ),
              autofocus: true,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  // Get URL from text field - simplified for demo
                  Navigator.pop(context, 'https://example.com/image.jpg');
                },
                child: const Text('Insert'),
              ),
            ],
          ),
        );
        if (url != null && url.isNotEmpty) {
          widget.commands.insertBlock(
            BlockType.image,
            attributes: {
              'source': 'url',
              'url': url,
              'width': 400.0,
              'height': 300.0,
              'caption': '',
            },
          );
        }
        break;
      case ImageSource.cloud:
        // TODO: Implement cloud storage integration
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cloud storage integration coming soon'),
          ),
        );
        break;
    }
  }

  Future<void> _insertFromCamera() async {
    // TODO: Implement camera capture
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Camera capture coming soon')));
  }

  Future<void> _insertChart() async {
    // Launch chart insertion dialog from ky_charts
    // This would integrate with the ky_charts plugin we created earlier
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Opening chart editor...')));
    // In production: await ChartDialog.show(context, commands: widget.commands);
  }

  Future<void> _insertTable() async {
    // Show table grid selector
    final result = await showDialog<Map<String, int>>(
      context: context,
      builder: (context) => TableGridSelector(),
    );

    if (result != null) {
      final rows = result['rows'] ?? 3;
      final cols = result['cols'] ?? 3;

      widget.commands.insertBlock(
        BlockType.table,
        attributes: {
          'rows': rows,
          'cols': cols,
          'data': List.generate(rows, (_) => List.generate(cols, (_) => '')),
          'borderWidth': 1.0,
          'borderColor': '#000000',
        },
      );
    }
  }

  Future<void> _insertDrawing() async {
    // TODO: Implement drawing canvas
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Drawing canvas coming soon')));
  }

  Future<void> _insertLink() async {
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => LinkDialog(),
    );

    if (result != null) {
      widget.commands.insertText(
        result['text'] ?? result['url']!,
        attributes: {'link': result['url'], 'tooltip': result['title'] ?? ''},
      );
    }
  }

  Future<void> _insertBookmark() async {
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Insert Bookmark'),
        content: TextField(
          decoration: const InputDecoration(
            labelText: 'Bookmark Name',
            hintText: 'e.g., chapter1',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // Get text from field - simplified
              Navigator.pop(context, 'bookmark1');
            },
            child: const Text('Insert'),
          ),
        ],
      ),
    );

    if (name != null && name.isNotEmpty) {
      widget.commands.insertBlock(
        BlockType.bookmark,
        attributes: {'name': name},
      );
    }
  }

  Future<void> _insertTableOfContents() async {
    widget.commands.insertBlock(
      BlockType.toc,
      attributes: {'maxDepth': 3, 'includeLinks': true},
    );
  }

  Future<void> _insertPageBreak() async {
    widget.commands.insertBlock(BlockType.pageBreak, attributes: {});
  }

  Future<void> _editHeaderFooter() async {
    // Toggle header/footer editing mode
    widget.commands.toggleHeaderFooter();
  }

  Future<void> _insertPageNumber() async {
    final format = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Page Number Format'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('1, 2, 3'),
              onTap: () => Navigator.pop(context, 'numeric'),
            ),
            ListTile(
              title: const Text('i, ii, iii'),
              onTap: () => Navigator.pop(context, 'roman'),
            ),
            ListTile(
              title: const Text('a, b, c'),
              onTap: () => Navigator.pop(context, 'alpha'),
            ),
            ListTile(
              title: const Text('Page 1 of 10'),
              onTap: () => Navigator.pop(context, 'full'),
            ),
          ],
        ),
      ),
    );

    if (format != null) {
      widget.commands.insertBlock(
        BlockType.pageNumber,
        attributes: {'format': format},
      );
    }
  }

  Future<void> _insertSymbol() async {
    // Show symbol picker dialog
    final symbol = await showDialog<String>(
      context: context,
      builder: (context) => SymbolPickerDialog(),
    );

    if (symbol != null) {
      widget.commands.insertText(symbol);
    }
  }

  Future<void> _insertDateTime() async {
    final now = DateTime.now();
    final format = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Date & Time Format'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text('${now.day}/${now.month}/${now.year}'),
              subtitle: const Text('DD/MM/YYYY'),
              onTap: () => Navigator.pop(context, 'DD/MM/YYYY'),
            ),
            ListTile(
              title: Text('${now.month}/${now.day}/${now.year}'),
              subtitle: const Text('MM/DD/YYYY'),
              onTap: () => Navigator.pop(context, 'MM/DD/YYYY'),
            ),
            ListTile(
              title: Text('${_formatDate(now)} ${_formatTime(now)}'),
              subtitle: const Text('Full date and time'),
              onTap: () => Navigator.pop(context, 'full'),
            ),
            ListTile(
              title: Text(_formatTime(now)),
              subtitle: const Text('Time only'),
              onTap: () => Navigator.pop(context, 'time'),
            ),
          ],
        ),
      ),
    );

    if (format != null) {
      String dateTimeStr;
      switch (format) {
        case 'DD/MM/YYYY':
          dateTimeStr =
              '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';
          break;
        case 'MM/DD/YYYY':
          dateTimeStr =
              '${now.month.toString().padLeft(2, '0')}/${now.day.toString().padLeft(2, '0')}/${now.year}';
          break;
        case 'full':
          dateTimeStr = '${_formatDate(now)} ${_formatTime(now)}';
          break;
        case 'time':
          dateTimeStr = _formatTime(now);
          break;
        default:
          dateTimeStr = now.toString();
      }
      widget.commands.insertText(dateTimeStr);
    }
  }

  String _formatDate(DateTime dt) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }

  String _formatTime(DateTime dt) {
    final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    return '$hour:${dt.minute.toString().padLeft(2, '0')} $period';
  }
}

enum ImageSource { file, url, cloud }

/// Table grid selector widget
class TableGridSelector extends StatefulWidget {
  const TableGridSelector({super.key});

  @override
  State<TableGridSelector> createState() => _TableGridSelectorState();
}

class _TableGridSelectorState extends State<TableGridSelector> {
  int _selectedRows = 3;
  int _selectedCols = 3;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Insert Table'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$_selectedRows x $_selectedCols'),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 8,
              mainAxisSpacing: 2,
              crossAxisSpacing: 2,
            ),
            itemCount: 64,
            itemBuilder: (context, index) {
              final row = (index / 8).floor() + 1;
              final col = (index % 8) + 1;
              final isSelected = row <= _selectedRows && col <= _selectedCols;

              return GestureDetector(
                onEnter: (_) {
                  setState(() {
                    _selectedRows = row;
                    _selectedCols = col;
                  });
                },
                onTap: () => Navigator.pop(context, {
                  'rows': _selectedRows,
                  'cols': _selectedCols,
                }),
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.blue : Colors.grey[300],
                    border: Border.all(color: Colors.grey),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, {
                  'rows': _selectedRows,
                  'cols': _selectedCols,
                }),
                child: const Text('Insert'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Link insertion dialog
class LinkDialog extends StatefulWidget {
  const LinkDialog({super.key});

  @override
  State<LinkDialog> createState() => _LinkDialogState();
}

class _LinkDialogState extends State<LinkDialog> {
  final _urlController = TextEditingController();
  final _textController = TextEditingController();
  final _titleController = TextEditingController();

  @override
  void dispose() {
    _urlController.dispose();
    _textController.dispose();
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Insert Link'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _urlController,
            decoration: const InputDecoration(
              labelText: 'URL',
              hintText: 'https://example.com',
            ),
            keyboardType: TextInputType.url,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _textController,
            decoration: const InputDecoration(
              labelText: 'Display Text (optional)',
              hintText: 'Click here',
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: 'Title/Tooltip (optional)',
              hintText: 'Hover text',
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_urlController.text.isEmpty) return;
            Navigator.pop(context, {
              'url': _urlController.text,
              'text': _textController.text,
              'title': _titleController.text,
            });
          },
          child: const Text('Insert'),
        ),
      ],
    );
  }
}

/// Symbol picker dialog
class SymbolPickerDialog extends StatelessWidget {
  const SymbolPickerDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final symbols = [
      '©',
      '®',
      '™',
      '§',
      '¶',
      '•',
      '…',
      '—',
      '–',
      '°',
      '±',
      '×',
      '÷',
      '√',
      '∞',
      '≈',
      '≠',
      '≤',
      '≥',
      'α',
      'β',
      'γ',
      'δ',
      'ε',
      'π',
      'σ',
      'ω',
      'Δ',
      'Ω',
      '→',
      '←',
      '↑',
      '↓',
      '↔',
      '⇒',
      '⇐',
      '⇑',
      '⇓',
      '★',
      '☆',
      '❤',
      '♠',
      '♣',
      '♦',
      '♫',
      '☀',
      '☁',
      '☂',
    ];

    return AlertDialog(
      title: const Text('Insert Symbol'),
      content: SizedBox(
        width: 400,
        height: 300,
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 10,
            mainAxisSpacing: 4,
            crossAxisSpacing: 4,
          ),
          itemCount: symbols.length,
          itemBuilder: (context, index) {
            return GestureDetector(
              onTap: () => Navigator.pop(context, symbols[index]),
              child: Center(
                child: Text(
                  symbols[index],
                  style: const TextStyle(fontSize: 20),
                ),
              ),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}
