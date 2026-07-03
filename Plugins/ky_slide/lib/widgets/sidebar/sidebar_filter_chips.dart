import 'package:flutter/material.dart';

class SidebarFilterChipOption<T> {
  final T value;
  final String label;
  final IconData icon;
  final String? badgeLabel;

  const SidebarFilterChipOption({
    required this.value,
    required this.label,
    required this.icon,
    this.badgeLabel,
  });
}

class SidebarFilterChips<T> extends StatelessWidget {
  final List<SidebarFilterChipOption<T>> options;
  final T selectedValue;
  final Color accentColor;
  final ValueChanged<T> onSelected;

  const SidebarFilterChips({
    super.key,
    required this.options,
    required this.selectedValue,
    required this.accentColor,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 34,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: options.length,
        separatorBuilder: (_, _) => const SizedBox(width: 6),
        itemBuilder: (context, index) {
          final option = options[index];
          final isSelected = option.value == selectedValue;

          return _SidebarFilterChip(
            option: option,
            isSelected: isSelected,
            accentColor: accentColor,
            onSelected: () => onSelected(option.value),
          );
        },
      ),
    );
  }
}

class _SidebarFilterChip<T> extends StatelessWidget {
  final SidebarFilterChipOption<T> option;
  final bool isSelected;
  final Color accentColor;
  final VoidCallback onSelected;

  const _SidebarFilterChip({
    required this.option,
    required this.isSelected,
    required this.accentColor,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final color = isSelected ? Colors.white : Colors.white54;

    return Tooltip(
      message: option.label,
      waitDuration: const Duration(milliseconds: 450),
      child: Material(
        color: isSelected
            ? accentColor.withValues(alpha: 0.18)
            : Colors.white.withValues(alpha: 0.045),
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onSelected,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            height: 34,
            padding: const EdgeInsets.symmetric(horizontal: 9),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected
                    ? accentColor.withValues(alpha: 0.56)
                    : Colors.white.withValues(alpha: 0.08),
              ),
            ),
            child: Row(
              children: [
                Icon(option.icon, size: 14, color: color),
                const SizedBox(width: 5),
                Text(
                  option.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: color,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (option.badgeLabel != null) ...[
                  const SizedBox(width: 6),
                  _SidebarFilterChipBadge(
                    label: option.badgeLabel!,
                    isSelected: isSelected,
                    accentColor: accentColor,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SidebarFilterChipBadge extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Color accentColor;

  const _SidebarFilterChipBadge({
    required this.label,
    required this.isSelected,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final color = isSelected ? Colors.white : Colors.white54;

    return Container(
      constraints: const BoxConstraints(minWidth: 18),
      height: 18,
      padding: const EdgeInsets.symmetric(horizontal: 5),
      decoration: BoxDecoration(
        color: isSelected
            ? accentColor.withValues(alpha: 0.28)
            : Colors.white.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isSelected
              ? accentColor.withValues(alpha: 0.5)
              : Colors.white.withValues(alpha: 0.08),
        ),
      ),
      child: Center(
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: color,
            fontSize: 10,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}
