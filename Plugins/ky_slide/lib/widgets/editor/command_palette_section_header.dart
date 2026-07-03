import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

/// Compact heading that separates command palette result groups.
class CommandPaletteSectionHeader extends StatelessWidget {
  final String title;

  const CommandPaletteSectionHeader({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 10, 4, 4),
      child: Text(
        title.toUpperCase(),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: Colors.white38,
          fontSize: 10,
          fontWeight: FontWeight.w900,
          letterSpacing: 0,
        ),
      ),
    );
  }
}

@Preview(name: 'Command palette section header', size: Size(240, 80))
Widget commandPaletteSectionHeaderPreview() {
  return const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: Scaffold(
      backgroundColor: Color(0xFF0F172A),
      body: Center(child: CommandPaletteSectionHeader(title: 'Recent')),
    ),
  );
}
