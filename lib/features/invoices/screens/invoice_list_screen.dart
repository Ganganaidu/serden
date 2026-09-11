import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_fab.dart';
import '../../../core/widgets/loading_overlay.dart';
import '../../../core/widgets/main_shell.dart';
import '../../../core/widgets/pill_tabs.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../core/widgets/tip_banner.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../bloc/invoice_bloc.dart';
import '../models/invoice_model.dart';

class InvoiceListScreen extends StatefulWidget {
  const InvoiceListScreen({super.key});

  @override
  State<InvoiceListScreen> createState() => _InvoiceListScreenState();
}

class _InvoiceListScreenState extends State<InvoiceListScreen> {
  int _tabIndex = 0;
  String _search = '';
  bool _hasFetched = false;
  late final GoRouter _goRouter;

  static const _tabOrder = [
    InvoiceTab.active,
    InvoiceTab.overdue,
    InvoiceTab.paid,
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
    if (path == AppRoutes.invoices) _refresh();
  }

  void _fetchOnce() {
    if (_hasFetched) return;
    final proId = _proId;
    if (proId == null) return;
    _hasFetched = true;
    context.read<InvoiceBloc>().add(InvoicesFetchRequested(proId));
  }

  void _refresh() {
    final proId = _proId;
    if (proId == null) return;
    context.read<InvoiceBloc>().add(InvoicesFetchRequested(proId));
  }

  Future<void> _handleRefresh() async {
    _refresh();
    try {
      await context
          .read<InvoiceBloc>()
          .stream
          .firstWhere((s) => s is InvoicesLoaded || s is InvoicesError)
          .timeout(const Duration(seconds: 15));
    } catch (_) {}
  }

  int? get _proId {
    final authState = context.read<AuthBloc>().state;
    return authState is AuthAuthenticated ? authState.user.proId : null;
  }

  List<InvoiceSummary> _filtered(List<InvoiceSummary> all) {
    final q = _search.trim().toLowerCase();
    return all
        .where((i) =>
            i.tab == _tabOrder[_tabIndex] &&
            (q.isEmpty ||
                i.clientName.toLowerCase().contains(q) ||
                i.number.toString().contains(q) ||
                (i.total.toStringAsFixed(0).contains(q))))
        .toList();
  }

