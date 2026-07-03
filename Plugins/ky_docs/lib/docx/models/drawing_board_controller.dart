import 'package:flutter/material.dart';

import 'drawing_point.dart';
import 'drawing_board_state.dart';

class DrawingBoardController extends ChangeNotifier {
  DrawingBoardState _state = DrawingBoardState();
  DrawingBoardState get state => _state;
  void addPoint(Offset point) {
    final paint =
        Paint()
          ..color = _state.isErasing ? Colors.white : _state.currentColor
          ..strokeWidth = _state.isErasing ? 20 : _state.strokeWidth
          ..strokeCap = StrokeCap.round
          ..style = PaintingStyle.stroke;
    _state = _state.copyWith(
      points: [..._state.points, DrawingPoint(point, paint)],
    );
    notifyListeners();
  }

  void addNull() {
    _state = _state.copyWith(points: [..._state.points, null]);
    notifyListeners();
  }

  void setColor(Color color) {
    _state = _state.copyWith(currentColor: color, isErasing: false);
    notifyListeners();
  }

  void setStrokeWidth(double width) {
    _state = _state.copyWith(strokeWidth: width);
    notifyListeners();
  }

  void toggleEraser() {
    _state = _state.copyWith(isErasing: !_state.isErasing);
    notifyListeners();
  }

  void clear() {
    _state = DrawingBoardState(
      currentColor: _state.currentColor,
      strokeWidth: _state.strokeWidth,
    );
    notifyListeners();
  }

  void undo() {
    if (_state.points.isEmpty) return;
    final points = List<DrawingPoint?>.from(_state.points);
    do {
      points.removeLast();
    } while (points.isNotEmpty && points.last != null);
    _state = _state.copyWith(points: points);
    notifyListeners();
  }
}
