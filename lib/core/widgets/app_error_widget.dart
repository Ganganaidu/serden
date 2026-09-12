import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Inline error widget for use inside screens when a BLoC/Cubit emits an
/// error state. Displays a card with a message and an optional retry button.
///
/// Set [scrollable] to true when this widget is a direct child of a
/// [RefreshIndicator] — it wraps the content in a scrollable ListView so
/// pull-to-refresh still works.
class AppErrorWidget extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  final String? retryLabel;

  /// Wrap content in [ListView] with [AlwaysScrollableScrollPhysics] so a
  /// parent [RefreshIndicator] can detect the gesture.
  final bool scrollable;

  const AppErrorWidget({
    super.key,
    required this.message,
    this.onRetry,
    this.retryLabel,
    this.scrollable = false,
  });

  @override
  Widget build(BuildContext context) {
    final content = Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.redTint,
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(
                Icons.wifi_off_rounded,
                color: AppColors.redDeep,
                size: 30,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Unable to load',
              style: AppTextStyles.rowTitle.copyWith(color: AppColors.ink),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              message,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.inkSoft,
                fontSize: 14,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 20),
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: Text(retryLabel ?? 'Retry'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.green800,
                  side: const BorderSide(color: AppColors.green800),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  textStyle: AppTextStyles.buttonText.copyWith(fontSize: 14),
                ),
              ),
            ],
          ],
        ),
      ),
    );

    if (scrollable) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [const SizedBox(height: 40), content],
      );
    }
    return content;
  }
}
