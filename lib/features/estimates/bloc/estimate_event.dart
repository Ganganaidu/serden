part of 'estimate_bloc.dart';

abstract class EstimateEvent extends Equatable {
  const EstimateEvent();
  @override
  List<Object?> get props => [];
}

class EstimatesFetchRequested extends EstimateEvent {
  final int proId;
  final String? searchTerm;
  const EstimatesFetchRequested(this.proId, {this.searchTerm});
  @override
  List<Object?> get props => [proId, searchTerm];
}

class EstimateCreateRequested extends EstimateEvent {
  final Estimate estimate;
  const EstimateCreateRequested(this.estimate);
  @override
  List<Object?> get props => [estimate];
}

class EstimateUpdateRequested extends EstimateEvent {
  final Estimate estimate;
  const EstimateUpdateRequested(this.estimate);
  @override
  List<Object?> get props => [estimate];
}

class EstimateDeleteRequested extends EstimateEvent {
  final int estimateId;
  const EstimateDeleteRequested(this.estimateId);
  @override
  List<Object?> get props => [estimateId];
}

class EstimateSendRequested extends EstimateEvent {
  final int estimateId;
  const EstimateSendRequested(this.estimateId);
  @override
  List<Object?> get props => [estimateId];
}
