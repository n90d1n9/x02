import 'package:flutter/material.dart';

class SidebarActionCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final String? semanticsLabel;
  final Color? accentColor;
  final bool selected;
  final EdgeInsetsGeometry margin;
  final EdgeInsetsGeometry padding;
  final Color backgroundColor;
  final Color borderColor;
  final double borderRadius;
  final Duration animationDuration;

  const SidebarActionCard({
    super.key,
    required this.child,
    this.onPressed,
    this.semanticsLabel,
    this.accentColor,
    this.selected = false,
    this.margin = const EdgeInsets.only(bottom: 8),
    this.padding = const EdgeInsets.all(10),
    this.backgroundColor = const Color(0x0CFFFFFF),
    this.borderColor = const Color(0x14FFFFFF),
    this.borderRadius = 8,
    this.animationDuration = const Duration(milliseconds: 140),
  });

  @override
  State<SidebarActionCard> createState() => _SidebarActionCardState();
}

class _SidebarActionCardState extends State<SidebarActionCard> {
  bool _isHovered = false;
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(widget.borderRadius);
    final accentColor = widget.accentColor ?? Colors.white;
    final isInteractive = widget.onPressed != null;
    final isHighlighted = widget.selected || _isHovered || _isFocused;
    final backgroundColor = _backgroundColor(accentColor);
    final borderColor = _borderColor(accentColor);

    return Padding(
      padding: widget.margin,
      child: Semantics(
        button: isInteractive,
        label: widget.semanticsLabel,
        selected: widget.selected,
        child: FocusableActionDetector(
          enabled: isInteractive,
          mouseCursor: isInteractive
              ? SystemMouseCursors.click
              : SystemMouseCursors.basic,
          onShowHoverHighlight: (value) {
            setState(() => _isHovered = value);
          },
          onShowFocusHighlight: (value) {
            setState(() => _isFocused = value);
          },
          child: Material(
            color: Colors.transparent,
            borderRadius: radius,
            child: InkWell(
              onTap: widget.onPressed,
              borderRadius: radius,
              splashColor: accentColor.withValues(alpha: 0.12),
              highlightColor: accentColor.withValues(alpha: 0.08),
              child: AnimatedContainer(
                duration: widget.animationDuration,
                curve: Curves.easeOutCubic,
                padding: widget.padding,
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: radius,
                  border: Border.all(color: borderColor),
                  boxShadow: isHighlighted
                      ? [
                          BoxShadow(
                            color: accentColor.withValues(alpha: 0.08),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : const [],
                ),
                child: widget.child,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color _backgroundColor(Color accentColor) {
    if (widget.selected) {
      return accentColor.withValues(alpha: 0.12);
    }
    if (_isHovered) {
      return accentColor.withValues(alpha: 0.08);
    }
    if (_isFocused) {
      return accentColor.withValues(alpha: 0.06);
    }
    return widget.backgroundColor;
  }

  Color _borderColor(Color accentColor) {
    if (widget.selected) {
      return accentColor.withValues(alpha: 0.48);
    }
    if (_isFocused) {
      return accentColor.withValues(alpha: 0.56);
    }
    if (_isHovered) {
      return accentColor.withValues(alpha: 0.34);
    }
    return widget.borderColor;
  }
}
