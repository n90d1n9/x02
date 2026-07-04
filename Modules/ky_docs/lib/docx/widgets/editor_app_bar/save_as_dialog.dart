import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Save As dialog implementation similar to MS Word/Google Docs
class SaveAsDialog extends StatefulWidget {
  final String currentTitle;
  final String? currentPath;
  final List<String> availableFormats;

  const SaveAsDialog({
    super.key,
    required this.currentTitle,
    this.currentPath,
    this.availableFormats = const ['docx', 'pdf', 'txt'],
  });

  static Future<SaveAsResult?> show(
    BuildContext context, {
    required String currentTitle,
    String? currentPath,
    List<String>? availableFormats,
  }) {
    return showDialog<SaveAsResult>(
      context: context,
      builder: (context) => SaveAsDialog(
        currentTitle: currentTitle,
        currentPath: currentPath,
        availableFormats: availableFormats ?? ['docx', 'pdf', 'txt'],
      ),
    );
  }

  @override
  State<SaveAsDialog> createState() => _SaveAsDialogState();
}

class _SaveAsDialogState extends State<SaveAsDialog> {
  late TextEditingController _nameController;
  String _selectedFormat = 'docx';
  String? _selectedLocation;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    // Remove extension from current title for editing
    final nameWithoutExt = widget.currentTitle.replaceAll(
      RegExp(r'\.(docx|pdf|txt)$'),
      '',
    );
    _nameController = TextEditingController(text: nameWithoutExt);
    _selectedLocation = widget.currentPath ?? _getDefaultLocation();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  String _getDefaultLocation() {
    // Default to Documents folder
    return 'Documents';
  }

  String get _fullFileName => '${_nameController.text.trim()}.$_selectedFormat';

  Future<void> _pickLocation() async {
    final result = await FilePicker.platform.getDirectoryPath();
    if (result != null) {
      setState(() {
        _selectedLocation = result;
      });
    }
  }

  Future<void> _save() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter a file name')));
      return;
    }

    setState(() => _isSaving = true);

    try {
      // For now, return the result - actual saving will be handled by caller
      Navigator.of(context).pop(
        SaveAsResult(
          fileName: _fullFileName,
          format: _selectedFormat,
          location: _selectedLocation,
          fullPath: _selectedLocation != null
              ? '$_selectedLocation/$_fullFileName'
              : _fullFileName,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.save_as, color: Colors.blue),
          SizedBox(width: 8),
          Text('Save As'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // File name input
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'File name',
                hintText: 'Enter document name',
                prefixIcon: Icon(Icons.description),
                border: OutlineInputBorder(),
              ),
              autofocus: true,
              onSubmitted: (_) => _save(),
            ),
            const SizedBox(height: 16),

            // Format selection
            const Text(
              'Save as type:',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: widget.availableFormats.map((format) {
                final isSelected = _selectedFormat == format;
                return ChoiceChip(
                  label: Text(format.toUpperCase()),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() => _selectedFormat = format);
                    }
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Location selector
            const Text(
              'Location:',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: _pickLocation,
              borderRadius: BorderRadius.circular(4),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.folder, color: Colors.amber),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _selectedLocation ?? 'Select location...',
                        style: const TextStyle(fontSize: 14),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Icon(Icons.edit, size: 16, color: Colors.grey),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Full path: ${_selectedLocation ?? 'Not selected'}/$_fullFileName',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
                fontStyle: FontStyle.italic,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton.icon(
          onPressed: _isSaving ? null : _save,
          icon: _isSaving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.save),
          label: Text(_isSaving ? 'Saving...' : 'Save'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }
}

/// Result from Save As dialog
class SaveAsResult {
  final String fileName;
  final String format;
  final String? location;
  final String fullPath;

  const SaveAsResult({
    required this.fileName,
    required this.format,
    this.location,
    required this.fullPath,
  });

  /// Get file extension with dot
  String get extension => '.$format';

  /// Get file name without extension
  String get nameWithoutExtension => fileName.replaceAll(RegExp(r'\.\w+$'), '');
}
