import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'core/di/injection.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/app_error_screen.dart';
import 'features/auth/bloc/auth_bloc.dart';
import 'features/clients/bloc/client_bloc.dart';
import 'features/estimates/bloc/estimate_bloc.dart';
import 'features/invoices/bloc/invoice_bloc.dart';
import 'features/items/cubit/items_cubit.dart';
import 'features/items/cubit/markups_cubit.dart';
import 'features/leads/bloc/lead_bloc.dart';
import 'features/notifications/cubit/notifications_cubit.dart';
import 'features/reviews/cubit/reviews_cubit.dart';
import 'features/taxes/cubit/taxes_cubit.dart';

class SerdenApp extends StatefulWidget {
  const SerdenApp({super.key});

  @override
  State<SerdenApp> createState() => _SerdenAppState();
}

class _SerdenAppState extends State<SerdenApp> {
  late final AuthBloc _authBloc;
  late ClientBloc _clientBloc;
  late EstimateBloc _estimateBloc;
  late InvoiceBloc _invoiceBloc;
  late LeadBloc _leadBloc;
  late ItemsCubit _itemsCubit;
  late MarkupsCubit _markupsCubit;
  late NotificationsCubit _notificationsCubit;
  late ReviewsCubit _reviewsCubit;
  late TaxesCubit _taxesCubit;

  GoRouter? _router;
  StreamSubscription<AuthState>? _authSub;
  StreamSubscription<void>? _expiredSub;

  /// Bumped on every reset so the whole tree (and any screen-local state)
  /// is rebuilt against the fresh blocs.
  int _sessionGen = 0;
  String? _userKey;

  @override
  void initState() {
    super.initState();
    _authBloc = Injection.createAuthBloc()..add(const AuthCheckRequested());
    _createDataBlocs();
    _authSub = _authBloc.stream.listen(_onAuthChanged);
    _expiredSub = Injection.sessionExpired.listen((_) {
      _authBloc.add(const AuthSignOutRequested());
    });
  }

  /// Drops every in-memory list/detail the previous user loaded, on logout
  /// and whenever a different user becomes authenticated.
  void _onAuthChanged(AuthState state) {
    if (state is AuthUnauthenticated) {
      _userKey = null;
      _resetSessionData();
    } else if (state is AuthAuthenticated) {
      final key = state.user.publicId;
      if (_userKey != null && _userKey != key) _resetSessionData();
      _userKey = key;
    }
  }

  void _resetSessionData() {
    _closeDataBlocs();
    setState(() {
      _createDataBlocs();
      _sessionGen++;
    });
  }

  void _createDataBlocs() {
    _clientBloc = Injection.createClientBloc();
    _estimateBloc = Injection.createEstimateBloc();
    _invoiceBloc = Injection.createInvoiceBloc();
    _leadBloc = Injection.createLeadBloc();
    _itemsCubit = Injection.createItemsCubit();
    _markupsCubit = Injection.createMarkupsCubit();
    _notificationsCubit = Injection.createNotificationsCubit();
    _reviewsCubit = Injection.createReviewsCubit();
    _taxesCubit = Injection.createTaxesCubit();
  }

  void _closeDataBlocs() {
    _clientBloc.close();
    _estimateBloc.close();
    _invoiceBloc.close();
    _leadBloc.close();
    _itemsCubit.close();
    _markupsCubit.close();
    _notificationsCubit.close();
    _reviewsCubit.close();
    _taxesCubit.close();
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _expiredSub?.cancel();
    _authBloc.close();
    _clientBloc.close();
    _estimateBloc.close();
    _invoiceBloc.close();
    _leadBloc.close();
    _itemsCubit.close();
    _markupsCubit.close();
    _notificationsCubit.close();
    _reviewsCubit.close();
    _taxesCubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      key: ValueKey(_sessionGen),
      providers: [
        BlocProvider.value(value: _authBloc),
        BlocProvider.value(value: _clientBloc),
        BlocProvider.value(value: _estimateBloc),
        BlocProvider.value(value: _invoiceBloc),
        BlocProvider.value(value: _leadBloc),
        BlocProvider.value(value: _itemsCubit),
        BlocProvider.value(value: _markupsCubit),
        BlocProvider.value(value: _notificationsCubit),
        BlocProvider.value(value: _reviewsCubit),
        BlocProvider.value(value: _taxesCubit),
      ],
      child: Builder(
        builder: (context) {
          final router = _router ??= AppRouter.router(context);
          return MaterialApp.router(
            title: 'Serden',
            theme: AppTheme.lightTheme,
            routerConfig: router,
            debugShowCheckedModeBanner: false,
            builder: (context, child) {
              return _ErrorBoundary(child: child ?? const SizedBox.shrink());
            },
          );
        },
      ),
    );
  }
}

/// Catches errors thrown during widget builds and swaps the subtree for
/// [AppErrorScreen] rather than crashing the whole app.
class _ErrorBoundary extends StatefulWidget {
  final Widget child;
  const _ErrorBoundary({required this.child});

  @override
  State<_ErrorBoundary> createState() => _ErrorBoundaryState();
}

class _ErrorBoundaryState extends State<_ErrorBoundary> {
  Object? _error;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reset error whenever the child subtree changes so a retry can succeed.
    _error = null;
  }

  void _clearError() => setState(() => _error = null);

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return AppErrorScreen(onRetry: _clearError);
    }
    return widget.child;
  }
}
