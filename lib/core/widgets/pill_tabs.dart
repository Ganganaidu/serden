import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class PillTab {
  final String label;
  final int? count;

  /// Active label + indicator color; defaults to green800
  /// (Overdue uses red, new Leads uses orange).
  final Color? activeColor;

  const PillTab(this.label, {this.count, this.activeColor});
}

/// Top tab strip on a white bar under the header, with an animated
/// underline indicator — the standard Material top-tab look, which also
/// reads naturally on iOS (Pending / Approved / Declined, Active / Overdue
/// / Paid, …). Fully controlled via [selectedIndex] / [onChanged].
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

  static const double _height = 46;
  static const double _indicatorInset = 14;

  @override
  Widget build(BuildContext context) {
    final activeColor =
        tabs[selectedIndex].activeColor ?? AppColors.green800;

    return Container(
      color: AppColors.card,
      height: _height,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final tabWidth = constraints.maxWidth / tabs.length;
          return Stack(
            children: [
              // Baseline hairline
              const Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Divider(height: 1, thickness: 1, color: AppColors.line),
              ),
              // Tabs
              Positioned.fill(
                child: Row(
                  children: [
                    for (var i = 0; i < tabs.length; i++)
                      Expanded(child: _tab(i, activeColor)),
                  ],
                ),
              ),
              // Sliding underline indicator
              AnimatedPositioned(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                left: selectedIndex * tabWidth + _indicatorInset,
                width: (tabWidth - _indicatorInset * 2).clamp(0, double.infinity),
                bottom: 0,
                child: Container(
                  height: 2.5,
                  decoration: BoxDecoration(
                    color: activeColor,
                    borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(2)),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _tab(int i, Color activeColor) {
    final tab = tabs[i];
    final selected = i == selectedIndex;
    final fg = selected ? activeColor : AppColors.inkSoft;

    return InkWell(
      onTap: () => onChanged(i),
      child: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                tab.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 13.5,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                  color: fg,
                ),
              ),
            ),
            if (tab.count != null) ...[
              const SizedBox(width: 6),
              _CountBadge(
                count: tab.count!,
                selected: selected,
                activeColor: activeColor,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CountBadge extends StatelessWidget {
  final int count;
  final bool selected;
  final Color activeColor;

  const _CountBadge({
    required this.count,
    required this.selected,
    required this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 18),
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: selected
            ? activeColor.withValues(alpha: 0.12)
            : AppColors.grayTint,
        borderRadius: BorderRadius.circular(9),
      ),
      child: Text(
        '$count',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontFamily: AppTextStyles.fontFamily,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: selected ? activeColor : AppColors.inkSoft,
        ),
      ),
    );
  }
}
