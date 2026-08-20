import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/network/api_client.dart';
import '../../../core/utils/app_logger.dart';
import '../../../core/config/app_config.dart';

part 'account_view_state.dart';

class AccountViewCubit extends Cubit<AccountViewState> {
  final ApiClient _apiClient;

  AccountViewCubit({required ApiClient apiClient})
      : _apiClient = apiClient,
        super(const AccountViewLoading());

  Future<void> load(int userId) async {
    emit(const AccountViewLoading());
    if (AppConfig.useMockData) {
      await Future.delayed(const Duration(milliseconds: 300));
      emit(const AccountViewLoaded(
        proName: 'Serden Group LLC',
        serdenProId: 'PRO-20251103-11356',
        phone: '+1 (360) 836-7775',
        address: '1104 Main St, Ste 610',
        city: 'Vancouver',
        state: 'WA',
        zipCode: '98660',
      ));
      return;
    }
    try {
      final response = await _apiClient.get('/Pros/user/$userId');
      final data = response.data as Map<String, dynamic>?;
      if (data == null) {
        emit(const AccountViewLoaded());
        return;
      }
      emit(AccountViewLoaded(
        proName: data['proName'] as String?,
        serdenProId: data['serdenProId'] as String?,
        phone: data['phone'] as String?,
        address: data['streetAddress'] as String?,
        city: data['city'] as String?,
        state: data['state'] as String?,
        zipCode: data['zipCode'] as String?,
      ));
    } catch (e) {
      AppLogger.error('AccountViewCubit.load: $e');
      emit(const AccountViewLoaded());
    }
  }
}
