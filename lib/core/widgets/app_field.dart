import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';
import '../theme/app_text.dart';

/// Label-above text field. Forms use an uppercase overline label and a 48pt
/// field on `fieldBg`; login/search use [height] 54 on white with a sentence
/// case label ([uppercase] false).
class LabeledField extends StatelessWidget {
  const LabeledField({
    super.key,
    this.label,
    this.controller,
    this.hint,
    this.keyboardType,
    this.obscure = false,
    this.maxLines = 1,
    this.height = 48,
    this.enabled = true,
    this.uppercase = true,
    this.fill = AppColors.fieldBg,
    this.radius,
    this.trailingLabel,
    this.suffix,
    this.onChanged,
    this.onSubmitted,
    this.autofillHints,
    this.textInputAction,
    this.inputFormatters,
    this.focusNode,
    this.errorText,
  });

  final String? label;
  final TextEditingController? controller;
  final String? hint;
  final TextInputType? keyboardType;
  final bool obscure;
  final int maxLines;
  final double height;
  final bool enabled;
  final bool uppercase;
  final Color fill;
  final double? radius;
  final String? trailingLabel;
  final Widget? suffix;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final Iterable<String>? autofillHints;
  final TextInputAction? textInputAction;
  final List<TextInputFormatter>? inputFormatters;
  final FocusNode? focusNode;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final multiline = maxLines != 1;
    final r = radius ?? (multiline ? 18.0 : (height >= 54 ? 16.0 : 14.0));
    OutlineInputBorder border(Color c) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(r),
          borderSide: BorderSide(color: c, width: 1.5),
        );

    final labelStyle = uppercase
        ? AppText.overline(color: AppColors.textSecondary)
        : AppText.body(13, weight: FontWeight.w700, color: AppColors.textBody);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(uppercase ? label!.toUpperCase() : label!, style: labelStyle),
              if (trailingLabel != null)
                Text(
                  trailingLabel!,
                  style: AppText.body(13, weight: FontWeight.w500, color: AppColors.textSecondary),
                ),
            ],
          ),
          const SizedBox(height: 6),
        ],
        ConstrainedBox(
          constraints: BoxConstraints(minHeight: multiline ? 0 : height),
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            enabled: enabled,
            keyboardType: keyboardType,
            obscureText: obscure,
            maxLines: obscure ? 1 : maxLines,
            minLines: multiline ? maxLines : 1,
            onChanged: onChanged,
            onSubmitted: onSubmitted,
            autofillHints: autofillHints,
            textInputAction: textInputAction,
            inputFormatters: inputFormatters,
            style: AppText.body(
              multiline ? 15 : 16,
              weight: multiline ? FontWeight.w400 : FontWeight.w500,
              height: multiline ? 1.5 : null,
              color: AppColors.ink,
            ),
            cursorColor: AppColors.ink,
            decoration: InputDecoration(
              isDense: true,
              hintText: hint,
              hintStyle: AppText.body(multiline ? 15 : 15.5, color: AppColors.textSecondary),
              errorText: errorText,
              filled: true,
              fillColor: fill,
              hoverColor: Colors.transparent,
              suffixIcon: suffix,
              contentPadding: EdgeInsets.symmetric(
                horizontal: multiline ? 14 : 16,
                vertical: multiline ? 14 : (height - 22) / 2,
              ),
              border: border(AppColors.inputBorder),
              enabledBorder: border(AppColors.inputBorder),
              disabledBorder: border(AppColors.inputBorder),
              focusedBorder: border(AppColors.ink),
              errorBorder: border(AppColors.danger),
              focusedErrorBorder: border(AppColors.danger),
            ),
          ),
        ),
      ],
    );
  }
}
