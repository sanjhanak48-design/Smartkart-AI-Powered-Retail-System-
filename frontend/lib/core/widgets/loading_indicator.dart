import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// A centered, full-area loading indicator used while a page awaits data.
class LoadingIndicator extends StatelessWidget {
  const LoadingIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(color: AppColors.primary),
    );
  }
}
