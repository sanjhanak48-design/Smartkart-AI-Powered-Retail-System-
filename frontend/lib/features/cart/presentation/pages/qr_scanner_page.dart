import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../controllers/qr_scanner_controller.dart';

/// Test seam: widget tests override this provider to inject a fake scanner
/// that emits controlled payloads without a physical camera.
typedef QrScannerBuilder = Widget Function(
  BuildContext context,
  ValueChanged<String> onDetect,
);

final qrScannerBuilderProvider = Provider<QrScannerBuilder?>((ref) => null);

class QrScannerPage extends ConsumerWidget {
  const QrScannerPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<QrScanState>(qrScannerControllerProvider, (previous, next) {
      if (next is QrLinked && context.mounted) {
        context.go('/live-cart');
      }
    });

    final builder = ref.watch(qrScannerBuilderProvider);
    final state = ref.watch(qrScannerControllerProvider);

    void onDetect(String raw) {
      ref.read(qrScannerControllerProvider.notifier).onQrDetected(raw);
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Scan Cart')),
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (builder != null)
            builder(context, onDetect)
          else
            _LiveScannerView(onDetect: onDetect),
          const _ScanFrameOverlay(),
          const SafeArea(child: _GuidanceBanner()),
          SafeArea(
            child: _StatusOverlay(
              state: state,
              onReset: () =>
                  ref.read(qrScannerControllerProvider.notifier).reset(),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScanFrameOverlay extends StatelessWidget {
  const _ScanFrameOverlay();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Center(
        child: Container(
          key: const Key('scan_frame'),
          width: AppSpacing.scanFrameSize,
          height: AppSpacing.scanFrameSize,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 20,
                spreadRadius: 12,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            child: Stack(
              children: [
                Align(
                  alignment: Alignment.center,
                  child: Container(
                    height: 2,
                    margin: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.white.withValues(alpha: 0),
                          Colors.white,
                          Colors.white.withValues(alpha: 0),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(top: 10, left: 10, child: _CornerDot()),
                Positioned(top: 10, right: 10, child: _CornerDot()),
                Positioned(bottom: 10, left: 10, child: _CornerDot()),
                Positioned(bottom: 10, right: 10, child: _CornerDot()),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CornerDot extends StatelessWidget {
  const _CornerDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle),
    );
  }
}

class _GuidanceBanner extends StatelessWidget {
  const _GuidanceBanner();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: Container(
        margin: const EdgeInsets.all(AppSpacing.md),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: Colors.black54,
          borderRadius: BorderRadius.circular(AppSpacing.radiusRound),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.qr_code_2, size: 18, color: Colors.white70),
            const SizedBox(width: AppSpacing.xs),
            const Flexible(
              child: Text(
                'Point the camera at the QR code on the cart',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusOverlay extends StatelessWidget {
  const _StatusOverlay({required this.state, required this.onReset});

  final QrScanState state;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final Widget? panel = switch (state) {
      QrIdle() => null,
      QrValidating() => _busyPanel(context, 'Checking cart…', icon: Icons.link),
      QrLinking() => _busyPanel(
        context,
        'Linking cart…',
        icon: Icons.shopping_cart_outlined,
      ),
      QrLinked(:final cartId) => _successPanel(context, cartId),
      QrInvalid(:final message) => _messagePanel(
        context,
        icon: Icons.error_outline,
        message: message,
        buttonLabel: 'Scan Again',
        color: Theme.of(context).colorScheme.errorContainer,
        onPressed: onReset,
      ),
      QrError(:final message) => _messagePanel(
        context,
        icon: Icons.error_outline,
        message: message,
        buttonLabel: 'Retry',
        color: Theme.of(context).colorScheme.errorContainer,
        onPressed: onReset,
      ),
    };

    return Align(
      alignment: Alignment.bottomCenter,
      child: panel ?? const SizedBox.shrink(),
    );
  }

  Widget _busyPanel(
    BuildContext context,
    String label, {
    required IconData icon,
  }) {
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.all(AppSpacing.md),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 8)],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(label, style: AppTextStyles.body),
          ],
        ),
      ),
    );
  }

  Widget _successPanel(BuildContext context, String cartId) {
    return Container(
      margin: const EdgeInsets.all(AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.primary, width: 1.5),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.check_circle_outline, color: AppColors.primary),
          const SizedBox(width: AppSpacing.sm),
          Flexible(
            child: Text(
              'Cart linked! Open the Live Cart to continue.',
              style: AppTextStyles.body.copyWith(color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _messagePanel(
    BuildContext context, {
    required IconData icon,
    required String message,
    required String buttonLabel,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Container(
      margin: const EdgeInsets.all(AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.onErrorContainer),
          const SizedBox(height: AppSpacing.xs),
          Text(
            message,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onErrorContainer,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.sm),
          FilledButton(onPressed: onPressed, child: Text(buttonLabel)),
        ],
      ),
    );
  }
}

class _LiveScannerView extends StatefulWidget {
  const _LiveScannerView({required this.onDetect});

  final ValueChanged<String> onDetect;

  @override
  State<_LiveScannerView> createState() => _LiveScannerViewState();
}

class _LiveScannerViewState extends State<_LiveScannerView> {
  MobileScannerController? _controller;

  @override
  void initState() {
    super.initState();
    _controller = MobileScannerController();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _handleDetect(BarcodeCapture capture) {
    for (final barcode in capture.barcodes) {
      final raw = barcode.rawValue;
      if (raw != null && raw.isNotEmpty) {
        widget.onDetect(raw);
        break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MobileScanner(
      controller: _controller,
      onDetect: _handleDetect,
      placeholderBuilder: (context) => const LoadingIndicator(),
      errorBuilder: (context, error) => Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.no_photography_outlined,
                size: 48,
                color: AppColors.textSecondary,
              ),
              const SizedBox(height: AppSpacing.sm),
              const Text('Unable to access the camera.'),
            ],
          ),
        ),
      ),
    );
  }
}
