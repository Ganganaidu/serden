import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/errors/failures.dart';
import '../models/tax_model.dart';
import '../repository/tax_repository.dart';

part 'taxes_state.dart';

class TaxesCubit extends Cubit<TaxesState> {
  final TaxRepository _repository;

  TaxesCubit({required TaxRepository repository})
      : _repository = repository,
        super(const TaxesInitial());

  List<TaxRate> get _current =>
      state is TaxesLoaded ? (state as TaxesLoaded).taxes : [];

  Future<void> fetch(int proId) async {
    emit(const TaxesLoading());
    final result = await _repository.fetchTaxes(proId);
    result.fold(
      (failure) => emit(TaxesError(failure.message)),
      (taxes) => emit(TaxesLoaded(taxes)),
    );
  }

  Future<Either<Failure, TaxRate>> create({
    required int proId,
    required String name,
    required double rate,
  }) async {
    final result = await _repository.createTax(
        proId: proId, name: name, rate: rate);
    result.fold(
      (_) {},
      (tax) => emit(TaxesLoaded([..._current, tax])),
    );
    return result;
  }

  Future<Either<Failure, TaxRate>> update(TaxRate tax) async {
    final result = await _repository.updateTax(tax);
    result.fold(
      (_) {},
      (updated) {
        final next = _current
            .map((t) => t.id == updated.id ? updated : t)
            .toList();
        emit(TaxesLoaded(next));
      },
    );
    return result;
  }

  Future<Either<Failure, void>> delete(int taxId) async {
    final result = await _repository.deleteTax(taxId);
    result.fold(
      (_) {},
      (_) => emit(TaxesLoaded(_current.where((t) => t.id != taxId).toList())),
    );
    return result;
  }
}
