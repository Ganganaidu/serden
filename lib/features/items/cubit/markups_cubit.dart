import 'package:flutter_bloc/flutter_bloc.dart';

import '../models/item_model.dart';

class MarkupsCubit extends Cubit<List<ItemMarkup>> {
  MarkupsCubit() : super(const []);

  void addMarkup(ItemMarkup markup) {
    emit([...state, markup]);
  }
}
