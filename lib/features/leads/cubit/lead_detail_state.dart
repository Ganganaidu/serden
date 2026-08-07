part of 'lead_detail_cubit.dart';

sealed class LeadDetailState extends Equatable {
  const LeadDetailState();
  @override
  List<Object?> get props => [];
}

class LeadDetailInitial extends LeadDetailState {
  const LeadDetailInitial();
}

class LeadDetailLoading extends LeadDetailState {
  final Lead? preview;
  const LeadDetailLoading({this.preview});
  @override
  List<Object?> get props => [preview];
}

class LeadDetailLoaded extends LeadDetailState {
  final Lead lead;
  const LeadDetailLoaded(this.lead);
  @override
  List<Object> get props => [lead];
}

class LeadDetailError extends LeadDetailState {
  final String message;
  final Lead? stale;
  const LeadDetailError({required this.message, this.stale});
  @override
  List<Object?> get props => [message, stale];
}

class LeadNoteAdding extends LeadDetailState {
  final Lead lead;
  const LeadNoteAdding(this.lead);
  @override
  List<Object> get props => [lead];
}

class LeadNoteAddSuccess extends LeadDetailState {
  final Lead lead;
  const LeadNoteAddSuccess(this.lead);
  @override
  List<Object> get props => [lead];
}

class LeadNoteAddFailure extends LeadDetailState {
  final Lead lead;
  final String message;
  const LeadNoteAddFailure({required this.lead, required this.message});
  @override
  List<Object> get props => [lead, message];
}
