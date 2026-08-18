import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_fab.dart';
import '../../../core/widgets/avatar_widget.dart';
import '../../../core/widgets/loading_overlay.dart';
import '../../../core/widgets/main_shell.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../bloc/client_bloc.dart';
import '../models/client_model.dart';

class ClientListScreen extends StatefulWidget {
  const ClientListScreen({super.key});

  @override
  State<ClientListScreen> createState() => _ClientListScreenState();
}

class _ClientListScreenState extends State<ClientListScreen>
    with WidgetsBindingObserver {
  static const _letters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';

  final _scrollController = ScrollController();
  final Map<String, GlobalKey> _sectionKeys = {};
  final GlobalKey _indexBarKey = GlobalKey();
  String _search = '';
  String? _draggingLetter;
  bool _hasFetched = false;
  DateTime? _backgroundedAt;
  late final GoRouter _goRouter;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _goRouter = GoRouter.of(context);
    _goRouter.routeInformationProvider.addListener(_onRouteChanged);
    // Attempt fetch immediately — succeeds if auth is already complete
    // (e.g. tab switch after initial load). If auth is still in progress
    // the BlocListener below will catch the AuthAuthenticated transition.
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchOnce());
  }

  // Fires on every route change. Refresh whenever the clients list
  // becomes the active screen (tab switch OR returning from add/detail).
  void _onRouteChanged() {
    final path = _goRouter.routeInformationProvider.value.uri.path;
    if (path == AppRoutes.clients) _refresh();
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

  // One-time initial fetch — skips if already done (prevents double-fire
  // when both initState and BlocListener trigger on cold start).
  void _fetchOnce() {
    if (_hasFetched) return;
    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthAuthenticated) return;
    final proId = authState.user.proId;
    if (proId == null) return;
    _hasFetched = true;
    context.read<ClientBloc>().add(ClientsFetchRequested(proId));
  }

  // Explicit refresh — used by pull-to-refresh, route change, and app resume.
  void _refresh() {
    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthAuthenticated) return;
    final proId = authState.user.proId;
    if (proId == null) return;
    context.read<ClientBloc>().add(ClientsFetchRequested(proId));
  }

  Future<void> _handleRefresh() async {
    _refresh();
    try {
      await context
          .read<ClientBloc>()
          .stream
          .firstWhere((s) => s is ClientsLoaded || s is ClientsError)
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

  Map<String, List<Client>> _grouped(List<Client> clients) {
    final q = _search.trim().toLowerCase();
    final rows = clients
        .where((c) =>
            q.isEmpty ||
            c.name.toLowerCase().contains(q) ||
            c.place.toLowerCase().contains(q))
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));

    final groups = <String, List<Client>>{};
    for (final client in rows) {
      final letter = client.name[0].toUpperCase();
      final key = _letters.contains(letter) ? letter : '#';
      groups.putIfAbsent(key, () => []).add(client);
    }
    return groups;
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

  void _showAddSheet() {
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: AppColors.grabber,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Text('Add a client',
                  style: AppTextStyles.headingSmall.copyWith(fontSize: 17)),
              const SizedBox(height: 14),
              _SheetOption(
                icon: Icons.edit_outlined,
                title: 'Create new client',
                subtitle: 'Enter details manually',
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  context.push(AppRoutes.addClient);
                },
              ),
              const SizedBox(height: 10),
              _SheetOption(
                icon: Icons.person_add_alt_outlined,
                title: 'Import from contacts',
                subtitle: 'Pull from your address book',
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  context.push(AppRoutes.addClient, extra: {'importContacts': true});
                },
              ),
              TextButton(
                onPressed: () => Navigator.of(sheetContext).pop(),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.inkSoft,
                  textStyle: const TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                child: const Text('Cancel'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      // Fires when auth completes after the screen is already built (cold start).
      listenWhen: (_, curr) => curr is AuthAuthenticated,
      listener: (context, _) => _fetchOnce(),
      child: BlocConsumer<ClientBloc, ClientsState>(
      listener: (context, state) {
        // Refresh list after a successful create (navigated back from AddClientScreen)
        if (state is ClientCreateSuccess) {
          setState(() {}); // triggers grouped rebuild with new clients
        }
      },
      builder: (context, state) {
        final clients = switch (state) {
          ClientsLoaded(:final clients) => clients,
          ClientCreating(:final clients) => clients,
          ClientCreateSuccess(:final clients) => clients,
          ClientCreateFailure(:final clients) => clients,
          ClientUpdateInProgress(:final clients) => clients,
          ClientUpdateSuccess(:final clients) => clients,
          ClientUpdateFailure(:final clients) => clients,
          ClientDeleteInProgress(:final clients) => clients,
          ClientDeleteSuccess(:final clients) => clients,
          ClientDeleteFailure(:final clients) => clients,
          _ => <Client>[],
        };
        final isLoading = state is ClientsLoading;
        final errorMessage = state is ClientsError ? state.message : null;

        final total =
            clients.fold<double>(0, (sum, c) => sum + c.lifetimeValue);
        final groups = _grouped(clients);
        _sectionKeys.clear();
        for (final letter in groups.keys) {
          _sectionKeys[letter] = GlobalKey();
        }

        return Scaffold(
          body: Column(
            children: [
              AppHeader(
                title: 'Clients',
                subtitle: '${clients.length} clients · ',
                subtitleSpans: [
                  TextSpan(
                    text: Formatters.currencyShort(total),
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w700),
                  ),
                  const TextSpan(text: ' lifetime work'),
                ],
                actions: [
                  const NotificationBellButton(),
                ],
                bottom: HeaderSearchBar(
                  hint: 'Search name, address, or city',
                  onChanged: (v) => setState(() => _search = v),
                ),
              ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _handleRefresh,
                  color: AppColors.orange500,
                  child: Stack(
                  children: [
                    if (isLoading)
                      const Center(child: CircularProgressIndicator())
                    else if (errorMessage != null)
                      _ErrorState(
                        message: errorMessage,
                        onRetry: _refresh,
                      )
                    else if (groups.isEmpty)
                      EmptyState(
                        title: _search.isEmpty ? 'No clients yet' : 'No matches',
                        description: _search.isEmpty
                            ? 'Tap the button below to add your first client.'
                            : 'Try a different name or city — or add them as a new client.',
                      )
                    else
                      ListView(
                        controller: _scrollController,
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.only(right: 30, bottom: 96),
                        children: [
                          for (final entry in groups.entries) ...[
                            Padding(
                              key: _sectionKeys[entry.key],
                              padding:
                                  const EdgeInsets.fromLTRB(20, 16, 20, 6),
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
                            for (final client in entry.value)
                              _ClientRow(
                                client: client,
                                onTap: () => context.push(
                                  '/clients/${client.clientId}',
                                  extra: client,
                                ),
                              ),
                          ],
                        ],
                      ),
                    if (!isLoading && groups.isNotEmpty)
                      Positioned(
                        right: 3,
                        top: 10,
                        bottom: 10,
                        child: _indexBar(groups.keys.toSet()),
                      ),
                    if (_draggingLetter != null)
                      Positioned(
                        right: 43,
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
                ), // RefreshIndicator
              ),
            ],
          ),
          floatingActionButton:
              AppFab(label: 'Add client', onPressed: _showAddSheet),
        );
      },
      ),   // BlocConsumer
    );     // BlocListener
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

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

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
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.inkSoft),
            ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: onRetry,
              child: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ClientRow extends StatelessWidget {
  final Client client;
  final VoidCallback onTap;

  const _ClientRow({required this.client, required this.onTap});

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
          padding: const EdgeInsets.fromLTRB(20, 12, 16, 12),
          child: Row(
            children: [
              AvatarWidget(name: client.name),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      client.name,
                      style: AppTextStyles.rowTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      client.place,
                      style: AppTextStyles.caption,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (client.isNew)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.orangeTint,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text('New client',
                      style: AppTextStyles.chip
                          .copyWith(color: AppColors.orangeDeep)),
                )
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      Formatters.currencyShort(client.lifetimeValue),
                      style: AppTextStyles.rowAmount.copyWith(fontSize: 14),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${client.jobs} job${client.jobs == 1 ? '' : 's'}',
                      style: AppTextStyles.caption.copyWith(
                          fontSize: 11.5, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SheetOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SheetOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.page,
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
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.greenTint,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 19, color: AppColors.greenDeep),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTextStyles.rowTitle),
                    const SizedBox(height: 2),
                    Text(subtitle, style: AppTextStyles.caption),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right,
                  size: 18, color: AppColors.inkFaint),
            ],
          ),
        ),
      ),
    );
  }
}
