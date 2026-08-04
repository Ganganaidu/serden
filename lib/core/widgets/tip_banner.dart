import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Orange-tinted informational banner with a leading icon.
class TipBanner extends StatelessWidget {
  final IconData icon;
  final List<InlineSpan> spans;
  final VoidCallback? onTap;

  const TipBanner({
    super.key,
    this.icon = Icons.lightbulb_outline,
    required this.spans,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.orangeTint,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 1),
                child: Icon(icon, size: 17, color: AppColors.orangeDeep),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text.rich(
                  TextSpan(children: spans),
                  style: const TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    height: 1.5,
                    color: AppColors.orangeDeep,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
