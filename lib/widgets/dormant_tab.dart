import 'package:flutter/widgets.dart';
import 'package:flutter/rendering.dart';

/// Keep state without laying out, painting or hit-testing a hidden tab.
class DormantTab extends SingleChildRenderObjectWidget {
  final bool active;
  const DormantTab({super.key, required this.active, required super.child});
  @override
  RenderObject createRenderObject(BuildContext context) =>
      _DormantTabRender(active);
  @override
  void updateRenderObject(
    BuildContext context,
    covariant _DormantTabRender renderObject,
  ) {
    renderObject.active = active;
  }
}

class _DormantTabRender extends RenderProxyBox {
  _DormantTabRender(this._active);
  bool _active;
  set active(bool value) {
    if (value == _active) return;
    _active = value;
    markNeedsLayout();
    markNeedsPaint();
    markNeedsSemanticsUpdate();
  }

  @override
  void performLayout() {
    if (_active) {
      super.performLayout();
    } else {
      size = constraints.smallest;
    }
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (_active) super.paint(context, offset);
  }

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) =>
      _active && super.hitTest(result, position: position);
  @override
  void visitChildrenForSemantics(RenderObjectVisitor visitor) {
    if (_active) super.visitChildrenForSemantics(visitor);
  }
}
