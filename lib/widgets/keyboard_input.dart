import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Scene geometry stays fixed; focused scroll regions consume real IME insets.
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

/// Direct input in the original form, without another route or duplicate field.
class KeyboardInput extends StatefulWidget {
  final TextEditingController? controller;
  final String? initialValue;
  final bool? enabled;
  final bool autofocus, obscureText, autocorrect, enableSuggestions;
  final bool selectAllOnTap, enableInteractiveSelection;
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
    this.selectAllOnTap = false,
    this.enableInteractiveSelection = true,
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

class _KeyboardInputState extends State<KeyboardInput>
    with WidgetsBindingObserver {
  final _focus = FocusNode();
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeMetrics() {
    if (!_focus.hasFocus) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _focus.hasFocus) {
        Scrollable.ensureVisible(
          context,
          alignment: 1,
          alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
          duration: Duration.zero,
        );
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => TextFormField(
    controller: widget.controller,
    initialValue: widget.initialValue,
    focusNode: _focus,
    autofocus: widget.autofocus,
    enabled: widget.enabled,
    obscureText: widget.obscureText,
    autocorrect: widget.autocorrect,
    enableSuggestions: widget.enableSuggestions,
    keyboardType: widget.keyboardType,
    textInputAction: widget.textInputAction,
    textCapitalization: widget.textCapitalization,
    inputFormatters: widget.inputFormatters,
    minLines: widget.minLines,
    maxLines: widget.maxLines,
    maxLength: widget.maxLength,
    style: widget.style,
    cursorColor: widget.cursorColor,
    decoration: widget.decoration,
    validator: widget.validator,
    enableInteractiveSelection: widget.enableInteractiveSelection,
    onTap: widget.selectAllOnTap
        ? () {
            final controller = widget.controller;
            if (controller != null) {
              controller.selection = TextSelection(
                baseOffset: 0,
                extentOffset: controller.text.length,
              );
            }
          }
        : null,
    onChanged: widget.onChanged,
    onFieldSubmitted: widget.onSubmitted,
  );
}

/// Only the scrollable containing the focused field gets a shorter viewport.
/// Its origin is fixed; other scenes, the header and navigation keep their size.
class KeyboardScrollArea extends StatefulWidget {
  final Widget child;
  const KeyboardScrollArea({super.key, required this.child});
  @override
  State<KeyboardScrollArea> createState() => _KeyboardScrollAreaState();
}

class _KeyboardScrollAreaState extends State<KeyboardScrollArea>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    FocusManager.instance.addListener(_changed);
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  @override
  void didChangeMetrics() => _changed();
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    FocusManager.instance.removeListener(_changed);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool containsFocus = false;
    FocusManager.instance.primaryFocus?.context?.visitAncestorElements((
      element,
    ) {
      if (element == context) {
        containsFocus = true;
        return false;
      }
      return true;
    });
    final metrics = MediaQueryData.fromView(View.of(context));
    // Only keyboard avoidance needs a screen coordinate. Do not derive a
    // persistent clip from last frame's render position: it can cut off headers
    // after a route/focus change, even with the keyboard closed.
    final keyboardOpen = containsFocus && metrics.viewInsets.bottom > 0;
    final box = keyboardOpen ? context.findRenderObject() : null;
    final top = box is RenderBox && box.hasSize
        ? box.localToGlobal(Offset.zero).dy
        : metrics.viewPadding.top;
    final height = keyboardOpen
        ? math.max(0.0, metrics.size.height - metrics.viewInsets.bottom - top)
        : double.infinity;
    return ClipRect(
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: height),
          child: widget.child,
        ),
      ),
    );
  }
}

/// A value edited and saved where it is displayed, without a dialog.
class InlineValueInput extends StatefulWidget {
  final String value, label;
  final double fontSize;
  final bool enabled, multiline;
  final Future<void> Function(String) save;
  final Widget Function(VoidCallback? edit)? displayBuilder;
  const InlineValueInput({
    super.key,
    required this.value,
    required this.label,
    required this.save,
    this.displayBuilder,
    this.enabled = true,
    this.multiline = false,
    this.fontSize = 18,
  });
  @override
  State<InlineValueInput> createState() => _InlineValueInputState();
}

