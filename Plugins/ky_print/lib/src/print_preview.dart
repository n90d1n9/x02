import 'package:flutter/material.dart';

/// Print preview widget for displaying document pages before printing
class PrintPreviewWidget extends StatefulWidget {
  /// List of page widgets to preview
  final List<Widget> pages;

  /// Document title
  final String documentTitle;

  /// Initial page to display
  final int initialPage;

  const PrintPreviewWidget({
    Key? key,
    required this.pages,
    required this.documentTitle,
    this.initialPage = 0,
  }) : super(key: key);

  @override
  State<PrintPreviewWidget> createState() => _PrintPreviewWidgetState();
}

class _PrintPreviewWidgetState extends State<PrintPreviewWidget> {
  late PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: widget.initialPage);
    _currentPage = widget.initialPage;
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.documentTitle,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Page ${_currentPage + 1} of ${widget.pages.length}',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              // Navigation controls
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: _currentPage > 0
                        ? () {
                            _pageController.previousPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          }
                        : null,
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: _currentPage < widget.pages.length - 1
                        ? () {
                            _pageController.nextPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          }
                        : null,
                  ),
                ],
              ),
            ],
          ),
        ),

        // Page preview
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            itemCount: widget.pages.length,
            onPageChanged: (index) => setState(() => _currentPage = index),
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: Card(
                  elevation: 4,
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Center(
                      child: widget.pages[index],
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        // Footer with zoom controls
        Container(
          padding: const EdgeInsets.all(8.0),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            border: Border(top: BorderSide(color: Colors.grey[300]!)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.zoom_out),
                onPressed: () {
                  // Implement zoom out
                },
              ),
              const Text('100%'),
              IconButton(
                icon: const Icon(Icons.zoom_in),
                onPressed: () {
                  // Implement zoom in
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}
