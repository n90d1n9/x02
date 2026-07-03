import 'dart:convert';
import 'dart:typed_data';

class DrawingData {
  final String id;
  final Uint8List imageBytes;
  final double width;
  final double height;
  const DrawingData({
    required this.id,
    required this.imageBytes,
    required this.width,
    required this.height,
  });
  Map<String, dynamic> toJson() => {
    'id': id,
    'imageBytes': base64Encode(imageBytes),
    'width': width,
    'height': height,
  };
  factory DrawingData.fromJson(Map<String, dynamic> json) => DrawingData(
    id: json['id'],
    imageBytes: base64Decode(json['imageBytes']),
    width: json['width'],
    height: json['height'],
  );
}
