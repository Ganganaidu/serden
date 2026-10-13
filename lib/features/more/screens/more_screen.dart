import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/loading_overlay.dart';
import '../../../core/widgets/main_shell.dart';
import '../../auth/bloc/auth_bloc.dart';

class MoreScreen extends StatefulWidget {
  const MoreScreen({super.key});

  @override
  State<MoreScreen> createState() => _MoreScreenState();
}

class _MoreScreenState extends State<MoreScreen> {
  String _version = '';

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    final info = await PackageInfo.fromPlatform();
    if (mounted) {
      setState(() => _version = info.version);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          AppHeader(
            title: 'More',
            subtitle: 'Serden Group LLC',
            actions: [const NotificationBellButton()],
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              children: [
                const SectionHeader(
                  title: 'Your business',
                  padding: EdgeInsets.fromLTRB(4, 0, 4, 8),
                ),
                AppCard(
                  child: Column(
                    children: [
                      CardRow(
                        icon: Icons.person_outline,
                        grayIcon: true,
                        title: 'My account',
                        onTap: () => context.push(AppRoutes.accountView),
                      ),
                      CardRow(
                        icon: Icons.home_work_outlined,
                        grayIcon: true,
                        title: 'My Company',
                        attention: true,
                        onTap: () => context.push(AppRoutes.companyProfile),
                      ),
                      CardRow(
                        icon: Icons.notifications_outlined,
                        grayIcon: true,
                        title: 'Notifications',
                        onTap: () => context.push(AppRoutes.notifications),
                      ),
                      CardRow(
                        icon: Icons.star_outline,
                        title: 'Reviews',
                        onTap: () => context.push(AppRoutes.reviews),
                      ),
                    ],
                  ),
                ),
                const SectionHeader(title: 'Account'),
                AppCard(
                  child: Column(
                    children: [
                      CardRow(
                        icon: Icons.credit_card_outlined,
                        grayIcon: true,
                        title: 'Payment settings',
                        value: 'Setup needed',
                        attention: true,
                        onTap: () {},
                      ),
                      CardRow(
                        icon: Icons.attach_money,
                        grayIcon: true,
                        title: 'Taxes',
                        onTap: () => context.push(AppRoutes.taxes),
                      ),
                      CardRow(
                        icon: Icons.sell_outlined,
                        title: 'Items',
                        showDivider: true,
                        onTap: () => context.push(AppRoutes.items),
                      ),
                      CardRow(
                        icon: Icons.percent,
                        grayIcon: true,
                        title: 'Line Item Markup',
                        showDivider: false,
                        onTap: () => context.push(AppRoutes.markups),
                      ),
                    ],
                  ),
                ),
                const SectionHeader(title: 'Support'),
                AppCard(
                  child: Column(
                    children: [
                      CardRow(
                        icon: Icons.help_outline,
                        grayIcon: true,
                        title: 'Get help / contact',
                        onTap: () => context.push(AppRoutes.contactUs),
                      ),
                      CardRow(
                        icon: Icons.info_outline,
                        grayIcon: true,
                        title: 'About this app',
                        value: _version.isNotEmpty ? 'v$_version' : null,
                        showDivider: false,
                        onTap: () => context.push(AppRoutes.about),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            decoration: const BoxDecoration(
              color: AppColors.page,
              border: Border(top: BorderSide(color: AppColors.line)),
            ),
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
            child: SafeArea(
              top: false,
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () =>
                      context.read<AuthBloc>().add(const AuthSignOutRequested()),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.inkSoft,
                    side: const BorderSide(color: AppColors.line),
                    backgroundColor: AppColors.card,
                    textStyle: AppTextStyles.buttonText.copyWith(fontSize: 14.5),
                  ),
                  icon: const Icon(Icons.logout, size: 16),
                  label: const Text('Log out'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
