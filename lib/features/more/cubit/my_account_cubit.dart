import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../auth/models/user_model.dart';
import '../../auth/repository/auth_repository.dart';

part 'my_account_state.dart';

class MyAccountCubit extends Cubit<MyAccountState> {
  final AuthRepository _repository;

  MyAccountCubit({required AuthRepository repository})
      : _repository = repository,
        super(const MyAccountInitial());

  Future<void> save({
    required int userId,
    required String firstName,
    required String lastName,
    required String email,
  }) async {
    emit(const MyAccountSaving());
    final result = await _repository.updateUser(
      userId: userId,
      firstName: firstName,
      lastName: lastName,
      email: email,
    );
    result.fold(
      (failure) => emit(MyAccountError(failure.message)),
      (user) => emit(MyAccountSaved(user)),
    );
  }

  Future<void> changePassword({
    required String email,
    required String currentPassword,
    required String newPassword,
  }) async {
    emit(const MyAccountSaving());
    final result = await _repository.changePassword(
      email: email,
      currentPassword: currentPassword,
      newPassword: newPassword,
    );
    result.fold(
      (failure) => emit(MyAccountError(failure.message)),
      (_) => emit(const MyAccountPasswordChanged()),
    );
  }

  void reset() => emit(const MyAccountInitial());
}
