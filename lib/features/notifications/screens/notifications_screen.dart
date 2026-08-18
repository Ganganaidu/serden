import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/loading_overlay.dart';
import '../../../core/widgets/main_shell.dart';
import '../cubit/notifications_cubit.dart';
import '../models/notification_model.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<NotificationsCubit>().fetch();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onTap(AppNotification n) {
    context.read<NotificationsCubit>().markAsRead(n.id);
    switch (n.type) {
      case NotificationType.lead:
        context.go(AppRoutes.leadDetail.replaceFirst(':id', n.entityId));
      case NotificationType.estimate:
        context.go(AppRoutes.estimateDetail.replaceFirst(':id', n.entityId));
      case NotificationType.invoice:
        context.go(AppRoutes.invoiceDetail.replaceFirst(':id', n.entityId));
      case NotificationType.client:
        context.go(AppRoutes.clientDetail.replaceFirst(':id', n.entityId));
      case NotificationType.general:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.page,
      body: BlocBuilder<NotificationsCubit, NotificationsState>(
        builder: (context, state) {
          final loaded = state is NotificationsLoaded ? state : null;
          return Column(
            children: [
              DetailHeader(
                backLabel: 'Back',
                title: 'Notifications',
                actions: [
                  if (loaded != null && loaded.hasUnread)
                    HeaderIconButton(
                      icon: Icons.done_all,
                      tooltip: 'Mark all as read',
                      onTap: () =>
                          context.read<NotificationsCubit>().markAllAsRead(),
                    ),
                ],
                bottom: HeaderSearchBar(
                  hint: 'Search notifications',
                  controller: _searchController,
                  onChanged: (v) =>
                      context.read<NotificationsCubit>().search(v),
                ),
              ),
              Expanded(child: _buildBody(state)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBody(NotificationsState state) {
    if (state is NotificationsLoading || state is NotificationsInitial) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state is NotificationsError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_outlined,
                  size: 48, color: AppColors.inkFaint),
              const SizedBox(height: 16),
              Text(state.message,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyMedium
                      .copyWith(color: AppColors.inkSoft)),
              const SizedBox(height: 20),
              TextButton(
                onPressed: () =>
                    context.read<NotificationsCubit>().fetch(),
                child: const Text('Try again'),
              ),
            ],
          ),
        ),
      );
    }

    if (state is NotificationsLoaded) {
      final items = state.filtered;
      if (items.isEmpty) {
        return EmptyState(
          title: state.query.isNotEmpty
              ? 'No matches'
              : 'You\'re all caught up',
          description: state.query.isNotEmpty
              ? 'Try a different search term.'
              : 'New notifications will appear here.',
        );
      }
      return ListView.builder(
        padding: const EdgeInsets.only(bottom: 40),
        itemCount: items.length,
        itemBuilder: (_, i) => _NotificationRow(
          notification: items[i],
          onTap: () => _onTap(items[i]),
        ),
      );
    }

    return const SizedBox.shrink();
  }
}

// ─── Notification row ─────────────────────────────────────────────────────────

class _NotificationRow extends StatelessWidget {
  final AppNotification notification;
  final VoidCallback onTap;

  const _NotificationRow({required this.notification, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isUnread = !notification.isRead;

    return Material(
      color: isUnread ? AppColors.orangeTint.withValues(alpha: 0.35) : AppColors.card,
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              bottom: const BorderSide(color: AppColors.line),
              left: isUnread
                  ? const BorderSide(color: AppColors.orange500, width: 3)
                  : BorderSide.none,
            ),
          ),
          padding: EdgeInsets.fromLTRB(isUnread ? 17 : 20, 14, 20, 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _TypeIcon(type: notification.type),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notification.title,
                      style: AppTextStyles.rowTitle.copyWith(
                        fontWeight: isUnread
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: isUnread ? AppColors.ink : AppColors.inkSoft,
                        fontSize: 14.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatTimestamp(notification.createdAt),
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),
              ),
              if (isUnread)
                Padding(
                  padding: const EdgeInsets.only(left: 10, top: 2),
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.orange500,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final day = DateTime(dt.year, dt.month, dt.day);

    final time = DateFormat('h:mm a').format(dt);

    if (day == today) return 'Today · $time';
    if (day == yesterday) return 'Yesterday · $time';

    final month = DateFormat('MMMM').format(dt);
    final ordinal = _ordinal(dt.day);
    return '$month ${dt.day}$ordinal ${dt.year} · $time';
  }

  String _ordinal(int n) {
    if (n >= 11 && n <= 13) return 'th';
    switch (n % 10) {
      case 1:
        return 'st';
      case 2:
        return 'nd';
      case 3:
        return 'rd';
      default:
        return 'th';
    }
  }
}

// ─── Type icon ────────────────────────────────────────────────────────────────

class _TypeIcon extends StatelessWidget {
  final NotificationType type;
  const _TypeIcon({required this.type});

  @override
  Widget build(BuildContext context) {
    final (bg, fg, icon) = switch (type) {
      NotificationType.lead => (
          AppColors.orangeTint,
          AppColors.orange500,
          Icons.bolt,
        ),
      NotificationType.estimate => (
          AppColors.greenTint,
          AppColors.greenDeep,
          Icons.article_outlined,
        ),
      NotificationType.invoice => (
          AppColors.greenTint,
          AppColors.greenDeep,
          Icons.receipt_long_outlined,
        ),
      NotificationType.client => (
          AppColors.grayTint,
          AppColors.grayDeep,
          Icons.person_outline,
        ),
      NotificationType.general => (
          AppColors.grayTint,
          AppColors.grayDeep,
          Icons.notifications_outlined,
        ),
    };

    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, size: 20, color: fg),
    );
  }
}
