import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../models/estimate_model.dart';
import '../repository/estimate_repository.dart';

part 'estimate_event.dart';
part 'estimate_state.dart';

class EstimateBloc extends Bloc<EstimateEvent, EstimatesState> {
  final EstimateRepository _repository;

  EstimateBloc({required EstimateRepository repository})
      : _repository = repository,
        super(const EstimatesInitial()) {
    on<EstimatesFetchRequested>(_onFetch);
    on<EstimateCreateRequested>(_onCreate);
    on<EstimateUpdateRequested>(_onUpdate);
    on<EstimateDeleteRequested>(_onDelete);
    on<EstimateSendRequested>(_onSend);
  }

  Future<void> _onFetch(
      EstimatesFetchRequested event, Emitter<EstimatesState> emit) async {
    emit(const EstimatesLoading());
    final result = await _repository.fetchEstimates(
      event.proId,
      searchTerm: event.searchTerm,
    );
    result.fold(
      (failure) => emit(EstimatesError(failure.message)),
      (estimates) => emit(EstimatesLoaded(estimates)),
    );
  }

  List<EstimateSummary> get _current {
    final s = state;
    if (s is EstimatesLoaded) return s.estimates;
    if (s is EstimateMutating) return s.estimates;
    if (s is EstimateMutateSuccess) return s.estimates;
    if (s is EstimateMutateFailure) return s.estimates;
    return const [];
  }

  Future<void> _onCreate(
      EstimateCreateRequested event, Emitter<EstimatesState> emit) async {
    final current = _current;
    emit(EstimateMutating(current));
    final result = await _repository.createEstimate(event.estimate);
    result.fold(
      (failure) =>
          emit(EstimateMutateFailure(estimates: current, message: failure.message)),
      (created) {
        final next = [_summaryOf(created), ...current];
        emit(EstimateMutateSuccess(estimates: next, estimate: created));
        emit(EstimatesLoaded(next));
      },
    );
  }

  Future<void> _onUpdate(
      EstimateUpdateRequested event, Emitter<EstimatesState> emit) async {
    final current = _current;
    emit(EstimateMutating(current));
    final result = await _repository.updateEstimate(event.estimate);
    result.fold(
      (failure) =>
          emit(EstimateMutateFailure(estimates: current, message: failure.message)),
      (updated) {
        final summary = _summaryOf(updated);
        final next = current
            .map((e) => e.estimateId == updated.estimateId ? summary : e)
            .toList();
        emit(EstimateMutateSuccess(estimates: next, estimate: updated));
        emit(EstimatesLoaded(next));
      },
    );
  }

  Future<void> _onDelete(
      EstimateDeleteRequested event, Emitter<EstimatesState> emit) async {
    final current = _current;
    emit(EstimateMutating(current));
    final result = await _repository.deleteEstimate(event.estimateId);
    result.fold(
      (failure) =>
          emit(EstimateMutateFailure(estimates: current, message: failure.message)),
      (_) {
        final next =
            current.where((e) => e.estimateId != event.estimateId).toList();
        emit(EstimateMutateSuccess(estimates: next, estimate: null));
        emit(EstimatesLoaded(next));
      },
    );
  }

  Future<void> _onSend(
      EstimateSendRequested event, Emitter<EstimatesState> emit) async {
    final current = _current;
    emit(EstimateMutating(current));
    final result = await _repository.sendEstimate(event.estimateId);
    result.fold(
      (failure) =>
          emit(EstimateMutateFailure(estimates: current, message: failure.message)),
      (_) {
        emit(EstimateMutateSuccess(estimates: current, estimate: null));
        emit(EstimatesLoaded(current));
      },
    );
  }

  EstimateSummary _summaryOf(Estimate e) => EstimateSummary(
        estimateId: e.estimateId,
        publicId: e.publicId,
        estimateNumber: e.estimateNumber,
        clientName: e.clientName?.trim().isNotEmpty == true
            ? e.clientName!
            : 'Unnamed client',
        estimateDate: e.estimateDate,
        expirationDate: e.expirationDate,
        total: e.total,
        status: e.status,
        isApproved: e.isApproved,
        createdDate: e.createdDate,
      );
}
