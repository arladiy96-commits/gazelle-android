import 'package:flutter/widgets.dart';

/// Keep tab state using Flutter's standard layout and route lifecycle.
class DormantTab extends StatelessWidget {
  final bool active;
  final Widget child;
  const DormantTab({super.key, required this.active, required this.child});
  @override
  Widget build(BuildContext context) => Offstage(
    offstage: !active,
    child: ExcludeFocus(excluding: !active, child: child),
  );
}
