import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_error_widget.dart';
import '../../../core/widgets/app_fab.dart';
import '../../../core/widgets/loading_overlay.dart';
import '../../../core/widgets/main_shell.dart';
import '../../../core/widgets/pill_tabs.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../core/widgets/tip_banner.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../bloc/estimate_bloc.dart';
import '../models/estimate_model.dart';

class EstimateListScreen extends StatefulWidget {
  const EstimateListScreen({super.key});

  @override
  State<EstimateListScreen> createState() => _EstimateListScreenState();
}

class _EstimateListScreenState extends State<EstimateListScreen> {
  int _tabIndex = 0;
  String _search = '';
  bool _hasFetched = false;
  late final GoRouter _goRouter;

  static const _tabOrder = [
    EstimateTab.pending,
    EstimateTab.approved,
    EstimateTab.declined,
  ];

  @override
  void initState() {
    super.initState();
    _goRouter = GoRouter.of(context);
    _goRouter.routeInformationProvider.addListener(_onRouteChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchOnce());
  }

  @override
  void dispose() {
    _goRouter.routeInformationProvider.removeListener(_onRouteChanged);
    super.dispose();
  }

  void _onRouteChanged() {
    final path = _goRouter.routeInformationProvider.value.uri.path;
    if (path == AppRoutes.estimates) _refresh();
  }

  void _fetchOnce() {
    if (_hasFetched) return;
    final proId = _proId;
    if (proId == null) return;
    _hasFetched = true;
    context.read<EstimateBloc>().add(EstimatesFetchRequested(proId));
  }

  void _refresh() {
    final proId = _proId;
    if (proId == null) return;
    context.read<EstimateBloc>().add(EstimatesFetchRequested(proId));
  }

  Future<void> _handleRefresh() async {
    _refresh();
    try {
      await context
          .read<EstimateBloc>()
          .stream
          .firstWhere((s) => s is EstimatesLoaded || s is EstimatesError)
          .timeout(const Duration(seconds: 15));
    } catch (_) {}
  }

  int? get _proId {
    final authState = context.read<AuthBloc>().state;
    return authState is AuthAuthenticated ? authState.user.proId : null;
  }

  List<EstimateSummary> _filtered(List<EstimateSummary> all) {
    final q = _search.trim().toLowerCase();
    return all
        .where((e) =>
            e.tab == _tabOrder[_tabIndex] &&
            (q.isEmpty ||
                e.clientName.toLowerCase().contains(q) ||
                e.number.toString().contains(q) ||
                (e.amount?.toStringAsFixed(0).contains(q) ?? false)))
        .toList();
  }

  int _count(List<EstimateSummary> all, EstimateTab tab) =>
      all.where((e) => e.tab == tab).length;

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listenWhen: (_, curr) => curr is AuthAuthenticated,
      listener: (context, _) => _fetchOnce(),
      child: _buildContent(),
    );
  }

  Widget _buildContent() {
    return BlocConsumer<EstimateBloc, EstimatesState>(
      listenWhen: (_, curr) => curr is EstimateMutateFailure,
      listener: (context, state) {
        if (state is EstimateMutateFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.orangeDeep,
            ),
          );
        }
      },
      builder: (context, state) {
        final estimates = switch (state) {
          EstimatesLoaded(:final estimates) => estimates,
          EstimateMutating(:final estimates) => estimates,
          EstimateMutateSuccess(:final estimates) => estimates,
          EstimateMutateFailure(:final estimates) => estimates,
          _ => const <EstimateSummary>[],
        };
        final isLoading =
            state is EstimatesLoading || state is EstimatesInitial;
        final errorMessage = state is EstimatesError ? state.message : null;

        if (!isLoading &&
            errorMessage == null &&
            estimates.isEmpty &&
            _search.trim().isEmpty) {
          return const _EstimatesWelcomeView();
        }

        final pending = estimates
            .where((e) => e.tab == EstimateTab.pending && e.amount != null)
            .toList();
        final pendingTotal =
            pending.fold<double>(0, (sum, e) => sum + (e.amount ?? 0));

        return Scaffold(
          body: Column(
            children: [
              AppHeader(
                title: 'Estimates',
                subtitle: '${pending.length} pending · ',
                subtitleSpans: [
                  TextSpan(
                    text: Formatters.currencyShort(pendingTotal),
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w700),
                  ),
                  const TextSpan(text: ' awaiting approval'),
                ],
                actions: [const NotificationBellButton()],
                bottom: HeaderSearchBar(
                  hint: 'Search client, number, or amount',
                  onChanged: (v) => setState(() => _search = v),
                ),
              ),
              PillTabs(
                tabs: [
                  PillTab('Pending',
                      count: _count(estimates, EstimateTab.pending)),
                  PillTab('Approved',
                      count: _count(estimates, EstimateTab.approved)),
                  PillTab('Declined',
                      count: _count(estimates, EstimateTab.declined)),
                ],
                selectedIndex: _tabIndex,
                onChanged: (i) => setState(() => _tabIndex = i),
              ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _handleRefresh,
                  color: AppColors.orange500,
                  child: isLoading && estimates.isEmpty
                      ? const Center(child: CircularProgressIndicator())
                      : errorMessage != null && estimates.isEmpty
                          ? AppErrorWidget(
                              message: errorMessage, onRetry: _refresh, scrollable: true)
                          : _list(estimates),
                ),
              ),
            ],
          ),
          floatingActionButton: AppFab(
            label: 'New estimate',
            onPressed: () => context.push(AppRoutes.newEstimate),
          ),
        );
      },
    );
  }

  Widget _list(List<EstimateSummary> all) {
    final rows = _filtered(all);
    if (rows.isEmpty) {
      final searching = _search.trim().isNotEmpty;
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 80),
          EmptyState(
            title: searching ? 'No matches' : 'Nothing here yet',
            description: searching
                ? 'Try a different name or number.'
                : 'Estimates you ${_tabIndex == 0 ? 'send' : 'move here'} will show up in this tab.',
          ),
        ],
      );
    }

    final children = <Widget>[];
    String? lastMonth;
    for (final e in rows) {
      final month = Formatters.monthYear(e.date);
      if (month != lastMonth) {
        children.add(_MonthHeader(label: month));
        lastMonth = month;
      }
      children.add(_EstimateRow(
        estimate: e,
        onTap: () => context.push('/estimates/${e.id}'),
      ));
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 96),
      children: children,
    );
  }
}


