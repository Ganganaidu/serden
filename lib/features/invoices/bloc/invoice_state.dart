part of 'invoice_bloc.dart';

abstract class InvoicesState extends Equatable {
  const InvoicesState();
  @override
  List<Object?> get props => [];
}

class InvoicesInitial extends InvoicesState {
  const InvoicesInitial();
}

class InvoicesLoading extends InvoicesState {
  const InvoicesLoading();
}

class InvoicesLoaded extends InvoicesState {
  final List<InvoiceSummary> invoices;
  const InvoicesLoaded(this.invoices);
  @override
  List<Object?> get props => [invoices];
}

class InvoicesError extends InvoicesState {
  final String message;
  const InvoicesError(this.message);
  @override
  List<Object?> get props => [message];
}

/// A create / update / delete / send call is in-flight; carries the current
/// list so the list screen stays visible during the operation.
class InvoiceMutating extends InvoicesState {
  final List<InvoiceSummary> invoices;
  const InvoiceMutating(this.invoices);
  @override
  List<Object?> get props => [invoices];
}

class InvoiceMutateSuccess extends InvoicesState {
  final List<InvoiceSummary> invoices;

  /// The created / updated invoice; null for delete and send.
  final Invoice? invoice;
  const InvoiceMutateSuccess({required this.invoices, this.invoice});
  @override
  List<Object?> get props => [invoices, invoice];
}

class InvoiceMutateFailure extends InvoicesState {
  final List<InvoiceSummary> invoices;
  final String message;
  const InvoiceMutateFailure({required this.invoices, required this.message});
  @override
  List<Object?> get props => [invoices, message];
}
