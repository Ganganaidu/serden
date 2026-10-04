import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../clients/models/client_model.dart';
import '../../clients/repository/client_repository.dart';
import '../../invoices/models/invoice_model.dart';
import '../../invoices/repository/invoice_repository.dart';
import '../../more/models/company_profile_model.dart';
import '../../more/repository/company_profile_repository.dart';
import '../../../shared/models/send_document_draft.dart';
import '../models/estimate_model.dart';
import '../repository/estimate_repository.dart';

part 'estimate_detail_state.dart';

class EstimateDetailCubit extends Cubit<EstimateDetailState> {
  final EstimateRepository _repository;
  final InvoiceRepository _invoiceRepository;
  final CompanyProfileRepository _companyRepository;
  final ClientRepository _clientRepository;

  // Cached across status changes so the paper document keeps its header data.
  CompanyProfile? _company;
  Client? _client;

  EstimateDetailCubit({
    required EstimateRepository repository,
    required InvoiceRepository invoiceRepository,
    required CompanyProfileRepository companyRepository,
    required ClientRepository clientRepository,
  })  : _repository = repository,
        _invoiceRepository = invoiceRepository,
        _companyRepository = companyRepository,
        _clientRepository = clientRepository,
        super(const EstimateDetailInitial());

  void applyUpdate(Estimate updated) => emit(_loaded(updated));

  Future<void> fetch(int estimateId, {int? userId}) async {
    emit(EstimateDetailLoading(preview: _current));
    final result = await _repository.fetchEstimateDetail(estimateId);
    await result.fold(
      (failure) async =>
          emit(EstimateDetailError(message: failure.message, stale: _current)),
      (estimate) async {
        if (userId != null && _company == null) {
          final r = await _companyRepository.fetchProfile(userId);
          _company = r.fold((_) => null, (c) => c);
        }
        if (estimate.clientId != null &&
            _client?.clientId != estimate.clientId) {
          final r =
              await _clientRepository.fetchClientDetail(estimate.clientId!);
          _client = r.fold((_) => null, (c) => c);
        }
        emit(_loaded(estimate));
      },
    );
  }

  /// Emails the document via POST …/send-email, then marks it sent.
  Future<void> sendEmail(SendDocumentDraft draft) async {
    final current = _current;
    if (current == null) return;
    final publicId = current.publicId;
    if (publicId == null) {
      emit(EstimateDetailActionFailure(
          estimate: current, message: 'This estimate cannot be sent yet.'));
      return;
    }
    emit(EstimateDetailBusy(current));
    final result = await _repository.sendEstimateEmail(publicId, draft);
    result.fold(
      (failure) => emit(EstimateDetailActionFailure(
          estimate: current, message: failure.message)),
      (_) {
        final updated = current.copyWith(status: 'sent');
        emit(EstimateDetailActionSuccess(
            estimate: updated, message: 'Estimate sent'));
        emit(_loaded(updated));
      },
    );
  }

  /// [key] is one of `pending` / `approved` / `declined` from the status band.
  Future<void> setStatus(int estimateId, String key) async {
    final current = _current;
    if (current == null) return;

    final (status, isApproved) = switch (key) {
      'approved' => ('approved', true),
      'declined' => ('declined', false),
      _ => ('sent', false),
    };
    if (current.status?.toLowerCase() == status &&
        (current.isApproved ?? false) == isApproved) {
      return;
    }

    emit(EstimateDetailBusy(current));
    final result = await _repository
        .updateEstimate(current.copyWith(status: status, isApproved: isApproved));
    result.fold(
      (failure) => emit(EstimateDetailActionFailure(
          estimate: current, message: failure.message)),
      (updated) {
        // PUT may echo back a trimmed body — keep the richer local copy.
        final merged = current.copyWith(
          status: updated.status ?? status,
          isApproved: updated.isApproved ?? isApproved,
        );
        emit(EstimateDetailActionSuccess(
            estimate: merged, message: 'Status updated'));
        emit(_loaded(merged));
      },
    );
  }

