import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/loading_overlay.dart';
import '../../auth/bloc/auth_bloc.dart';

/// Read-only "My account" overview (serden-account-view design).
class AccountViewScreen extends StatefulWidget {
  const AccountViewScreen({super.key});

  @override
  State<AccountViewScreen> createState() => _AccountViewScreenState();
}

class _AccountViewScreenState extends State<AccountViewScreen> {
  static const _serdenId = 'PRO-20251103-11356';
  bool _copied = false;

  Future<void> _copyId() async {
    await Clipboard.setData(const ClipboardData(text: _serdenId));
    if (!mounted) return;
    setState(() => _copied = true);
    Future<void>.delayed(const Duration(milliseconds: 1800), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  InkWell(
                    onTap: () => context.pop(),
                    borderRadius: BorderRadius.circular(8),
                    child: Row(
                      children: const [
                        Icon(Icons.arrow_back_ios_new,
                            size: 14, color: AppColors.inkSoft),
                        SizedBox(width: 4),
                        Text(
                          'More',
                          style: TextStyle(
                            fontFamily: AppTextStyles.fontFamily,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.inkSoft,
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () => context.push(AppRoutes.myAccount),
                    child: const Text('Edit'),
                  ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(18, 0, 18, 12),
              child: Text('My account', style: AppTextStyles.headingMedium),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
                children: [
                  _profileCard(),
                  const SectionHeader(title: 'Account details'),
                  AppCard(
                    child: Column(
                      children: [
                        _valueRow('Username', 'serden'),
                        _serdenIdRow(),
                        _valueRow('Company name', 'Serden Group LLC',
                            chevron: true),
                        _valueRow(
                            'Address', '1104 Main St, Ste 610, Vancouver, WA',
                            chevron: true, showDivider: false),
                      ],
                    ),
                  ),
                  const SectionHeader(title: 'Membership and billing'),
                  AppCard(
                    child: Column(
                      children: [
                        _iconRow(
                          icon: Icons.verified_user_outlined,
                          greenIcon: true,
                          title: 'Pro membership',
                          subtitle: 'Renews Jul 4, 2027 · \$100/year',
                          onTap: () => context.push(AppRoutes.choosePlan),
                        ),
                        _iconRow(
                          icon: Icons.credit_card_outlined,
                          title: 'Payment method',
                          subtitle: 'Visa ending 4242 · expires 08/27',
                          showDivider: false,
                          onTap: () {},
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  OutlinedButton.icon(
                    onPressed: () => context
                        .read<AuthBloc>()
                        .add(const AuthSignOutRequested()),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.inkSoft,
                      side: const BorderSide(color: AppColors.line),
                      backgroundColor: AppColors.card,
                      textStyle:
                          AppTextStyles.buttonText.copyWith(fontSize: 14.5),
                    ),
                    icon: const Icon(Icons.logout, size: 16),
                    label: const Text('Sign out'),
                  ),
                  const Padding(
                    padding: EdgeInsets.only(top: 14),
                    child: Text(
                      'Serden for iOS · v4.2.1',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                        color: AppColors.inkFaint,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _profileCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
      decoration: BoxDecoration(
        color: AppColors.green800,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
              shape: BoxShape.circle,
            ),
            child: const Text(
              'DS',
              style: TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Dennis Serov',
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '+1 (360) 836-7775\nserdengroup@gmail.com',
                  style: AppTextStyles.headerSubtitle
                      .copyWith(fontSize: 12.5, height: 1.55),
                ),
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.14),
                    border: Border.all(
                        color: Colors.white.withValues(alpha: 0.16)),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.verified_user_outlined,
                          size: 12, color: AppColors.overdueOnHeader),
                      SizedBox(width: 5),
                      Text(
                        'Serdefied Pro',
                        style: TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
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

  Widget _valueRow(String label, String value,
      {bool chevron = false, bool showDivider = true}) {
    return InkWell(
      onTap: chevron ? () {} : null,
      child: Container(
        decoration: BoxDecoration(
          border: showDivider
              ? const Border(bottom: BorderSide(color: AppColors.line))
              : null,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Text(label, style: AppTextStyles.rowTitle.copyWith(fontSize: 14)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                value,
                textAlign: TextAlign.right,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.labelMedium
                    .copyWith(fontSize: 13.5, color: AppColors.inkSoft),
              ),
            ),
            if (chevron) ...[
              const SizedBox(width: 6),
              const Icon(Icons.chevron_right,
                  size: 16, color: AppColors.inkFaint),
            ],
          ],
        ),
      ),
    );
  }

  Widget _serdenIdRow() {
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.line)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
      child: Row(
        children: [
          Text('Serden ID',
              style: AppTextStyles.rowTitle.copyWith(fontSize: 14)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _serdenId,
              textAlign: TextAlign.right,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.labelMedium.copyWith(
                fontSize: 13.5,
                color: AppColors.inkSoft,
                letterSpacing: 0.3,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Material(
            color: _copied ? AppColors.greenTint : AppColors.grayTint,
            borderRadius: BorderRadius.circular(20),
            child: InkWell(
              onTap: _copyId,
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.copy_outlined,
                      size: 12,
                      color: _copied
                          ? AppColors.greenDeep
                          : AppColors.inkSoft,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      _copied ? 'Copied' : 'Copy',
                      style: TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: _copied
                            ? AppColors.greenDeep
                            : AppColors.inkSoft,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _iconRow({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool greenIcon = false,
    bool showDivider = true,
  }) {
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
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: greenIcon ? AppColors.greenTint : AppColors.grayTint,
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(
                icon,
                size: 18,
                color: greenIcon ? AppColors.greenDeep : AppColors.inkSoft,
              ),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: AppTextStyles.rowTitle.copyWith(fontSize: 14.5)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: AppTextStyles.caption.copyWith(fontSize: 12)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right,
                size: 16, color: AppColors.inkFaint),
          ],
        ),
      ),
    );
  }
}
