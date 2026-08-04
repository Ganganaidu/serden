import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// White rounded card with a hairline border — the standard container
/// for grouped rows and forms in the new design.
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;

  const AppCard({super.key, required this.child, this.padding});

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.card,
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(14),
      ),
      padding: padding,
      child: child,
    );
  }
}

/// Tappable row inside an [AppCard]: leading icon chip, title,
/// optional value, chevron. Matches the "More" menu rows.
class CardRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? value;

  /// Highlights the value in orange ("85% complete", "Setup needed").
  final bool attention;

  /// Grey icon chip instead of green.
  final bool grayIcon;
  final Widget? valueWidget;
  final bool showChevron;
  final bool showDivider;
  final VoidCallback? onTap;

  const CardRow({
    super.key,
    required this.icon,
    required this.title,
    this.value,
    this.valueWidget,
    this.attention = false,
    this.grayIcon = false,
    this.showChevron = true,
    this.showDivider = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          border: showDivider
              ? const Border(bottom: BorderSide(color: AppColors.line))
              : null,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: grayIcon ? AppColors.grayTint : AppColors.greenTint,
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(
                icon,
                size: 17,
                color: grayIcon ? AppColors.inkSoft : AppColors.greenDeep,
              ),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Text(title, style: AppTextStyles.rowTitle),
            ),
            if (valueWidget != null) valueWidget!,
            if (value != null)
              Text(
                value!,
                style: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 13,
                  fontWeight: attention ? FontWeight.w700 : FontWeight.w600,
                  color:
                      attention ? AppColors.orangeDeep : AppColors.inkFaint,
                ),
              ),
            if (showChevron) ...[
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right,
                  size: 18, color: AppColors.inkFaint),
            ],
          ],
        ),
      ),
    );
  }
}
