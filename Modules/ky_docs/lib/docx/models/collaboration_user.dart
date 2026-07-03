import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/rendering.dart';

class CollaborationUser {
  final String id;
  final String name;
  final Color color;
  final int cursorPosition;
  final DateTime lastActive;
  CollaborationUser({
    required this.id,
    required this.name,
    required this.color,
    required this.cursorPosition,
    required this.lastActive,
  });
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'color': color.toARGB32(),
    'cursorPosition': cursorPosition,
    'lastActive': lastActive.toIso8601String(),
  };
  factory CollaborationUser.fromJson(Map<String, dynamic> json) =>
      CollaborationUser(
        id: json['id'],
        name: json['name'],
        color: Color(json['color']),
        cursorPosition: json['cursorPosition'],
        lastActive: DateTime.parse(json['lastActive']),
      );
}
