import 'package:dartz/dartz.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/errors/failures.dart';
import '../models/item_model.dart';
import '../models/markup_template.dart';
import '../repository/markup_repository.dart';

part 'markups_state.dart';

class MarkupsCubit extends Cubit<MarkupsState> {
  final MarkupRepository _repository;

  MarkupsCubit({required MarkupRepository repository})
      : _repository = repository,
        super(const MarkupsInitial());

  List<MarkupTemplate> get _current =>
      state is MarkupsLoaded ? (state as MarkupsLoaded).templates : [];

  Future<void> fetch(int proId) async {
    if (state is MarkupsLoading) return;
    emit(const MarkupsLoading());
    final result = await _repository.fetchMarkups(proId);
    result.fold(
      (f) => emit(MarkupsError(f.message)),
      (templates) => emit(MarkupsLoaded(templates)),
    );
  }

  Future<Either<Failure, MarkupTemplate>> create({
    required int proId,
    required String name,
    required MarkupType type,
    required double rate,
  }) async {
    final result = await _repository.createMarkup(
      proId: proId,
      name: name,
      type: type,
      rate: rate,
    );
    result.fold(
      (_) {},
      (template) => emit(MarkupsLoaded([..._current, template])),
    );
    return result;
  }

  Future<Either<Failure, MarkupTemplate>> update(
      MarkupTemplate template) async {
    final result = await _repository.updateMarkup(template);
    result.fold(
      (_) {},
      (updated) {
        final next = _current
            .map((t) => t.id == updated.id ? updated : t)
            .toList();
        emit(MarkupsLoaded(next));
      },
    );
    return result;
  }

  Future<Either<Failure, void>> delete(int markupId) async {
    final result = await _repository.deleteMarkup(markupId);
    result.fold(
      (_) {},
      (_) => emit(
          MarkupsLoaded(_current.where((t) => t.id != markupId).toList())),
    );
    return result;
  }
}
