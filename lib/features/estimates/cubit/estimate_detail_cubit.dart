import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../clients/models/client_model.dart';
import '../../clients/repository/client_repository.dart';
import '../../more/models/company_profile_model.dart';
import '../../more/repository/company_profile_repository.dart';
import '../models/estimate_model.dart';
import '../repository/estimate_repository.dart';

part 'estimate_detail_state.dart';

class EstimateDetailCubit extends Cubit<EstimateDetailState> {
  final EstimateRepository _repository;
  final CompanyProfileRepository _companyRepository;
  final ClientRepository _clientRepository;

  // Cached across status changes so the paper document keeps its header data.
  CompanyProfile? _company;
  Client? _client;

  EstimateDetailCubit({
    required EstimateRepository repository,
    required CompanyProfileRepository companyRepository,
    required ClientRepository clientRepository,
  })  : _repository = repository,
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

  Future<void> send(int estimateId) async {
    final current = _current;
    if (current == null) return;
    emit(EstimateDetailBusy(current));
    final result = await _repository.sendEstimate(estimateId);
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
        _ => null,
      };
}