class _MonthHeader extends StatelessWidget {
  final String label;
  const _MonthHeader({required this.label});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
        child: Text(label.toUpperCase(), style: AppTextStyles.sectionLabel),
      );
}

class _EstimateRow extends StatelessWidget {
  final EstimateSummary estimate;
  final VoidCallback onTap;
  const _EstimateRow({required this.estimate, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.card,
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: AppColors.line)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      estimate.clientName,
                      style: AppTextStyles.rowTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${Formatters.dateShort(estimate.date)} · #${estimate.number}',
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    estimate.amount == null
                        ? '—'
                        : Formatters.currency(estimate.amount!),
                    style: AppTextStyles.rowAmount,
                  ),
                  const SizedBox(height: 5),
                  StatusChip(
                      status: estimate.docStatus, label: estimate.statusNote),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// First-run state of the Estimates tab: welcome message,
/// getting-started checklist, and free-plan tip.
class _EstimatesWelcomeView extends StatefulWidget {
  const _EstimatesWelcomeView();

  @override
  State<_EstimatesWelcomeView> createState() => _EstimatesWelcomeViewState();
}

class _EstimatesWelcomeViewState extends State<_EstimatesWelcomeView> {
  final _done = <String>{'account'};

  static const _steps = [
    (
      key: 'account',
      icon: Icons.check,
      title: 'Create your account',
      sub: "Done — you're in.",
    ),
    (
      key: 'details',
      icon: Icons.home_outlined,
      title: 'Add your business details',
      sub: 'Your name, logo, and trade appear on every document you send.',
    ),
    (
      key: 'estimate',
      icon: Icons.description_outlined,
      title: 'Send your first estimate',
      sub: 'Clients can approve it on the spot from their phone.',
    ),
    (
      key: 'verify',
      icon: Icons.verified_user_outlined,
      title: 'Get Serdefied',
      sub: 'Verify your license to earn the trust badge homeowners look for.',
    ),
  ];

  void _openStep(String key) {
    switch (key) {
      case 'details':
        context.push(AppRoutes.companyProfile);
      case 'estimate':
        context.push(AppRoutes.newEstimate);
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          AppHeader(
            title: 'Estimates',
            subtitle: "Let's get you set up",
            actions: [
              const NotificationBellButton(),
            ],
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(bottom: 88),
              children: [
                const SizedBox(height: 36),
                _welcomeHero(context),
                const SizedBox(height: 30),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: SectionHeader(
                    title: 'Getting started',
                    trailing: '${_done.length} of ${_steps.length} done',
                    padding: const EdgeInsets.only(bottom: 10),
                  ),
                ),
                for (final step in _steps)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                    child: _StepCard(
                      icon: step.icon,
                      title: step.title,
                      sub: step.sub,
                      done: _done.contains(step.key),
                      onTap: () => _openStep(step.key),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                  child: TipBanner(
                    spans: const [
                      TextSpan(
                        text: 'Free plan: ',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      TextSpan(
                        text:
                            'you can send 3 estimates and invoices per month. No card needed to start.',
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

  Widget _welcomeHero(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        children: [
          SizedBox(
            width: 84,
            height: 84,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    color: AppColors.greenTint,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(Icons.description_outlined,
                      size: 34, color: AppColors.greenDeep),
                ),
                Positioned(
                  bottom: 4,
                  right: 4,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: AppColors.orange500,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.page, width: 3),
                    ),
                    child: const Icon(Icons.add, size: 13, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          const Text('Welcome to Serden', style: AppTextStyles.headingMedium),
          const SizedBox(height: 8),
          Text(
            'Send your first professional estimate in under two minutes — right from the jobsite.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.inkSoft),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => context.push(AppRoutes.newEstimate),
            style: ElevatedButton.styleFrom(
              minimumSize: Size.zero,
              padding:
                  const EdgeInsets.symmetric(horizontal: 26, vertical: 15),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Text('Create your first estimate'),
                SizedBox(width: 8),
                Icon(Icons.arrow_forward, size: 17),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StepCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String sub;
  final bool done;
  final VoidCallback onTap;

  const _StepCard({
    required this.icon,
    required this.title,
    required this.sub,
    required this.done,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.line),
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: done ? AppColors.greenDeep : AppColors.greenTint,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(
                  done ? Icons.check : icon,
                  size: 18,
                  color: done ? Colors.white : AppColors.greenDeep,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: done ? AppColors.inkFaint : AppColors.ink,
                        decoration: done ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      sub,
                      style: AppTextStyles.caption.copyWith(height: 1.4),
                    ),
                  ],
                ),
              ),
              if (!done) ...[
                const SizedBox(width: 8),
                const Icon(Icons.chevron_right,
                    size: 18, color: AppColors.inkFaint),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
