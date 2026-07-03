import 'package:flutter/material.dart';

import '../theme/ky_sheet_theme.dart';
import 'sheet_ribbon_density.dart';

/// Provides horizontal ribbon overflow with subtle edge fades.
class SheetRibbonOverflowScroller extends StatefulWidget {
  const SheetRibbonOverflowScroller({
    super.key,
    required this.child,
    this.controller,
    this.fadeWidth,
  });

  /// The horizontally scrollable ribbon content.
  final Widget child;

  /// Optional controller for parent-owned scrolling and visibility behavior.
  final ScrollController? controller;

  /// Optional width of the leading and trailing overflow fades.
  ///
  /// When omitted, the value is resolved from [SheetRibbonDensityScope].
  final double? fadeWidth;

  @override
  State<SheetRibbonOverflowScroller> createState() =>
      _SheetRibbonOverflowScrollerState();
}

/// Tracks scroll metrics for the reusable ribbon overflow container.
class _SheetRibbonOverflowScrollerState
    extends State<SheetRibbonOverflowScroller> {
  late final ScrollController _ownedController;
  bool _showStartFade = false;
  bool _showEndFade = false;
  bool _updateScheduled = false;

  ScrollController get _controller => widget.controller ?? _ownedController;

  @override
  void initState() {
    super.initState();
    _ownedController = ScrollController();
    _controller.addListener(_updateMetrics);
  }

  @override
  void didUpdateWidget(covariant SheetRibbonOverflowScroller oldWidget) {
    super.didUpdateWidget(oldWidget);

    final previousController = oldWidget.controller ?? _ownedController;
    final nextController = _controller;
    if (identical(previousController, nextController)) return;

    previousController.removeListener(_updateMetrics);
    nextController.addListener(_updateMetrics);
    _scheduleMetricsUpdate();
  }

  @override
  void dispose() {
    _controller.removeListener(_updateMetrics);
    _ownedController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final density = SheetRibbonDensityScope.of(context);
    final fadeWidth = widget.fadeWidth ?? density.overflowFadeWidth;

    _scheduleMetricsUpdate();

    return Stack(
      children: [
        NotificationListener<ScrollMetricsNotification>(
          onNotification: (_) {
            _scheduleMetricsUpdate();
            return false;
          },
          child: SingleChildScrollView(
            key: const ValueKey('ky-sheet-ribbon-overflow-scroll'),
            controller: _controller,
            scrollDirection: Axis.horizontal,
            child: widget.child,
          ),
        ),
        if (_showStartFade)
          _RibbonOverflowFade(
            key: const ValueKey('ky-sheet-ribbon-overflow-start-fade'),
            alignment: Alignment.centerLeft,
            width: fadeWidth,
          ),
        if (_showEndFade)
          _RibbonOverflowFade(
            key: const ValueKey('ky-sheet-ribbon-overflow-end-fade'),
            alignment: Alignment.centerRight,
            width: fadeWidth,
          ),
        if (_showStartFade)
          _RibbonOverflowScrollButton(
            key: const ValueKey('ky-sheet-ribbon-overflow-scroll-previous'),
            alignment: Alignment.centerLeft,
            controlKey: const ValueKey(
              'ky-sheet-ribbon-overflow-scroll-previous-control',
            ),
            icon: Icons.chevron_left,
            iconSize: density.overflowButtonIconSize,
            inset: density.overflowButtonInset,
            size: density.overflowButtonSize,
            tooltip: 'Scroll ribbon left',
            onPressed: () => _scrollBy(-1),
          ),
        if (_showEndFade)
          _RibbonOverflowScrollButton(
            key: const ValueKey('ky-sheet-ribbon-overflow-scroll-next'),
            alignment: Alignment.centerRight,
            controlKey: const ValueKey(
              'ky-sheet-ribbon-overflow-scroll-next-control',
            ),
            icon: Icons.chevron_right,
            iconSize: density.overflowButtonIconSize,
            inset: density.overflowButtonInset,
            size: density.overflowButtonSize,
            tooltip: 'Scroll ribbon right',
            onPressed: () => _scrollBy(1),
          ),
      ],
    );
  }

  void _scheduleMetricsUpdate() {
    if (_updateScheduled) return;
    _updateScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateScheduled = false;
      if (!mounted) return;
      _updateMetrics();
    });
  }

  void _updateMetrics() {
    if (!_controller.hasClients) return;

    final position = _controller.position;
    final maxScroll = position.maxScrollExtent;
    final offset = position.pixels;
    final nextStart = maxScroll > 0 && offset > 0.5;
    final nextEnd = maxScroll > 0 && offset < maxScroll - 0.5;

    if (_showStartFade == nextStart && _showEndFade == nextEnd) return;

    setState(() {
      _showStartFade = nextStart;
      _showEndFade = nextEnd;
    });
  }

  void _scrollBy(double direction) {
    if (!_controller.hasClients) return;

    final position = _controller.position;
    final step = position.viewportDimension * 0.72;
    final target = (position.pixels + direction * step)
        .clamp(position.minScrollExtent, position.maxScrollExtent)
        .toDouble();

    if ((target - position.pixels).abs() < 0.5) return;

    _controller.animateTo(
      target,
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
    );
  }
}

/// Paints one side of the ribbon overflow fade.
class _RibbonOverflowFade extends StatelessWidget {
  const _RibbonOverflowFade({
    super.key,
    required this.alignment,
    required this.width,
  });

  final Alignment alignment;
  final double width;

  bool get _isStart => alignment == Alignment.centerLeft;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: Align(
          alignment: alignment,
          child: Container(
            width: width,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: _isStart ? Alignment.centerLeft : Alignment.centerRight,
                end: _isStart ? Alignment.centerRight : Alignment.centerLeft,
                colors: const [KySheetColors.surface, Color(0x00FFFFFF)],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Icon-only edge control for nudging overflowed ribbon content.
class _RibbonOverflowScrollButton extends StatelessWidget {
  const _RibbonOverflowScrollButton({
    super.key,
    required this.alignment,
    required this.controlKey,
    required this.icon,
    required this.iconSize,
    required this.inset,
    required this.tooltip,
    required this.onPressed,
    required this.size,
  });

  final Alignment alignment;
  final Key controlKey;
  final IconData icon;
  final double iconSize;
  final double inset;
  final String tooltip;
  final VoidCallback onPressed;
  final double size;

  bool get _isStart => alignment == Alignment.centerLeft;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      bottom: 0,
      left: _isStart ? inset : null,
      right: _isStart ? null : inset,
      child: Center(
        child: Tooltip(
          message: tooltip,
          child: Material(
            color: KySheetColors.surface,
            elevation: 1,
            shadowColor: KySheetColors.gridLineStrong.withValues(alpha: 0.55),
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onPressed,
              child: SizedBox.square(
                key: controlKey,
                dimension: size,
                child: Icon(
                  icon,
                  size: iconSize,
                  color: KySheetColors.mutedText,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
