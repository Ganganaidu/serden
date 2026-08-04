import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class PillTab {
  final String label;
  final int? count;

  /// Active fill; defaults to green800 (overdue uses red, leads-new orange).
  final Color? activeColor;

  const PillTab(this.label, {this.count, this.activeColor});
}

/// Rounded segmented tabs on a white bar under the header
/// (Pending / Approved / Declined, Active / Overdue / Paid, …).
class PillTabs extends StatelessWidget {
  final List<PillTab> tabs;
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  const PillTabs({
    super.key,
    required this.tabs,
    required this.selectedIndex,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.card,
        border: Border(bottom: BorderSide(color: AppColors.line)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          for (var i = 0; i < tabs.length; i++) ...[
            if (i > 0) const SizedBox(width: 6),
            Expanded(child: _tab(i)),
          ],
        ],
      ),
    );
  }

  Widget _tab(int i) {
    final tab = tabs[i];
    final selected = i == selectedIndex;
    final fill = selected ? (tab.activeColor ?? AppColors.green800) : null;

    return Material(
      color: fill ?? Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: () => onChanged(i),
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 4),
          child: Text.rich(
            TextSpan(
              text: tab.label,
              children: [
                if (tab.count != null)
                  TextSpan(
                    text: ' ${tab.count}',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: (selected ? Colors.white : AppColors.inkSoft)
                          .withValues(alpha: 0.65),
                    ),
                  ),
              ],
            ),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              color: selected ? Colors.white : AppColors.inkSoft,
            ),
          ),
        ),
      ),
    );
  }
}
