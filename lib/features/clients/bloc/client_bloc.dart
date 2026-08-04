import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../models/client_model.dart';
import '../repository/client_repository.dart';

part 'client_event.dart';
part 'client_state.dart';

class ClientBloc extends Bloc<ClientEvent, ClientsState> {
  final ClientRepository _repository;

  ClientBloc({required ClientRepository repository})
      : _repository = repository,
        super(const ClientsInitial()) {
    on<ClientsFetchRequested>(_onFetch);
    on<ClientCreateRequested>(_onCreate);
    on<ClientUpdateRequested>(_onUpdate);
    on<ClientDeleteRequested>(_onDelete);
  }

  Future<void> _onFetch(
      ClientsFetchRequested event, Emitter<ClientsState> emit) async {
    emit(const ClientsLoading());
    final result = await _repository.fetchClients(event.proId);
    result.fold(
      (failure) => emit(ClientsError(failure.message)),
      (clients) => emit(ClientsLoaded(clients)),
    );
  }

  List<Client> get _currentClients {
    final s = state;
    if (s is ClientsLoaded) return s.clients;
    if (s is ClientCreating) return s.clients;
    if (s is ClientCreateSuccess) return s.clients;
    if (s is ClientCreateFailure) return s.clients;
    if (s is ClientUpdateInProgress) return s.clients;
    if (s is ClientUpdateSuccess) return s.clients;
    if (s is ClientUpdateFailure) return s.clients;
    if (s is ClientDeleteInProgress) return s.clients;
    if (s is ClientDeleteSuccess) return s.clients;
    if (s is ClientDeleteFailure) return s.clients;
    return [];
  }

  Future<void> _onUpdate(
      ClientUpdateRequested event, Emitter<ClientsState> emit) async {
    final current = _currentClients;
    emit(ClientUpdateInProgress(current));
    final result = await _repository.updateClient(event.client);
    result.fold(
      (failure) =>
          emit(ClientUpdateFailure(clients: current, message: failure.message)),
      (updated) {
        final next = current
            .map((c) => c.clientId == updated.clientId ? updated : c)
            .toList();
        emit(ClientUpdateSuccess(clients: next, updated: updated));
      },
    );
  }

  Future<void> _onDelete(
      ClientDeleteRequested event, Emitter<ClientsState> emit) async {
    final current = _currentClients;
    emit(ClientDeleteInProgress(current));
    final result = await _repository.deleteClient(event.clientId);
    result.fold(
      (failure) =>
          emit(ClientDeleteFailure(clients: current, message: failure.message)),
      (_) {
        final next =
            current.where((c) => c.clientId != event.clientId).toList();
        emit(ClientDeleteSuccess(next));
      },
    );
  }

  Future<void> _onCreate(
      ClientCreateRequested event, Emitter<ClientsState> emit) async {
    final currentClients = _currentClients;
    emit(ClientCreating(currentClients));
    final result = await _repository.createClient(
      proId: event.proId,
      name: event.name,
      email: event.email,
      phoneMobile: event.phoneMobile,
      phoneOther: event.phoneOther,
      address: event.address,
      address2: event.address2,
      city: event.city,
      state: event.state,
      zipCode: event.zipCode,
      privateNotes: event.privateNotes,
    );
    result.fold(
      (failure) => emit(
          ClientCreateFailure(clients: currentClients, message: failure.message)),
      (created) {
        final updated = [...currentClients, created]
          ..sort((a, b) => a.name.compareTo(b.name));
        emit(ClientCreateSuccess(clients: updated, created: created));
      },
    );
  }
}
