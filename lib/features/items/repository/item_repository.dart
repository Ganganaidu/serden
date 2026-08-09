import 'package:dartz/dartz.dart';

import '../../../core/config/app_config.dart';
import '../../../core/errors/exceptions.dart';
import '../../../core/errors/failures.dart';
import '../../../core/network/api_client.dart';
import '../../../core/utils/app_logger.dart';
import '../models/item_model.dart';

abstract class ItemRepository {
  Future<Either<Failure, List<Item>>> fetchItems(int proId);
  Future<Either<Failure, Item>> createItem({
    required int proId,
    required String name,
    String? description,
    double? unitPrice,
    String? unit,
    ItemMarkup markup,
    String? privateNote,
  });
  Future<Either<Failure, Item>> updateItem(Item item);
  Future<Either<Failure, void>> deleteItem(int itemId);
}

class ItemRepositoryImpl implements ItemRepository {
  final ApiClient _apiClient;
  static const bool _useMock = AppConfig.useMockData;

  ItemRepositoryImpl({required ApiClient apiClient}) : _apiClient = apiClient;

  @override
  Future<Either<Failure, List<Item>>> fetchItems(int proId) async {
    AppLogger.api('fetchItems: proId=$proId');
    if (_useMock) {
      await Future.delayed(const Duration(milliseconds: 500));
      return Right(mockItems);
    }
    try {
      final response = await _apiClient.get('/lineItems/pro/$proId');
      final data = response.data as List<dynamic>;
      final items = data
          .map((e) => Item.fromJson(e as Map<String, dynamic>))
          .toList();
      AppLogger.api('fetchItems: loaded ${items.length} items');
      return Right(items);
    } on UnauthorizedException catch (e) {
      return Left(UnauthorizedFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, statusCode: e.statusCode));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      AppLogger.error('fetchItems: unexpected — $e');
      return const Left(UnexpectedFailure());
    }
  }

  @override
  Future<Either<Failure, Item>> createItem({
    required int proId,
    required String name,
    String? description,
    double? unitPrice,
    String? unit,
    ItemMarkup markup = ItemMarkup.none,
    String? privateNote,
  }) async {
    AppLogger.api('createItem: proId=$proId name=$name');
    if (_useMock) {
      await Future.delayed(const Duration(milliseconds: 600));
      final item = Item(
        itemId: DateTime.now().millisecondsSinceEpoch,
        proId: proId,
        name: name,
        description: description,
        unitPrice: unitPrice,
        unit: unit,
        markup: markup,
        privateNote: privateNote,
      );
      return Right(item);
    }
    try {
      final response = await _apiClient.post(
        '/lineItems',
        data: {
          'proId': proId,
          'itemName': name,
          if (unitPrice != null) 'rate': unitPrice,
          if (description != null && description.isNotEmpty)
            'description': description,
          if (unit != null && unit.isNotEmpty) 'unit': unit,
          if (markup.hasMarkup && markup.name != null) 'markupName': markup.name,
          if (markup.hasMarkup) 'markupType': markup.apiType,
          if (markup.hasMarkup) 'markupRate': markup.rate,
          if (privateNote != null && privateNote.isNotEmpty)
            'privateNote': privateNote,
        },
      );
      return Right(Item.fromJson(response.data as Map<String, dynamic>));
    } on UnauthorizedException catch (e) {
      return Left(UnauthorizedFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, statusCode: e.statusCode));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      AppLogger.error('createItem: unexpected — $e');
      return const Left(UnexpectedFailure());
    }
  }

  @override
  Future<Either<Failure, Item>> updateItem(Item item) async {
    AppLogger.api('updateItem: itemId=${item.itemId}');
    if (_useMock) {
      await Future.delayed(const Duration(milliseconds: 600));
      return Right(item);
    }
    try {
      final response = await _apiClient.put(
        '/lineItems/${item.itemId}',
        data: item.toJson(),
      );
      return Right(Item.fromJson(response.data as Map<String, dynamic>));
    } on UnauthorizedException catch (e) {
      return Left(UnauthorizedFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, statusCode: e.statusCode));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      AppLogger.error('updateItem: unexpected — $e');
      return const Left(UnexpectedFailure());
    }
  }

  @override
  Future<Either<Failure, void>> deleteItem(int itemId) async {
    AppLogger.api('deleteItem: itemId=$itemId');
    if (_useMock) {
      await Future.delayed(const Duration(milliseconds: 400));
      return const Right(null);
    }
    try {
      await _apiClient.delete('/lineItems/$itemId');
      return const Right(null);
    } on UnauthorizedException catch (e) {
      return Left(UnauthorizedFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, statusCode: e.statusCode));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      AppLogger.error('deleteItem: unexpected — $e');
      return const Left(UnexpectedFailure());
    }
  }
}
