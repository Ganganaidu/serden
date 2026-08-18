import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_constants.dart';
import '../models/lead_model.dart';
import '../repository/lead_repository.dart';

part 'lead_event.dart';
part 'lead_state.dart';

class LeadBloc extends Bloc<LeadEvent, LeadsState> {
  final LeadRepository _repository;

  // Tracks the next page to fetch; reset to 0 on every fresh fetch.
  int _nextPage = 0;

  LeadBloc({required LeadRepository repository})
      : _repository = repository,
        super(const LeadsInitial()) {
    on<LeadsFetchRequested>(_onFetch);
    on<LeadsLoadMoreRequested>(_onLoadMore);
    on<LeadCreateRequested>(_onCreate);
    on<LeadUpdateRequested>(_onUpdate);
    on<LeadStatusUpdateRequested>(_onStatusUpdate);
    on<LeadDeleteRequested>(_onDelete);
  }

  Future<void> _onFetch(
      LeadsFetchRequested event, Emitter<LeadsState> emit) async {
    _nextPage = 0;
    emit(const LeadsLoading());
    final result = await _repository.fetchLeads(
      event.userId,
      pageIndex: _nextPage,
      pageSize: AppConstants.pageSize,
    );
    result.fold(
      (failure) => emit(LeadsError(failure.message)),
      (leads) {
        _nextPage = 1;
        emit(LeadsLoaded(
          leads,
          hasMore: leads.length >= AppConstants.pageSize,
        ));
      },
    );
  }

  Future<void> _onLoadMore(
      LeadsLoadMoreRequested event, Emitter<LeadsState> emit) async {
    final s = state;
    if (s is! LeadsLoaded || s.isLoadingMore || !s.hasMore) return;

    emit(s.copyWith(isLoadingMore: true));

    final result = await _repository.fetchLeads(
      event.userId,
      pageIndex: _nextPage,
      pageSize: AppConstants.pageSize,
    );

    result.fold(
      (failure) => emit(s.copyWith(isLoadingMore: false)),
      (newLeads) {
        _nextPage++;
        final merged = [...s.leads, ...newLeads];
        emit(LeadsLoaded(
          merged,
          hasMore: newLeads.length >= AppConstants.pageSize,
        ));
      },
    );
  }

  List<Lead> get _currentLeads {
    final s = state;
    if (s is LeadsLoaded) return s.leads;
    if (s is LeadCreating) return s.leads;
    if (s is LeadCreateSuccess) return s.leads;
    if (s is LeadCreateFailure) return s.leads;
    if (s is LeadUpdateInProgress) return s.leads;
    if (s is LeadUpdateSuccess) return s.leads;
    if (s is LeadUpdateFailure) return s.leads;
    if (s is LeadDeleteInProgress) return s.leads;
    if (s is LeadDeleteSuccess) return s.leads;
    if (s is LeadDeleteFailure) return s.leads;
    return [];
  }

  bool get _currentHasMore {
    final s = state;
    return s is LeadsLoaded ? s.hasMore : false;
  }

  Future<void> _onCreate(
      LeadCreateRequested event, Emitter<LeadsState> emit) async {
    final current = _currentLeads;
    final hasMore = _currentHasMore;
    emit(LeadCreating(current));
    final result = await _repository.createLead(
      userId: event.userId,
      firstName: event.firstName,
      lastName: event.lastName,
      phone: event.phone,
      email: event.email,
      streetAddress: event.streetAddress,
      addressLine2: event.addressLine2,
      city: event.city,
      state: event.state,
      zipCode: event.zipCode,
      requestText: event.requestText,
      categoryName: event.categoryName,
      leadSource: event.leadSource,
      leadCost: event.leadCost,
      status: event.status,
    );
    result.fold(
      (failure) =>
          emit(LeadCreateFailure(leads: current, message: failure.message)),
      (created) {
        final updated = [created, ...current];
        emit(LeadCreateSuccess(leads: updated, created: created));
      },
    );
    // Restore hasMore after create
    if (state is LeadCreateSuccess) {
      emit(LeadsLoaded(_currentLeads, hasMore: hasMore));
    }
  }

  Future<void> _onUpdate(
      LeadUpdateRequested event, Emitter<LeadsState> emit) async {
    final current = _currentLeads;
    final hasMore = _currentHasMore;
    emit(LeadUpdateInProgress(current));
    final result = await _repository.updateLead(event.lead, event.userId);
    result.fold(
      (failure) =>
          emit(LeadUpdateFailure(leads: current, message: failure.message)),
      (updated) {
        final next = current
            .map((l) => l.requestId == updated.requestId ? updated : l)
            .toList();
        emit(LeadUpdateSuccess(leads: next, updated: updated));
        emit(LeadsLoaded(next, hasMore: hasMore));
      },
    );
  }

  Future<void> _onStatusUpdate(
      LeadStatusUpdateRequested event, Emitter<LeadsState> emit) async {
    final current = _currentLeads;
    final hasMore = _currentHasMore;
    emit(LeadUpdateInProgress(current));
    final result = await _repository.updateLeadStatus(
      event.requestId,
      event.userId,
      event.status,
      notes: event.notes,
    );
    result.fold(
      (failure) =>
          emit(LeadUpdateFailure(leads: current, message: failure.message)),
      (_) {
        final next = current.map((l) {
          if (l.requestId != event.requestId) return l;
          return l.copyWith(
            status: event.status,
            notes: event.notes ?? l.notes,
          );
        }).toList();
        final updated =
            next.firstWhere((l) => l.requestId == event.requestId);
        emit(LeadUpdateSuccess(leads: next, updated: updated));
        emit(LeadsLoaded(next, hasMore: hasMore));
      },
    );
  }

  Future<void> _onDelete(
      LeadDeleteRequested event, Emitter<LeadsState> emit) async {
    final current = _currentLeads;
    final hasMore = _currentHasMore;
    emit(LeadDeleteInProgress(current));
    final result =
        await _repository.deleteLead(event.requestId, event.userId);
    result.fold(
      (failure) =>
          emit(LeadDeleteFailure(leads: current, message: failure.message)),
      (_) {
        final next =
            current.where((l) => l.requestId != event.requestId).toList();
        emit(LeadDeleteSuccess(next));
        emit(LeadsLoaded(next, hasMore: hasMore));
      },
    );
  }
}
