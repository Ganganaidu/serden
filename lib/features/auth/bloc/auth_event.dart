part of 'auth_bloc.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();
  @override
  List<Object?> get props => [];
}

class AuthCheckRequested extends AuthEvent {
  const AuthCheckRequested();
}

class AuthSignInRequested extends AuthEvent {
  final String email;
  final String password;
  const AuthSignInRequested({required this.email, required this.password});
  @override
  List<Object> get props => [email, password];
}

class AuthSignUpRequested extends AuthEvent {
  final String email;
  final String password;
  final String confirmPassword;
  final String firstName;
  final String lastName;
  const AuthSignUpRequested({
    required this.email,
    required this.password,
    required this.confirmPassword,
    required this.firstName,
    required this.lastName,
  });
  @override
  List<Object> get props =>
      [email, password, confirmPassword, firstName, lastName];
}

class AuthSignOutRequested extends AuthEvent {
  const AuthSignOutRequested();
}
