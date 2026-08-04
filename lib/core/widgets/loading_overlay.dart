import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class LoadingOverlay extends StatelessWidget {
  final Widget child;
  final bool isLoading;

  const LoadingOverlay({
    super.key,
    required this.child,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          const ColoredBox(
            color: Colors.black26,
            child: Center(
              child: CircularProgressIndicator(color: AppColors.green800),
            ),
          ),
      ],
    );
  }
}

/// Uppercase grey section label ("GETTING STARTED", "YOUR BUSINESS", …).
class SectionHeader extends StatelessWidget {
  final String title;
  final String? trailing;
  final Widget? trailingWidget;
  final EdgeInsetsGeometry padding;

  const SectionHeader({
    super.key,
    required this.title,
    this.trailing,
    this.trailingWidget,
    this.padding = const EdgeInsets.fromLTRB(4, 20, 4, 8),
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(title.toUpperCase(), style: AppTextStyles.sectionLabel),
          if (trailing != null)
            Text(trailing!, style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w600)),
          if (trailingWidget != null) trailingWidget!,
        ],
      ),
    );
  }
}

/// Centered empty-list message ("Nothing here yet").
class EmptyState extends StatelessWidget {
  final String title;
  final String description;
  final IconData? icon;
  final String? buttonLabel;
  final VoidCallback? onButtonTap;

  const EmptyState({
    super.key,
    required this.title,
    required this.description,
    this.icon,
    this.buttonLabel,
    this.onButtonTap,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 56),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  color: AppColors.greenTint,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(icon, color: AppColors.greenDeep, size: 34),
              ),
              const SizedBox(height: 18),
            ],
            Text(
              title,
              style: AppTextStyles.rowTitle.copyWith(color: AppColors.inkSoft),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              description,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.inkFaint,
                fontSize: 14,
                height: 1.6,
              ),
              textAlign: TextAlign.center,
            ),
            if (buttonLabel != null) ...[
              const SizedBox(height: 22),
              ElevatedButton(
                onPressed: onButtonTap,
                child: Text(buttonLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
