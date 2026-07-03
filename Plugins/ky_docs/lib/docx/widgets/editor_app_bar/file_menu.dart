import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../states/doc_notifier.dart';
import '../../../states/docs_provider.dart';
import 'save_as_dialog.dart';

/// File menu implementation similar to MS Word/Google Docs File menu
class DocumentFileMenu extends ConsumerStatefulWidget {
  final VoidCallback? onNew;
  final VoidCallback? onOpen;
  final VoidCallback? onSave;
  final VoidCallback? onSaveAs;
  final ValueChanged<String>? onImport;
  final ValueChanged<String>? onExport;
  final VoidCallback? onPrint;
  final VoidCallback? onShare;
  final VoidCallback? onClose;

  const DocumentFileMenu({
    super.key,
    this.onNew,
    this.onOpen,
    this.onSave,
    this.onSaveAs,
    this.onImport,
    this.onExport,
    this.onPrint,
    this.onShare,
    this.onClose,
  });

  @override
  ConsumerState<DocumentFileMenu> createState() => _DocumentFileMenuState();
}

class _DocumentFileMenuState extends ConsumerState<DocumentFileMenu> {
  bool _isOpen = false;
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;

  @override
  void dispose() {
    _removeOverlay();
    super.dispose();
  }

  void _toggleMenu() {
    if (_isOpen) {
      _removeOverlay();
    } else {
      _showOverlay();
    }
  }

