part of 'lead_bloc.dart';

abstract class LeadsState extends Equatable {
  const LeadsState();
  @override
  List<Object?> get props => [];
}

class LeadsInitial extends LeadsState {
  const LeadsInitial();
}

class LeadsLoading extends LeadsState {
  const LeadsLoading();
}

class LeadsLoaded extends LeadsState {
  final List<Lead> leads;
  final bool hasMore;
  final bool isLoadingMore;

  const LeadsLoaded(
    this.leads, {
    this.hasMore = false,
    this.isLoadingMore = false,
  });

  LeadsLoaded copyWith({
    List<Lead>? leads,
    bool? hasMore,
    bool? isLoadingMore,
  }) =>
      LeadsLoaded(
        leads ?? this.leads,
        hasMore: hasMore ?? this.hasMore,
        isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      );

  @override
  List<Object> get props => [leads, hasMore, isLoadingMore];
}

class LeadsError extends LeadsState {
  final String message;
  const LeadsError(this.message);
  @override
  List<Object> get props => [message];
}

class LeadCreating extends LeadsState {
  final List<Lead> leads;
  const LeadCreating(this.leads);
  @override
  List<Object> get props => [leads];
}

class LeadCreateSuccess extends LeadsState {
  final List<Lead> leads;
  final Lead created;
  const LeadCreateSuccess({required this.leads, required this.created});
  @override
  List<Object> get props => [leads, created];
}

class LeadCreateFailure extends LeadsState {
  final List<Lead> leads;
  final String message;
  const LeadCreateFailure({required this.leads, required this.message});
  @override
  List<Object> get props => [leads, message];
}

class LeadUpdateInProgress extends LeadsState {
  final List<Lead> leads;
  const LeadUpdateInProgress(this.leads);
  @override
  List<Object> get props => [leads];
}

class LeadUpdateSuccess extends LeadsState {
  final List<Lead> leads;
  final Lead updated;
  const LeadUpdateSuccess({required this.leads, required this.updated});
  @override
  List<Object> get props => [leads, updated];
}

class LeadUpdateFailure extends LeadsState {
  final List<Lead> leads;
  final String message;
  const LeadUpdateFailure({required this.leads, required this.message});
  @override
  List<Object> get props => [leads, message];
}

class LeadDeleteInProgress extends LeadsState {
  final List<Lead> leads;
  const LeadDeleteInProgress(this.leads);
  @override
  List<Object> get props => [leads];
}

class LeadDeleteSuccess extends LeadsState {
  final List<Lead> leads;
  const LeadDeleteSuccess(this.leads);
  @override
  List<Object> get props => [leads];
}

class LeadDeleteFailure extends LeadsState {
  final List<Lead> leads;
  final String message;
  const LeadDeleteFailure({required this.leads, required this.message});
  @override
  List<Object> get props => [leads, message];
}
