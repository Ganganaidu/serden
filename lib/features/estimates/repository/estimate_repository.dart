import 'package:dartz/dartz.dart';

import '../../../core/config/app_config.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/errors/exceptions.dart';
import '../../../core/errors/failures.dart';
import '../../../core/network/api_client.dart';
import '../../../core/utils/app_logger.dart';
import '../models/estimate_model.dart';

abstract class EstimateRepository {
  Future<Either<Failure, List<EstimateSummary>>> fetchEstimates(
    int proId, {
    String? searchTerm,
    String? status,
    String sortBy = 'date',
    String sortDirection = 'desc',
    int pageIndex = 1,
    int pageSize = AppConstants.pageSize,
  });

  Future<Either<Failure, Estimate>> fetchEstimateDetail(int estimateId);

  Future<Either<Failure, String>> fetchNextNumber(int proId);

  Future<Either<Failure, Estimate>> createEstimate(Estimate estimate);

  Future<Either<Failure, Estimate>> updateEstimate(Estimate estimate);

  Future<Either<Failure, void>> deleteEstimate(int estimateId);

  Future<Either<Failure, void>> sendEstimate(int estimateId);
}

class EstimateRepositoryImpl implements EstimateRepository {
  final ApiClient _apiClient;
  static const bool _useMock = AppConfig.useMockData;

  EstimateRepositoryImpl({required ApiClient apiClient})
      : _apiClient = apiClient;

