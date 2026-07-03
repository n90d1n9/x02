import 'package:flutter/material.dart';

import '../models/animation.dart';

class AnimatedComponentWrapper extends StatefulWidget {
  final AnimationType animation;
  final Widget child;
  final double delay;
  final double duration;

  const AnimatedComponentWrapper({
    super.key,
    required this.animation,
    required this.child,
    this.delay = 0,
    this.duration = 0.6,
  });

  @override
  State<AnimatedComponentWrapper> createState() =>
      _AnimatedComponentWrapperState();
}

class _AnimatedComponentWrapperState extends State<AnimatedComponentWrapper>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(milliseconds: (widget.duration * 1000).toInt()),
      vsync: this,
    );

    _setupAnimation();

    if (widget.delay > 0) {
      Future.delayed(Duration(milliseconds: (widget.delay * 1000).toInt()), () {
        if (mounted) _controller.forward();
      });
    } else {
      _controller.forward();
    }
  }

  void _setupAnimation() {
    switch (widget.animation) {
      case AnimationType.fadeIn:
        _animation = Tween<double>(begin: 0.0, end: 1.0).animate(_controller);
        break;
      case AnimationType.zoom:
        _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
        );
        break;
      case AnimationType.bounce:
        _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(parent: _controller, curve: Curves.bounceOut),
        );
        break;
      case AnimationType.elastic:
        _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
        );
        break;
      case AnimationType.slideIn:
      case AnimationType.slideUp:
        _animation = Tween<double>(
          begin: 0.0,
          end: 1.0,
        ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
        break;
      default:
        _animation = Tween<double>(begin: 1.0, end: 1.0).animate(_controller);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.animation == AnimationType.none) {
      return widget.child;
    }

    if (widget.animation == AnimationType.fadeIn) {
      return FadeTransition(opacity: _animation, child: widget.child);
    }

    if (widget.animation == AnimationType.slideIn) {
      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, -1),
          end: Offset.zero,
        ).animate(_animation),
        child: widget.child,
      );
    }

    if (widget.animation == AnimationType.slideRight) {
      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(-1, 0),
          end: Offset.zero,
        ).animate(_animation),
        child: widget.child,
      );
    }

    if (widget.animation == AnimationType.slideLeft) {
      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(1, 0),
          end: Offset.zero,
        ).animate(_animation),
        child: widget.child,
      );
    }

    if (widget.animation == AnimationType.slideUp) {
      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 1),
          end: Offset.zero,
        ).animate(_animation),
        child: widget.child,
      );
    }

    if (widget.animation == AnimationType.rotate) {
      return RotationTransition(turns: _animation, child: widget.child);
    }

    return ScaleTransition(scale: _animation, child: widget.child);
  }
}
