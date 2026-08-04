import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/loading_overlay.dart';
import '../../../core/widgets/main_shell.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const DetailHeader(backLabel: 'Settings', title: 'About'),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 96),
              children: [
                Center(
                  child: Container(
                    width: 76,
                    height: 76,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.green800,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'S',
                      style: TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontSize: 34,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                const Center(
                  child: Text('Serden', style: AppTextStyles.headingMedium),
                ),
                const SizedBox(height: 4),
                Center(
                  child: Text(
                    'Made for pros',
                    style: AppTextStyles.bodyMedium
                        .copyWith(color: AppColors.inkSoft),
                  ),
                ),
                const SectionHeader(title: 'App'),
                AppCard(
                  child: Column(
                    children: const [
                      _AboutRow(label: 'Version', value: '4.2.1'),
                      _AboutRow(label: 'Terms of Service', chevron: true),
                      _AboutRow(
                        label: 'Privacy Policy',
                        chevron: true,
                        showDivider: false,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AboutRow extends StatelessWidget {
  final String label;
  final String? value;
  final bool chevron;
  final bool showDivider;

  const _AboutRow({
    required this.label,
    this.value,
    this.chevron = false,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: chevron ? () {} : null,
      child: Container(
        decoration: BoxDecoration(
          border: showDivider
              ? const Border(bottom: BorderSide(color: AppColors.line))
              : null,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        child: Row(
          children: [
            Expanded(
              child:
                  Text(label, style: AppTextStyles.rowTitle.copyWith(fontSize: 14.5)),
            ),
            if (value != null)
              Text(
                value!,
                style: AppTextStyles.labelMedium
                    .copyWith(fontSize: 13.5, color: AppColors.inkFaint),
              ),
            if (chevron)
              const Icon(Icons.chevron_right,
                  size: 16, color: AppColors.inkFaint),
          ],
        ),
      ),
    );
  }
}
