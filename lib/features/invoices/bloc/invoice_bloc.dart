import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../models/invoice_model.dart';
import '../repository/invoice_repository.dart';

part 'invoice_event.dart';
part 'invoice_state.dart';

class InvoiceBloc extends Bloc<InvoiceEvent, InvoicesState> {
  final InvoiceRepository _repository;

  InvoiceBloc({required InvoiceRepository repository})
      : _repository = repository,
        super(const InvoicesInitial()) {
    on<InvoicesFetchRequested>(_onFetch);
    on<InvoiceCreateRequested>(_onCreate);
    on<InvoiceUpdateRequested>(_onUpdate);
    on<InvoiceDeleteRequested>(_onDelete);
    on<InvoiceSendRequested>(_onSend);
  }

  Future<void> _onFetch(
      InvoicesFetchRequested event, Emitter<InvoicesState> emit) async {
    emit(const InvoicesLoading());
    final result = await _repository.fetchInvoices(
      event.proId,
      searchTerm: event.searchTerm,
    );
    result.fold(
      (failure) => emit(InvoicesError(failure.message)),
      (invoices) => emit(InvoicesLoaded(invoices)),
    );
  }

  List<InvoiceSummary> get _current {
    final s = state;
    if (s is InvoicesLoaded) return s.invoices;
    if (s is InvoiceMutating) return s.invoices;
    if (s is InvoiceMutateSuccess) return s.invoices;
    if (s is InvoiceMutateFailure) return s.invoices;
    return const [];
  }

  Future<void> _onCreate(
      InvoiceCreateRequested event, Emitter<InvoicesState> emit) async {
    final current = _current;
    emit(InvoiceMutating(current));
    final result = await _repository.createInvoice(event.invoice);
    result.fold(
      (failure) =>
          emit(InvoiceMutateFailure(invoices: current, message: failure.message)),
      (created) {
        final next = [_summaryOf(created), ...current];
        emit(InvoiceMutateSuccess(invoices: next, invoice: created));
        emit(InvoicesLoaded(next));
      },
    );
  }

  Future<void> _onUpdate(
      InvoiceUpdateRequested event, Emitter<InvoicesState> emit) async {
    final current = _current;
    emit(InvoiceMutating(current));
    final result = await _repository.updateInvoice(event.invoice);
    result.fold(
      (failure) =>
          emit(InvoiceMutateFailure(invoices: current, message: failure.message)),
      (updated) {
        final summary = _summaryOf(updated);
        final next = current
            .map((i) => i.invoiceId == updated.invoiceId ? summary : i)
            .toList();
        emit(InvoiceMutateSuccess(invoices: next, invoice: updated));
        emit(InvoicesLoaded(next));
      },
    );
  }

  Future<void> _onDelete(
      InvoiceDeleteRequested event, Emitter<InvoicesState> emit) async {
    final current = _current;
    emit(InvoiceMutating(current));
    final result = await _repository.deleteInvoice(event.invoiceId);
    result.fold(
      (failure) =>
          emit(InvoiceMutateFailure(invoices: current, message: failure.message)),
      (_) {
        final next =
            current.where((i) => i.invoiceId != event.invoiceId).toList();
        emit(InvoiceMutateSuccess(invoices: next, invoice: null));
        emit(InvoicesLoaded(next));
      },
    );
  }

  Future<void> _onSend(
      InvoiceSendRequested event, Emitter<InvoicesState> emit) async {
    final current = _current;
    emit(InvoiceMutating(current));
    final result = await _repository.sendInvoice(event.invoiceId);
    result.fold(
      (failure) =>
          emit(InvoiceMutateFailure(invoices: current, message: failure.message)),
      (_) {
        emit(InvoiceMutateSuccess(invoices: current, invoice: null));
        emit(InvoicesLoaded(current));
      },
    );
  }

  InvoiceSummary _summaryOf(Invoice i) => InvoiceSummary(
        invoiceId: i.invoiceId,
        publicId: i.publicId,
        invoiceNumber: i.invoiceNumber,
        clientName: i.clientName?.trim().isNotEmpty == true
            ? i.clientName!
            : 'Unnamed client',
        invoiceDate: i.invoiceDate,
        daysToPay: i.daysToPay,
        dueDate: i.dueDate,
        total: i.total,
        status: i.status,
        createdDate: i.createdDate,
      );
}
