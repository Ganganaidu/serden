part of 'client_bloc.dart';

abstract class ClientEvent extends Equatable {
  const ClientEvent();
  @override
  List<Object?> get props => [];
}

class ClientsFetchRequested extends ClientEvent {
  final int proId;
  const ClientsFetchRequested(this.proId);
  @override
  List<Object> get props => [proId];
}

class ClientCreateRequested extends ClientEvent {
  final int proId;
  final String name;
  final String? email;
  final String? phoneMobile;
  final String? phoneOther;
  final String? address;
  final String? address2;
  final String? city;
  final String? state;
  final String? zipCode;
  final String? privateNotes;

  const ClientCreateRequested({
    required this.proId,
    required this.name,
    this.email,
    this.phoneMobile,
    this.phoneOther,
    this.address,
    this.address2,
    this.city,
    this.state,
    this.zipCode,
    this.privateNotes,
  });

  @override
  List<Object?> get props =>
      [proId, name, email, phoneMobile, address, city, state, zipCode];
}

class ClientUpdateRequested extends ClientEvent {
  final Client client;
  const ClientUpdateRequested(this.client);
  @override
  List<Object> get props => [client];
}

class ClientDeleteRequested extends ClientEvent {
  final int clientId;
  const ClientDeleteRequested(this.clientId);
  @override
  List<Object> get props => [clientId];
}
