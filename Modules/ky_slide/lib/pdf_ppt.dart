import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const MyPPT());
}

class MyPPT extends StatelessWidget {
  const MyPPT({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PowerPoint Viewer',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const PPTViewerHome(),
    );
  }
}

class PPTViewerHome extends StatefulWidget {
  const PPTViewerHome({Key? key}) : super(key: key);

  @override
  State<PPTViewerHome> createState() => _PPTViewerHomeState();
}

class _PPTViewerHomeState extends State<PPTViewerHome> {
  String? _filePath;
  bool _isLoading = false;
  final List<String> _recentFiles = [];

  @override
  void initState() {
    super.initState();
    _checkPermissions();
    _loadRecentFiles();
  }

  Future<void> _checkPermissions() async {
    if (Platform.isAndroid) {
      if (await Permission.storage.request().isGranted) {
        // Permission granted
      } else {
        // Permission denied
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Storage permission is required')),
        );
      }
    }
  }

  Future<void> _loadRecentFiles() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final recentFiles = prefs.getStringList('recent_files') ?? [];
      setState(() {
        _recentFiles.clear();
        _recentFiles.addAll(recentFiles);
      });
    } catch (e) {
      debugPrint('Error loading recent files: $e');
    }
  }

  Future<void> _saveRecentFiles() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('recent_files', _recentFiles);
    } catch (e) {
      debugPrint('Error saving recent files: $e');
    }
  }

  Future<void> _pickFile() async {
    setState(() {
      _isLoading = true;
    });

    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['ppt', 'pptx', 'pdf'],
      );

      if (result != null) {
        String path = result.files.single.path!;

        // Currently, we can only directly view PDF files
        // For PPT/PPTX, we'd need to convert them to PDF first
        if (path.endsWith('.pdf')) {
          _openFile(path);
        } else if (path.endsWith('.ppt') || path.endsWith('.pptx')) {
          // Show message that conversion is needed
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'PowerPoint files need to be converted to PDF first. '
                'Please convert the file and try again.',
              ),
              duration: Duration(seconds: 5),
            ),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _openFile(String path) {
    setState(() {
      _filePath = path;
    });

    // Add to recent files
    _addToRecentFiles(path);

    // Navigate to viewer
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => PDFViewerScreen(filePath: path)),
    );
  }

  void _addToRecentFiles(String path) {
    // Remove if already exists
    _recentFiles.remove(path);

    // Add to beginning of list
    _recentFiles.insert(0, path);

    // Keep only last 10 files
    if (_recentFiles.length > 10) {
      _recentFiles.removeLast();
    }

    // Save to SharedPreferences
    _saveRecentFiles();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('PowerPoint & PDF Viewer')),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'PowerPoint & PDF Viewer',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Open and view PDF files directly. PowerPoint files need to be converted to PDF.',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _pickFile,
                          icon: const Icon(Icons.file_open),
                          label: const Text('Open File'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Recent files
                  Expanded(
                    child:
                        _recentFiles.isEmpty
                            ? const Center(child: Text('No recent files'))
                            : ListView.builder(
                              itemCount: _recentFiles.length,
                              itemBuilder: (context, index) {
                                final path = _recentFiles[index];
                                return ListTile(
                                  leading: Icon(
                                    path.endsWith('.pdf')
                                        ? Icons.picture_as_pdf
                                        : Icons.slideshow,
                                    color:
                                        path.endsWith('.pdf')
                                            ? Colors.red
                                            : Colors.orange,
                                  ),
                                  title: Text(path.split('/').last),
                                  subtitle: Text(
                                    path,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  onTap: () => _openFile(path),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.delete),
                                    onPressed: () {
                                      setState(() {
                                        _recentFiles.removeAt(index);
                                        _saveRecentFiles();
                                      });
                                    },
                                  ),
                                );
                              },
                            ),
                  ),
                ],
              ),
    );
  }
}

class PDFViewerScreen extends StatefulWidget {
  final String filePath;

  const PDFViewerScreen({Key? key, required this.filePath}) : super(key: key);

  @override
  State<PDFViewerScreen> createState() => _PDFViewerScreenState();
}

class _PDFViewerScreenState extends State<PDFViewerScreen> {
  int _currentPage = 0;
  int _totalPages = 0;
  bool _isLoading = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.filePath.split('/').last),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              showDialog(
                context: context,
                builder:
                    (context) => AlertDialog(
                      title: const Text('File Information'),
                      content: Text(
                        'Path: ${widget.filePath}\n'
                        'Pages: $_totalPages\n'
                        'Current Page: ${_currentPage + 1}',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Close'),
                        ),
                      ],
                    ),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          PDFView(
            filePath: widget.filePath,
            enableSwipe: true,
            swipeHorizontal: true,
            autoSpacing: true,
            pageFling: true,
            pageSnap: true,
            onRender: (_pages) {
              setState(() {
                _totalPages = _pages!;
                _isLoading = false;
              });
            },
            onError: (error) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text('Error: $error')));
              setState(() {
                _isLoading = false;
              });
            },
            onPageChanged: (page, total) {
              setState(() {
                _currentPage = page!;
              });
            },
          ),
          if (_isLoading) const Center(child: CircularProgressIndicator()),
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Page ${_currentPage + 1} of $_totalPages',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
