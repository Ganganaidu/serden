part of 'my_account_cubit.dart';

abstract class MyAccountState extends Equatable {
  const MyAccountState();
  @override
  List<Object?> get props => [];
}

class MyAccountInitial extends MyAccountState {
  const MyAccountInitial();
}

class MyAccountSaving extends MyAccountState {
  const MyAccountSaving();
}

class MyAccountSaved extends MyAccountState {
  final UserModel user;
  const MyAccountSaved(this.user);
  @override
  List<Object> get props => [user];
}

class MyAccountPasswordChanged extends MyAccountState {
  const MyAccountPasswordChanged();
}

class MyAccountError extends MyAccountState {
  final String message;
  const MyAccountError(this.message);
  @override
  List<Object> get props => [message];
}