  /// Creates a draft invoice from the estimate (POST /Invoices — there is no
  /// dedicated convert endpoint), marks the estimate approved, and emits
  /// [EstimateDetailInvoiceCreated].
  Future<void> convertToInvoice() async {
    final current = _current;
    if (current == null) return;
    emit(EstimateDetailBusy(current));
    final result =
        await _invoiceRepository.createInvoice(_invoiceFromEstimate(current));
    await result.fold(
      (failure) async => emit(EstimateDetailActionFailure(
          estimate: current, message: failure.message)),
      (invoice) async {
        // Converting means the client accepted — mark the estimate approved.
        // Best-effort: the invoice already exists, so a failure here must not
        // block navigating to it.
        var updated = current;
        if (!(current.isApproved ?? false) ||
            current.status?.toLowerCase() != 'approved') {
          final r = await _repository.updateEstimate(
              current.copyWith(status: 'approved', isApproved: true));
          updated = r.fold(
            (_) => current,
            (e) => current.copyWith(
              status: e.status ?? 'approved',
              isApproved: e.isApproved ?? true,
            ),
          );
        }
        emit(EstimateDetailInvoiceCreated(
            estimate: updated, invoiceId: invoice.invoiceId));
        emit(_loaded(updated));
      },
    );
  }

  /// Copies the estimate's content into a new invoice. Ids are reset so the
  /// API creates fresh rows; line items are regrouped under their sections
  /// (the estimate API returns them flat, keyed by `sectionId`).
  Invoice _invoiceFromEstimate(Estimate e) {
    InvoiceLineItem toItem(EstimateLineItem li) => InvoiceLineItem(
          description: li.description,
          notes: li.notes,
          unitPrice: li.unitPrice,
          quantity: li.quantity,
          markupType: li.markupType,
          markupValue: li.markupValue,
          isTaxable: li.isTaxable,
          taxRate: li.taxRate,
          taxAmount: li.taxAmount,
          total: li.lineTotal,
          sortOrder: li.sortOrder,
        );

    final consumed = <EstimateLineItem>{};
    final sections = <InvoiceSection>[];
    for (final s in e.sections) {
      final items = s.lineItems.isNotEmpty
          ? s.lineItems
          : e.lineItems
              .where((li) => li.sectionId != null && li.sectionId == s.sectionId)
              .toList();
      consumed.addAll(items);
      sections.add(InvoiceSection(
        name: s.name,
        sortOrder: s.sortOrder,
        subtotal: s.subtotal,
        isExpanded: s.isExpanded,
        lineItems: items.map(toItem).toList(),
      ));
    }
    final loose =
        e.lineItems.where((li) => !consumed.contains(li)).map(toItem).toList();

    return Invoice(
      proId: e.proId,
      clientId: e.clientId,
      clientName: e.clientName,
      invoiceDate: DateTime.now(),
      poNumber: e.poNumber,
      groupItemsIntoSections: e.groupItemsIntoSections,
      subtotal: e.subtotal,
      markupType: e.markupType,
      markupValue: e.markupValue,
      discountType: e.discountType,
      discountValue: e.discountValue,
      depositType: e.depositType,
      depositValue: e.depositValue,
      taxName: e.taxName,
      taxRate: e.taxRate,
      total: e.total,
      showClientSignature: e.showClientSignature,
      showMySignature: e.showMySignature,
      showRate: e.showRate,
      showQuantity: e.showQuantity,
      showItemTotals: e.showItemTotals,
      showSectionTotals: e.showSectionTotals,
      notes: e.notes,
      privateNotes: e.privateNotes,
      status: 'draft',
      sections: sections,
      lineItems: loose,
    );
  }

  Future<void> delete(int estimateId) async {
    final current = _current;
    if (current == null) return;
    emit(EstimateDetailBusy(current));
    final result = await _repository.deleteEstimate(estimateId);
    result.fold(
      (failure) => emit(EstimateDetailActionFailure(
          estimate: current, message: failure.message)),
      (_) => emit(const EstimateDetailDeleted()),
    );
  }

  EstimateDetailLoaded _loaded(Estimate e) =>
      EstimateDetailLoaded(e, company: _company, client: _client);

  Estimate? get _current => switch (state) {
        EstimateDetailLoaded(:final estimate) => estimate,
        EstimateDetailLoading(:final preview) => preview,
        EstimateDetailError(:final stale) => stale,
        EstimateDetailBusy(:final estimate) => estimate,
        EstimateDetailActionFailure(:final estimate) => estimate,
        EstimateDetailActionSuccess(:final estimate) => estimate,
        EstimateDetailInvoiceCreated(:final estimate) => estimate,
        _ => null,
      };
}
