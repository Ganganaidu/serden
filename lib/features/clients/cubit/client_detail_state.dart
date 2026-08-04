part of 'client_detail_cubit.dart';

abstract class ClientDetailState extends Equatable {
  const ClientDetailState();
  @override
  List<Object?> get props => [];
}

class ClientDetailInitial extends ClientDetailState {
  const ClientDetailInitial();
}

class ClientDetailLoading extends ClientDetailState {
  final Client? preview;
  const ClientDetailLoading({this.preview});
  @override
  List<Object?> get props => [preview];
}

class ClientDetailLoaded extends ClientDetailState {
  final Client client;
  const ClientDetailLoaded(this.client);
  @override
  List<Object> get props => [client];
}

class ClientDetailError extends ClientDetailState {
  final String message;
  final Client? stale;
  const ClientDetailError({required this.message, this.stale});
  @override
  List<Object?> get props => [message, stale];
}
