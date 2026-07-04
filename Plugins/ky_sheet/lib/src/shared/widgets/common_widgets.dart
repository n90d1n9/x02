import 'package:flutter/material.dart';

/// Reusable dropdown button widget for toolbar and menus.
class ToolbarDropdown<T> extends StatelessWidget {
  final T value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;
  final double width;
  final String? hint;

  const ToolbarDropdown({
    Key? key,
    required this.value,
    required this.items,
    required this.onChanged,
    this.width = 120,
    this.hint,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(4),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          hint: hint != null ? Text(hint!) : null,
          items: items,
          onChanged: onChanged,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          icon: const Icon(Icons.arrow_drop_down, size: 20),
        ),
      ),
    );
  }
}

/// Reusable toggle button for toolbar actions (Bold, Italic, etc.).
class ToolbarToggleButton extends StatelessWidget {
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;
  final String? tooltip;

  const ToolbarToggleButton({
    Key? key,
    required this.icon,
    required this.isActive,
    required this.onTap,
    this.tooltip,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final widget = InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: isActive ? Colors.blue.shade50 : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Icon(
          icon,
          size: 18,
          color: isActive ? Colors.blue : Colors.black87,
        ),
      ),
    );

    return tooltip != null 
        ? Tooltip(message: tooltip!, child: widget)
        : widget;
  }
}

/// Reusable menu item with keyboard shortcut display.
class MenuShortcutItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? shortcut;
  final VoidCallback onTap;
  final bool isEnabled;

  const MenuShortcutItem({
    Key? key,
    required this.icon,
    required this.label,
    this.shortcut,
    required this.onTap,
    this.isEnabled = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, size: 20, color: isEnabled ? null : Colors.grey),
      title: Text(
        label,
        style: TextStyle(
          color: isEnabled ? null : Colors.grey,
          fontSize: 13,
        ),
      ),
      trailing: shortcut != null
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(3),
              ),
              child: Text(
                shortcut!,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade700,
                ),
              ),
            )
          : null,
      onTap: isEnabled ? onTap : null,
      enabled: isEnabled,
      dense: true,
    );
  }
}

/// Separator line for menus.
class MenuSeparator extends StatelessWidget {
  const MenuSeparator({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Divider(height: 1, thickness: 1, color: Colors.grey.shade300);
  }
}
