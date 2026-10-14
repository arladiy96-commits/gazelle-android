import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// The navigator and its scenes never consume keyboard insets. Only the editor
/// reads the real view metrics, so opening the IME cannot move a scene or dialog.
class KeyboardScene extends StatelessWidget {
  final Widget child;
  const KeyboardScene({super.key, required this.child});
  @override
  Widget build(BuildContext context) {
    final data = MediaQuery.of(context);
    return MediaQuery(
      data: data.copyWith(
        viewInsets: EdgeInsets.zero,
        padding: data.viewPadding,
      ),
      child: child,
    );
  }
}

/// Every app text entry goes through this editor, including Form validation.
/// The original controller remains authoritative; dismissing the keyboard never
/// submits a business operation or loses the text already typed.
class KeyboardInput extends StatefulWidget {
  final TextEditingController? controller;
  final String? initialValue;
  final bool? enabled;
  final bool autofocus, obscureText, autocorrect, enableSuggestions;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final TextCapitalization textCapitalization;
  final List<TextInputFormatter>? inputFormatters;
  final int? minLines, maxLines, maxLength;
  final TextStyle? style;
  final Color? cursorColor;
  final InputDecoration? decoration;
  final ValueChanged<String>? onChanged, onSubmitted;
  final FormFieldValidator<String>? validator;
  const KeyboardInput({
    super.key,
    this.controller,
    this.initialValue,
    this.enabled,
    this.autofocus = false,
    this.obscureText = false,
    this.autocorrect = true,
    this.enableSuggestions = true,
    this.keyboardType,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.none,
    this.inputFormatters,
    this.minLines,
    this.maxLines = 1,
    this.maxLength,
    this.style,
    this.cursorColor,
    this.decoration = const InputDecoration(),
    this.onChanged,
    this.onSubmitted,
    this.validator,
  }) : assert(controller == null || initialValue == null);
  @override
  State<KeyboardInput> createState() => _KeyboardInputState();
}

class _KeyboardInputState extends State<KeyboardInput> {
  TextEditingController? _owned;
  final _displayFocus = FocusNode(canRequestFocus: false);
  bool _opening = false;
  TextEditingController get _controller => widget.controller ?? _owned!;
  @override
  void initState() {
    super.initState();
    if (widget.controller == null)
      _owned = TextEditingController(text: widget.initialValue);
    if (widget.autofocus)
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && ModalRoute.of(context)?.isCurrent != false) _open();
      });
  }

  @override
  void didUpdateWidget(covariant KeyboardInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller == null && _owned == null) {
      _owned = TextEditingController(
        text: oldWidget.controller?.text ?? widget.initialValue,
      );
    }
  }

  Future<void> _open() async {
    if (_opening || widget.enabled == false) return;
    _opening = true;
    try {
      final submitted = await showGeneralDialog<bool>(
        context: context,
        barrierDismissible: false,
        barrierLabel: 'Ввод',
        barrierColor: const Color(0xB3000000),
        transitionDuration: Duration.zero,
        pageBuilder: (_, __, ___) =>
            _KeyboardEditor(input: widget, controller: _controller),
      );
      if (mounted && submitted == true)
        widget.onSubmitted?.call(_controller.text);
    } finally {
      _opening = false;
    }
  }

  @override
  void dispose() {
    _displayFocus.dispose();
    _owned?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => TextFormField(
    controller: _controller,
    focusNode: _displayFocus,
    readOnly: true,
    enableInteractiveSelection: false,
    enabled: widget.enabled,
    obscureText: widget.obscureText,
    minLines: widget.minLines,
    maxLines: widget.maxLines,
    maxLength: widget.maxLength,
    style: widget.style,
    decoration: widget.decoration,
    validator: widget.validator,
    onTap: _open,
  );
}

class _KeyboardEditor extends StatefulWidget {
  final KeyboardInput input;
  final TextEditingController controller;
  const _KeyboardEditor({required this.input, required this.controller});
  @override
  State<_KeyboardEditor> createState() => _KeyboardEditorState();
}

class _KeyboardEditorState extends State<_KeyboardEditor>
    with WidgetsBindingObserver {
  final _focus = FocusNode();
  late bool _hidden = widget.input.obscureText;
  String? _error;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeMetrics() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _focus.dispose();
    super.dispose();
  }

  void _done() {
    final error = widget.input.validator?.call(widget.controller.text);
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    _focus.unfocus();
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final input = widget.input;
    final metrics = MediaQueryData.fromView(View.of(context));
    final top = metrics.viewPadding.top + 12;
    final bottom =
        math.max(metrics.viewInsets.bottom, metrics.viewPadding.bottom) + 8;
    final available = math.max(0.0, metrics.size.height - top - bottom);
    final decoration = input.decoration ?? const InputDecoration();
    final multiline = input.maxLines == null || input.maxLines! > 1;
    return Padding(
      padding: EdgeInsets.fromLTRB(10, top, 10, bottom),
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 560, maxHeight: available),
          child: Material(
            color: const Color(0xFF111A20),
            borderRadius: BorderRadius.circular(18),
            clipBehavior: Clip.antiAlias,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          decoration.labelText ?? decoration.hintText ?? 'Ввод',
                          style: const TextStyle(
                            fontSize: 18,
                            color: Color(0xFFE6E9E9),
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Закрыть',
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          _focus.unfocus();
                          Navigator.of(context).pop(false);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: widget.controller,
                    focusNode: _focus,
                    autofocus: true,
                    obscureText: _hidden,
                    autocorrect: input.autocorrect,
                    enableSuggestions: input.enableSuggestions,
                    keyboardType: input.keyboardType,
                    textInputAction: multiline
                        ? TextInputAction.newline
                        : TextInputAction.done,
                    textCapitalization: input.textCapitalization,
                    inputFormatters: input.inputFormatters,
                    minLines: input.minLines,
                    maxLines: input.maxLines,
                    maxLength: input.maxLength,
                    style: input.style,
                    cursorColor: input.cursorColor,
                    decoration: InputDecoration(
                      hintText: decoration.hintText,
                      errorText: _error,
                      border: const OutlineInputBorder(),
                      suffixIcon: input.obscureText
                          ? IconButton(
                              tooltip: _hidden
                                  ? 'Показать пароль'
                                  : 'Скрыть пароль',
                              onPressed: () =>
                                  setState(() => _hidden = !_hidden),
                              icon: Icon(
                                _hidden
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                              ),
                            )
                          : null,
                    ),
                    onChanged: (value) {
                      if (_error != null) setState(() => _error = null);
                      input.onChanged?.call(value);
                    },
                    onSubmitted: (_) {
                      if (!multiline) _done();
                    },
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: _done,
                      child: const Text('Готово'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
