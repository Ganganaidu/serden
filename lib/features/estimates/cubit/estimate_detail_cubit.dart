import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../models/estimate_model.dart';
import '../repository/estimate_repository.dart';

part 'estimate_detail_state.dart';

class EstimateDetailCubit extends Cubit<EstimateDetailState> {
  final EstimateRepository _repository;

  EstimateDetailCubit({required EstimateRepository repository})
      : _repository = repository,
        super(const EstimateDetailInitial());

  void applyUpdate(Estimate updated) => emit(EstimateDetailLoaded(updated));

  Future<void> fetch(int estimateId) async {
    emit(EstimateDetailLoading(preview: _current));
    final result = await _repository.fetchEstimateDetail(estimateId);
    result.fold(
      (failure) =>
          emit(EstimateDetailError(message: failure.message, stale: _current)),
      (estimate) => emit(EstimateDetailLoaded(estimate)),
    );
  }

  Future<void> send(int estimateId) async {
    final current = _current;
    if (current == null) return;
    emit(EstimateDetailBusy(current));
    final result = await _repository.sendEstimate(estimateId);
    result.fold(
      (failure) =>
          emit(EstimateDetailActionFailure(estimate: current, message: failure.message)),
      (_) {
        final updated = current.copyWith(status: 'sent');
        emit(EstimateDetailActionSuccess(estimate: updated, message: 'Estimate sent'));
        emit(EstimateDetailLoaded(updated));
      },
    );
  }

  Future<void> delete(int estimateId) async {
    final current = _current;
    if (current == null) return;
    emit(EstimateDetailBusy(current));
    final result = await _repository.deleteEstimate(estimateId);
    result.fold(
      (failure) =>
          emit(EstimateDetailActionFailure(estimate: current, message: failure.message)),
      (_) => emit(const EstimateDetailDeleted()),
    );
  }

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
