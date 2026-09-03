part of 'estimate_bloc.dart';

abstract class EstimatesState extends Equatable {
  const EstimatesState();
  @override
  List<Object?> get props => [];
}

class EstimatesInitial extends EstimatesState {
  const EstimatesInitial();
}

class EstimatesLoading extends EstimatesState {
  const EstimatesLoading();
}

class EstimatesLoaded extends EstimatesState {
  final List<EstimateSummary> estimates;
  const EstimatesLoaded(this.estimates);
  @override
  List<Object?> get props => [estimates];
}

class EstimatesError extends EstimatesState {
  final String message;
  const EstimatesError(this.message);
  @override
  List<Object?> get props => [message];
}

/// A create / update / delete / send call is in-flight; carries the current
/// list so the list screen stays visible during the operation.
class EstimateMutating extends EstimatesState {
  final List<EstimateSummary> estimates;
  const EstimateMutating(this.estimates);
  @override
  List<Object?> get props => [estimates];
}

class EstimateMutateSuccess extends EstimatesState {
  final List<EstimateSummary> estimates;

  /// The created / updated estimate; null for delete and send.
  final Estimate? estimate;
  const EstimateMutateSuccess({required this.estimates, this.estimate});
  @override
  List<Object?> get props => [estimates, estimate];
}

class EstimateMutateFailure extends EstimatesState {
  final List<EstimateSummary> estimates;
  final String message;
  const EstimateMutateFailure({required this.estimates, required this.message});
  @override
  List<Object?> get props => [estimates, message];
}
