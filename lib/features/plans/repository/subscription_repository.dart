import 'package:dartz/dartz.dart';

import '../../../core/config/app_config.dart';
import '../../../core/errors/exceptions.dart';
import '../../../core/errors/failures.dart';
import '../../../core/network/api_client.dart';
import '../../../core/utils/app_logger.dart';
import '../models/subscription_usage.dart';

abstract class SubscriptionRepository {
  Future<Either<Failure, SubscriptionUsage>> fetchUsage(int userId);
}

class SubscriptionRepositoryImpl implements SubscriptionRepository {
  final ApiClient _apiClient;
  static const bool _useMock = AppConfig.useMockData;

  SubscriptionRepositoryImpl({required ApiClient apiClient})
      : _apiClient = apiClient;

  @override
  Future<Either<Failure, SubscriptionUsage>> fetchUsage(int userId) async {
    AppLogger.api('fetchSubscriptionUsage: userId=$userId');
    if (_useMock) {
      await Future.delayed(const Duration(milliseconds: 400));
      return const Right(SubscriptionUsage(
        invoicesUsed: 1,
        invoicesLimit: 3,
        estimatesUsed: 2,
        estimatesLimit: 3,
      ));
    }
    try {
      final response = await _apiClient.get('/SubscriptionUsage/user/$userId');
      return Right(
          SubscriptionUsage.fromJson(response.data as Map<String, dynamic>));
    } on UnauthorizedException catch (e) {
      return Left(UnauthorizedFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, statusCode: e.statusCode));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      AppLogger.error('fetchSubscriptionUsage: unexpected — $e');
      return const Left(UnexpectedFailure());
    }
  }
}
