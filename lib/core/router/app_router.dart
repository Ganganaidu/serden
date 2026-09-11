import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/bloc/auth_bloc.dart';
import '../../features/auth/screens/email_verification_screen.dart';
import '../../features/auth/screens/onboarding_screen.dart';
import '../utils/onboarding_prefs.dart';
import '../../features/auth/screens/sign_in_screen.dart';
import '../../features/auth/screens/sign_up_screen.dart';
import '../../features/clients/cubit/client_detail_cubit.dart';
import '../../features/clients/models/client_model.dart';
import '../../features/clients/screens/add_client_screen.dart';
import '../../features/clients/screens/client_detail_screen.dart';
import '../../features/clients/screens/client_list_screen.dart';
import '../../core/di/injection.dart';
import '../../features/estimates/cubit/estimate_detail_cubit.dart';
import '../../features/estimates/models/estimate_model.dart';
import '../../features/estimates/screens/estimate_detail_screen.dart';
import '../../features/estimates/screens/estimate_list_screen.dart';
import '../../features/estimates/screens/new_estimate_screen.dart';
import '../../features/invoices/cubit/invoice_detail_cubit.dart';
import '../../features/invoices/screens/invoice_detail_screen.dart';
import '../../features/invoices/screens/invoice_list_screen.dart';
import '../../features/invoices/screens/new_invoice_screen.dart';
import '../../features/invoices/screens/record_payment_screen.dart';
import '../../features/leads/cubit/lead_detail_cubit.dart';
import '../../features/leads/models/lead_model.dart';
import '../../features/leads/screens/add_lead_screen.dart';
import '../../features/leads/screens/lead_detail_screen.dart';
import '../../features/leads/screens/leads_screen.dart';
import '../../features/items/models/item_model.dart';
import '../../features/items/screens/item_form_screen.dart';
import '../../features/more/cubit/account_view_cubit.dart';
import '../../features/more/cubit/company_profile_cubit.dart';
import '../../features/more/cubit/my_account_cubit.dart';
import '../../features/more/cubit/contact_us_cubit.dart';
import '../../features/more/screens/about_screen.dart';
import '../../features/more/screens/contact_us_screen.dart';
import '../../features/more/screens/account_view_screen.dart';
import '../../features/more/screens/company_profile_screen.dart';
import '../../features/more/screens/items_screen.dart';
import '../../features/more/screens/more_screen.dart';
import '../../features/more/screens/my_account_screen.dart';
import '../../features/more/screens/reviews_screen.dart';
import '../../features/more/screens/markups_screen.dart';
import '../../features/more/screens/settings_screen.dart';
import '../../features/notifications/screens/notifications_screen.dart';
import '../../features/plans/screens/choose_plan_screen.dart';
import '../../features/taxes/screens/taxes_screen.dart';
import '../widgets/main_shell.dart';

abstract class AppRoutes {
  static const onboarding = '/onboarding';
  static const signIn = '/sign-in';
  static const signUp = '/sign-up';
  static const emailVerification = '/email-verification';

  // Shell tabs (must start with /)
  static const estimates = '/estimates';
  static const newEstimate = '/estimates/new';
  static const estimateDetail = '/estimates/:id';

  static const invoices = '/invoices';
  static const newInvoice = '/invoices/new';
  static const invoiceDetail = '/invoices/:id';
  static const recordPayment = '/invoices/:id/record-payment';

  static const clients = '/clients';
  static const clientDetail = '/clients/:id';
  static const addClient = '/clients/add';

  static const leads = '/leads';
  static const leadDetail = '/leads/:id';
  static const addLead = '/leads/add';

  static const more = '/more';
  static const itemForm = '/more/items/form';
  static const settings = '/more/settings';
  static const myAccount = '/more/settings/account';
  static const accountView = '/more/account';
  static const companyProfile = '/more/company-profile';
  static const reviews = '/more/reviews';
  static const items = '/more/items';
  static const about = '/more/settings/about';

  static const choosePlan = '/choose-plan';
  static const notifications = '/notifications';
  static const taxes = '/more/taxes';
  static const markups = '/more/markups';
  static const contactUs = '/more/contact';
}

