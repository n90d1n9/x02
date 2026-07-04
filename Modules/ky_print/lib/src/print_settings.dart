import 'package:flutter/material.dart';

/// Print settings configuration dialog
class PrintSettingsDialog extends StatefulWidget {
  /// Current print job configuration
  final String documentTitle;
  final int totalPages;
  final PrintOrientation initialOrientation;
  final PaperSize initialPaperSize;
  final int initialCopies;
  final double initialScale;
  final bool initialGrayscale;
  final bool initialDuplex;

  const PrintSettingsDialog({
    Key? key,
    required this.documentTitle,
    required this.totalPages,
    this.initialOrientation = PrintOrientation.portrait,
    this.initialPaperSize = PaperSize.a4,
    this.initialCopies = 1,
    this.initialScale = 1.0,
    this.initialGrayscale = false,
    this.initialDuplex = false,
  }) : super(key: key);

  @override
  State<PrintSettingsDialog> createState() => _PrintSettingsDialogState();
}

class _PrintSettingsDialogState extends State<PrintSettingsDialog> {
  late PrintOrientation _orientation;
  late PaperSize _paperSize;
  late int _copies;
  late double _scale;
  late bool _grayscale;
  late bool _duplex;
  Range? _pageRange;

  @override
  void initState() {
    super.initState();
    _orientation = widget.initialOrientation;
    _paperSize = widget.initialPaperSize;
    _copies = widget.initialCopies;
    _scale = widget.initialScale;
    _grayscale = widget.initialGrayscale;
    _duplex = widget.initialDuplex;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Print Settings'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Document Info
            _buildInfoSection(),
            const Divider(),

            // Orientation
            _buildOrientationSection(),
            const Divider(),

            // Paper Size
            _buildPaperSizeSection(),
            const Divider(),

            // Copies
            _buildCopiesSection(),
            const Divider(),

            // Page Range
            _buildPageRangeSection(),
            const Divider(),

            // Scale
            _buildScaleSection(),
            const Divider(),

            // Advanced Options
            _buildAdvancedSection(),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: const Text('Cancel'),
        ),
        ElevatedButton.icon(
          onPressed: () => _confirmSettings(),
          icon: const Icon(Icons.print),
          label: const Text('Print'),
        ),
      ],
    );
  }

  Widget _buildInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.documentTitle,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 4),
        Text(
          '${widget.totalPages} page${widget.totalPages != 1 ? 's' : ''}',
          style: TextStyle(color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildOrientationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Orientation',
            style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: RadioListTile<PrintOrientation>(
                title: const Text('Portrait'),
                leading: const Icon(Icons.portrait),
                value: PrintOrientation.portrait,
                groupValue: _orientation,
                onChanged: (value) => setState(() => _orientation = value!),
                contentPadding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
              ),
            ),
            Expanded(
              child: RadioListTile<PrintOrientation>(
                title: const Text('Landscape'),
                leading: const Icon(Icons.landscape),
                value: PrintOrientation.landscape,
                groupValue: _orientation,
                onChanged: (value) => setState(() => _orientation = value!),
                contentPadding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPaperSizeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Paper Size', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        DropdownButtonFormField<PaperSize>(
          value: _paperSize,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          items: const [
            DropdownMenuItem(
                value: PaperSize.a4, child: Text('A4 (210 x 297 mm)')),
            DropdownMenuItem(
                value: PaperSize.a3, child: Text('A3 (297 x 420 mm)')),
            DropdownMenuItem(
                value: PaperSize.letter, child: Text('Letter (8.5 x 11 in)')),
            DropdownMenuItem(
                value: PaperSize.legal, child: Text('Legal (8.5 x 14 in)')),
            DropdownMenuItem(
                value: PaperSize.b5, child: Text('B5 (176 x 250 mm)')),
          ],
          onChanged: (value) => setState(() => _paperSize = value!),
        ),
      ],
    );
  }

  Widget _buildCopiesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Copies', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Row(
          children: [
            IconButton(
              onPressed: _copies > 1 ? () => setState(() => _copies--) : null,
              icon: const Icon(Icons.remove_circle_outline),
            ),
            Expanded(
              child: TextField(
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                controller: TextEditingController(text: _copies.toString()),
                onChanged: (value) {
                  final copies = int.tryParse(value);
                  if (copies != null && copies > 0) {
                    setState(() => _copies = copies);
                  }
                },
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(vertical: 8),
                ),
              ),
            ),
            IconButton(
              onPressed: () => setState(() => _copies++),
              icon: const Icon(Icons.add_circle_outline),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPageRangeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Pages', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: RadioListTile<int>(
                title: const Text('All Pages'),
                value: 0,
                groupValue: _pageRange == null ? 0 : 1,
                onChanged: (value) => setState(() => _pageRange = null),
                contentPadding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
              ),
            ),
            Expanded(
              child: RadioListTile<int>(
                title: const Text('Custom Range'),
                value: 1,
                groupValue: _pageRange == null ? 0 : 1,
                onChanged: (value) {
                  setState(() {
                    _pageRange = Range(1, widget.totalPages);
                  });
                },
                contentPadding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
              ),
            ),
          ],
        ),
        if (_pageRange != null) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'From',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(vertical: 8),
                  ),
                  controller:
                      TextEditingController(text: _pageRange!.start.toString()),
                  onChanged: (value) {
                    final start = int.tryParse(value);
                    if (start != null &&
                        start >= 1 &&
                        start <= widget.totalPages) {
                      setState(() {
                        _pageRange = Range(start, _pageRange!.end);
                      });
                    }
                  },
                ),
              ),
              const SizedBox(width: 16),
              const Text('to'),
              const SizedBox(width: 16),
              Expanded(
                child: TextField(
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'To',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(vertical: 8),
                  ),
                  controller:
                      TextEditingController(text: _pageRange!.end.toString()),
                  onChanged: (value) {
                    final end = int.tryParse(value);
                    if (end != null && end >= 1 && end <= widget.totalPages) {
                      setState(() {
                        _pageRange = Range(_pageRange!.start, end);
                      });
                    }
                  },
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildScaleSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Scale', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Slider(
                value: _scale,
                min: 0.5,
                max: 1.0,
                divisions: 10,
                label: '${(_scale * 100).round()}%',
                onChanged: (value) => setState(() => _scale = value),
              ),
            ),
            SizedBox(
              width: 60,
              child: Text('${(_scale * 100).round()}%'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAdvancedSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Advanced', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        CheckboxListTile(
          title: const Text('Grayscale'),
          subtitle: const Text('Print in black and white'),
          value: _grayscale,
          onChanged: (value) => setState(() => _grayscale = value!),
          contentPadding: EdgeInsets.zero,
          visualDensity: VisualDensity.compact,
        ),
        CheckboxListTile(
          title: const Text('Duplex Printing'),
          subtitle: const Text('Print on both sides'),
          value: _duplex,
          onChanged: (value) => setState(() => _duplex = value!),
          contentPadding: EdgeInsets.zero,
          visualDensity: VisualDensity.compact,
        ),
      ],
    );
  }

  void _confirmSettings() {
    Navigator.of(context).pop({
      'orientation': _orientation,
      'paperSize': _paperSize,
      'copies': _copies,
      'scale': _scale,
      'grayscale': _grayscale,
      'duplex': _duplex,
      'pageRange': _pageRange,
    });
  }
}
