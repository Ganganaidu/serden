import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../models/lead_model.dart';
import '../repository/lead_repository.dart';

part 'lead_detail_state.dart';

class LeadDetailCubit extends Cubit<LeadDetailState> {
  final LeadRepository _repository;

  LeadDetailCubit({required LeadRepository repository})
      : _repository = repository,
        super(const LeadDetailInitial());

  Future<void> fetch(int requestId, int userId, {Lead? preview}) async {
    emit(LeadDetailLoading(preview: preview));
    final result = await _repository.fetchLeadDetail(requestId, userId);
    await result.fold(
      (failure) async => emit(LeadDetailError(
        message: failure.message,
        stale: preview,
      )),
      (lead) async {
        // Fetch notes, history, in parallel; errors are non-fatal.
        final notesFut = _repository.fetchNotes(requestId, userId);
        final historyFut = _repository.fetchHistory(requestId, userId);
        final notesResult = await notesFut;
        final historyResult = await historyFut;
        emit(LeadDetailLoaded(lead.copyWith(
          leadNotes: notesResult.fold((_) => lead.leadNotes, (n) => n),
          leadHistories:
              historyResult.fold((_) => lead.leadHistories, (h) => h),
        )));
      },
    );
  }

  void applyUpdate(Lead updated) {
    final current = _currentLead;
    if (current == null) return;
    emit(LeadDetailLoaded(updated.copyWith(
      leadNotes: current.leadNotes,
      leadHistories: current.leadHistories,
    )));
  }

  Future<void> addNote(int requestId, int userId, String noteText) async {
    final current = _currentLead;
    if (current == null) return;
    emit(LeadNoteAdding(current));
    final result = await _repository.addNote(requestId, userId, noteText);
    result.fold(
      (failure) => emit(
          LeadNoteAddFailure(lead: current, message: failure.message)),
      (note) {
        final updated = current.copyWith(
          leadNotes: [note, ...current.leadNotes],
        );
        emit(LeadNoteAddSuccess(updated));
        emit(LeadDetailLoaded(updated));
      },
    );
  }

  Future<void> deleteNote(int requestId, int userId, int noteId) async {
    final current = _currentLead;
    if (current == null) return;
    final result = await _repository.deleteNote(requestId, userId, noteId);
    result.fold(
      (_) {},
      (_) {
        final updated = current.copyWith(
          leadNotes: current.leadNotes
              .where((n) => n.leadNoteId != noteId)
              .toList(),
        );
        emit(LeadDetailLoaded(updated));
      },
    );
  }

  Lead? get _currentLead => switch (state) {
        LeadDetailLoaded(:final lead) => lead,
        LeadNoteAdding(:final lead) => lead,
        LeadNoteAddSuccess(:final lead) => lead,
        LeadNoteAddFailure(:final lead) => lead,
        _ => null,
      };
}
