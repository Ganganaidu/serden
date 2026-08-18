import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/di/injection.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/bloc/auth_bloc.dart';
import 'features/clients/bloc/client_bloc.dart';
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
  late final ClientBloc _clientBloc;
  late final LeadBloc _leadBloc;
  late final ItemsCubit _itemsCubit;
  late final MarkupsCubit _markupsCubit;
  late final NotificationsCubit _notificationsCubit;
  late final ReviewsCubit _reviewsCubit;
  late final TaxesCubit _taxesCubit;

  @override
  void initState() {
    super.initState();
    _authBloc = Injection.createAuthBloc();
    _clientBloc = Injection.createClientBloc();
    _leadBloc = Injection.createLeadBloc();
    _itemsCubit = Injection.createItemsCubit();
    _markupsCubit = Injection.createMarkupsCubit();
    _notificationsCubit = Injection.createNotificationsCubit();
    _reviewsCubit = Injection.createReviewsCubit();
    _taxesCubit = Injection.createTaxesCubit();
  }

  @override
  void dispose() {
    _authBloc.close();
    _clientBloc.close();
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
      providers: [
        BlocProvider.value(value: _authBloc),
        BlocProvider.value(value: _clientBloc),
        BlocProvider.value(value: _leadBloc),
        BlocProvider.value(value: _itemsCubit),
        BlocProvider.value(value: _markupsCubit),
        BlocProvider.value(value: _notificationsCubit),
        BlocProvider.value(value: _reviewsCubit),
        BlocProvider.value(value: _taxesCubit),
      ],
      child: Builder(
        builder: (context) {
          final router = AppRouter.router(context);
          return MaterialApp.router(
            title: 'Serden',
            theme: AppTheme.lightTheme,
            routerConfig: router,
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}
