import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/drawing_board_controller.dart';
import '../models/drawing_board_painter.dart';
import '../models/drawing_data.dart';
import '../states/provider.dart';

class DocxDrawingDialog extends ConsumerStatefulWidget {
  const DocxDrawingDialog({super.key});

  @override
  ConsumerState<DocxDrawingDialog> createState() => _DocxDrawingDialogState();
}

class _DocxDrawingDialogState extends ConsumerState<DocxDrawingDialog> {
  final DrawingBoardController _controller = DrawingBoardController();

  static const _canvasPixels = 400;
  static const _canvasSize = 400.0;
  static const _palette = [
    Colors.black,
    Colors.red,
    Colors.blue,
    Colors.green,
    Colors.yellow,
    Colors.orange,
    Colors.purple,
    Colors.pink,
    Colors.brown,
    Colors.grey,
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: SizedBox(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        child: Column(
          children: [
            _DrawingToolbar(controller: _controller, palette: _palette),
            Expanded(
              child: Container(
                color: Colors.white,
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (context, _) {
                    return GestureDetector(
                      onPanStart: (details) {
                        _controller.addPoint(details.localPosition);
                      },
                      onPanUpdate: (details) {
                        _controller.addPoint(details.localPosition);
                      },
                      onPanEnd: (_) {
                        _controller.addNull();
                      },
                      child: CustomPaint(
                        painter: DrawingBoardPainter(_controller.state.points),
                        size: Size.infinite,
                      ),
                    );
                  },
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: _insertDrawing,
                    icon: const Icon(Icons.check),
                    label: const Text('Insert'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _insertDrawing() async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final painter = DrawingBoardPainter(_controller.state.points);
    painter.paint(canvas, const Size(_canvasSize, _canvasSize));

    final picture = recorder.endRecording();
    final image = await picture.toImage(_canvasPixels, _canvasPixels);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

    if (byteData == null || !mounted) {
      return;
    }

    ref
        .read(documentProvider.notifier)
        .insertDrawing(byteData.buffer.asUint8List(), _canvasSize, _canvasSize);
    Navigator.pop(context);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Drawing inserted')));
  }
}

class _DrawingToolbar extends StatelessWidget {
  final DrawingBoardController controller;
  final List<Color> palette;

  const _DrawingToolbar({required this.controller, required this.palette});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Column(
        children: [
          Row(
            children: [
              const Text(
                'Drawing Board',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.undo),
                onPressed: controller.undo,
                tooltip: 'Undo',
              ),
              IconButton(
                icon: const Icon(Icons.clear),
                onPressed: controller.clear,
                tooltip: 'Clear All',
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
                tooltip: 'Close',
              ),
            ],
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                AnimatedBuilder(
                  animation: controller,
                  builder: (context, _) {
                    return IconButton(
                      icon: Icon(
                        controller.state.isErasing
                            ? Icons.auto_fix_high
                            : Icons.auto_fix_off,
                        color: controller.state.isErasing ? Colors.red : null,
                      ),
                      onPressed: controller.toggleEraser,
                      tooltip: 'Eraser',
                    );
                  },
                ),
                const SizedBox(width: 8),
                for (final color in palette)
                  AnimatedBuilder(
                    animation: controller,
                    builder: (context, _) {
                      final selected = controller.state.currentColor == color;
                      return GestureDetector(
                        onTap: () => controller.setColor(color),
                        child: Container(
                          width: 36,
                          height: 36,
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: selected ? Colors.white : Colors.grey,
                              width: selected ? 3 : 1,
                            ),
                            boxShadow: selected
                                ? const [
                                    BoxShadow(
                                      color: Colors.black26,
                                      blurRadius: 4,
                                    ),
                                  ]
                                : null,
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          AnimatedBuilder(
            animation: controller,
            builder: (context, _) {
              return Row(
                children: [
                  const Icon(Icons.line_weight, size: 16),
                  Expanded(
                    child: Slider(
                      value: controller.state.strokeWidth,
                      min: 1,
                      max: 20,
                      divisions: 19,
                      label: controller.state.strokeWidth.toInt().toString(),
                      onChanged: controller.setStrokeWidth,
                    ),
                  ),
                  Text('${controller.state.strokeWidth.toInt()}px'),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class DocxDrawingPreview extends ConsumerWidget {
  final DrawingData drawing;

  const DocxDrawingPreview({super.key, required this.drawing});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      child: Stack(
        children: [
          SizedBox(
            width: 120,
            height: 120,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Image.memory(drawing.imageBytes, fit: BoxFit.contain),
            ),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: CircleAvatar(
              radius: 12,
              backgroundColor: Colors.red,
              child: IconButton(
                padding: EdgeInsets.zero,
                iconSize: 16,
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () {
                  ref.read(documentProvider.notifier).deleteDrawing(drawing.id);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
