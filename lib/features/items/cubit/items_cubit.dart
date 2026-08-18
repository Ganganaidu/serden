import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/errors/failures.dart';
import '../models/item_model.dart';
import '../repository/item_repository.dart';

part 'items_state.dart';

class ItemsCubit extends Cubit<ItemsState> {
  final ItemRepository _repository;

  ItemsCubit({required ItemRepository repository})
      : _repository = repository,
        super(const ItemsInitial());

  List<Item> get _current {
    final s = state;
    return s is ItemsLoaded ? s.items : [];
  }

  Future<void> fetch(int proId) async {
    emit(const ItemsLoading());
    final result = await _repository.fetchItems(proId);
    result.fold(
      (failure) => emit(ItemsError(failure.message)),
      (items) => emit(ItemsLoaded(_sorted(items))),
    );
  }

  Future<Either<Failure, Item>> create({
    required int proId,
    required String name,
    String? description,
    double? unitPrice,
    String? unit,
    ItemMarkup markup = ItemMarkup.none,
    String? privateNote,
  }) async {
    final result = await _repository.createItem(
      proId: proId,
      name: name,
      description: description,
      unitPrice: unitPrice,
      unit: unit,
      markup: markup,
      privateNote: privateNote,
    );
    result.fold(
      (_) {},
      (item) => emit(ItemsLoaded(_sorted([..._current, item]))),
    );
    return result;
  }

  Future<Either<Failure, Item>> update(Item item) async {
    final result = await _repository.updateItem(item);
    result.fold(
      (_) {},
      (updated) {
        final next = _current
            .map((i) => i.itemId == updated.itemId ? updated : i)
            .toList();
        emit(ItemsLoaded(_sorted(next)));
      },
    );
    return result;
  }

  Future<Either<Failure, void>> delete(int itemId) async {
    final result = await _repository.deleteItem(itemId);
    result.fold(
      (_) {},
      (_) {
        final next = _current.where((i) => i.itemId != itemId).toList();
        emit(ItemsLoaded(next));
      },
    );
    return result;
  }

  List<Item> _sorted(List<Item> items) =>
      items..sort((a, b) => a.name.compareTo(b.name));
}
