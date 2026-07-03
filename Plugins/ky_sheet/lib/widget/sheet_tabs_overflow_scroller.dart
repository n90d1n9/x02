import 'package:flutter/material.dart';

import '../theme/ky_sheet_theme.dart';

/// Horizontal overflow container for workbook sheet tabs.
class SheetTabsOverflowScroller extends StatefulWidget {
  const SheetTabsOverflowScroller({
    super.key,
    required this.child,
    this.controller,
  });

  /// Tab row rendered inside the horizontal viewport.
  final Widget child;

  /// Optional parent-owned controller used for scroll-to-active behavior.
  final ScrollController? controller;

  @override
  State<SheetTabsOverflowScroller> createState() =>
      _SheetTabsOverflowScrollerState();
}

/// Tracks tab overflow metrics and renders edge scroll affordances.
class _SheetTabsOverflowScrollerState extends State<SheetTabsOverflowScroller> {
  static const _fadeWidth = 24.0;
  static const _controlSize = 26.0;

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
  void didUpdateWidget(covariant SheetTabsOverflowScroller oldWidget) {
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
    _scheduleMetricsUpdate();

    return Stack(
      children: [
        NotificationListener<ScrollMetricsNotification>(
          onNotification: (_) {
            _scheduleMetricsUpdate();
            return false;
          },
          child: SingleChildScrollView(
            key: const ValueKey('ky-sheet-tabs-overflow-scroll'),
            controller: _controller,
            scrollDirection: Axis.horizontal,
            child: widget.child,
          ),
        ),
        if (_showStartFade)
          const _SheetTabsOverflowFade(
            key: ValueKey('ky-sheet-tabs-overflow-start-fade'),
            alignment: Alignment.centerLeft,
            width: _fadeWidth,
          ),
        if (_showEndFade)
          const _SheetTabsOverflowFade(
            key: ValueKey('ky-sheet-tabs-overflow-end-fade'),
            alignment: Alignment.centerRight,
            width: _fadeWidth,
          ),
        if (_showStartFade)
          _SheetTabsOverflowButton(
            key: const ValueKey('ky-sheet-tabs-overflow-scroll-previous'),
            controlKey: const ValueKey(
              'ky-sheet-tabs-overflow-scroll-previous-control',
            ),
            alignment: Alignment.centerLeft,
            icon: Icons.chevron_left,
            tooltip: 'Scroll sheets left',
            onPressed: () => _scrollBy(-1),
          ),
        if (_showEndFade)
          _SheetTabsOverflowButton(
            key: const ValueKey('ky-sheet-tabs-overflow-scroll-next'),
            controlKey: const ValueKey(
              'ky-sheet-tabs-overflow-scroll-next-control',
            ),
            alignment: Alignment.centerRight,
            icon: Icons.chevron_right,
            tooltip: 'Scroll sheets right',
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

/// Edge fade that signals hidden sheet tabs beyond the viewport.
class _SheetTabsOverflowFade extends StatelessWidget {
  const _SheetTabsOverflowFade({
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

/// Icon-only edge control for nudging hidden sheet tabs into view.
class _SheetTabsOverflowButton extends StatelessWidget {
  const _SheetTabsOverflowButton({
    super.key,
    required this.controlKey,
    required this.alignment,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final Key controlKey;
  final Alignment alignment;
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  bool get _isStart => alignment == Alignment.centerLeft;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Align(
        alignment: alignment,
        child: Padding(
          padding: EdgeInsets.only(
            left: _isStart ? 1 : 0,
            right: _isStart ? 0 : 1,
          ),
          child: Tooltip(
            message: tooltip,
            child: Material(
              color: KySheetColors.surface,
              borderRadius: BorderRadius.circular(8),
              elevation: 1,
              child: InkWell(
                key: controlKey,
                onTap: onPressed,
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: _SheetTabsOverflowScrollerState._controlSize,
                  height: _SheetTabsOverflowScrollerState._controlSize,
                  child: Icon(icon, size: 18, color: KySheetColors.mutedText),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
