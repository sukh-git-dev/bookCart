import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class AppAnimationUtils {
  static const int staggerStepMs = 70;
  static Duration staggerDelay(int order) =>
      Duration(milliseconds: order * staggerStepMs);
}

extension AppEntranceAnimationX on Widget {
  Widget animatePage({Duration delay = Duration.zero}) {
    return animate(delay: delay)
        .fadeIn(duration: 420.ms, curve: Curves.easeOutCubic)
        .moveY(begin: 20, end: 0, duration: 420.ms, curve: Curves.easeOutCubic);
  }

  Widget animateCard({int order = 0}) {
    final delay = AppAnimationUtils.staggerDelay(order);
    return animate(delay: delay)
        .fadeIn(duration: 360.ms, curve: Curves.easeOutCubic)
        .moveY(begin: 16, end: 0, duration: 360.ms, curve: Curves.easeOutCubic);
  }

  Widget animateListItem({int order = 0}) {
    final delay = AppAnimationUtils.staggerDelay(order);
    return animate(delay: delay)
        .fadeIn(duration: 300.ms, curve: Curves.easeOutCubic)
        .moveY(begin: 12, end: 0, duration: 300.ms, curve: Curves.easeOutCubic);
  }
}

class AppStaggeredColumn extends StatelessWidget {
  const AppStaggeredColumn({
    super.key,
    required this.children,
    this.crossAxisAlignment = CrossAxisAlignment.center,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.mainAxisSize = MainAxisSize.max,
    this.startOrder = 0,
  });

  final List<Widget> children;
  final CrossAxisAlignment crossAxisAlignment;
  final MainAxisAlignment mainAxisAlignment;
  final MainAxisSize mainAxisSize;
  final int startOrder;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: crossAxisAlignment,
      mainAxisAlignment: mainAxisAlignment,
      mainAxisSize: mainAxisSize,
      children: [
        for (int index = 0; index < children.length; index++)
          _animatedChild(children[index], startOrder + index),
      ],
    );
  }

  Widget _animatedChild(Widget child, int order) {
    if (child is Expanded) {
      return Expanded(
        flex: child.flex,
        child: child.child.animateCard(order: order),
      );
    }

    if (child is Flexible) {
      return Flexible(
        flex: child.flex,
        fit: child.fit,
        child: child.child.animateCard(order: order),
      );
    }

    return child.animateCard(order: order);
  }
}