  void _showOverlay() {
    _overlayEntry = _createOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);
    setState(() => _isOpen = true);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    setState(() => _isOpen = false);
  }

  Future<void> _handleSaveAs() async {
    _removeOverlay();
    
    // Get current document state
    final docNotifier = ref.read(documentProvider.notifier);
    final docState = ref.read(documentProvider);
    
    // Show Save As dialog
    final result = await SaveAsDialog.show(
      context,
      currentTitle: docState.metadata.title,
    );
    
    if (result != null) {
      // Call the saveDocumentAs method on the notifier
      final success = await docNotifier.saveDocumentAs(
        newTitle: result.nameWithoutExtension,
        format: result.format,
        location: result.location,
      );
      
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Saved as ${result.fileName}'),
            backgroundColor: Colors.green,
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to save document'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
    
    // Also call the callback if provided
    widget.onSaveAs?.call();
  }

  OverlayEntry _createOverlayEntry() {
    final renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;

    return OverlayEntry(
      builder: (context) => Positioned(
        width: size.width,
        child: CompositedTransformFollower(
          link: _layerLink,
          offset: Offset(0, size.height + 8),
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              constraints: const BoxConstraints(minWidth: 280),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: _buildMenuContent(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMenuContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildMenuItem(
          icon: Icons.note_add,
          label: 'New',
          subtitle: 'Create a new document',
          shortcut: 'Ctrl+N',
          onTap: () {
            _removeOverlay();
            widget.onNew?.call();
          },
        ),
        _buildMenuItem(
          icon: Icons.folder_open,
          label: 'Open',
          subtitle: 'Open an existing document',
          shortcut: 'Ctrl+O',
          onTap: () {
            _removeOverlay();
            widget.onOpen?.call();
          },
        ),
        const Divider(height: 1),
        _buildMenuItem(
          icon: Icons.save,
          label: 'Save',
          subtitle: 'Save current document',
          shortcut: 'Ctrl+S',
          enabled: widget.onSave != null,
          onTap: () {
            _removeOverlay();
            widget.onSave?.call();
          },
        ),
        _buildMenuItem(
          icon: Icons.save_as,
          label: 'Save As...',
          subtitle: 'Save with a new name or format',
          shortcut: 'Ctrl+Shift+S',
          onTap: _handleSaveAs,
        ),
        const Divider(height: 1),
        _buildSubMenu(
          icon: Icons.file_upload,
          label: 'Import',
          children: [
            _buildSubMenuItem(
              icon: Icons.description,
              label: 'DOCX',
              subtitle: 'Microsoft Word document',
              onTap: () {
                _removeOverlay();
                widget.onImport?.call('docx');
              },
            ),
            _buildSubMenuItem(
              icon: Icons.picture_as_pdf,
              label: 'PDF',
              subtitle: 'Portable Document Format',
              onTap: () {
                _removeOverlay();
                widget.onImport?.call('pdf');
              },
            ),
            _buildSubMenuItem(
              icon: Icons.text_fields,
              label: 'Plain Text',
              subtitle: 'TXT file',
              onTap: () {
                _removeOverlay();
                widget.onImport?.call('txt');
              },
            ),
          ],
        ),
        _buildSubMenu(
          icon: Icons.file_download,
          label: 'Export / Download',
          children: [
            _buildSubMenuItem(
              icon: Icons.description,
              label: 'DOCX',
              subtitle: 'Microsoft Word format',
              onTap: () {
                _removeOverlay();
                widget.onExport?.call('docx');
              },
            ),
            _buildSubMenuItem(
              icon: Icons.picture_as_pdf,
              label: 'PDF',
              subtitle: 'Portable Document Format',
              onTap: () {
                _removeOverlay();
                widget.onExport?.call('pdf');
              },
            ),
            _buildSubMenuItem(
              icon: Icons.tune,
              label: 'PDF (Advanced Options)',
              subtitle: 'Customize PDF export settings',
              onTap: () {
                _removeOverlay();
                widget.onExport?.call('pdf_advanced');
              },
            ),
            _buildSubMenuItem(
              icon: Icons.text_fields,
              label: 'Plain Text',
              subtitle: 'TXT file',
              onTap: () {
                _removeOverlay();
                widget.onExport?.call('txt');
              },
            ),
          ],
        ),
        const Divider(height: 1),
        _buildMenuItem(
          icon: Icons.print,
          label: 'Print',
          subtitle: 'Print document',
          shortcut: 'Ctrl+P',
          enabled: widget.onPrint != null,
          onTap: () {
            _removeOverlay();
            widget.onPrint?.call();
          },
        ),
        _buildMenuItem(
          icon: Icons.share,
          label: 'Share',
          subtitle: 'Share with others',
          shortcut: 'Ctrl+Shift+P',
          enabled: widget.onShare != null,
          onTap: () {
            _removeOverlay();
            widget.onShare?.call();
          },
        ),
        const Divider(height: 1),
        _buildMenuItem(
          icon: Icons.close,
          label: 'Close',
          subtitle: 'Close current document',
          onTap: () {
            _removeOverlay();
            widget.onClose?.call();
          },
        ),
      ],
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String label,
    String? subtitle,
    String? shortcut,
    bool enabled = true,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: enabled ? onTap : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: enabled ? Colors.blue : Colors.grey,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: enabled ? Colors.black87 : Colors.grey,
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 11,
                        color: enabled ? Colors.grey.shade600 : Colors.grey.shade400,
                      ),
                    ),
                ],
              ),
            ),
            if (shortcut != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  shortcut,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey.shade700,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubMenu({
    required IconData icon,
    required String label,
    required List<Widget> children,
  }) {
    return PopupMenuButton<String>(
      offset: const Offset(280, -8),
      itemBuilder: (context) => [],
      child: _buildMenuItem(
        icon: icon,
        label: label,
        onTap: () {},
      ),
    );
  }

  Widget _buildSubMenuItem({
    required IconData icon,
    required String label,
    String? subtitle,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 8),
        child: Row(
          children: [
            Icon(icon, size: 18, color: Colors.blue.shade700),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: IconButton(
        icon: const Text(
          'File',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        tooltip: 'File menu',
        onPressed: _toggleMenu,
        color: _isOpen ? Colors.blue : Colors.black87,
      ),
    );
  }
}
