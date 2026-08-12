import 'package:dartz/dartz.dart';

import '../../../core/config/app_config.dart';
import '../../../core/errors/exceptions.dart';
import '../../../core/errors/failures.dart';
import '../../../core/network/api_client.dart';
import '../../../core/utils/app_logger.dart';
import '../models/item_model.dart';
import '../models/markup_template.dart';

abstract class MarkupRepository {
  Future<Either<Failure, List<MarkupTemplate>>> fetchMarkups(int proId);
  Future<Either<Failure, MarkupTemplate>> createMarkup({
    required int proId,
    required String name,
    required MarkupType type,
    required double rate,
  });
}

class MarkupRepositoryImpl implements MarkupRepository {
  final ApiClient _apiClient;
  static const bool _useMock = AppConfig.useMockData;

  MarkupRepositoryImpl({required ApiClient apiClient})
      : _apiClient = apiClient;

  @override
  Future<Either<Failure, List<MarkupTemplate>>> fetchMarkups(int proId) async {
    AppLogger.api('fetchMarkups: proId=$proId');
    if (_useMock) {
      await Future.delayed(const Duration(milliseconds: 400));
      return Right([
        MarkupTemplate(id: 1, proId: proId, name: 'Overhead', type: MarkupType.percent, rate: 10),
        MarkupTemplate(id: 2, proId: proId, name: 'Material markup', type: MarkupType.percent, rate: 15),
      ]);
    }
    try {
      final response = await _apiClient.get('/lineitems/markups/pro/$proId');
      final data = response.data as List<dynamic>;
      if (data.isNotEmpty) {
        AppLogger.api(
            'fetchMarkups: first item keys = ${(data.first as Map<String, dynamic>).keys.toList()}');
        AppLogger.api('fetchMarkups: first item = ${data.first}');
      }
      final templates = data
          .map((e) => MarkupTemplate.fromJson(e as Map<String, dynamic>))
          .toList();
      AppLogger.api('fetchMarkups: loaded ${templates.length} templates');
      return Right(templates);
    } on UnauthorizedException catch (e) {
      return Left(UnauthorizedFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, statusCode: e.statusCode));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      AppLogger.error('fetchMarkups: unexpected — $e');
      return const Left(UnexpectedFailure());
    }
  }

  @override
  Future<Either<Failure, MarkupTemplate>> createMarkup({
    required int proId,
    required String name,
    required MarkupType type,
    required double rate,
  }) async {
    AppLogger.api('createMarkup: proId=$proId name=$name');
    if (_useMock) {
      await Future.delayed(const Duration(milliseconds: 500));
      return Right(MarkupTemplate(
        id: DateTime.now().millisecondsSinceEpoch,
        proId: proId,
        name: name,
        type: type,
        rate: rate,
      ));
    }
    try {
      final response = await _apiClient.post(
        '/lineitems/markups',
        data: {
          'proId': proId,
          'markupName': name,
          'markupType': type == MarkupType.flat ? 'F' : 'P',
          'markupRate': rate,
        },
      );
      return Right(
          MarkupTemplate.fromJson(response.data as Map<String, dynamic>));
    } on UnauthorizedException catch (e) {
      return Left(UnauthorizedFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, statusCode: e.statusCode));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      AppLogger.error('createMarkup: unexpected — $e');
      return const Left(UnexpectedFailure());
    }
  }
}
