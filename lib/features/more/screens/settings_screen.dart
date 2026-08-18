import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/loading_overlay.dart';
import '../../../core/widgets/main_shell.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const DetailHeader(backLabel: 'More', title: 'Settings'),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              children: [
                const SectionHeader(
                  title: 'General',
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
                        icon: Icons.notifications_outlined,
                        grayIcon: true,
                        title: 'Notifications',
                        onTap: () => context.push(AppRoutes.notifications),
                      ),
                      CardRow(
                        icon: Icons.attach_money,
                        grayIcon: true,
                        title: 'Taxes',
                        onTap: () => context.push(AppRoutes.taxes),
                      ),
                      CardRow(
                        icon: Icons.percent,
                        grayIcon: true,
                        title: 'Line Item Markup',
                        onTap: () => context.push(AppRoutes.markups),
                      ),
                      CardRow(
                        icon: Icons.home_work_outlined,
                        grayIcon: true,
                        title: 'Company profile',
                        value: '85% complete',
                        attention: true,
                        showDivider: false,
                        onTap: () => context.push(AppRoutes.companyProfile),
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
