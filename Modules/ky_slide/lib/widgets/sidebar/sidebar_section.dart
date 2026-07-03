import 'package:flutter/material.dart';

class SidebarSection extends StatefulWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final List<Color> gradientColors;
  final Widget child;
  final bool collapsible;
  final bool initiallyExpanded;
  final bool? isExpanded;
  final ValueChanged<bool>? onExpandedChanged;

  const SidebarSection({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.gradientColors,
    required this.child,
    this.collapsible = false,
    this.initiallyExpanded = true,
    this.isExpanded,
    this.onExpandedChanged,
  });

  @override
  State<SidebarSection> createState() => _SidebarSectionState();
}

class _SidebarSectionState extends State<SidebarSection> {
  late bool _isExpanded;

  @override
  void initState() {
    super.initState();
    _isExpanded = !widget.collapsible || widget.initiallyExpanded;
  }

  @override
  void didUpdateWidget(SidebarSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.collapsible && !_isExpanded) {
      _isExpanded = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final showBody = _isExpandedNow;

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SidebarSectionHeader(
            title: widget.title,
            icon: widget.icon,
            gradientColors: widget.gradientColors,
            collapsible: widget.collapsible,
            isExpanded: showBody,
            onToggle: _toggleExpanded,
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeOutCubic,
            transitionBuilder: (child, animation) {
              return SizeTransition(
                sizeFactor: animation,
                alignment: AlignmentDirectional.topStart,
                child: FadeTransition(opacity: animation, child: child),
              );
            },
            child: showBody
                ? _SidebarSectionBody(
                    key: const ValueKey('sidebar-section-body'),
                    subtitle: widget.subtitle,
                    child: widget.child,
                  )
                : const SizedBox.shrink(
                    key: ValueKey('sidebar-section-collapsed'),
                  ),
          ),
        ],
      ),
    );
  }

  bool get _isExpandedNow {
    if (!widget.collapsible) {
      return true;
    }

    return widget.isExpanded ?? _isExpanded;
  }

  void _toggleExpanded() {
    if (!widget.collapsible) {
      return;
    }

    final nextValue = !_isExpandedNow;
    if (widget.isExpanded == null) {
      setState(() => _isExpanded = nextValue);
    }

    widget.onExpandedChanged?.call(nextValue);
  }
}

class _SidebarSectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Color> gradientColors;
  final bool collapsible;
  final bool isExpanded;
  final VoidCallback onToggle;

  const _SidebarSectionHeader({
    required this.title,
    required this.icon,
    required this.gradientColors,
    required this.collapsible,
    required this.isExpanded,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final header = Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: gradientColors),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Colors.white, size: 18),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        if (collapsible) ...[
          const SizedBox(width: 8),
          Tooltip(
            message: isExpanded ? 'Collapse $title' : 'Expand $title',
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: Icon(
                isExpanded
                    ? Icons.keyboard_arrow_up
                    : Icons.keyboard_arrow_down,
                color: Colors.white70,
                size: 18,
              ),
            ),
          ),
        ],
      ],
    );

    if (!collapsible) {
      return header;
    }

    return Semantics(
      button: true,
      expanded: isExpanded,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onToggle,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: header,
          ),
        ),
      ),
    );
  }
}

class _SidebarSectionBody extends StatelessWidget {
  final String subtitle;
  final Widget child;

  const _SidebarSectionBody({
    super.key,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: const TextStyle(
            color: Colors.white60,
            fontSize: 11,
            height: 1.25,
          ),
        ),
        const SizedBox(height: 12),
        child,
      ],
    );
  }
}
