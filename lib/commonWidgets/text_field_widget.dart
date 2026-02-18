import 'package:flutter/material.dart';
import 'package:music_app/themes/font.dart';

import '../themes/styles.dart';

class TextFieldWidget extends StatefulWidget {
  final TextEditingController controller;
  final TextStyle? style;
  final Color? cursorColor;
  final TextInputAction? textInputAction;
  final bool? isObscureText;
  final Function(String)? onTextChanged;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String>? onFieldSubmitted;
  final EdgeInsets? contentPadding;
  final String? hintText;
  final TextStyle? hintStyle;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final Color? fillColor;
  final Color? textStyleColor;
  final FocusNode? focusNode;
  final bool? wantListeners;
  final Function(bool)? onFocusChange;
  final bool? hasFocus;
  final Iterable<String>? autofillHints;
  final bool readOnly;
  final int? maxLines;
  final int? maxLength;
  final TextInputType? keyboardType;
  final VoidCallback? onSuffixIconPressed;

  const TextFieldWidget({
    super.key,
    required this.controller,
    this.style,
    this.cursorColor,
    this.textInputAction,
    this.isObscureText,
    this.onTextChanged,
    this.validator,
    this.onFieldSubmitted,
    this.contentPadding,
    this.hintText,
    this.hintStyle,
    this.prefixIcon,
    this.suffixIcon,
    this.fillColor,
    this.textStyleColor,
    this.focusNode,
    this.wantListeners = false,
    this.onFocusChange,
    this.hasFocus = false,
    this.autofillHints,
    this.readOnly = false,
    this.maxLines,
    this.maxLength,
    this.keyboardType,
    this.onSuffixIconPressed,
  });

  @override
  State<TextFieldWidget> createState() => _TextFieldWidgetState();
}

class _TextFieldWidgetState extends State<TextFieldWidget> {
  @override
  void initState() {
    super.initState();

    if (widget.wantListeners == true) {
      widget.focusNode?.addListener(() {
        widget.onFocusChange?.call(widget.focusNode!.hasFocus);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      // height: widget.maxLines != null && widget.maxLines! > 1 ? 120 : 48,
      child: TextFormField(
        readOnly: widget.readOnly,
        controller: widget.controller,
        maxLines: widget.maxLines ?? 1,
        maxLength: widget.maxLength,
        keyboardType: widget.keyboardType,
        style:
            widget.style ??
            Styles.customTextStyle(
              fontSize: 14,
              fontFamily: AppFonts.medium,
              color: widget.textStyleColor,
            ),
        focusNode: widget.focusNode,
        cursorColor:
            widget.cursorColor ?? Theme.of(context).colorScheme.onSurface,
        cursorWidth: 1.0,
        textInputAction: widget.textInputAction ?? TextInputAction.next,
        obscureText: widget.isObscureText ?? false,
        onChanged: widget.onTextChanged,
        validator: widget.validator,
        onFieldSubmitted: widget.onFieldSubmitted,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        autofillHints: widget.autofillHints,
        decoration: InputDecoration(
          fillColor: widget.fillColor,
          filled: widget.fillColor != null ? true : false,
          contentPadding: widget.contentPadding ?? const EdgeInsets.all(10),
          hintText: widget.hintText,
          hintStyle:
              widget.hintStyle ??
              Styles.customTextStyle(
                fontSize: 14.0,
                fontFamily: AppFonts.regularFonts,
              ),
          prefixIcon: Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: widget.prefixIcon,
          ),
          prefixIconConstraints: const BoxConstraints(
            minHeight: 0,
            minWidth: 0,
          ),
          suffixIcon: widget.suffixIcon != null
              ? Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onTap: widget.onSuffixIconPressed, // Your callback
                    child: widget.suffixIcon,
                  ),
                )
              : null,
          suffixIconConstraints: const BoxConstraints(
            minHeight: 0,
            minWidth: 0,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: BorderSide(color: Colors.transparent),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: BorderSide(color: Colors.transparent),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: BorderSide(color: Colors.transparent),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: BorderSide(color: Colors.transparent),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: BorderSide(color: Colors.transparent),
          ),
          disabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: BorderSide(color: Colors.grey.shade400),
          ),
          errorMaxLines: 3,
          counterText: widget.maxLength != null ? '' : null,
        ),
      ),
    );
  }
}
