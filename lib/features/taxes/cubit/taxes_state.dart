part of 'taxes_cubit.dart';

abstract class TaxesState extends Equatable {
  const TaxesState();
  @override
  List<Object?> get props => [];
}

class TaxesInitial extends TaxesState {
  const TaxesInitial();
}

class TaxesLoading extends TaxesState {
  const TaxesLoading();
}

class TaxesLoaded extends TaxesState {
  final List<TaxRate> taxes;
  const TaxesLoaded(this.taxes);
  @override
  List<Object?> get props => [taxes];
}

class TaxesError extends TaxesState {
  final String message;
  const TaxesError(this.message);
  @override
  List<Object?> get props => [message];
}
