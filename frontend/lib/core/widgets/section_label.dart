import 'package:flutter/material.dart';

import '../theme/app_dimens.dart';
import '../theme/app_text_styles.dart';

/// Small section label above content groups.
class SectionLabel extends StatelessWidget {
  const SectionLabel({super.key, required this.text, this.trailing});

  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(text.toUpperCase(), style: AppTextStyles.sectionLabel),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}
