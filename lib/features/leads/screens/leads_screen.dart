import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_fab.dart';
import '../../../core/widgets/loading_overlay.dart';
import '../../../core/widgets/main_shell.dart';
import '../../../core/widgets/pill_tabs.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../bloc/lead_bloc.dart';
import '../models/lead_model.dart';

class LeadsScreen extends StatefulWidget {
  const LeadsScreen({super.key});

  @override
  State<LeadsScreen> createState() => _LeadsScreenState();
}

class _LeadsScreenState extends State<LeadsScreen>
    with WidgetsBindingObserver {
  int _tabIndex = 0;
  String _search = '';
  int? _userId;
  final _scrollController = ScrollController();
  DateTime? _backgroundedAt;
  late final GoRouter _goRouter;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _goRouter = GoRouter.of(context);
    _goRouter.routeInformationProvider.addListener(_onRouteChanged);
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      _userId = authState.user.userId;
      context.read<LeadBloc>().add(LeadsFetchRequested(_userId!));
    }
    _scrollController.addListener(_onScroll);
  }

  // Fires on every route change. Refresh whenever the leads list
  // becomes the active screen (tab switch OR returning from add/detail).
  void _onRouteChanged() {
    final path = _goRouter.routeInformationProvider.value.uri.path;
    if (path == AppRoutes.leads) _refresh();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _backgroundedAt = DateTime.now();
    } else if (state == AppLifecycleState.resumed) {
      final bg = _backgroundedAt;
      _backgroundedAt = null;
      if (bg != null && DateTime.now().difference(bg) > const Duration(minutes: 2)) {
        _refresh();
      }
    }
  }

  void _refresh() {
    final uid = _userId;
    if (uid == null) return;
    context.read<LeadBloc>().add(LeadsFetchRequested(uid));
  }

  Future<void> _handleRefresh() async {
    _refresh();
    try {
      await context
          .read<LeadBloc>()
          .stream
          .firstWhere((s) => s is LeadsLoaded || s is LeadsError)
          .timeout(const Duration(seconds: 15));
    } catch (_) {
      // Timeout — dismiss spinner anyway
    }
  }

  @override
  void dispose() {
    _goRouter.routeInformationProvider.removeListener(_onRouteChanged);
    WidgetsBinding.instance.removeObserver(this);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final uid = _userId;
    if (uid == null) return;
    final pos = _scrollController.position;
    if (pos.pixels >= pos.maxScrollExtent - 200) {
      context.read<LeadBloc>().add(LeadsLoadMoreRequested(uid));
    }
  }

  bool _inTab(Lead lead, int tab) => switch (tab) {
        0 => lead.status == LeadStatus.newLead,
        1 =>
          lead.status == LeadStatus.contacted ||
              lead.status == LeadStatus.quoted,
        2 => lead.status == LeadStatus.won,
        _ => true,
      };

  List<Lead> _filtered(List<Lead> leads) {
    final q = _search.trim().toLowerCase();
    return leads
        .where((l) =>
            _inTab(l, _tabIndex) &&
            (q.isEmpty ||
                l.fullName.toLowerCase().contains(q) ||
                (l.requestText?.toLowerCase().contains(q) ?? false) ||
                l.place.toLowerCase().contains(q)))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listenWhen: (_, curr) => curr is AuthAuthenticated,
      listener: (context, state) {
        if (state is AuthAuthenticated) {
          context
              .read<LeadBloc>()
              .add(LeadsFetchRequested(state.user.userId));
        }
      },
      child: BlocBuilder<LeadBloc, LeadsState>(
        builder: (context, state) {
          final leads = switch (state) {
            LeadsLoaded(:final leads) => leads,
            LeadCreating(:final leads) => leads,
            LeadCreateSuccess(:final leads) => leads,
            LeadCreateFailure(:final leads) => leads,
            LeadUpdateInProgress(:final leads) => leads,
            LeadUpdateSuccess(:final leads) => leads,
            LeadUpdateFailure(:final leads) => leads,
            LeadDeleteInProgress(:final leads) => leads,
            LeadDeleteSuccess(:final leads) => leads,
            LeadDeleteFailure(:final leads) => leads,
            _ => const <Lead>[],
          };

          final isLoading = state is LeadsLoading;
          final isLoadingMore =
              state is LeadsLoaded && state.isLoadingMore;
          final newCount =
              leads.where((l) => l.status == LeadStatus.newLead).length;

          return Scaffold(
            body: Column(
              children: [
                AppHeader(
                  title: 'Leads',
                  subtitleSpans: newCount > 0
                      ? [
                          TextSpan(
                            text: '$newCount new',
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700),
                          ),
                          const TextSpan(text: ' · reply fast to win the job'),
                        ]
                      : [
                          const TextSpan(
                              text: 'All caught up — nothing waiting on you'),
                        ],
                  actions: [const NotificationBellButton()],
                  bottom: HeaderSearchBar(
                    hint: 'Search name, project, or city',
                    onChanged: (v) => setState(() => _search = v),
                  ),
                ),
                PillTabs(
                  tabs: [
                    PillTab('New',
                        count: leads.where((l) => _inTab(l, 0)).length,
                        activeColor: AppColors.orange500),
                    PillTab('Working',
                        count: leads.where((l) => _inTab(l, 1)).length),
                    PillTab('Won',
                        count: leads.where((l) => _inTab(l, 2)).length),
                    PillTab('All', count: leads.length),
                  ],
                  selectedIndex: _tabIndex,
                  onChanged: (i) => setState(() => _tabIndex = i),
                ),
                Expanded(
                  child: isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : state is LeadsError
                          ? _ErrorView(
                              message: state.message,
                              onRetry: () {
                                final authState =
                                    context.read<AuthBloc>().state;
                                if (authState is AuthAuthenticated) {
                                  context.read<LeadBloc>().add(
                                      LeadsFetchRequested(
                                          authState.user.userId));
                                }
                              },
                            )
                          : _list(_filtered(leads),
                              isLoadingMore: isLoadingMore),
                ),
              ],
            ),
            floatingActionButton: AppFab(
              label: 'Add lead',
              onPressed: () => context.push(AppRoutes.addLead),
            ),
          );
        },
      ),
    );
  }

  Widget _list(List<Lead> rows, {required bool isLoadingMore}) {
    if (rows.isEmpty && !isLoadingMore) {
      final searching = _search.trim().isNotEmpty;
      return EmptyState(
        title: searching
            ? 'No matches'
            : (_tabIndex == 0 ? 'No new leads right now' : 'Nothing here yet'),
        description: searching
            ? 'Try a different name, project, or city.'
            : (_tabIndex == 0
                ? 'New requests from homeowners near you will land here.'
                : 'Leads in this stage will show up here.'),
      );
    }

    final itemCount = rows.length + (isLoadingMore ? 1 : 0);
    return RefreshIndicator(
      onRefresh: _handleRefresh,
      color: AppColors.orange500,
      child: ListView.builder(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 96),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        if (index == rows.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        return _LeadRow(
          lead: rows[index],
          onTap: () => context.push(
            AppRoutes.leadDetail
                .replaceFirst(':id', rows[index].requestId.toString()),
            extra: rows[index],
          ),
        );
      },
      ),
    ); // RefreshIndicator
  }
}

