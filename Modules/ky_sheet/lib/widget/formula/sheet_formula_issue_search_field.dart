import 'package:flutter/material.dart';

class SheetFormulaIssueSearchField extends StatefulWidget {
  const SheetFormulaIssueSearchField({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final String value;
  final ValueChanged<String> onChanged;

  @override
  State<SheetFormulaIssueSearchField> createState() =>
      _SheetFormulaIssueSearchFieldState();
}

class _SheetFormulaIssueSearchFieldState
    extends State<SheetFormulaIssueSearchField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
  }

  @override
  void didUpdateWidget(SheetFormulaIssueSearchField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value == _controller.text) return;
    _controller.text = widget.value;
    _controller.selection = TextSelection.collapsed(
      offset: _controller.text.length,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      key: const ValueKey('ky-sheet-formula-health-search'),
      controller: _controller,
      decoration: InputDecoration(
        isDense: true,
        labelText: 'Search issues',
        prefixIcon: const Icon(Icons.search, size: 18),
        suffixIcon: widget.value.trim().isEmpty
            ? null
            : IconButton(
                key: const ValueKey('ky-sheet-formula-health-search-clear'),
                tooltip: 'Clear Formula Health Search',
                icon: const Icon(Icons.close, size: 18),
                onPressed: () => widget.onChanged(''),
              ),
        border: const OutlineInputBorder(),
      ),
      onChanged: widget.onChanged,
    );
  }
}
