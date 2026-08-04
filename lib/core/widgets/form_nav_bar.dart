import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// White top bar for modal-style forms:
/// Cancel · centered title (+ optional subtitle) · Save.
class FormNavBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String? subtitle;
  final String leadingLabel;
  final String? trailingLabel;
  final bool trailingEnabled;
  final VoidCallback? onLeading;
  final VoidCallback? onTrailing;

  const FormNavBar({
    super.key,
    required this.title,
    this.subtitle,
    this.leadingLabel = 'Cancel',
    this.trailingLabel,
    this.trailingEnabled = true,
    this.onLeading,
    this.onTrailing,
  });

  @override
  Size get preferredSize => const Size.fromHeight(58);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.card,
        border: Border(bottom: BorderSide(color: AppColors.line)),
      ),
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
      child: SizedBox(
        height: 58,
        child: Row(
          children: [
            SizedBox(
              width: 88,
              child: TextButton(
                onPressed: onLeading ?? () => context.pop(),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.inkSoft,
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  textStyle: const TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                child: Text(leadingLabel),
              ),
            ),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(title, style: AppTextStyles.headingSmall),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      style: const TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.inkFaint,
                      ),
                    ),
                ],
              ),
            ),
            SizedBox(
              width: 100,
              child: trailingLabel == null
                  ? null
                  : TextButton(
                      onPressed: trailingEnabled ? onTrailing : null,
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.orange500,
                        disabledForegroundColor: AppColors.inkFaint,
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                        textStyle: const TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      child: Text(trailingLabel!),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
