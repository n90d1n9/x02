import 'package:flutter/material.dart';
import 'package:ky_print/ky_print.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ky Print Example',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const ExampleScreen(),
    );
  }
}

class ExampleScreen extends StatefulWidget {
  const ExampleScreen({super.key});

  @override
  State<ExampleScreen> createState() => _ExampleScreenState();
}

class _ExampleScreenState extends State<ExampleScreen> {
  bool _isPrinting = false;
  double _progress = 0.0;

  @override
  void initState() {
    super.initState();

    // Listen to print progress
    kyPrint.progressStream.listen((progress) {
      setState(() => _progress = progress);
    });
  }

  @override
  void dispose() {
    kyPrint.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ky Print Example'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Info card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Ky Print Demo',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'This example demonstrates the Ky Print plugin functionality.',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 16),
                    if (_isPrinting) ...[
                      LinearProgressIndicator(value: _progress),
                      const SizedBox(height: 8),
                      Text('Printing: ${(_progress * 100).round()}%'),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Print buttons
            ElevatedButton.icon(
              onPressed: _isPrinting ? null : _handleQuickPrint,
              icon: const Icon(Icons.print),
              label: const Text('Quick Print'),
            ),

            const SizedBox(height: 8),

            ElevatedButton.icon(
              onPressed: _isPrinting ? null : _handlePrintWithSettings,
              icon: const Icon(Icons.settings),
              label: const Text('Print with Settings'),
            ),

            const SizedBox(height: 8),

            ElevatedButton.icon(
              onPressed: _isPrinting ? null : _handlePreview,
              icon: const Icon(Icons.visibility),
              label: const Text('Print Preview'),
            ),

            const SizedBox(height: 8),

            ElevatedButton.icon(
              onPressed: _isPrinting ? null : _handleSaveAsPdf,
              icon: const Icon(Icons.save),
              label: const Text('Save as PDF'),
            ),

            const SizedBox(height: 8),

            OutlinedButton.icon(
              onPressed: _isPrinting ? _handleCancel : null,
              icon: const Icon(Icons.cancel),
              label: const Text('Cancel Print'),
            ),

            const Spacer(),

            // Status
            Center(
              child: Text(
                _isPrinting ? 'Printing in progress...' : 'Ready to print',
                style: TextStyle(
                  color: _isPrinting ? Colors.blue : Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleQuickPrint() async {
    setState(() => _isPrinting = true);

    try {
      final result = await kyPrint.quickPrint(
        documentTitle: 'Quick Print Example',
        pages: _buildSamplePages(),
      );

      _showResult(result);
    } finally {
      setState(() => _isPrinting = false);
    }
  }

  Future<void> _handlePrintWithSettings() async {
    setState(() => _isPrinting = true);

    try {
      final result = await kyPrint.printDocument(
        context: context,
        documentTitle: 'Document with Settings',
        pages: _buildSamplePages(),
        orientation: PrintOrientation.portrait,
        paperSize: PaperSize.a4,
      );

      _showResult(result);
    } finally {
      setState(() => _isPrinting = false);
    }
  }

  Future<void> _handlePreview() async {
    await kyPrint.preview(
      context: context,
      documentTitle: 'Preview Example',
      pages: _buildSamplePages(),
    );
  }

  Future<void> _handleSaveAsPdf() async {
    setState(() => _isPrinting = true);

    try {
      final result = await kyPrint.saveAsPdf(
        documentTitle: 'PDF Export Example',
        pages: _buildSamplePages(),
        fileName: 'example_document.pdf',
      );

      _showResult(result);
    } finally {
      setState(() => _isPrinting = false);
    }
  }

  void _handleCancel() {
    kyPrint.cancelPrint();
    setState(() => _isPrinting = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Print cancelled')),
    );
  }

  List<Widget> _buildSamplePages() {
    return [
      // Page 1
      Container(
        width: 595,
        height: 842,
        padding: const EdgeInsets.all(40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Sample Document',
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            const Text(
              'This is page 1 of the sample document.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              height: 200,
              decoration: BoxDecoration(
                color: Colors.blue.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: Text('Sample Content Area'),
              ),
            ),
          ],
        ),
      ),

      // Page 2
      Container(
        width: 595,
        height: 842,
        padding: const EdgeInsets.all(40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Page 2',
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            const Text(
              'This is page 2 with different content.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                children: List.generate(4, (index) {
                  return Card(
                    child: Center(child: Text('Item ${index + 1}')),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    ];
  }

  void _showResult(dynamic result) {
    if (result.isSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Success! Printed ${result.pagesPrinted} pages'),
          backgroundColor: Colors.green,
        ),
      );
    } else if (result.isError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${result.errorMessage}'),
          backgroundColor: Colors.red,
        ),
      );
    } else if (result.isCancelled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Print cancelled')),
      );
    }
  }
}
