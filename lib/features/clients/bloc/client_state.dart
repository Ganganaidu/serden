part of 'client_bloc.dart';

abstract class ClientsState extends Equatable {
  const ClientsState();
  @override
  List<Object?> get props => [];
}

class ClientsInitial extends ClientsState {
  const ClientsInitial();
}

class ClientsLoading extends ClientsState {
  const ClientsLoading();
}

class ClientsLoaded extends ClientsState {
  final List<Client> clients;
  const ClientsLoaded(this.clients);
  @override
  List<Object> get props => [clients];
}

class ClientsError extends ClientsState {
  final String message;
  const ClientsError(this.message);
  @override
  List<Object> get props => [message];
}

/// Emitted while a create API call is in-flight; carries the existing list
/// so the list screen stays visible during the save.
class ClientCreating extends ClientsState {
  final List<Client> clients;
  const ClientCreating(this.clients);
  @override
  List<Object> get props => [clients];
}

class ClientCreateSuccess extends ClientsState {
  final List<Client> clients;
  final Client created;
  const ClientCreateSuccess({required this.clients, required this.created});
  @override
  List<Object> get props => [clients, created];
}

class ClientCreateFailure extends ClientsState {
  final List<Client> clients;
  final String message;
  const ClientCreateFailure({required this.clients, required this.message});
  @override
  List<Object> get props => [clients, message];
}

class ClientUpdateInProgress extends ClientsState {
  final List<Client> clients;
  const ClientUpdateInProgress(this.clients);
  @override
  List<Object> get props => [clients];
}

class ClientUpdateSuccess extends ClientsState {
  final List<Client> clients;
  final Client updated;
  const ClientUpdateSuccess({required this.clients, required this.updated});
  @override
  List<Object> get props => [clients, updated];
}

class ClientUpdateFailure extends ClientsState {
  final List<Client> clients;
  final String message;
  const ClientUpdateFailure({required this.clients, required this.message});
  @override
  List<Object> get props => [clients, message];
}

class ClientDeleteInProgress extends ClientsState {
  final List<Client> clients;
  const ClientDeleteInProgress(this.clients);
  @override
  List<Object> get props => [clients];
}

class ClientDeleteSuccess extends ClientsState {
  final List<Client> clients;
  const ClientDeleteSuccess(this.clients);
  @override
  List<Object> get props => [clients];
}

class ClientDeleteFailure extends ClientsState {
  final List<Client> clients;
  final String message;
  const ClientDeleteFailure({required this.clients, required this.message});
  @override
  List<Object> get props => [clients, message];
}
