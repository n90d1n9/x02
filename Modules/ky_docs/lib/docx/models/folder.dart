import 'package:flutter/material.dart';

class Folder {
  static const _fallbackIcon = Icons.folder;
  static const _knownIcons = <int, IconData>{
    0xe2c7: Icons.folder,
    0xe2c8: Icons.folder_open,
    0xe2c9: Icons.folder_shared,
    0xe2ca: Icons.folder_special,
  };

  final String id;
  final String name;
  final IconData icon;
  final Color color;
  final DateTime createdAt;
  Folder({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    required this.createdAt,
  });
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'icon': icon.codePoint,
    'color': color.toARGB32(),
    'createdAt': createdAt.toIso8601String(),
  };
  factory Folder.fromJson(Map<String, dynamic> json) => Folder(
    id: json['id'],
    name: json['name'],
    icon: _knownIcons[json['icon']] ?? _fallbackIcon,
    color: Color(json['color']),
    createdAt: DateTime.parse(json['createdAt']),
  );
}
