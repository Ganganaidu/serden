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
  final CompanyProfile? company;
  final Client? client;
  const EstimateDetailLoaded(this.estimate, {this.company, this.client});
  @override
  List<Object?> get props => [estimate, company, client];
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

/// The estimate was converted to a (draft) invoice; the screen navigates to it.
class EstimateDetailInvoiceCreated extends EstimateDetailState {
  final Estimate estimate;
  final int invoiceId;
  const EstimateDetailInvoiceCreated(
      {required this.estimate, required this.invoiceId});
  @override
  List<Object?> get props => [estimate, invoiceId];
}

/// Creating the invoice hit the plan's monthly limit — show the upgrade prompt.
class EstimateDetailLimitReached extends EstimateDetailState {
  final Estimate estimate;
  const EstimateDetailLimitReached(this.estimate);
  @override
  List<Object?> get props => [estimate];
}
