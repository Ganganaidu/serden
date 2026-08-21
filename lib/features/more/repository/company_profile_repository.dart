import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';

import '../../../core/errors/exceptions.dart';
import '../../../core/errors/failures.dart';
import '../../../core/network/api_client.dart';
import '../../../core/utils/app_logger.dart';
import '../models/company_profile_model.dart';

abstract class CompanyProfileRepository {
  Future<Either<Failure, CompanyProfile>> fetchProfile(int userId);
  Future<Either<Failure, CompanyProfile>> updateProfile(CompanyProfile profile);

  /// Uploads [filePath] as the new company logo for [proId].
  /// Returns the bare filename stored in `proLogo` on success.
  Future<Either<Failure, String>> uploadLogo(int proId, String filePath);

  /// Uploads [filePath] as a project photo for [proId].
  Future<Either<Failure, ProPhoto>> uploadProjectPhoto(
      int proId, String filePath);
}

class CompanyProfileRepositoryImpl implements CompanyProfileRepository {
  final ApiClient _apiClient;

  CompanyProfileRepositoryImpl({required ApiClient apiClient})
      : _apiClient = apiClient;

  @override
  Future<Either<Failure, CompanyProfile>> fetchProfile(int userId) async {
    AppLogger.api('CompanyProfileRepository.fetchProfile: userId=$userId');
    try {
      final response = await _apiClient.get('/Pros/user/$userId');
      final data = response.data as Map<String, dynamic>;
      return Right(CompanyProfile.fromJson(data));
    } on UnauthorizedException catch (e) {
      return Left(UnauthorizedFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, statusCode: e.statusCode));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      AppLogger.error('CompanyProfileRepository.fetchProfile unexpected: $e');
      return const Left(UnexpectedFailure());
    }
  }

  @override
  Future<Either<Failure, CompanyProfile>> updateProfile(
      CompanyProfile profile) async {
    AppLogger.api(
        'CompanyProfileRepository.updateProfile: proId=${profile.proId}');
    try {
      final response = await _apiClient.put(
        '/Pros/${profile.proId}',
        data: profile.toJson(),
      );
      final data = response.data as Map<String, dynamic>;
      return Right(CompanyProfile.fromJson(data));
    } on UnauthorizedException catch (e) {
      return Left(UnauthorizedFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, statusCode: e.statusCode));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      AppLogger.error('CompanyProfileRepository.updateProfile unexpected: $e');
      return const Left(UnexpectedFailure());
    }
  }

  @override
  Future<Either<Failure, String>> uploadLogo(
      int proId, String filePath) async {
    AppLogger.api('CompanyProfileRepository.uploadLogo: proId=$proId');
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(filePath),
      });
      final response = await _apiClient.post(
        '/Pros/$proId/logo',
        data: formData,
      );
      // API may return the updated profile or just the filename string.
      final data = response.data;
      if (data is Map<String, dynamic>) {
        return Right((data['proLogo'] as String?) ?? '');
      }
      return Right(data?.toString() ?? '');
    } on UnauthorizedException catch (e) {
      return Left(UnauthorizedFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, statusCode: e.statusCode));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      AppLogger.error('CompanyProfileRepository.uploadLogo unexpected: $e');
      return const Left(UnexpectedFailure());
    }
  }

  @override
  Future<Either<Failure, ProPhoto>> uploadProjectPhoto(
      int proId, String filePath) async {
    AppLogger.api(
        'CompanyProfileRepository.uploadProjectPhoto: proId=$proId');
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(filePath),
      });
      final response = await _apiClient.post(
        '/Pros/$proId/photos',
        data: formData,
      );
      final data = response.data;
      if (data is Map<String, dynamic>) {
        return Right(ProPhoto.fromJson(data));
      }
      // If the API returns a plain string URL or filename
      final str = data?.toString() ?? '';
      return Right(
        str.startsWith('http')
            ? ProPhoto(url: str)
            : ProPhoto(fileName: str),
      );
    } on UnauthorizedException catch (e) {
      return Left(UnauthorizedFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, statusCode: e.statusCode));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      AppLogger.error(
          'CompanyProfileRepository.uploadProjectPhoto unexpected: $e');
      return const Left(UnexpectedFailure());
    }
  }
}
