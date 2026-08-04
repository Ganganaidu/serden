import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/user_model.dart';
import '../repository/auth_repository.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _repository;

  AuthBloc({required AuthRepository repository})
      : _repository = repository,
        super(const AuthInitial()) {
    on<AuthCheckRequested>(_onCheckRequested);
    on<AuthSignInRequested>(_onSignIn);
    on<AuthSignUpRequested>(_onSignUp);
    on<AuthSignOutRequested>(_onSignOut);
  }

  Future<void> _onCheckRequested(
      AuthCheckRequested event, Emitter<AuthState> emit) async {
    emit(const AuthLoading());
    final isAuth = await _repository.isAuthenticated();
    if (!isAuth) {
      emit(const AuthUnauthenticated());
      return;
    }
    final result = await _repository.getCurrentUser();
    result.fold(
      (_) => emit(const AuthUnauthenticated()),
      (user) => emit(AuthAuthenticated(user)),
    );
  }

  Future<void> _onSignIn(
      AuthSignInRequested event, Emitter<AuthState> emit) async {
    emit(const AuthLoading());
    final result =
        await _repository.signIn(event.email, event.password);
    result.fold(
      (failure) => emit(AuthFailure(failure.message)),
      (user) => emit(AuthAuthenticated(user)),
    );
  }

  Future<void> _onSignUp(
      AuthSignUpRequested event, Emitter<AuthState> emit) async {
    emit(const AuthLoading());
    final result = await _repository.signUp(
      email: event.email,
      password: event.password,
      confirmPassword: event.confirmPassword,
      firstName: event.firstName,
      lastName: event.lastName,
    );
    result.fold(
      (failure) => emit(AuthFailure(failure.message)),
      (user) => emit(AuthAuthenticated(user)),
    );
  }

  Future<void> _onSignOut(
      AuthSignOutRequested event, Emitter<AuthState> emit) async {
    await _repository.signOut();
    emit(const AuthUnauthenticated());
  }
}
