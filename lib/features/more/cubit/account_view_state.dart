part of 'account_view_cubit.dart';

abstract class AccountViewState extends Equatable {
  const AccountViewState();
  @override
  List<Object?> get props => [];
}

class AccountViewLoading extends AccountViewState {
  const AccountViewLoading();
}

class AccountViewLoaded extends AccountViewState {
  final String? proName;
  final String? serdenProId;
  final String? phone;
  final String? address;
  final String? city;
  final String? state;
  final String? zipCode;

  const AccountViewLoaded({
    this.proName,
    this.serdenProId,
    this.phone,
    this.address,
    this.city,
    this.state,
    this.zipCode,
  });

  String get fullAddress {
    final parts = [address, city, state].where((s) => s != null && s.isNotEmpty).toList();
    return parts.join(', ');
  }

  @override
  List<Object?> get props =>
      [proName, serdenProId, phone, address, city, state, zipCode];
}
