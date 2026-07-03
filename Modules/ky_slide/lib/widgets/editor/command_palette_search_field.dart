import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

/// Search input used to filter command palette results.
class CommandPaletteSearchField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final String value;
  final Color accentColor;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  const CommandPaletteSearchField({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.value,
    required this.accentColor,
    required this.onChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final hasValue = value.trim().isNotEmpty;

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
      child: Container(
        height: 42,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.055),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: TextField(
          focusNode: focusNode,
          controller: controller,
          onChanged: onChanged,
          cursorColor: accentColor,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
          decoration: InputDecoration(
            isDense: true,
            border: InputBorder.none,
            hintText: 'Search commands',
            hintStyle: const TextStyle(
              color: Colors.white38,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
            prefixIcon: const Icon(
              Icons.search,
              color: Colors.white38,
              size: 18,
            ),
            prefixIconConstraints: const BoxConstraints(
              minWidth: 40,
              minHeight: 42,
            ),
            suffixIcon: hasValue
                ? IconButton(
                    tooltip: 'Clear command search',
                    icon: const Icon(
                      Icons.close,
                      color: Colors.white54,
                      size: 16,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 38,
                      minHeight: 42,
                    ),
                    onPressed: onClear,
                  )
                : null,
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      ),
    );
  }
}

@Preview(name: 'Command palette search field', size: Size(520, 100))
Widget commandPaletteSearchFieldPreview() {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    home: Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Center(
        child: SizedBox(
          width: 460,
          child: CommandPaletteSearchField(
            controller: TextEditingController(text: 'slide'),
            focusNode: FocusNode(),
            value: 'slide',
            accentColor: const Color(0xFF38BDF8),
            onChanged: (_) {},
            onClear: () {},
          ),
        ),
      ),
    ),
  );
}