  int _count(List<InvoiceSummary> all, InvoiceTab tab) =>
      all.where((i) => i.tab == tab).length;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<InvoiceBloc, InvoicesState>(
      builder: (context, state) {
        if (state is InvoicesInitial || state is InvoicesLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (state is InvoicesError) {
          return Scaffold(
            body: Column(
              children: [
                AppHeader(
                  title: 'Invoices',
                  actions: [const NotificationBellButton()],
                ),
                Expanded(
                  child: EmptyState(
                    title: 'Could not load invoices',
                    description: state.message,
                  ),
                ),
              ],
            ),
          );
        }

        final invoices = switch (state) {
          InvoicesLoaded(:final invoices) => invoices,
          InvoiceMutating(:final invoices) => invoices,
          InvoiceMutateSuccess(:final invoices) => invoices,
          InvoiceMutateFailure(:final invoices) => invoices,
          _ => <InvoiceSummary>[],
        };

        if (invoices.isEmpty) return const _InvoicesEmptyView();

        final open = invoices
            .where((i) =>
                i.tab == InvoiceTab.active || i.tab == InvoiceTab.overdue)
            .toList();
        final outstanding =
            open.fold<double>(0, (sum, i) => sum + i.balance);
        final overdueAmt = invoices
            .where((i) => i.tab == InvoiceTab.overdue)
            .fold<double>(0, (sum, i) => sum + i.balance);

        return Scaffold(
          body: RefreshIndicator(
            onRefresh: _handleRefresh,
            color: AppColors.primary,
            child: Column(
              children: [
                AppHeader(
                  title: 'Invoices',
                  subtitleSpans: [
                    TextSpan(
                      text: Formatters.currencyShort(outstanding),
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w700),
                    ),
                    const TextSpan(text: ' outstanding'),
                    if (overdueAmt > 0) ...[
                      const TextSpan(text: ' · '),
                      TextSpan(
                        text:
                            '${Formatters.currencyShort(overdueAmt)} overdue',
                        style: const TextStyle(
                          color: AppColors.overdueOnHeader,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ],
                  actions: [const NotificationBellButton()],
                  bottom: HeaderSearchBar(
                    hint: 'Search client, number, or amount',
                    onChanged: (v) => setState(() => _search = v),
                  ),
                ),
                PillTabs(
                  tabs: [
                    PillTab('Active',
                        count: _count(invoices, InvoiceTab.active)),
                    PillTab('Overdue',
                        count: _count(invoices, InvoiceTab.overdue),
                        activeColor: AppColors.redDeep),
                    PillTab('Paid',
                        count: _count(invoices, InvoiceTab.paid)),
                  ],
                  selectedIndex: _tabIndex,
                  onChanged: (i) => setState(() => _tabIndex = i),
                ),
                Expanded(child: _list(invoices)),
              ],
            ),
          ),
          floatingActionButton: AppFab(
            label: 'New invoice',
            onPressed: () => context.push(AppRoutes.newInvoice),
          ),
        );
      },
    );
  }

  Widget _list(List<InvoiceSummary> all) {
    final rows = _filtered(all);
    if (rows.isEmpty) {
      final searching = _search.trim().isNotEmpty;
      return EmptyState(
        title: searching
            ? 'No matches'
            : (_tabIndex == 1 ? 'Nothing overdue' : 'Nothing here yet'),
        description: searching
            ? 'Try a different name or number.'
            : (_tabIndex == 1
                ? 'Nice — every client is paying on time.'
                : 'Invoices in this state will show up here.'),
      );
    }

    final children = <Widget>[];
    String? lastMonth;
    for (final invoice in rows) {
      final month = Formatters.monthYear(invoice.date);
      if (month != lastMonth) {
        final monthTotal = rows
            .where((r) => Formatters.monthYear(r.date) == month)
            .fold<double>(0, (sum, r) => sum + r.total);
        children.add(_MonthHeader(
          label: month,
          total: Formatters.currencyShort(monthTotal),
        ));
        lastMonth = month;
      }
      children.add(_InvoiceRow(
        invoice: invoice,
        onTap: () => context.push('/invoices/${invoice.id}'),
      ));
    }

    return ListView(
      padding: const EdgeInsets.only(bottom: 96),
      children: children,
    );
  }
}

class _MonthHeader extends StatelessWidget {
  final String label;
  final String total;
  const _MonthHeader({required this.label, required this.total});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label.toUpperCase(), style: AppTextStyles.sectionLabel),
            Text(
              total,
              style:
                  AppTextStyles.caption.copyWith(fontWeight: FontWeight.w700),
            ),
          ],
        ),
      );
}

