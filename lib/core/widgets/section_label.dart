import 'package:flutter/material.dart';

import '../theme/app_text.dart';

/// Uppercase overline label above form/list sections.
class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key, this.trailing});

  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(text.toUpperCase(), style: AppText.overline()),
        ?trailing,
      ],
    );
  }
}
