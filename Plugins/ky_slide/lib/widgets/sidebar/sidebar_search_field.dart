import 'package:flutter/material.dart';

class SidebarSearchField extends StatefulWidget {
  final String value;
  final String hintText;
  final Color accentColor;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  const SidebarSearchField({
    super.key,
    required this.value,
    required this.hintText,
    required this.accentColor,
    required this.onChanged,
    required this.onClear,
  });

  @override
  State<SidebarSearchField> createState() => _SidebarSearchFieldState();
}

class _SidebarSearchFieldState extends State<SidebarSearchField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
  }

  @override
  void didUpdateWidget(SidebarSearchField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != _controller.text) {
      _controller.value = TextEditingValue(
        text: widget.value,
        selection: TextSelection.collapsed(offset: widget.value.length),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasValue = widget.value.trim().isNotEmpty;

    return Container(
      height: 38,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.045),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: TextField(
        controller: _controller,
        onChanged: widget.onChanged,
        cursorColor: widget.accentColor,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
        decoration: InputDecoration(
          isDense: true,
          border: InputBorder.none,
          hintText: widget.hintText,
          hintStyle: const TextStyle(
            color: Colors.white38,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
          prefixIcon: const Icon(Icons.search, color: Colors.white38, size: 16),
          prefixIconConstraints: const BoxConstraints(
            minWidth: 34,
            minHeight: 38,
          ),
          suffixIcon: hasValue
              ? IconButton(
                  tooltip: 'Clear search',
                  icon: const Icon(
                    Icons.close,
                    color: Colors.white54,
                    size: 16,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 34,
                    minHeight: 38,
                  ),
                  onPressed: widget.onClear,
                )
              : null,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 0,
            vertical: 11,
          ),
        ),
      ),
    );
  }
}
