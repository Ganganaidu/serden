part of 'invoice_bloc.dart';

abstract class InvoiceEvent extends Equatable {
  const InvoiceEvent();
  @override
  List<Object?> get props => [];
}

class InvoicesFetchRequested extends InvoiceEvent {
  final int proId;
  final String? searchTerm;
  const InvoicesFetchRequested(this.proId, {this.searchTerm});
  @override
  List<Object?> get props => [proId, searchTerm];
}

class InvoiceCreateRequested extends InvoiceEvent {
  final Invoice invoice;
  const InvoiceCreateRequested(this.invoice);
  @override
  List<Object?> get props => [invoice];
}

class InvoiceUpdateRequested extends InvoiceEvent {
  final Invoice invoice;
  const InvoiceUpdateRequested(this.invoice);
  @override
  List<Object?> get props => [invoice];
}

class InvoiceDeleteRequested extends InvoiceEvent {
  final int invoiceId;
  const InvoiceDeleteRequested(this.invoiceId);
  @override
  List<Object?> get props => [invoiceId];
}

class InvoiceSendRequested extends InvoiceEvent {
  final int invoiceId;
  const InvoiceSendRequested(this.invoiceId);
  @override
  List<Object?> get props => [invoiceId];
}
