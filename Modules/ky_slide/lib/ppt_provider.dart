// powerpoint_import_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:path/path.dart' as path;
import 'package:permission_handler/permission_handler.dart';

import 'ppt.dart';
import 'ppt_service.dart';

// Provider for PowerPointReaderService
final pptReaderServiceProvider = Provider<PowerPointReaderService>((ref) {
  return PowerPointReaderService();
});

class PowerPointImportScreen extends ConsumerStatefulWidget {
  const PowerPointImportScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<PowerPointImportScreen> createState() =>
      _PowerPointImportScreenState();
}

class _PowerPointImportScreenState
    extends ConsumerState<PowerPointImportScreen> {
  bool _isLoading = false;
  String _statusMessage = '';
  File? _selectedFile;
  PowerPointPresentation? _parsedPresentation;
  double _importProgress = 0.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Import PowerPoint')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // File selection card
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Select PowerPoint File',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    _selectedFile != null
                        ? _buildSelectedFileInfo()
                        : const Text('No file selected'),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        ElevatedButton.icon(
                          onPressed: _isLoading ? null : _pickFile,
                          icon: const Icon(Icons.file_upload),
                          label: const Text('Browse Files'),
                        ),
                        if (_selectedFile != null)
                          TextButton.icon(
                            onPressed: _isLoading
                                ? null
                                : () => setState(() => _selectedFile = null),
                            icon: const Icon(Icons.close),
                            label: const Text('Clear'),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Import progress
            if (_isLoading)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LinearProgressIndicator(value: _importProgress),
                  const SizedBox(height: 8),
                  Text(_statusMessage),
                ],
              ),

            const SizedBox(height: 16),

            // Import button
            FilledButton.icon(
              onPressed: (_selectedFile != null && !_isLoading)
                  ? _importPresentation
                  : null,
              icon: const Icon(Icons.download),
              label: const Text('Import Presentation'),
            ),

            const SizedBox(height: 24),

            // Preview section
            if (_parsedPresentation != null)
              Expanded(child: _buildPresentationPreview()),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedFileInfo() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.insert_drive_file),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  path.basename(_selectedFile!.path),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${_getFileSize(_selectedFile!)} • ${path.extension(_selectedFile!.path).toUpperCase()}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPresentationPreview() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Presentation Preview',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            Text(
              _parsedPresentation!.title,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            Text(
              '${_parsedPresentation!.slides.length} slides',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: _parsedPresentation!.slides.length,
                itemBuilder: (context, index) {
                  final slide = _parsedPresentation!.slides[index];
                  return ListTile(
                    leading: CircleAvatar(child: Text('${index + 1}')),
                    title: Text(slide.title),
                    subtitle: Text(
                      slide.bulletPoints.isNotEmpty
                          ? '${slide.bulletPoints.length} bullet points'
                          : (slide.content.isNotEmpty
                                ? 'Text slide'
                                : 'Empty slide'),
                    ),
                    trailing: slide.images.isNotEmpty
                        ? const Icon(Icons.image)
                        : null,
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _convertToAppPresentation,
              child: const Text('Convert to App Presentation'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickFile() async {
    try {
      // Request storage permission on Android
      if (Platform.isAndroid) {
        final status = await Permission.storage.request();
        if (!status.isGranted) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Storage permission is required')),
            );
          }
          return;
        }
      }

      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pptx'],
      );

      if (result != null && result.files.single.path != null) {
        setState(() {
          _selectedFile = File(result.files.single.path!);
          _parsedPresentation = null;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error selecting file: $e')));
      }
    }
  }

  Future<void> _importPresentation() async {
    if (_selectedFile == null) return;

    try {
      setState(() {
        _isLoading = true;
        _statusMessage = 'Initializing...';
        _importProgress = 0.1;
      });

      final pptReaderService = ref.read(pptReaderServiceProvider);

      // Update progress steps
      setState(() {
        _statusMessage = 'Reading PowerPoint file...';
        _importProgress = 0.3;
      });

      final presentation = await pptReaderService.readFromFile(_selectedFile!);

      // Update progress
      setState(() {
        _statusMessage = 'Parsing slides...';
        _importProgress = 0.7;
      });

      // Short delay to show progress
      await Future.delayed(const Duration(milliseconds: 500));

      setState(() {
        _parsedPresentation = presentation;
        _statusMessage = 'Import complete!';
        _importProgress = 1.0;
      });

      await Future.delayed(const Duration(seconds: 1));

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _statusMessage = 'Error: $e';
      });

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Import failed: $e')));
      }
    }
  }

  void _convertToAppPresentation() {
    if (_parsedPresentation == null) return;

    try {
      // Convert PPT slides to app slides
      final slides = _parsedPresentation!.slides.map((pptSlide) {
        // Determine slide type
        SlideType slideType = SlideType.text;
        if (pptSlide.bulletPoints.isNotEmpty) {
          slideType = SlideType.bulletPoints;
        } else if (pptSlide.images.isNotEmpty) {
          slideType = SlideType.image;
        }

        // Prepare content based on slide type
        String content;
        if (slideType == SlideType.bulletPoints) {
          content = pptSlide.bulletPoints.join('\n');
        } else {
          content = pptSlide.content;
        }

        return Slide(
          id: pptSlide.id,
          title: pptSlide.title,
          content: content,
          type: slideType,
        );
      }).toList();

      // Create new presentation
      final newPresentation = Presentation(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: _parsedPresentation!.title,
        lastModified: DateTime.now(),
        slides: slides,
      );

      // Add to provider
      ref.read(presentationsProvider.notifier).addPresentation(newPresentation);

      // Navigate back and show success message
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully imported "${newPresentation.title}"'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Conversion failed: $e')));
      }
    }
  }

  String _getFileSize(File file) {
    final bytes = file.lengthSync();

    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }
}
