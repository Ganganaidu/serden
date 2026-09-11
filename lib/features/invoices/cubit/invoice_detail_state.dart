part of 'invoice_detail_cubit.dart';

sealed class InvoiceDetailState extends Equatable {
  const InvoiceDetailState();
  @override
  List<Object?> get props => [];
}

class InvoiceDetailInitial extends InvoiceDetailState {
  const InvoiceDetailInitial();
}

class InvoiceDetailLoading extends InvoiceDetailState {
  final Invoice? preview;
  const InvoiceDetailLoading({this.preview});
  @override
  List<Object?> get props => [preview];
}

class InvoiceDetailLoaded extends InvoiceDetailState {
  final Invoice invoice;
  final CompanyProfile? company;
  final Client? client;
  const InvoiceDetailLoaded(this.invoice, {this.company, this.client});
  @override
  List<Object?> get props => [invoice, company, client];
}

class InvoiceDetailError extends InvoiceDetailState {
  final String message;
  final Invoice? stale;
  const InvoiceDetailError({required this.message, this.stale});
  @override
  List<Object?> get props => [message, stale];
}

class InvoiceDetailBusy extends InvoiceDetailState {
  final Invoice invoice;
  const InvoiceDetailBusy(this.invoice);
  @override
  List<Object?> get props => [invoice];
}

class InvoiceDetailActionSuccess extends InvoiceDetailState {
  final Invoice invoice;
  final String message;
  const InvoiceDetailActionSuccess(
      {required this.invoice, required this.message});
  @override
  List<Object?> get props => [invoice, message];
}

class InvoiceDetailActionFailure extends InvoiceDetailState {
  final Invoice invoice;
  final String message;
  const InvoiceDetailActionFailure(
      {required this.invoice, required this.message});
  @override
  List<Object?> get props => [invoice, message];
}

class InvoiceDetailDeleted extends InvoiceDetailState {
  const InvoiceDetailDeleted();
}