  @override
  Future<Either<Failure, List<EstimateSummary>>> fetchEstimates(
    int proId, {
    String? searchTerm,
    String? status,
    String sortBy = 'date',
    String sortDirection = 'desc',
    int pageIndex = 1,
    int pageSize = AppConstants.pageSize,
  }) async {
    AppLogger.api('fetchEstimates: proId=$proId status=$status');
    if (_useMock) {
      await Future.delayed(const Duration(milliseconds: 600));
      return Right(mockEstimates);
    }
    try {
      final response = await _apiClient.get(
        '/Estimates/pro/$proId',
        queryParams: {
          if (searchTerm != null && searchTerm.isNotEmpty)
            'searchTerm': searchTerm,
          if (status != null && status.isNotEmpty) 'status': status,
          'sortBy': sortBy,
          'sortDirection': sortDirection,
          'pageIndex': pageIndex,
          'pageSize': pageSize,
        },
      );
      final data = response.data as List<dynamic>;
      final estimates = data
          .map((e) => EstimateSummary.fromJson(e as Map<String, dynamic>))
          .toList();
      AppLogger.api('fetchEstimates: loaded ${estimates.length} estimates');
      return Right(estimates);
    } on UnauthorizedException catch (e) {
      return Left(UnauthorizedFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, statusCode: e.statusCode));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      AppLogger.error('fetchEstimates: unexpected — $e');
      return const Left(UnexpectedFailure());
    }
  }

  @override
  Future<Either<Failure, Estimate>> fetchEstimateDetail(int estimateId) async {
    AppLogger.api('fetchEstimateDetail: estimateId=$estimateId');
    try {
      final response = await _apiClient.get('/Estimates/$estimateId');
      final estimate =
          Estimate.fromJson(response.data as Map<String, dynamic>);
      AppLogger.api(
          'fetchEstimateDetail: loaded estimateId=${estimate.estimateId}');
      return Right(estimate);
    } on UnauthorizedException catch (e) {
      return Left(UnauthorizedFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, statusCode: e.statusCode));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      AppLogger.error('fetchEstimateDetail: unexpected — $e');
      return const Left(UnexpectedFailure());
    }
  }

  @override
  Future<Either<Failure, String>> fetchNextNumber(int proId) async {
    AppLogger.api('fetchNextNumber: proId=$proId');
    try {
      final response = await _apiClient.get('/Estimates/pro/$proId/next-number');
      return Right(response.data.toString());
    } on UnauthorizedException catch (e) {
      return Left(UnauthorizedFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, statusCode: e.statusCode));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      AppLogger.error('fetchNextNumber: unexpected — $e');
      return const Left(UnexpectedFailure());
    }
  }

  @override
  Future<Either<Failure, Estimate>> createEstimate(Estimate estimate) async {
    AppLogger.api('createEstimate: proId=${estimate.proId}');
    try {
      final response = await _apiClient.post(
        '/Estimates',
        data: {
          'proId': estimate.proId,
          if (estimate.clientId != null) 'clientId': estimate.clientId,
          'estimateDate': estimate.estimateDate.toIso8601String(),
          if (estimate.expirationDate != null)
            'expirationDate': estimate.expirationDate!.toIso8601String(),
          if (estimate.poNumber != null && estimate.poNumber!.isNotEmpty)
            'poNumber': estimate.poNumber,
          'groupItemsIntoSections': estimate.groupItemsIntoSections,
          'subtotal': estimate.subtotal,
          if (estimate.markupType != null) 'markupType': estimate.markupType,
          if (estimate.markupValue != null) 'markupValue': estimate.markupValue,
          if (estimate.discountType != null)
            'discountType': estimate.discountType,
          if (estimate.discountValue != null)
            'discountValue': estimate.discountValue,
          if (estimate.depositType != null) 'depositType': estimate.depositType,
          if (estimate.depositValue != null)
            'depositValue': estimate.depositValue,
          if (estimate.taxName != null) 'taxName': estimate.taxName,
          if (estimate.taxRate != null) 'taxRate': estimate.taxRate,
          'total': estimate.total,
          'showClientSignature': estimate.showClientSignature,
          'showMySignature': estimate.showMySignature,
          if (estimate.notes != null && estimate.notes!.isNotEmpty)
            'notes': estimate.notes,
          if (estimate.privateNotes != null &&
              estimate.privateNotes!.isNotEmpty)
            'privateNotes': estimate.privateNotes,
          'sections': estimate.sections.map((e) => e.toJson()).toList(),
          'lineItems': estimate.lineItems.map((e) => e.toJson()).toList(),
        },
      );
      final created =
          Estimate.fromJson(response.data as Map<String, dynamic>);
      AppLogger.api('createEstimate: created estimateId=${created.estimateId}');
      return Right(created);
    } on UnauthorizedException catch (e) {
      return Left(UnauthorizedFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, statusCode: e.statusCode));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      AppLogger.error('createEstimate: unexpected — $e');
      return const Left(UnexpectedFailure());
    }
  }

  @override
  Future<Either<Failure, Estimate>> updateEstimate(Estimate estimate) async {
    AppLogger.api('updateEstimate: estimateId=${estimate.estimateId}');
    try {
      final response = await _apiClient.put(
        '/Estimates/${estimate.estimateId}',
        data: estimate.toJson(),
      );
      final updated = response.data != null
          ? Estimate.fromJson(response.data as Map<String, dynamic>)
          : estimate;
      AppLogger.api('updateEstimate: success estimateId=${estimate.estimateId}');
      return Right(updated);
    } on UnauthorizedException catch (e) {
      return Left(UnauthorizedFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, statusCode: e.statusCode));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      AppLogger.error('updateEstimate: unexpected — $e');
      return const Left(UnexpectedFailure());
    }
  }

  @override
  Future<Either<Failure, void>> deleteEstimate(int estimateId) async {
    AppLogger.api('deleteEstimate: estimateId=$estimateId');
    try {
      await _apiClient.delete('/Estimates/$estimateId');
      AppLogger.api('deleteEstimate: success estimateId=$estimateId');
      return const Right(null);
    } on UnauthorizedException catch (e) {
      return Left(UnauthorizedFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, statusCode: e.statusCode));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      AppLogger.error('deleteEstimate: unexpected — $e');
      return const Left(UnexpectedFailure());
    }
  }

  @override
  Future<Either<Failure, void>> sendEstimate(int estimateId) async {
    AppLogger.api('sendEstimate: estimateId=$estimateId');
    try {
      await _apiClient.post('/Estimates/$estimateId/send');
      AppLogger.api('sendEstimate: success estimateId=$estimateId');
      return const Right(null);
    } on UnauthorizedException catch (e) {
      return Left(UnauthorizedFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, statusCode: e.statusCode));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      AppLogger.error('sendEstimate: unexpected — $e');
      return const Left(UnexpectedFailure());
    }
  }
}
