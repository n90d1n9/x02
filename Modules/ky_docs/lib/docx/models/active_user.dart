import 'package:flutter/material.dart';

class ActiveUser {
  final String id;
  final String name;
  final Color color;
  final DateTime lastSeen;

  ActiveUser({
    required this.id,
    required this.name,
    required this.color,
    required this.lastSeen,
  });
}
