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
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              children: [
                const SectionHeader(
                  title: 'Your business',
                  padding: EdgeInsets.fromLTRB(4, 0, 4, 8),
                ),
                AppCard(
                  child: Column(
                    children: [
                      CardRow(
                        icon: Icons.bar_chart,
                        title: 'Dashboard',
                        onTap: () {},
                      ),
                      CardRow(
                        icon: Icons.star_outline,
                        title: 'Reviews',
                        onTap: () => context.push(AppRoutes.reviews),
                      ),
                      CardRow(
                        icon: Icons.sell_outlined,
                        title: 'Items',
                        showDivider: false,
                        onTap: () => context.push(AppRoutes.items),
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
                        icon: Icons.settings_outlined,
                        grayIcon: true,
                        title: 'Settings',
                        showDivider: false,
                        onTap: () => context.push(AppRoutes.settings),
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
                const SizedBox(height: 22),
                OutlinedButton.icon(
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
                const Padding(
                  padding: EdgeInsets.only(top: 14),
                  child: Text(
                    'Serden · Made for pros',
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
    );
  }
}