class AppRouter {
  static GoRouter router(BuildContext context) {
    final authBloc = context.read<AuthBloc>();

    return GoRouter(
      initialLocation: AppRoutes.estimates,
      redirect: (context, state) {
        final authState = authBloc.state;
        final isAuthRoute = state.matchedLocation == AppRoutes.signIn ||
            state.matchedLocation == AppRoutes.signUp ||
            state.matchedLocation == AppRoutes.onboarding ||
            state.matchedLocation == AppRoutes.emailVerification;

        if (authState is AuthUnauthenticated && !isAuthRoute) {
          return OnboardingPrefs.seen ? AppRoutes.signIn : AppRoutes.onboarding;
        }
        if (authState is AuthAuthenticated && isAuthRoute) {
          return AppRoutes.estimates;
        }
        return null;
      },
      refreshListenable: GoRouterRefreshStream(authBloc.stream),
      routes: [
        // Auth routes (full-screen, no shell)
        GoRoute(
          path: AppRoutes.onboarding,
          builder: (_, __) => const OnboardingScreen(),
        ),
        GoRoute(
          path: AppRoutes.signIn,
          builder: (_, __) => const SignInScreen(),
        ),
        GoRoute(
          path: AppRoutes.signUp,
          builder: (_, __) => const SignUpScreen(),
        ),
        GoRoute(
          path: AppRoutes.emailVerification,
          builder: (_, state) => EmailVerificationScreen(
            email: state.extra as String? ?? '',
          ),
        ),

        // Notifications (full-screen push, accessible from any tab's bell icon)
        GoRoute(
          path: AppRoutes.notifications,
          builder: (_, __) => const NotificationsScreen(),
        ),

        // Plan selection (full-screen)
        GoRoute(
          path: AppRoutes.choosePlan,
          builder: (_, state) {
            final plan = state.uri.queryParameters['plan'] ?? 'basic';
            return ChoosePlanScreen(initialPlan: plan);
          },
        ),

        // Main shell with bottom nav. Each tab is its own branch so its
        // navigation stack and screen state survive tab switches.
        StatefulShellRoute(
          builder: (_, __, navigationShell) =>
              MainShell(navigationShell: navigationShell),
          navigatorContainerBuilder: (_, navigationShell, children) =>
              AnimatedBranchContainer(
            currentIndex: navigationShell.currentIndex,
            children: children,
          ),
          branches: [
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: AppRoutes.estimates,
                  builder: (_, __) => const EstimateListScreen(),
                  routes: [
                    GoRoute(
                      path: 'new',
                      builder: (_, state) {
                        final extra = state.extra as Map<String, dynamic>?;
                        return NewEstimateScreen(
                          estimateToEdit:
                              extra?['estimateToEdit'] as Estimate?,
                        );
                      },
                    ),
                    GoRoute(
                      path: ':id',
                      builder: (_, state) => BlocProvider<EstimateDetailCubit>(
                        create: (_) => Injection.createEstimateDetailCubit(),
                        child: EstimateDetailScreen(
                            id: state.pathParameters['id']!),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: AppRoutes.invoices,
                  builder: (_, __) => const InvoiceListScreen(),
                  routes: [
                    GoRoute(
                      path: 'new',
                      builder: (_, __) => const NewInvoiceScreen(),
                    ),
                    GoRoute(
                      path: ':id',
                      builder: (_, state) => BlocProvider<InvoiceDetailCubit>(
                        create: (_) => Injection.createInvoiceDetailCubit(),
                        child: InvoiceDetailScreen(
                            id: state.pathParameters['id']!),
                      ),
                      routes: [
                        GoRoute(
                          path: 'record-payment',
                          builder: (_, state) => BlocProvider<InvoiceDetailCubit>(
                            create: (_) => Injection.createInvoiceDetailCubit(),
                            child: RecordPaymentScreen(
                                invoiceId: state.pathParameters['id']!),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: AppRoutes.clients,
                  builder: (_, __) => const ClientListScreen(),
                  routes: [
                    GoRoute(
                      path: 'add',
                      builder: (_, state) {
                        final extra = state.extra as Map<String, dynamic>?;
                        return AddClientScreen(
                          importContacts:
                              extra?['importContacts'] as bool? ?? false,
                          clientToEdit: extra?['clientToEdit'] as Client?,
                        );
                      },
                    ),
                    GoRoute(
                      path: ':id',
                      builder: (_, state) {
                        final preview = state.extra as Client?;
                        return BlocProvider<ClientDetailCubit>(
                          create: (_) => Injection.createClientDetailCubit(),
                          child: ClientDetailScreen(
                            id: state.pathParameters['id']!,
                            previewClient: preview,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: AppRoutes.leads,
                  builder: (_, __) => const LeadsScreen(),
                  routes: [
                    GoRoute(
                      path: 'add',
                      builder: (_, state) {
                        final extra = state.extra as Map<String, dynamic>?;
                        return AddLeadScreen(
                          leadToEdit: extra?['leadToEdit'] as Lead?,
                        );
                      },
                    ),
                    GoRoute(
                      path: ':id',
                      builder: (_, state) {
                        final preview = state.extra as Lead?;
                        return BlocProvider<LeadDetailCubit>(
                          create: (_) => Injection.createLeadDetailCubit(),
                          child: LeadDetailScreen(
                            id: state.pathParameters['id']!,
                            previewLead: preview,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: AppRoutes.more,
                  builder: (_, __) => const MoreScreen(),
                  routes: [
                    GoRoute(
                      path: 'settings',
                      builder: (_, __) => const SettingsScreen(),
                      routes: [
                        GoRoute(
                          path: 'account',
                          builder: (_, __) => BlocProvider<MyAccountCubit>(
                            create: (_) => Injection.createMyAccountCubit(),
                            child: const MyAccountScreen(),
                          ),
                        ),
                        GoRoute(
                          path: 'about',
                          builder: (_, __) => const AboutScreen(),
                        ),
                      ],
                    ),
                    GoRoute(
                      path: 'account',
                      builder: (_, __) => MultiBlocProvider(
                        providers: [
                          BlocProvider<AccountViewCubit>(
                            create: (_) =>
                                Injection.createAccountViewCubit(),
                          ),
                          BlocProvider<MyAccountCubit>(
                            create: (_) =>
                                Injection.createMyAccountCubit(),
                          ),
                        ],
                        child: const AccountViewScreen(),
                      ),
                    ),
                    GoRoute(
                      path: 'company-profile',
                      builder: (_, __) => BlocProvider<CompanyProfileCubit>(
                        create: (_) =>
                            Injection.createCompanyProfileCubit(),
                        child: const CompanyProfileScreen(),
                      ),
                    ),
                    GoRoute(
                      path: 'reviews',
                      builder: (_, __) => const ReviewsScreen(),
                    ),
                    GoRoute(
                      path: 'taxes',
                      builder: (_, __) => const TaxesScreen(),
                    ),
                    GoRoute(
                      path: 'markups',
                      builder: (_, __) => const MarkupsScreen(),
                    ),
                    GoRoute(
                      path: 'contact',
                      builder: (_, __) => BlocProvider<ContactUsCubit>(
                        create: (_) => Injection.createContactUsCubit(),
                        child: const ContactUsScreen(),
                      ),
                    ),
                    GoRoute(
                      path: 'items',
                      builder: (_, __) => const ItemsScreen(),
                      routes: [
                        GoRoute(
                          path: 'form',
                          builder: (_, state) {
                            final extra =
                                state.extra as Map<String, dynamic>?;
                            return ItemFormScreen(
                              item: extra?['item'] as Item?,
                              proId: extra?['proId'] as int? ?? 0,
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ],
      errorBuilder: (_, state) => Scaffold(
        body: Center(child: Text('Page not found: ${state.error}')),
      ),
    );
  }
}

/// Slides/fades between tab branches without rebuilding them, so each
/// branch keeps its state (scroll position, search text, selected pill
/// tab).
///
/// The outgoing branch stays fully opaque underneath while the incoming
/// branch animates in on top. A plain cross-fade (both branches at
/// partial opacity) lets the scaffold background bleed through for a
/// frame or two, which reads as a white flash against the dark headers.
class AnimatedBranchContainer extends StatefulWidget {
  final int currentIndex;
  final List<Widget> children;

  const AnimatedBranchContainer({
    super.key,
    required this.currentIndex,
    required this.children,
  });

  @override
  State<AnimatedBranchContainer> createState() =>
      _AnimatedBranchContainerState();
}

class _AnimatedBranchContainerState extends State<AnimatedBranchContainer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 260),
    value: 1,
  );

  late int _current = widget.currentIndex;
  int? _previous;

  late final Animation<double> _fade = CurvedAnimation(
    // Fade completes slightly before the slide settles (~200ms of 260ms).
    parent: _controller,
    curve: const Interval(0, 0.77, curve: Curves.easeOutCubic),
  );

  @override
  void didUpdateWidget(AnimatedBranchContainer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentIndex != _current) {
      _previous = _current;
      _current = widget.currentIndex;
      _controller.forward(from: 0).whenComplete(() {
        if (mounted) setState(() => _previous = null);
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final previous = _previous;
    // Incoming branch slides in from the side it lives on relative to
    // the branch it replaces.
    final fromLeft = previous != null && previous > _current;
    final slide = Tween<Offset>(
      begin: Offset(fromLeft ? -0.05 : 0.05, 0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    // Children are re-ordered so the active branch always paints on top;
    // KeyedSubtree keeps each branch's element (and state) matched to its
    // branch index across re-orders.
    return Stack(
      fit: StackFit.expand,
      children: [
        for (var i = 0; i < widget.children.length; i++)
          if (i != _current && i != previous)
            KeyedSubtree(
              key: ValueKey('branch-$i'),
              child: Offstage(
                child: TickerMode(
                  enabled: false,
                  child: widget.children[i],
                ),
              ),
            ),
        if (previous != null)
          KeyedSubtree(
            key: ValueKey('branch-$previous'),
            child: IgnorePointer(
              child: TickerMode(
                enabled: false,
                child: widget.children[previous],
              ),
            ),
          ),
        KeyedSubtree(
          key: ValueKey('branch-$_current'),
          child: SlideTransition(
            position: slide,
            child: FadeTransition(
              opacity: _fade,
              child: widget.children[_current],
            ),
          ),
        ),
      ],
    );
  }
}

// Bridges BLoC stream to GoRouter's Listenable
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    _subscription = stream.listen((_) => notifyListeners());
  }

  late final dynamic _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
