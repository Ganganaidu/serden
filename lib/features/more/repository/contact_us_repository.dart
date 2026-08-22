import 'package:dartz/dartz.dart';

import '../../../core/errors/exceptions.dart';
import '../../../core/errors/failures.dart';
import '../../../core/network/api_client.dart';
import '../../../core/utils/app_logger.dart';

abstract class ContactUsRepository {
  Future<Either<Failure, bool>> submit({
    required String name,
    String? company,
    required String email,
    required String phone,
    required String subject,
    String? description,
    required String turnstileToken,
  });
}

class ContactUsRepositoryImpl implements ContactUsRepository {
  final ApiClient _apiClient;

  ContactUsRepositoryImpl({required ApiClient apiClient})
      : _apiClient = apiClient;

  @override
  Future<Either<Failure, bool>> submit({
    required String name,
    String? company,
    required String email,
    required String phone,
    required String subject,
    String? description,
    required String turnstileToken,
  }) async {
    AppLogger.api('ContactUsRepository.submit: subject=$subject');
    try {
      await _apiClient.post(
        '/ContactUs',
        data: {
          'name': name,
          'company': company,
          'email': email,
          'phone': phone,
          'subject': subject,
          'description': description,
          'turnstileToken': turnstileToken,
        },
      );
      return const Right(true);
    } on UnauthorizedException catch (e) {
      return Left(UnauthorizedFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, statusCode: e.statusCode));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      AppLogger.error('ContactUsRepository.submit unexpected: $e');
      return const Left(UnexpectedFailure());
    }
  }
}
