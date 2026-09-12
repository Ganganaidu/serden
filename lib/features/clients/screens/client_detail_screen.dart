import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/contact_launcher.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_error_widget.dart';
import '../../../core/widgets/avatar_widget.dart';
import '../../../core/widgets/loading_overlay.dart';
import '../cubit/client_detail_cubit.dart';
import '../models/client_model.dart';

class ClientDetailScreen extends StatefulWidget {
  final String id;
  final Client? previewClient;

  const ClientDetailScreen({
    super.key,
    required this.id,
    this.previewClient,
  });

  @override
  State<ClientDetailScreen> createState() => _ClientDetailScreenState();
}

class _ClientDetailScreenState extends State<ClientDetailScreen> {
  @override
  void initState() {
    super.initState();
    final clientId = int.tryParse(widget.id) ?? 0;
    context
        .read<ClientDetailCubit>()
        .fetch(clientId, preview: widget.previewClient);
  }

  Future<void> _handleEdit(Client client) async {
    final result = await context.push<Map<String, dynamic>>(
      AppRoutes.addClient,
      extra: {'clientToEdit': client},
    );
    if (!mounted || result == null) return;

    if (result['deleted'] == true) {
      if (context.canPop()) context.pop();
    } else if (result['client'] != null) {
      final updated = result['client'] as Client;
      context.read<ClientDetailCubit>().applyUpdate(updated);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ClientDetailCubit, ClientDetailState>(
      builder: (context, state) {
        final client = switch (state) {
          ClientDetailLoaded(:final client) => client,
          ClientDetailLoading(:final preview) => preview,
          ClientDetailError(:final stale) => stale,
          _ => null,
        };
        final isLoading = state is ClientDetailLoading;
        final errorMessage =
            state is ClientDetailError ? state.message : null;

        return Scaffold(
          body: Column(
            children: [
              _Header(
                client: client,
                isLoading: isLoading && client == null,
                onEdit: client != null
                    ? () => _handleEdit(client)
                    : null,
              ),
              Expanded(
                child: isLoading && client == null
                    ? const Center(child: CircularProgressIndicator())
                    : errorMessage != null && client == null
                        ? AppErrorWidget(
                            message: errorMessage,
                            onRetry: () {
                              final clientId = int.tryParse(widget.id) ?? 0;
                              context
                                  .read<ClientDetailCubit>()
                                  .fetch(clientId, preview: widget.previewClient);
                            },
                          )
                        : _Body(
                            client: client!,
                            isRefreshing: isLoading,
                            errorMessage: errorMessage,
                          ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─── Header ──────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final Client? client;
  final bool isLoading;
  final VoidCallback? onEdit;

  const _Header({
    required this.client,
    required this.isLoading,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final c = client;
    return Container(
      color: AppColors.green800,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
        left: 16,
        right: 16,
        bottom: 16,
      ),
      child: Column(
        children: [
          Row(
            children: [
              InkWell(
                onTap: () => context.pop(),
                borderRadius: BorderRadius.circular(8),
                child: Row(
                  children: const [
                    Icon(Icons.arrow_back_ios_new,
                        size: 14, color: Color(0xD9FFFFFF)),
                    SizedBox(width: 4),
                    Text(
                      'Clients',
                      style: TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xD9FFFFFF),
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              _SmallHeaderButton(
                icon: Icons.edit_outlined,
                onTap: onEdit ?? () {},
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (isLoading || c == null)
            _headerSkeleton()
          else ...[
            Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.25),
                      width: 2,
                    ),
                  ),
                  child: AvatarWidget(
                    name: c.name,
                    size: 56,
                    backgroundColor: AppColors.greenDeep,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        c.name,
                        style: const TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      if (c.city != null && c.city!.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          [c.city!, if (c.state != null) c.state!].join(', '),
                          style: AppTextStyles.headerSubtitle
                              .copyWith(fontSize: 12.5),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _QuickAction(
                    icon: Icons.call_outlined,
                    label: 'Call',
                    onTap: () => ContactLauncher.call(context, c.phoneMobile)),
                const SizedBox(width: 8),
                _QuickAction(
                    icon: Icons.chat_bubble_outline,
                    label: 'Text',
                    onTap: () => ContactLauncher.text(context, c.phoneMobile)),
                const SizedBox(width: 8),
                _QuickAction(
                    icon: Icons.mail_outline,
                    label: 'Email',
                    onTap: () => ContactLauncher.email(context, c.email)),
                const SizedBox(width: 8),
                _QuickAction(
                  icon: Icons.note_add_outlined,
                  label: 'Estimate',
                  primary: true,
                  onTap: () => context.push(AppRoutes.newEstimate),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _headerSkeleton() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 18,
                    width: 160,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 12,
                    width: 100,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: List.generate(
            4,
            (_) => Expanded(
              child: Container(
                margin: const EdgeInsets.only(right: 8),
                height: 54,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(11),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Body ─────────────────────────────────────────────────────────────────────

class _Body extends StatelessWidget {
  final Client client;
  final bool isRefreshing;
  final String? errorMessage;

  const _Body({
    required this.client,
    required this.isRefreshing,
    required this.errorMessage,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 96),
      children: [
        if (errorMessage != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.orangeTint,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded,
                      size: 16, color: AppColors.orangeDeep),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Showing cached data — $errorMessage',
                      style: AppTextStyles.caption.copyWith(
                          color: AppColors.orangeDeep, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ),
        _stats(client),
        const SectionHeader(title: 'Contact'),
        _contactCard(client),
        if (client.privateNotes != null &&
            client.privateNotes!.isNotEmpty) ...[
          const SectionHeader(title: 'Notes'),
          AppCard(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 13, 16, 13),
              child: Text(
                client.privateNotes!,
                style: AppTextStyles.bodyMedium.copyWith(height: 1.5),
              ),
            ),
          ),
        ],
        SectionHeader(
          title: 'Recent documents',
          trailingWidget: TextButton(
            onPressed: () {},
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              textStyle: const TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
              ),
            ),
            child: const Text('View all'),
          ),
        ),
        _documentsEmpty(),
      ],
    );
  }

  Widget _stats(Client client) {
    return Row(
      children: [
        _StatCard(
          value: '\$0',
          label: 'Outstanding',
          valueColor: AppColors.greenDeep,
        ),
        const SizedBox(width: 10),
        _StatCard(
          value: Formatters.currencyShort(client.lifetimeValue),
          label: 'Lifetime value',
        ),
        const SizedBox(width: 10),
        _StatCard(value: '${client.jobs}', label: 'Jobs'),
      ],
    );
  }

  Widget _contactCard(Client client) {
    final items = <(IconData, String, String, IconData)>[
      if (client.email != null && client.email!.isNotEmpty)
        (Icons.mail_outline, 'Email', client.email!, Icons.copy_outlined),
      if (client.phoneMobile != null && client.phoneMobile!.isNotEmpty)
        (Icons.call_outlined, 'Mobile', client.phoneMobile!, Icons.copy_outlined),
      if (client.phoneOther != null && client.phoneOther!.isNotEmpty)
        (Icons.call_outlined, 'Other', client.phoneOther!, Icons.copy_outlined),
      if (client.billingAddress.isNotEmpty)
        (Icons.place_outlined, 'Billing address', client.billingAddress, Icons.chevron_right),
    ];

    if (items.isEmpty) {
      return AppCard(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Text('No contact info on file', style: AppTextStyles.caption),
        ),
      );
    }

    return AppCard(
      child: Column(
        children: [
          for (var i = 0; i < items.length; i++)
            _ContactRow(
              icon: items[i].$1,
              label: items[i].$2,
              value: items[i].$3,
              actionIcon: items[i].$4,
              showDivider: i < items.length - 1,
            ),
        ],
      ),
    );
  }

  Widget _documentsEmpty() {
    return AppCard(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 28),
        child: Column(
          children: [
            const Icon(Icons.description_outlined,
                size: 32, color: AppColors.inkFaint),
            const SizedBox(height: 10),
            Text(
              'No documents yet',
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.inkSoft),
            ),
            const SizedBox(height: 4),
            Text(
              'Estimates and invoices will appear here.',
              textAlign: TextAlign.center,
              style:
                  AppTextStyles.caption.copyWith(fontSize: 12, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}


// ─── Reusable sub-widgets ─────────────────────────────────────────────────────

class _SmallHeaderButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _SmallHeaderButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: SizedBox(
          width: 34,
          height: 34,
          child: Icon(icon, size: 17, color: Colors.white),
        ),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool primary;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.primary = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: primary
            ? AppColors.orange500
            : Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(11),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(11),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(4, 10, 4, 8),
            child: Column(
              children: [
                Icon(icon, size: 18, color: Colors.white),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: const TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  final Color? valueColor;

  const _StatCard({required this.value, required this.label, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: AppColors.card,
          border: Border.all(color: AppColors.line),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontSize: 17,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.2,
                color: valueColor ?? AppColors.ink,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.inkFaint,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ContactRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final IconData actionIcon;
  final bool showDivider;

  const _ContactRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.actionIcon,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: showDivider
            ? const Border(bottom: BorderSide(color: AppColors.line))
            : null,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppColors.grayTint,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 16, color: AppColors.inkSoft),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.inkFaint,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.labelMedium.copyWith(fontSize: 14),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: Icon(actionIcon, size: 16, color: AppColors.inkFaint),
          ),
        ],
      ),
    );
  }
}