// ─── Error view ──────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_outlined,
                size: 48, color: AppColors.inkFaint),
            const SizedBox(height: 16),
            Text(message,
                textAlign: TextAlign.center,
                style:
                    AppTextStyles.bodyMedium.copyWith(color: AppColors.inkSoft)),
            const SizedBox(height: 20),
            TextButton(onPressed: onRetry, child: const Text('Try again')),
          ],
        ),
      ),
    );
  }
}

// ─── Lead row ────────────────────────────────────────────────────────────────

class _LeadRow extends StatelessWidget {
  final Lead lead;
  final VoidCallback onTap;

  const _LeadRow({required this.lead, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isNew = lead.status == LeadStatus.newLead;
    return Material(
      color: AppColors.card,
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              bottom: const BorderSide(color: AppColors.line),
              left: isNew
                  ? const BorderSide(color: AppColors.orange500, width: 3)
                  : BorderSide.none,
            ),
          ),
          padding: EdgeInsets.fromLTRB(isNew ? 17 : 20, 14, 20, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Expanded(
                    child: Text(
                      lead.fullName,
                      style: AppTextStyles.rowTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    lead.timeDisplay,
                    style: TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: lead.isFresh
                          ? AppColors.orangeDeep
                          : AppColors.inkFaint,
                    ),
                  ),
                ],
              ),
              if (lead.requestText != null && lead.requestText!.isNotEmpty) ...[
                const SizedBox(height: 3),
                Text(
                  lead.requestText!,
                  style: AppTextStyles.bodySmall
                      .copyWith(fontSize: 13.5, color: AppColors.inkSoft),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              if (lead.place.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(lead.place, style: AppTextStyles.caption),
              ],
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _statusChip(lead.status),
                  Row(
                    children: [
                      _QuickButton(
                          icon: Icons.call_outlined, onTap: () {}),
                      const SizedBox(width: 8),
                      _QuickButton(
                          icon: Icons.chat_bubble_outline, onTap: () {}),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statusChip(LeadStatus status) {
    final (bg, fg, icon, label) = switch (status) {
      LeadStatus.newLead => (
          AppColors.orangeTint,
          AppColors.orangeDeep,
          Icons.bolt_outlined,
          'New — reach out'
        ),
      LeadStatus.contacted => (
          AppColors.grayTint,
          AppColors.grayDeep,
          Icons.chat_bubble_outline,
          'Contacted'
        ),
      LeadStatus.quoted => (
          AppColors.greenTint,
          AppColors.greenDeep,
          Icons.send_outlined,
          'Estimate sent'
        ),
      LeadStatus.won => (
          AppColors.greenDeep,
          Colors.white,
          Icons.check,
          'Won'
        ),
      LeadStatus.lost => (
          AppColors.redTint,
          AppColors.redDeep,
          Icons.close,
          'Lost'
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: fg),
          const SizedBox(width: 4),
          Text(label, style: AppTextStyles.chip.copyWith(color: fg)),
        ],
      ),
    );
  }
}

class _QuickButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _QuickButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.greenTint,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: SizedBox(
          width: 34,
          height: 34,
          child: Icon(icon, size: 16, color: AppColors.greenDeep),
        ),
      ),
    );
  }
}
