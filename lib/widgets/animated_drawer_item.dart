// lib/widgets/animated_drawer_item.dart

import 'package:flutter/material.dart';
import 'dart:async';

class AnimatedDrawerItem extends StatefulWidget {
  final Widget child;
  final Duration delay;

  const AnimatedDrawerItem({
    super.key,
    required this.child,
    required this.delay,
  });

  @override
  _AnimatedDrawerItemState createState() => _AnimatedDrawerItemState();
}

class _AnimatedDrawerItemState extends State<AnimatedDrawerItem> {
  bool _isAnimated = false;

  @override
  void initState() {
    super.initState();
    Timer(widget.delay, () {
      if (mounted) {
        setState(() {
          _isAnimated = true;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: _isAnimated ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOut,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOut,
        transform: Matrix4.translationValues(0, _isAnimated ? 0 : 15, 0),
        child: widget.child,
      ),
    );
  }
}