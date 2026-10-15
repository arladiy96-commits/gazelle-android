import 'package:flutter/material.dart';

/// The same quiet dissolve for app routes and tab changes.
abstract final class AppMotion {
  static const duration = Duration(milliseconds: 200);
  static const curve = Curves.easeOutCubic;

  static Widget transition(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondary,
    Widget child,
  ) {
    if (MediaQuery.disableAnimationsOf(context)) return child;
    return FadeTransition(
      opacity: animation.drive(CurveTween(curve: curve)),
      child: RepaintBoundary(child: child),
    );
  }
}

class AppPageTransitions extends PageTransitionsBuilder {
  const AppPageTransitions();
  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) => AppMotion.transition(context, animation, secondaryAnimation, child);
}

/// Keep visited pages alive. Interrupted transitions continue from their current
/// opacity; only the selected page receives touches, focus and accessibility.
class AppTabStage extends StatefulWidget {
  final int index;
  final List<Widget> children;
  const AppTabStage({super.key, required this.index, required this.children});
  @override
  State<AppTabStage> createState() => _AppTabStageState();
}

class _AppTabStageState extends State<AppTabStage> {
  late final Set<int> _visible = {widget.index};
  @override
  void didUpdateWidget(covariant AppTabStage oldWidget) {
    super.didUpdateWidget(oldWidget);
    _visible.add(widget.index);
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return Stack(
      fit: StackFit.expand,
      children: [
        for (var i = 0; i < widget.children.length; i++)
          Offstage(
            offstage: reduceMotion ? i != widget.index : !_visible.contains(i),
            child: IgnorePointer(
              ignoring: i != widget.index,
              child: ExcludeSemantics(
                excluding: i != widget.index,
                child: ExcludeFocus(
                  excluding: i != widget.index,
                  child: AnimatedOpacity(
                    opacity: i == widget.index ? 1 : 0,
                    duration: reduceMotion ? Duration.zero : AppMotion.duration,
                    curve: AppMotion.curve,
                    onEnd: () {
                      if (mounted &&
                          i != widget.index &&
                          _visible.contains(i)) {
                        setState(() => _visible.remove(i));
                      }
                    },
                    child: TickerMode(
                      enabled: i == widget.index,
                      child: RepaintBoundary(child: widget.children[i]),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
