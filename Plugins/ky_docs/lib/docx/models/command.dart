import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class Command {
  final String title;
  final String description;
  final IconData icon;
  final Function(WidgetRef) action;
  final String? shortcut;

  Command(this.title, this.description, this.icon, this.action, this.shortcut);
}
