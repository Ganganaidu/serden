import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_error_widget.dart';
import '../../../core/widgets/app_fab.dart';
import '../../../core/widgets/loading_overlay.dart';
import '../../../core/widgets/main_shell.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../items/cubit/items_cubit.dart';
import '../../items/models/item_model.dart';

class ItemsScreen extends StatefulWidget {
  const ItemsScreen({super.key});

  @override
  State<ItemsScreen> createState() => _ItemsScreenState();
}

class _ItemsScreenState extends State<ItemsScreen>
    with WidgetsBindingObserver {
  static const _letters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
  final Map<String, GlobalKey> _sectionKeys = {};
  final GlobalKey _indexBarKey = GlobalKey();
  String _search = '';
  String? _draggingLetter;
  DateTime? _backgroundedAt;
  late final GoRouter _goRouter;

  int? get _proId {
    final auth = context.read<AuthBloc>().state;
    return auth is AuthAuthenticated ? auth.user.proId : null;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _goRouter = GoRouter.of(context);
    _goRouter.routeInformationProvider.addListener(_onRouteChanged);
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      final proId = authState.user.proId;
      if (proId != null) context.read<ItemsCubit>().fetch(proId);
    }
  }

  // Refresh when returning from the item form.
  void _onRouteChanged() {
    final path = _goRouter.routeInformationProvider.value.uri.path;
    if (path == AppRoutes.items) _refresh();
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
    final proId = _proId;
    if (proId != null) context.read<ItemsCubit>().fetch(proId);
  }

  Future<void> _handleRefresh() async {
    _refresh();
    try {
      await context
          .read<ItemsCubit>()
          .stream
          .firstWhere((s) => s is ItemsLoaded || s is ItemsError)
          .timeout(const Duration(seconds: 15));
    } catch (_) {
      // Timeout — dismiss spinner anyway
    }
  }

  @override
  void dispose() {
    _goRouter.routeInformationProvider.removeListener(_onRouteChanged);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Map<String, List<Item>> _grouped(List<Item> items) {
    final q = _search.trim().toLowerCase();
    final filtered = items
        .where((i) =>
            q.isEmpty ||
            i.name.toLowerCase().contains(q) ||
            (i.description ?? '').toLowerCase().contains(q))
        .toList();

    final groups = <String, List<Item>>{};
    for (final item in filtered) {
      final letter = item.name[0].toUpperCase();
      final key = _letters.contains(letter) ? letter : '#';
      groups.putIfAbsent(key, () => []).add(item);
    }
    return groups;
  }

  void _openForm({Item? item}) {
    final proId = _proId;
    if (proId == null) return;
    context.push(
      AppRoutes.itemForm,
      extra: {'proId': proId, if (item != null) 'item': item},
    );
  }

  void _jumpTo(String letter, {bool animate = true}) {
    final key = _sectionKeys[letter];
    if (key?.currentContext != null) {
      Scrollable.ensureVisible(
        key!.currentContext!,
        duration: animate ? const Duration(milliseconds: 300) : Duration.zero,
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _handleIndexDrag(Offset globalPosition) {
    final box =
        _indexBarKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;
    final local = box.globalToLocal(globalPosition);
    final fraction = (local.dy / box.size.height).clamp(0.0, 1.0);
    final idx =
        (fraction * _letters.length).floor().clamp(0, _letters.length - 1);
    final letter = _letters[idx];
    if (letter != _draggingLetter) {
      setState(() => _draggingLetter = letter);
      if (_sectionKeys.containsKey(letter)) {
        _jumpTo(letter, animate: false);
      }
    }
  }

  String _money(double value) {
    final hasCents = value != value.roundToDouble();
    return '\$${value.toStringAsFixed(hasCents ? 2 : 0)}';
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ItemsCubit, ItemsState>(
      builder: (context, state) {
        final items = state is ItemsLoaded ? state.items : <Item>[];
        final groups = _grouped(items);

        _sectionKeys.clear();
        for (final letter in groups.keys) {
          _sectionKeys[letter] = GlobalKey();
        }

        return Scaffold(
          body: Column(
            children: [
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
                              'More',
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
                    const Text('Items', style: AppTextStyles.headerTitle),
                    const SizedBox(height: 3),
                    Text(
                      state is ItemsLoaded
                          ? '${items.length} saved ${items.length == 1 ? 'item' : 'items'} · drop them into any estimate or invoice'
                          : 'Your saved catalog items',
                      style: AppTextStyles.headerSubtitle,
                    ),
                    HeaderSearchBar(
                      hint: 'Search your saved items',
                      onChanged: (v) => setState(() => _search = v),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _body(context, state, groups, items),
              ),
            ],
          ),
          floatingActionButton: AppFab(
            label: 'New item',
            onPressed: () => _openForm(),
          ),
        );
      },
    );
  }

  Widget _body(
    BuildContext context,
    ItemsState state,
    Map<String, List<Item>> groups,
    List<Item> items,
  ) {
    if (state is ItemsLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state is ItemsError) {
      return AppErrorWidget(
        message: state.message,
        onRetry: () {
          final proId = _proId;
          if (proId != null) context.read<ItemsCubit>().fetch(proId);
        },
      );
    }

    if (state is ItemsLoaded && items.isEmpty) {
      return const EmptyState(
        title: 'No items yet',
        description:
            'Add reusable items to your catalog — descriptions, prices, and units — then drop them into any estimate or invoice.',
        icon: Icons.inventory_2_outlined,
      );
    }

    if (groups.isEmpty) {
      return const EmptyState(
        title: 'No matches',
        description: 'Try a different search term.',
      );
    }

    return RefreshIndicator(
      onRefresh: _handleRefresh,
      color: AppColors.orange500,
      child: Stack(
      children: [
        ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(right: 34, bottom: 96),
          children: [
            for (final entry in groups.entries) ...[
              Padding(
                key: _sectionKeys[entry.key],
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 6),
                child: Text(
                  entry.key,
                  style: const TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.inkSoft,
                  ),
                ),
              ),
              for (final item in entry.value) _row(context, item),
            ],
          ],
        ),
        Positioned(
          right: 4,
          top: 10,
          bottom: 10,
          child: _indexBar(groups.keys.toSet()),
        ),
        if (_draggingLetter != null)
          Positioned(
            right: 44,
            top: 0,
            bottom: 0,
            child: IgnorePointer(
              child: Center(
                child: Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: AppColors.green800,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      _draggingLetter!,
                      style: const TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
      ),
    ); // RefreshIndicator
  }


  Widget _row(BuildContext context, Item item) {
    return Material(
      color: AppColors.card,
      child: InkWell(
        onTap: () => _openForm(item: item),
        child: Container(
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: AppColors.line)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 20, 16, 18),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: AppTextStyles.rowTitle
                          .copyWith(fontSize: 14.5, height: 1.35),
                    ),
                    if ((item.description ?? '').isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        item.description!,
                        style: AppTextStyles.caption.copyWith(fontSize: 12),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              if (item.unitPrice != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _money(item.unitPrice!),
                      style: AppTextStyles.rowAmount.copyWith(fontSize: 14.5),
                    ),
                    if ((item.unit ?? '').isNotEmpty)
                      Text(
                        '/ ${item.unit}',
                        style: AppTextStyles.caption.copyWith(
                            fontSize: 11.5, fontWeight: FontWeight.w600),
                      ),
                  ],
                )
              else
                Text(
                  'Price varies',
                  style: AppTextStyles.caption
                      .copyWith(fontSize: 12.5, fontWeight: FontWeight.w700),
                ),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right,
                  size: 18, color: AppColors.inkFaint),
            ],
          ),
        ),
      ),
    );
  }

  Widget _indexBar(Set<String> available) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onPanStart: (d) => _handleIndexDrag(d.globalPosition),
      onPanUpdate: (d) => _handleIndexDrag(d.globalPosition),
      onPanEnd: (_) => setState(() => _draggingLetter = null),
      onPanCancel: () => setState(() => _draggingLetter = null),
      child: Column(
        key: _indexBarKey,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (final letter in _letters.split(''))
            GestureDetector(
              onTap: available.contains(letter) ? () => _jumpTo(letter) : null,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Text(
                  letter,
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    height: 1.35,
                    color: available.contains(letter)
                        ? AppColors.greenDeep
                        : const Color(0xFFC9CFC9),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
