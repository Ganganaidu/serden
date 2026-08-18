import 'package:dartz/dartz.dart';

import '../../../core/config/app_config.dart';
import '../../../core/errors/exceptions.dart';
import '../../../core/errors/failures.dart';
import '../../../core/network/api_client.dart';
import '../../../core/utils/app_logger.dart';
import '../models/tax_model.dart';

abstract class TaxRepository {
  Future<Either<Failure, List<TaxRate>>> fetchTaxes(int proId);
  Future<Either<Failure, TaxRate>> createTax({
    required int proId,
    required String name,
    required double rate,
  });
  Future<Either<Failure, TaxRate>> updateTax(TaxRate tax);
  Future<Either<Failure, void>> deleteTax(int taxId);
}

class TaxRepositoryImpl implements TaxRepository {
  final ApiClient _apiClient;
  static const bool _useMock = AppConfig.useMockData;

  TaxRepositoryImpl({required ApiClient apiClient}) : _apiClient = apiClient;

  @override
  Future<Either<Failure, List<TaxRate>>> fetchTaxes(int proId) async {
    AppLogger.api('fetchTaxes: proId=$proId');
    if (_useMock) {
      await Future.delayed(const Duration(milliseconds: 400));
      return Right([
        TaxRate(id: 1, proId: proId, name: 'Sales tax', rate: 5.0),
        TaxRate(id: 2, proId: proId, name: 'State tax', rate: 7.5),
      ]);
    }
    try {
      final response = await _apiClient.get('/taxes/pro/$proId');
      final data = response.data as List<dynamic>;
      final taxes = data
          .map((e) => TaxRate.fromJson(e as Map<String, dynamic>))
          .toList();
      AppLogger.api('fetchTaxes: loaded ${taxes.length} taxes');
      return Right(taxes);
    } on UnauthorizedException catch (e) {
      return Left(UnauthorizedFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, statusCode: e.statusCode));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      AppLogger.error('fetchTaxes: unexpected — $e');
      return const Left(UnexpectedFailure());
    }
  }

  @override
  Future<Either<Failure, TaxRate>> createTax({
    required int proId,
    required String name,
    required double rate,
  }) async {
    AppLogger.api('createTax: proId=$proId name=$name rate=$rate');
    if (_useMock) {
      await Future.delayed(const Duration(milliseconds: 400));
      return Right(TaxRate(
        id: DateTime.now().millisecondsSinceEpoch,
        proId: proId,
        name: name,
        rate: rate,
      ));
    }
    try {
      final response = await _apiClient.post(
        '/taxes',
        data: {'proId': proId, 'taxName': name, 'taxRate': rate},
      );
      return Right(TaxRate.fromJson(response.data as Map<String, dynamic>));
    } on UnauthorizedException catch (e) {
      return Left(UnauthorizedFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, statusCode: e.statusCode));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      AppLogger.error('createTax: unexpected — $e');
      return const Left(UnexpectedFailure());
    }
  }

  @override
  Future<Either<Failure, TaxRate>> updateTax(TaxRate tax) async {
    AppLogger.api('updateTax: id=${tax.id}');
    if (_useMock) {
      await Future.delayed(const Duration(milliseconds: 400));
      return Right(tax);
    }
    try {
      final response = await _apiClient.put(
        '/taxes/${tax.id}',
        data: tax.toJson(),
      );
      return Right(TaxRate.fromJson(response.data as Map<String, dynamic>));
    } on UnauthorizedException catch (e) {
      return Left(UnauthorizedFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, statusCode: e.statusCode));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      AppLogger.error('updateTax: unexpected — $e');
      return const Left(UnexpectedFailure());
    }
  }

  @override
  Future<Either<Failure, void>> deleteTax(int taxId) async {
    AppLogger.api('deleteTax: id=$taxId');
    if (_useMock) {
      await Future.delayed(const Duration(milliseconds: 300));
      return const Right(null);
    }
    try {
      await _apiClient.delete('/taxes/$taxId');
      return const Right(null);
    } on UnauthorizedException catch (e) {
      return Left(UnauthorizedFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, statusCode: e.statusCode));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      AppLogger.error('deleteTax: unexpected — $e');
      return const Left(UnexpectedFailure());
    }
  }
}
