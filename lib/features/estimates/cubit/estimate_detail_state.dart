part of 'estimate_detail_cubit.dart';

sealed class EstimateDetailState extends Equatable {
  const EstimateDetailState();
  @override
  List<Object?> get props => [];
}

class EstimateDetailInitial extends EstimateDetailState {
  const EstimateDetailInitial();
}

class EstimateDetailLoading extends EstimateDetailState {
  final Estimate? preview;
  const EstimateDetailLoading({this.preview});
  @override
  List<Object?> get props => [preview];
}

class EstimateDetailLoaded extends EstimateDetailState {
  final Estimate estimate;
  const EstimateDetailLoaded(this.estimate);
  @override
  List<Object?> get props => [estimate];
}

class EstimateDetailError extends EstimateDetailState {
  final String message;
  final Estimate? stale;
  const EstimateDetailError({required this.message, this.stale});
  @override
  List<Object?> get props => [message, stale];
}

class EstimateDetailBusy extends EstimateDetailState {
  final Estimate estimate;
  const EstimateDetailBusy(this.estimate);
  @override
  List<Object?> get props => [estimate];
}

class EstimateDetailActionSuccess extends EstimateDetailState {
  final Estimate estimate;
  final String message;
  const EstimateDetailActionSuccess({required this.estimate, required this.message});
  @override
  List<Object?> get props => [estimate, message];
}

class EstimateDetailActionFailure extends EstimateDetailState {
  final Estimate estimate;
  final String message;
  const EstimateDetailActionFailure({required this.estimate, required this.message});
  @override
  List<Object?> get props => [estimate, message];
}

class EstimateDetailDeleted extends EstimateDetailState {
  const EstimateDetailDeleted();
}
