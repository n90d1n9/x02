import 'package:flutter/material.dart';

import '../models/style/gradient_animation.dart';

class AnimatedGradientContainer extends StatefulWidget {
  final GradientAnimation gradient;
  final Widget child;

  const AnimatedGradientContainer({
    super.key,
    required this.gradient,
    required this.child,
  });

  @override
  State<AnimatedGradientContainer> createState() =>
      _AnimatedGradientContainerState();
}

class _AnimatedGradientContainerState extends State<AnimatedGradientContainer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: widget.gradient.duration.toInt()),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: widget.gradient.colors,
              begin:
                  Alignment.lerp(
                    widget.gradient.begin as Alignment?,
                    widget.gradient.end as Alignment?,
                    _controller.value,
                  )!,
              end:
                  Alignment.lerp(
                    widget.gradient.end as Alignment?,
                    widget.gradient.begin as Alignment?,
                    _controller.value,
                  )!,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}
