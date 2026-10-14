part of 'app_shell.dart';

/// Keeps a form's top edge stationary while the keyboard consumes space below.
/// The child supplies its own scroll view. Insets are removed for descendants
/// so editors cannot add the keyboard height a second time.
Future<T?> _showKeyboardForm<T>({
  required BuildContext context,
  required WidgetBuilder builder,
}) => showGeneralDialog<T>(
  context: context,
  barrierDismissible: false,
  barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
  barrierColor: const Color(0x99000000),
  transitionDuration: AppMotion.duration,
  pageBuilder: (routeContext, animation, secondaryAnimation) =>
      _KeyboardFormViewport(child: Builder(builder: builder)),
  transitionBuilder: AppMotion.transition,
);

class _KeyboardFormViewport extends StatelessWidget {
  final Widget child;
  const _KeyboardFormViewport({required this.child});

  @override
  Widget build(BuildContext context) {
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;
    return SafeArea(
      bottom: false,
      child: Padding(
        // Follow OS insets directly. AnimatedPadding here would trail every
        // keyboard frame and repeatedly restart an additional animation.
        padding: EdgeInsets.fromLTRB(
          6,
          12,
          6,
          math.max(keyboard, MediaQuery.viewPaddingOf(context).bottom) + 8,
        ),
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: MediaQuery.removeViewInsets(
              context: context,
              removeBottom: true,
              child: Material(
                type: MaterialType.transparency,
                child: RepaintBoundary(child: child),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// AlertDialog does not expose Dialog.insetAnimationDuration. Consume the
/// keyboard padding outside it; its internal animated inset stays at zero.
class _KeyboardAlertDialog extends AlertDialog {
  const _KeyboardAlertDialog({
    super.title,
    super.titlePadding,
    super.titleTextStyle,
    super.content,
    super.contentPadding,
    super.contentTextStyle,
    super.actions,
    super.actionsPadding,
    super.actionsAlignment,
    super.backgroundColor,
    super.surfaceTintColor,
    super.shape,
    super.insetPadding,
    super.alignment = Alignment.topCenter,
    super.scrollable = true,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
    child: MediaQuery.removeViewInsets(
      context: context,
      removeBottom: true,
      child: Builder(builder: (context) => super.build(context)),
    ),
  );
}

/// Compact editors stay at the top; no bottom-sheet translation follows the IME.
Future<T?> _showStableInput<T>({
  required BuildContext context,
  required WidgetBuilder builder,
}) => _showKeyboardForm<T>(
  context: context,
  builder: (context) => Material(
    color: const Color(0xFF111A20),
    borderRadius: BorderRadius.circular(22),
    clipBehavior: Clip.antiAlias,
    child: SingleChildScrollView(child: builder(context)),
  ),
);
