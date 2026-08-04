import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../models/client_model.dart';
import '../repository/client_repository.dart';

part 'client_detail_state.dart';

class ClientDetailCubit extends Cubit<ClientDetailState> {
  final ClientRepository _repository;

  ClientDetailCubit({required ClientRepository repository})
      : _repository = repository,
        super(const ClientDetailInitial());

  void applyUpdate(Client updated) => emit(ClientDetailLoaded(updated));

  Future<void> fetch(int clientId, {Client? preview}) async {
    emit(ClientDetailLoading(preview: preview));
    final result = await _repository.fetchClientDetail(clientId);
    result.fold(
      (failure) => emit(ClientDetailError(message: failure.message, stale: preview)),
      (client) => emit(ClientDetailLoaded(client)),
    );
  }
}
