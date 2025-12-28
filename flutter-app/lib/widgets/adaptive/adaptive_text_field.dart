import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';

/// An adaptive text field.
/// Uses TextField on Android/Web and CupertinoTextField on iOS/macOS.
class AdaptiveTextField extends StatelessWidget {
  const AdaptiveTextField({
    super.key,
    this.controller,
    this.labelText,
    this.hintText,
    this.placeholder,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.onChanged,
    this.onSubmitted,
    this.maxLines = 1,
    this.minLines,
    this.enabled = true,
    this.autofocus = false,
    this.focusNode,
  });

  final TextEditingController? controller;
  final String? labelText;
  final String? hintText;
  final String? placeholder;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final int? maxLines;
  final int? minLines;
  final bool enabled;
  final bool autofocus;
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    return PlatformTextField(
      controller: controller,
      hintText: hintText ?? placeholder,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      maxLines: maxLines,
      minLines: minLines,
      autofocus: autofocus,
      focusNode: focusNode,
      material: (_, __) => MaterialTextFieldData(
        decoration: InputDecoration(
          labelText: labelText,
          hintText: hintText ?? placeholder,
          prefixIcon: prefixIcon,
          suffixIcon: suffixIcon,
          enabled: enabled,
        ),
      ),
      cupertino: (_, __) => CupertinoTextFieldData(
        placeholder: placeholder ?? labelText ?? hintText,
        prefix: prefixIcon != null
            ? Padding(
                padding: const EdgeInsets.only(left: 8),
                child: prefixIcon,
              )
            : null,
        suffix: suffixIcon != null
            ? Padding(
                padding: const EdgeInsets.only(right: 8),
                child: suffixIcon,
              )
            : null,
        enabled: enabled,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: CupertinoColors.systemGrey4),
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}

/// An adaptive text form field with validation support.
/// Uses TextFormField on Android/Web and CupertinoTextFormFieldRow on iOS/macOS.
class AdaptiveTextFormField extends StatelessWidget {
  const AdaptiveTextFormField({
    super.key,
    this.controller,
    this.labelText,
    this.hintText,
    this.placeholder,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.validator,
    this.onChanged,
    this.onSaved,
    this.maxLines = 1,
    this.minLines,
    this.enabled = true,
    this.autofocus = false,
    this.focusNode,
    this.textCapitalization = TextCapitalization.none,
  });

  final TextEditingController? controller;
  final String? labelText;
  final String? hintText;
  final String? placeholder;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  final FormFieldSetter<String>? onSaved;
  final int? maxLines;
  final int? minLines;
  final bool enabled;
  final bool autofocus;
  final FocusNode? focusNode;
  final TextCapitalization textCapitalization;

  @override
  Widget build(BuildContext context) {
    return PlatformTextFormField(
      controller: controller,
      hintText: hintText ?? placeholder,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      validator: validator,
      onChanged: onChanged,
      onSaved: onSaved,
      maxLines: maxLines,
      minLines: minLines,
      autofocus: autofocus,
      focusNode: focusNode,
      textCapitalization: textCapitalization,
      material: (_, __) => MaterialTextFormFieldData(
        decoration: InputDecoration(
          labelText: labelText,
          hintText: hintText ?? placeholder,
          prefixIcon: prefixIcon,
          suffixIcon: suffixIcon,
          enabled: enabled,
        ),
      ),
      cupertino: (_, __) => CupertinoTextFormFieldData(
        placeholder: placeholder ?? labelText ?? hintText,
        prefix: prefixIcon != null
            ? Padding(
                padding: const EdgeInsets.only(left: 8),
                child: prefixIcon,
              )
            : null,
        enabled: enabled,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: CupertinoColors.systemGrey4),
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}
