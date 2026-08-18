import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_fab.dart';
import '../../../core/widgets/loading_overlay.dart';
import '../../../core/widgets/main_shell.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../items/cubit/markups_cubit.dart';
import '../../items/models/markup_template.dart';
import '../../items/screens/markup_form_sheet.dart';

class MarkupsScreen extends StatefulWidget {
  const MarkupsScreen({super.key});

  @override
  State<MarkupsScreen> createState() => _MarkupsScreenState();
}

class _MarkupsScreenState extends State<MarkupsScreen>
    with WidgetsBindingObserver {
  String _search = '';
  DateTime? _backgroundedAt;

  int? get _proId {
    final auth = context.read<AuthBloc>().state;
    return auth is AuthAuthenticated ? auth.user.proId : null;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final proId = _proId;
    if (proId != null) context.read<MarkupsCubit>().fetch(proId);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _backgroundedAt = DateTime.now();
    } else if (state == AppLifecycleState.resumed) {
      final bg = _backgroundedAt;
      _backgroundedAt = null;
      if (bg != null &&
          DateTime.now().difference(bg) > const Duration(minutes: 2)) {
        _refresh();
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _refresh() {
    final proId = _proId;
    if (proId != null) context.read<MarkupsCubit>().fetch(proId);
  }

  Future<void> _handleRefresh() async {
    _refresh();
    try {
      await context
          .read<MarkupsCubit>()
          .stream
          .firstWhere((s) => s is MarkupsLoaded || s is MarkupsError)
          .timeout(const Duration(seconds: 15));
    } catch (_) {}
  }

  List<MarkupTemplate> _filtered(List<MarkupTemplate> markups) {
    final q = _search.trim().toLowerCase();
    if (q.isEmpty) return markups;
    return markups.where((m) => m.name.toLowerCase().contains(q)).toList();
  }

  Future<void> _openSheet({MarkupTemplate? template}) async {
    final proId = _proId;
    if (proId == null) return;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => BlocProvider.value(
        value: context.read<MarkupsCubit>(),
        child: MarkupFormSheet(proId: proId, template: template),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MarkupsCubit, MarkupsState>(
      builder: (context, state) {
        final markups =
            state is MarkupsLoaded ? state.templates : <MarkupTemplate>[];
        final filtered = _filtered(markups);

        return Scaffold(
          backgroundColor: AppColors.page,
          body: Column(
            children: [
              // ── Header ──────────────────────────────────────────────────
              Container(
                color: AppColors.green800,
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top + 6,
                  left: 20,
                  right: 20,
                  bottom: 18,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    InkWell(
                      onTap: () => context.pop(),
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.arrow_back_ios_new,
                                size: 14, color: Color(0xCCFFFFFF)),
                            SizedBox(width: 4),
                            Text(
                              'Settings',
                              style: TextStyle(
                                fontFamily: AppTextStyles.fontFamily,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color(0xCCFFFFFF),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text('Line Item Markup',
                        style: AppTextStyles.headerTitle),
                    const SizedBox(height: 3),
                    Text(
                      state is MarkupsLoaded
                          ? '${markups.length} ${markups.length == 1 ? 'markup' : 'markups'} saved'
                          : 'Manage your markup templates',
                      style: AppTextStyles.headerSubtitle,
                    ),
                    HeaderSearchBar(
                      hint: 'Search markups',
                      onChanged: (v) => setState(() => _search = v),
                    ),
                  ],
                ),
              ),

              // ── Body ────────────────────────────────────────────────────
              Expanded(child: _body(context, state, filtered)),
            ],
          ),
          floatingActionButton: AppFab(
            label: 'New markup',
            onPressed: () => _openSheet(),
          ),
        );
      },
    );
  }

  Widget _body(BuildContext context, MarkupsState state,
      List<MarkupTemplate> filtered) {
    if (state is MarkupsLoading || state is MarkupsInitial) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state is MarkupsError) {
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
                onPressed: _refresh,
                child: const Text('Try again'),
              ),
            ],
          ),
        ),
      );
    }

    if (state is MarkupsLoaded && state.templates.isEmpty) {
      return const EmptyState(
        title: 'No markups yet',
        description:
            'Add markup templates here — apply them to line items on any estimate or invoice.',
        icon: Icons.percent_outlined,
      );
    }

    if (filtered.isEmpty) {
      return const EmptyState(
        title: 'No matches',
        description: 'Try a different search term.',
      );
    }

    return RefreshIndicator(
      onRefresh: _handleRefresh,
      color: AppColors.orange500,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 96),
        itemCount: filtered.length,
        itemBuilder: (_, i) => _MarkupRow(
          markup: filtered[i],
          onTap: () => _openSheet(template: filtered[i]),
        ),
      ),
    );
  }
}

// ─── Markup list row ──────────────────────────────────────────────────────────

class _MarkupRow extends StatelessWidget {
  final MarkupTemplate markup;
  final VoidCallback onTap;

  const _MarkupRow({required this.markup, required this.onTap});

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
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  markup.name,
                  style: AppTextStyles.rowTitle
                      .copyWith(fontSize: 15, height: 1.35),
                ),
              ),
              Text(
                markup.displayRate,
                style: AppTextStyles.rowAmount.copyWith(
                  fontSize: 15,
                  color: AppColors.inkSoft,
                ),
              ),
              const SizedBox(width: 6),
              const Icon(Icons.chevron_right,
                  size: 18, color: AppColors.inkFaint),
            ],
          ),
        ),
      ),
    );
  }
}