class _InlineValueInputState extends State<InlineValueInput> {
  late final _text = TextEditingController(text: widget.value);
  bool _saving = false, _dirty = false, _editing = false;
  String? _error;
  @override
  void didUpdateWidget(covariant InlineValueInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_dirty && oldWidget.value != widget.value) _text.text = widget.value;
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving || !widget.enabled) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.save(_text.text);
      if (mounted)
        setState(() {
          _dirty = false;
          _editing = false;
        });
    } catch (e) {
      if (mounted)
        setState(
          () => _error = e is ArgumentError
              ? '${e.message}'
              : 'Не удалось сохранить',
        );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_editing && widget.displayBuilder != null) {
      return widget.displayBuilder!(
        widget.enabled
            ? () => setState(() {
                _text.text = widget.value;
                _text.selection = TextSelection(
                  baseOffset: 0,
                  extentOffset: _text.text.length,
                );
                _editing = true;
              })
            : null,
      );
    }
    return KeyboardInput(
      autofocus: widget.displayBuilder != null,
      controller: _text,
      style: TextStyle(
        fontSize: widget.fontSize,
        color: widget.displayBuilder == null ? null : const Color(0xFFE0B87B),
        fontWeight: widget.displayBuilder == null ? null : FontWeight.w600,
      ),
      enabled: widget.enabled && !_saving,
      maxLines: widget.multiline ? 3 : 1,
      keyboardType: widget.multiline
          ? TextInputType.multiline
          : const TextInputType.numberWithOptions(decimal: true),
      textInputAction: TextInputAction.done,
      onChanged: (_) => _dirty = true,
      onSubmitted: (_) => _save(),
      decoration: InputDecoration(
        labelText: widget.displayBuilder == null ? widget.label : null,
        hintText: widget.displayBuilder == null ? null : widget.label,
        isDense: widget.displayBuilder != null,
        contentPadding: widget.displayBuilder == null
            ? null
            : const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        suffixIconConstraints: widget.displayBuilder == null
            ? null
            : const BoxConstraints(minWidth: 32, minHeight: 32),
        errorText: _error,
        suffixIcon: IconButton(
          tooltip: 'Сохранить',
          onPressed: _saving ? null : _save,
          icon: _saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.check),
        ),
      ),
    );
  }
}

/// One editable control with the original mechanical counter face.
class DrumInput extends StatefulWidget {
  final TextEditingController controller;
  final bool enabled;
  final int places, maxDigits;
  final ValueChanged<String>? onChanged;
  const DrumInput({
    super.key,
    required this.controller,
    this.enabled = true,
    this.places = 6,
    this.maxDigits = 9,
    this.onChanged,
  });
  @override
  State<DrumInput> createState() => _DrumInputState();
}

class _DrumInputState extends State<DrumInput> {
  bool _focused = false;
  TextEditingController get controller => widget.controller;
  bool get enabled => widget.enabled;
  int get places => widget.places;
  int get maxDigits => widget.maxDigits;
  ValueChanged<String>? get onChanged => widget.onChanged;
  @override
  Widget build(BuildContext context) => Focus(
    onFocusChange: (focused) => setState(() => _focused = focused),
    child: Stack(
      fit: StackFit.expand,
      children: [
        KeyboardInput(
          controller: controller,
          selectAllOnTap: true,
          enableInteractiveSelection: false,
          enabled: enabled,
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.done,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(maxDigits),
          ],
          style: const TextStyle(color: Colors.transparent, fontSize: 74),
          cursorColor: Colors.transparent,
          decoration: const InputDecoration(
            filled: false,
            isCollapsed: true,
            contentPadding: EdgeInsets.zero,
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            disabledBorder: InputBorder.none,
          ),
          onChanged: onChanged,
        ),
        IgnorePointer(
          child: ExcludeSemantics(
            child: ValueListenableBuilder<TextEditingValue>(
              valueListenable: controller,
              builder: (_, value, __) {
                final allSelected =
                    _focused &&
                    value.text.isNotEmpty &&
                    value.selection.start == 0 &&
                    value.selection.end == value.text.length;
                final digits = _focused
                    ? value.text.padRight(
                        math.max(
                          places,
                          math.min(
                            maxDigits,
                            value.text.length + (allSelected ? 0 : 1),
                          ),
                        ),
                        '·',
                      )
                    : value.text.isEmpty
                    ? List.filled(places, '-').join()
                    : value.text.padLeft(places, '0');
                return Row(
                  children: [
                    for (var i = 0; i < digits.length; i++)
                      Expanded(
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(13),
                            border: Border.all(
                              color:
                                  allSelected ||
                                      (_focused && i == value.text.length)
                                  ? const Color(0xFFE0B87B)
                                  : const Color(0xFF37414A),
                              width:
                                  allSelected ||
                                      (_focused && i == value.text.length)
                                  ? 3
                                  : 1.5,
                            ),
                            gradient: const LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Color(0xFF03080B),
                                Color(0xFF38424A),
                                Color(0xFF101316),
                                Color(0xFF24211B),
                                Color(0xFF020507),
                              ],
                              stops: [0, .2, .49, .72, 1],
                            ),
                          ),
                          child: Center(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                digits[i],
                                style: const TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 75,
                                  color: Color(0xFFE0B87B),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ),
      ],
    ),
  );
}
