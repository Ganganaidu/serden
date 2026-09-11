import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../clients/models/client_model.dart';
import '../../clients/repository/client_repository.dart';
import '../../more/models/company_profile_model.dart';
import '../../more/repository/company_profile_repository.dart';
import '../models/invoice_model.dart';
import '../repository/invoice_repository.dart';

part 'invoice_detail_state.dart';

class InvoiceDetailCubit extends Cubit<InvoiceDetailState> {
  final InvoiceRepository _repository;
  final CompanyProfileRepository _companyRepository;
  final ClientRepository _clientRepository;

  CompanyProfile? _company;
  Client? _client;

  InvoiceDetailCubit({
    required InvoiceRepository repository,
    required CompanyProfileRepository companyRepository,
    required ClientRepository clientRepository,
  })  : _repository = repository,
        _companyRepository = companyRepository,
        _clientRepository = clientRepository,
        super(const InvoiceDetailInitial());

  void applyUpdate(Invoice updated) => emit(_loaded(updated));

  Future<void> fetch(int invoiceId, {int? userId}) async {
    emit(InvoiceDetailLoading(preview: _current));
    final result = await _repository.fetchInvoiceDetail(invoiceId);
    await result.fold(
      (failure) async =>
          emit(InvoiceDetailError(message: failure.message, stale: _current)),
      (invoice) async {
        if (userId != null && _company == null) {
          final r = await _companyRepository.fetchProfile(userId);
          _company = r.fold((_) => null, (c) => c);
        }
        if (invoice.clientId != null &&
            _client?.clientId != invoice.clientId) {
          final r =
              await _clientRepository.fetchClientDetail(invoice.clientId!);
          _client = r.fold((_) => null, (c) => c);
        }
        emit(_loaded(invoice));
      },
    );
  }

  Future<void> send(int invoiceId) async {
    final current = _current;
    if (current == null) return;
    emit(InvoiceDetailBusy(current));
    final result = await _repository.sendInvoice(invoiceId);
    result.fold(
      (failure) => emit(InvoiceDetailActionFailure(
          invoice: current, message: failure.message)),
      (_) {
        final updated = current.copyWith(status: 'sent');
        emit(InvoiceDetailActionSuccess(
            invoice: updated, message: 'Invoice sent'));
        emit(_loaded(updated));
      },
    );
  }

  Future<void> markPaid(String invoicePublicId) async {
    final current = _current;
    if (current == null) return;
    emit(InvoiceDetailBusy(current));
    final result = await _repository.markPaid(invoicePublicId);
    result.fold(
      (failure) => emit(InvoiceDetailActionFailure(
          invoice: current, message: failure.message)),
      (_) {
        final updated = current.copyWith(
          status: 'paid',
          paidDate: DateTime.now(),
        );
        emit(InvoiceDetailActionSuccess(
            invoice: updated, message: 'Marked as paid'));
        emit(_loaded(updated));
      },
    );
  }

  Future<void> recordPayment(
    String invoicePublicId, {
    required DateTime paymentDate,
    required double amount,
    String? paymentMethod,
    String? referenceNumber,
    String? notes,
  }) async {
    final current = _current;
    if (current == null) return;
    emit(InvoiceDetailBusy(current));
    final result = await _repository.recordPayment(
      invoicePublicId,
      paymentDate: paymentDate,
      amount: amount,
      paymentMethod: paymentMethod,
      referenceNumber: referenceNumber,
      notes: notes,
    );
    result.fold(
      (failure) => emit(InvoiceDetailActionFailure(
          invoice: current, message: failure.message)),
      (payment) {
        emit(InvoiceDetailActionSuccess(
            invoice: current, message: 'Payment recorded'));
        // Re-fetch to get updated totals and status from the server.
        fetch(current.invoiceId);
      },
    );
  }

  Future<void> delete(int invoiceId) async {
    final current = _current;
    if (current == null) return;
    emit(InvoiceDetailBusy(current));
    final result = await _repository.deleteInvoice(invoiceId);
    result.fold(
      (failure) => emit(InvoiceDetailActionFailure(
          invoice: current, message: failure.message)),
      (_) => emit(const InvoiceDetailDeleted()),
    );
  }

  InvoiceDetailLoaded _loaded(Invoice i) =>
      InvoiceDetailLoaded(i, company: _company, client: _client);

  Invoice? get _current => switch (state) {
        InvoiceDetailLoaded(:final invoice) => invoice,
        InvoiceDetailLoading(:final preview) => preview,
        InvoiceDetailError(:final stale) => stale,
        InvoiceDetailBusy(:final invoice) => invoice,
        InvoiceDetailActionFailure(:final invoice) => invoice,
        InvoiceDetailActionSuccess(:final invoice) => invoice,
        _ => null,
      };
}