class _InvoiceRow extends StatelessWidget {
  final InvoiceSummary invoice;
  final VoidCallback onTap;
  const _InvoiceRow({required this.invoice, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isOverdue = invoice.isOverdue;
    final chipStatus =
        isOverdue ? DocumentStatus.overdue : invoice.docStatus;
    final chipLabel = isOverdue ? 'Overdue' : invoice.statusNote;

    return Material(
      color: AppColors.card,
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              bottom: const BorderSide(color: AppColors.line),
              left: isOverdue
                  ? const BorderSide(color: AppColors.redDeep, width: 3)
                  : BorderSide.none,
            ),
          ),
          padding:
              EdgeInsets.fromLTRB(isOverdue ? 17 : 20, 14, 20, 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      invoice.clientName,
                      style: AppTextStyles.rowTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text.rich(
                      TextSpan(
                        text:
                            '${Formatters.dateShort(invoice.date)} · #${invoice.number}',
                        children: [
                          if (invoice.dueNote.isNotEmpty) ...[
                            const TextSpan(text: ' · '),
                            TextSpan(
                              text: invoice.dueNote,
                              style: isOverdue
                                  ? const TextStyle(
                                      color: AppColors.redDeep,
                                      fontWeight: FontWeight.w700,
                                    )
                                  : null,
                            ),
                          ],
                        ],
                      ),
                      style: AppTextStyles.caption,
                    ),
                    if (invoice.isPartial) ...[
                      const SizedBox(height: 8),
                      SizedBox(
                        width: 150,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(2),
                          child: LinearProgressIndicator(
                            value: invoice.paidAmount / invoice.total,
                            minHeight: 4,
                            backgroundColor: AppColors.grayTint,
                            color: AppColors.greenDeep,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    Formatters.currency(
                        invoice.isPaid ? invoice.total : invoice.balance),
                    style: AppTextStyles.rowAmount,
                  ),
                  if (invoice.isPartial) ...[
                    const SizedBox(height: 2),
                    Text(
                      'of ${Formatters.currencyShort(invoice.total)} · ${invoice.paidPercent}% paid',
                      style: AppTextStyles.caption.copyWith(fontSize: 11.5),
                    ),
                  ],
                  const SizedBox(height: 5),
                  StatusChip(status: chipStatus, label: chipLabel),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Empty state for the Invoices tab (serden-invoices-empty design).
class _InvoicesEmptyView extends StatelessWidget {
  const _InvoicesEmptyView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          AppHeader(
            title: 'Invoices',
            subtitle: "Get paid for the work you've done",
            actions: [
              const NotificationBellButton(),
            ],
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(bottom: 88),
              children: [
                const SizedBox(height: 48),
                _hero(context),
                const SizedBox(height: 26),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _howItWorks(),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 26, 20, 0),
                  child: TipBanner(
                    spans: const [
                      TextSpan(
                        text: 'Save a step: ',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      TextSpan(
                        text:
                            'turn on auto-generate invoice when sending an estimate, and the invoice creates itself the moment your client approves.',
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

  Widget _hero(BuildContext context) {
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
                  child: const Icon(Icons.receipt_long_outlined,
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
                    child: const Icon(Icons.attach_money,
                        size: 14, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          const Text('No invoices yet', style: AppTextStyles.headingMedium),
          const SizedBox(height: 8),
          Text(
            'Turn finished work into money — send an invoice your client can pay online in one tap.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.inkSoft),
          ),
          const SizedBox(height: 22),
          ElevatedButton(
            onPressed: () => context.push(AppRoutes.newInvoice),
            style: ElevatedButton.styleFrom(
              minimumSize: Size.zero,
              padding:
                  const EdgeInsets.symmetric(horizontal: 26, vertical: 15),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Create an invoice'),
                SizedBox(width: 8),
                Icon(Icons.arrow_forward, size: 17),
              ],
            ),
          ),
          TextButton(
            onPressed: () {},
            child: const Text('Convert an approved estimate'),
          ),
        ],
      ),
    );
  }

  Widget _howItWorks() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            title: 'How it works',
            padding: EdgeInsets.only(bottom: 12),
          ),
          const Row(
            children: [
              _FlowStep(
                  icon: Icons.description_outlined,
                  label: 'Build it in minutes'),
              _FlowArrow(),
              _FlowStep(
                  icon: Icons.send_outlined, label: 'Send from the jobsite'),
              _FlowArrow(),
              _FlowStep(
                  icon: Icons.credit_card_outlined,
                  label: 'Client pays online'),
            ],
          ),
        ],
      ),
    );
  }
}

class _FlowStep extends StatelessWidget {
  final IconData icon;
  final String label;
  const _FlowStep({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.greenTint,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, size: 18, color: AppColors.greenDeep),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              height: 1.3,
              color: AppColors.inkSoft,
            ),
          ),
        ],
      ),
    );
  }
}

class _FlowArrow extends StatelessWidget {
  const _FlowArrow();

  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsets.symmetric(horizontal: 3),
        child: Icon(Icons.arrow_forward, size: 14, color: AppColors.inkFaint),
      );
}
