// lib/models/interactive_element.dart
import 'package:flutter/material.dart';

import 'enums.dart';

class InteractiveElement {
  final String id;
  final InteractiveType type;
  final String? label;
  final List<String>? options;
  final int? duration;
  final String? link;
  final VoidCallback? onTap;

  InteractiveElement({
    required this.id,
    required this.type,
    this.label,
    this.options,
    this.duration,
    this.link,
    this.onTap,
  });

  factory InteractiveElement.fromJson(Map<String, dynamic> json) {
    return InteractiveElement(
      id: json['id'] as String? ?? 'unknown',
      type: InteractiveType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => InteractiveType.button,
      ),
      label: json['label'] as String?,
      options: (json['options'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList(),
      duration: json['duration'] as int?,
      link: json['link'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'label': label,
      'options': options,
      'duration': duration,
      'link': link,
    };
  }
}
