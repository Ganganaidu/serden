import '../../features/auth/bloc/auth_bloc.dart';
import '../../features/auth/repository/auth_repository.dart';
import '../../features/clients/bloc/client_bloc.dart';
import '../../features/clients/cubit/client_detail_cubit.dart';
import '../../features/clients/repository/client_repository.dart';
import '../../features/items/cubit/items_cubit.dart';
import '../../features/items/cubit/markups_cubit.dart';
import '../../features/items/repository/markup_repository.dart';
import '../../features/items/repository/item_repository.dart';
import '../../features/leads/bloc/lead_bloc.dart';
import '../../features/leads/cubit/lead_detail_cubit.dart';
import '../../features/leads/repository/lead_repository.dart';
import '../../features/more/cubit/account_view_cubit.dart';
import '../../features/more/cubit/company_profile_cubit.dart';
import '../../features/more/cubit/my_account_cubit.dart';
import '../../features/more/repository/company_profile_repository.dart';
import '../../features/notifications/cubit/notifications_cubit.dart';
import '../../features/notifications/repository/notification_repository.dart';
import '../../features/reviews/cubit/reviews_cubit.dart';
import '../../features/reviews/repository/review_repository.dart';
import '../../features/taxes/cubit/taxes_cubit.dart';
import '../../features/taxes/repository/tax_repository.dart';
import '../network/api_client.dart';
import '../network/token_interceptor.dart';
import '../storage/secure_storage.dart';

/// Simple manual dependency injection.
/// Replace with get_it or injectable if the team prefers it later.
class Injection {
  Injection._();

  static late SecureStorage _secureStorage;
  static late TokenInterceptor _tokenInterceptor;
  static late ApiClient _apiClient;
  static late AuthRepository _authRepository;
  static late ClientRepository _clientRepository;
  static late LeadRepository _leadRepository;
  static late ItemRepository _itemRepository;
  static late MarkupRepository _markupRepository;
  static late NotificationRepository _notificationRepository;
  static late ReviewRepository _reviewRepository;
  static late TaxRepository _taxRepository;
  static late CompanyProfileRepository _companyProfileRepository;

  static void init() {
    _secureStorage = SecureStorage();
    _tokenInterceptor = TokenInterceptor(_secureStorage);
    _apiClient = ApiClient(tokenInterceptor: _tokenInterceptor);
    _authRepository = AuthRepositoryImpl(
      apiClient: _apiClient,
      storage: _secureStorage,
    );
    _clientRepository = ClientRepositoryImpl(apiClient: _apiClient);
    _leadRepository = LeadRepositoryImpl(apiClient: _apiClient);
    _itemRepository = ItemRepositoryImpl(apiClient: _apiClient);
    _markupRepository = MarkupRepositoryImpl(apiClient: _apiClient);
    _notificationRepository = NotificationRepositoryImpl();
    _reviewRepository = ReviewRepositoryImpl(apiClient: _apiClient);
    _taxRepository = TaxRepositoryImpl(apiClient: _apiClient);
    _companyProfileRepository =
        CompanyProfileRepositoryImpl(apiClient: _apiClient);
  }

  static SecureStorage get secureStorage => _secureStorage;
  static ApiClient get apiClient => _apiClient;
  static AuthRepository get authRepository => _authRepository;
  static ClientRepository get clientRepository => _clientRepository;
  static LeadRepository get leadRepository => _leadRepository;

  static AuthBloc createAuthBloc() =>
      AuthBloc(repository: _authRepository)..add(const AuthCheckRequested());

  static ClientBloc createClientBloc() =>
      ClientBloc(repository: _clientRepository);

  static ClientDetailCubit createClientDetailCubit() =>
      ClientDetailCubit(repository: _clientRepository);

  static LeadBloc createLeadBloc() =>
      LeadBloc(repository: _leadRepository);

  static LeadDetailCubit createLeadDetailCubit() =>
      LeadDetailCubit(repository: _leadRepository);

  static ItemsCubit createItemsCubit() =>
      ItemsCubit(repository: _itemRepository);

  static MarkupsCubit createMarkupsCubit() =>
      MarkupsCubit(repository: _markupRepository);

  static NotificationsCubit createNotificationsCubit() =>
      NotificationsCubit(repository: _notificationRepository);

  static ReviewsCubit createReviewsCubit() =>
      ReviewsCubit(repository: _reviewRepository);

  static TaxesCubit createTaxesCubit() =>
      TaxesCubit(repository: _taxRepository);

  static MyAccountCubit createMyAccountCubit() =>
      MyAccountCubit(repository: _authRepository);

  static AccountViewCubit createAccountViewCubit() =>
      AccountViewCubit(apiClient: _apiClient);

  static CompanyProfileCubit createCompanyProfileCubit() =>
      CompanyProfileCubit(repository: _companyProfileRepository);
}
