import 'package:flutter/material.dart';

/// A full-width filled button with the standard vertical padding. When
/// [isLoading] is true it disables the button and shows a centered spinner,
/// replacing repeated `_busy ? spinner : label` button patterns.
class LoadingButton extends StatelessWidget {
  const LoadingButton({
    super.key,
    required this.isLoading,
    required this.onPressed,
    required this.child,
    this.spinnerColor,
    this.spinnerSize = 20,
  });

  final bool isLoading;
  final VoidCallback? onPressed;
  final Widget child;

  /// Spinner colour; when null the theme default is used.
  final Color? spinnerColor;
  final double spinnerSize;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: isLoading ? null : onPressed,
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        child: isLoading
            ? SizedBox(
                width: spinnerSize,
                height: spinnerSize,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: spinnerColor,
                ),
              )
            : child,
      ),
    );
  }
}
