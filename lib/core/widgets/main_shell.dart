import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Root shell with the five-tab bottom navigation:
/// Estimates · Invoices · Clients · Leads · More
class MainShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;
  const MainShell({super.key, required this.navigationShell});

  void _goBranch(int index) {
    // Tapping the active tab again pops that branch back to its root.
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = navigationShell.currentIndex;

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.card,
          border: Border(top: BorderSide(color: AppColors.line)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(6, 8, 6, 10),
            child: Row(
              children: [
                _NavItem(
                  icon: Icons.article_outlined,
                  label: 'Estimates',
                  selected: currentIndex == 0,
                  onTap: () => _goBranch(0),
                ),
                _NavItem(
                  icon: Icons.receipt_long_outlined,
                  label: 'Invoices',
                  selected: currentIndex == 1,
                  onTap: () => _goBranch(1),
                ),
                _NavItem(
                  icon: Icons.people_outline,
                  label: 'Clients',
                  selected: currentIndex == 2,
                  onTap: () => _goBranch(2),
                ),
                _NavItem(
                  icon: Icons.bolt_outlined,
                  label: 'Leads',
                  selected: currentIndex == 3,
                  showDot: true,
                  onTap: () => _goBranch(3),
                ),
                _NavItem(
                  icon: Icons.more_horiz,
                  label: 'More',
                  selected: currentIndex == 4,
                  onTap: () => _goBranch(4),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final bool showDot;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.showDot = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.green800 : AppColors.inkFaint;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(icon, size: 23, color: color),
                  if (showDot)
                    Positioned(
                      top: -2,
                      right: -6,
                      child: Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          color: AppColors.orange500,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 3),
              Text(
                label,
                style: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Dark green top section used on all list screens.
class AppHeader extends StatelessWidget {
  final String title;

  /// Plain-text subtitle. Use [subtitleSpans] for mixed emphasis.
  final String? subtitle;
  final List<InlineSpan>? subtitleSpans;
  final List<Widget>? actions;

  /// Extra content below the title row (e.g. [HeaderSearchBar]).
  final Widget? bottom;

  const AppHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.subtitleSpans,
    this.actions,
    this.bottom,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.green800,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 12,
        left: 20,
        right: 20,
        bottom: 18,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTextStyles.headerTitle),
                    if (subtitle != null || subtitleSpans != null) ...[
                      const SizedBox(height: 3),
                      Text.rich(
                        TextSpan(
                          text: subtitle,
                          children: subtitleSpans,
                        ),
                        style: AppTextStyles.headerSubtitle,
                      ),
                    ],
                  ],
                ),
              ),
              if (actions != null) ...actions!,
            ],
          ),
          if (bottom != null) bottom!,
        ],
      ),
    );
  }
}

/// 38x38 translucent icon button used inside [AppHeader].
class HeaderIconButton extends StatelessWidget {
  final IconData icon;
  final bool showDot;
  final VoidCallback? onTap;
  final String? tooltip;

  const HeaderIconButton({
    super.key,
    required this.icon,
    this.showDot = false,
    this.onTap,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(11),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(11),
        child: SizedBox(
          width: 38,
          height: 38,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(icon, size: 19, color: Colors.white),
              if (showDot)
                Positioned(
                  top: 9,
                  right: 10,
                  child: Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: AppColors.orange500,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.green800,
                        width: 1.5,
                      ),
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

/// Search bar styled for the dark green header.
class HeaderSearchBar extends StatelessWidget {
  final String hint;
  final ValueChanged<String>? onChanged;
  final TextEditingController? controller;

  const HeaderSearchBar({
    super.key,
    required this.hint,
    this.onChanged,
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: const TextStyle(
          fontFamily: AppTextStyles.fontFamily,
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        cursorColor: Colors.white,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(
            fontFamily: AppTextStyles.fontFamily,
            color: AppColors.onHeaderFaint,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          prefixIcon: const Icon(
            Icons.search,
            color: AppColors.onHeaderFaint,
            size: 18,
          ),
          isDense: true,
          filled: true,
          fillColor: Colors.white.withValues(alpha: 0.1),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(11),
            borderSide: BorderSide(
              color: Colors.white.withValues(alpha: 0.08),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(11),
            borderSide: BorderSide(
              color: Colors.white.withValues(alpha: 0.35),
            ),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        ),
      ),
    );
  }
}

/// Compact green header with a back label, used on detail screens.
class DetailHeader extends StatelessWidget {
  final String backLabel;
  final String? title;
  final List<Widget>? actions;
  final Widget? bottom;
  final VoidCallback? onBack;

  const DetailHeader({
    super.key,
    required this.backLabel,
    this.title,
    this.actions,
    this.bottom,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.green800,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
        left: 16,
        right: 16,
        bottom: bottom != null ? 16 : 12,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              InkWell(
                onTap: onBack ?? () => context.pop(),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.arrow_back_ios_new,
                          size: 14, color: Color(0xD9FFFFFF)),
                      const SizedBox(width: 4),
                      Text(
                        backLabel,
                        style: const TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xD9FFFFFF),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: title != null
                    ? Center(
                        child: Text(
                          title!,
                          style: const TextStyle(
                            fontFamily: AppTextStyles.fontFamily,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
              if (actions != null)
                ...actions!
              else
                // Balance the back button so the title stays centered.
                SizedBox(width: 60 + backLabel.length * 4),
            ],
          ),
          if (bottom != null) bottom!,
        ],
      ),
    );
  }
}
