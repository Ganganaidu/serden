import 'dart:convert';

import 'package:dartz/dartz.dart';
import '../../../core/config/app_config.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/errors/exceptions.dart';
import '../../../core/errors/failures.dart';
import '../../../core/network/api_client.dart';
import '../../../core/storage/secure_storage.dart';
import '../../../core/utils/app_logger.dart';
import '../models/user_model.dart';

abstract class AuthRepository {
  Future<Either<Failure, UserModel>> signIn(String email, String password);
  Future<Either<Failure, void>> signUp({
    required String email,
    required String password,
    required String confirmPassword,
    required String firstName,
    required String lastName,
    required String turnstileToken,
  });
  Future<Either<Failure, void>> signOut();
  Future<Either<Failure, UserModel>> getCurrentUser();
  Future<bool> isAuthenticated();
  Future<Either<Failure, void>> forgotPassword(
      String email, {required String turnstileToken});
  Future<Either<Failure, UserModel>> updateUser({
    required int userId,
    required String firstName,
    required String lastName,
    required String email,
  });
  Future<Either<Failure, void>> changePassword({
    required String email,
    required String currentPassword,
    required String newPassword,
  });
}

class AuthRepositoryImpl implements AuthRepository {
  final ApiClient _apiClient;
  final SecureStorage _storage;

  static const bool _useMock = AppConfig.useMockData;

  AuthRepositoryImpl({
    required ApiClient apiClient,
    required SecureStorage storage,
  })  : _apiClient = apiClient,
        _storage = storage;

  static UserModel _mockUser(String email) => const UserModel(
        userId: 1,
        proId: 1,
        publicId: 'mock-user-1',
        username: 'user@example.com',
        email: 'user@example.com',
        firstName: 'John',
        lastName: 'Smith',
      );

  Future<void> _persistSession(Map<String, dynamic> data) async {
    final accessToken = data['accessToken'] as String?;
    final refreshToken = data['refreshToken'] as String?;
    if (accessToken != null) {
      await _storage.write(AppConstants.accessTokenKey, accessToken);
    }
    if (refreshToken != null) {
      await _storage.write(AppConstants.refreshTokenKey, refreshToken);
    }
    if (data['user'] != null) {
      await _storage.write(AppConstants.userKey, jsonEncode(data['user']));
    }
    final expiresAt = data['expiresAt'] as String?;
    if (expiresAt != null) {
      await _storage.write(AppConstants.tokenExpiresAtKey, expiresAt);
    }
  }

  /// Fetches GET /api/Pros/user/{userId} and returns the proId.
  /// Returns null if the user has no Pro profile or on any error.
  Future<int?> _fetchProId(int userId) async {
    try {
      final response = await _apiClient.get('/Pros/user/$userId');
      final data = response.data as Map<String, dynamic>?;
      final proId = data?['proId'] as int?;
      AppLogger.auth('fetchProId: userId=$userId → proId=$proId');
      return proId;
    } catch (e) {
      AppLogger.auth('fetchProId: failed for userId=$userId — $e');
      return null;
    }
  }

  /// Attach proId to a user and persist the updated user JSON.
  Future<UserModel> _withProId(UserModel user) async {
    // Check if we already have a cached proId for this user
    final cached = await _storage.read(AppConstants.userKey);
    if (cached != null) {
      final cachedMap = jsonDecode(cached) as Map<String, dynamic>;
      final cachedProId = cachedMap['proId'] as int?;
      if (cachedProId != null) {
        return user.copyWith(proId: cachedProId);
      }
    }
    final proId = await _fetchProId(user.userId);
    final updated = user.copyWith(proId: proId);
    await _storage.write(AppConstants.userKey, jsonEncode(updated.toJson()));
    return updated;
  }

  @override
  Future<Either<Failure, UserModel>> signIn(
      String email, String password) async {
    AppLogger.auth('signIn: attempting for $email');
    if (_useMock) {
      await Future.delayed(const Duration(milliseconds: 800));
      await _storage.write(AppConstants.accessTokenKey, 'mock_access_token');
      await _storage.write(AppConstants.refreshTokenKey, 'mock_refresh_token');
      AppLogger.auth('signIn: mock success for $email');
      return Right(_mockUser(email));
    }
    try {
      final response = await _apiClient.post(
        '/Users/login',
        data: {'userName': email, 'password': password},
      );
      final data = response.data as Map<String, dynamic>;
      await _persistSession(data);
      final rawUser = UserModel.fromJson(data['user'] as Map<String, dynamic>);
      AppLogger.auth('signIn: success — userId=${rawUser.userId}');
      final user = await _withProId(rawUser);
      AppLogger.auth('signIn: proId=${user.proId}');
      return Right(user);
    } on UnauthorizedException catch (e) {
      AppLogger.auth('signIn: unauthorized — ${e.message}');
      return Left(UnauthorizedFailure(e.message));
    } on ServerException catch (e) {
      AppLogger.auth('signIn: server failure (${e.statusCode}) — ${e.message}');
      return Left(ServerFailure(e.message, statusCode: e.statusCode));
    } on NetworkException catch (e) {
      AppLogger.auth('signIn: network failure — ${e.message}');
      return Left(NetworkFailure(e.message));
    } catch (e) {
      AppLogger.error('signIn: unexpected exception — $e');
      return const Left(UnexpectedFailure());
    }
  }

  @override
  Future<Either<Failure, void>> signUp({
    required String email,
    required String password,
    required String confirmPassword,
    required String firstName,
    required String lastName,
    required String turnstileToken,
  }) async {
    AppLogger.auth('signUp: attempting for $email');
    if (_useMock) {
      await Future.delayed(const Duration(milliseconds: 800));
      AppLogger.auth('signUp: mock success for $email');
      return const Right(null);
    }
    try {
      await _apiClient.post(
        '/Users/register',
        data: {
          'username': email,
          'email': email,
          'password': password,
          'confirmPassword': confirmPassword,
          'firstName': firstName,
          'lastName': lastName,
          'turnstileToken': turnstileToken,
        },
      );
      AppLogger.auth('signUp: registered $email — email verification required');
      return const Right(null);
    } on ServerException catch (e) {
      AppLogger.auth('signUp: server failure (${e.statusCode}) — ${e.message}');
      return Left(ServerFailure(e.message, statusCode: e.statusCode));
    } on NetworkException catch (e) {
      AppLogger.auth('signUp: network failure — ${e.message}');
      return Left(NetworkFailure(e.message));
    } catch (e) {
      AppLogger.error('signUp: unexpected exception — $e');
      return const Left(UnexpectedFailure());
    }
  }

  @override
  Future<Either<Failure, void>> signOut() async {
    AppLogger.auth('signOut: attempting');
    if (!_useMock) {
      final refreshToken = await _storage.read(AppConstants.refreshTokenKey);
      if (refreshToken != null) {
        try {
          await _apiClient.post(
            '/Users/logout',
            data: {'refreshToken': refreshToken},
          );
        } catch (e) {
          AppLogger.auth('signOut: server logout failed (ignored) — $e');
        }
      }
    }
    await _storage.deleteAll();
    AppLogger.auth('signOut: local session cleared');
    return const Right(null);
  }

  @override
  Future<Either<Failure, UserModel>> getCurrentUser() async {
    AppLogger.auth('getCurrentUser: checking session');
    if (_useMock) {
      final token = await _storage.read(AppConstants.accessTokenKey);
      if (token == null) return const Left(UnauthorizedFailure());
      return Right(_mockUser('user@example.com'));
    }
    final cachedUserJson = await _storage.read(AppConstants.userKey);
    if (cachedUserJson == null) {
      AppLogger.auth('getCurrentUser: no cached user — unauthorized');
      return const Left(UnauthorizedFailure());
    }
    final cachedMap = jsonDecode(cachedUserJson) as Map<String, dynamic>;
    final publicId = cachedMap['publicId'] as String?;
    if (publicId == null) return const Left(UnauthorizedFailure());
    try {
      final response = await _apiClient
          .get('/Users/publicid', queryParams: {'publicId': publicId});
      final rawUser =
          UserModel.fromJson(response.data as Map<String, dynamic>);
      // Preserve proId from cache — it's not in the SerdenUser response.
      final cachedProId = cachedMap['proId'] as int?;
      final user = cachedProId != null
          ? rawUser.copyWith(proId: cachedProId)
          : await _withProId(rawUser);
      await _storage.write(AppConstants.userKey, jsonEncode(user.toJson()));
      AppLogger.auth(
          'getCurrentUser: valid — userId=${user.userId} proId=${user.proId}');
      return Right(user);
    } on UnauthorizedException {
      AppLogger.auth('getCurrentUser: refresh failed — unauthorized');
      return const Left(UnauthorizedFailure());
    } on ServerException catch (e) {
      AppLogger.auth(
          'getCurrentUser: server failure (${e.statusCode}) — ${e.message}');
      return Left(ServerFailure(e.message, statusCode: e.statusCode));
    } on NetworkException catch (e) {
      AppLogger.auth('getCurrentUser: network failure — ${e.message}');
      return Left(NetworkFailure(e.message));
    } catch (e) {
      AppLogger.error('getCurrentUser: unexpected exception — $e');
      return const Left(UnexpectedFailure());
    }
  }

  @override
  Future<bool> isAuthenticated() async {
    final token = await _storage.read(AppConstants.accessTokenKey);
    return token != null;
  }

  @override
  Future<Either<Failure, UserModel>> updateUser({
    required int userId,
    required String firstName,
    required String lastName,
    required String email,
  }) async {
    AppLogger.auth('updateUser: userId=$userId');
    if (_useMock) {
      await Future.delayed(const Duration(milliseconds: 600));
      final cached = await _storage.read(AppConstants.userKey);
      final base = cached != null
          ? UserModel.fromJson(jsonDecode(cached) as Map<String, dynamic>)
          : _mockUser(email);
      final updated =
          base.copyWith(firstName: firstName, lastName: lastName, email: email);
      await _storage.write(AppConstants.userKey, jsonEncode(updated.toJson()));
      return Right(updated);
    }
    try {
      await _apiClient.put(
        '/Users/$userId',
        data: {
          'userId': userId,
          'userName': email,
          'email': email,
          'firstName': firstName,
          'lastName': lastName,
        },
      );
      // Refresh the user from the server to get the canonical state
      final response = await _apiClient.get('/Users/$userId');
      final rawUser =
          UserModel.fromJson(response.data as Map<String, dynamic>);
      final cached = await _storage.read(AppConstants.userKey);
      final cachedProId = cached != null
          ? (jsonDecode(cached) as Map<String, dynamic>)['proId'] as int?
          : null;
      final updated = cachedProId != null
          ? rawUser.copyWith(proId: cachedProId)
          : rawUser;
      await _storage.write(AppConstants.userKey, jsonEncode(updated.toJson()));
      AppLogger.auth('updateUser: success for userId=$userId');
      return Right(updated);
    } on UnauthorizedException catch (e) {
      return Left(UnauthorizedFailure(e.message));
    } on ServerException catch (e) {
      AppLogger.auth('updateUser: server failure — ${e.message}');
      return Left(ServerFailure(e.message, statusCode: e.statusCode));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      AppLogger.error('updateUser: unexpected — $e');
      return const Left(UnexpectedFailure());
    }
  }

  @override
  Future<Either<Failure, void>> changePassword({
    required String email,
    required String currentPassword,
    required String newPassword,
  }) async {
    AppLogger.auth('changePassword: for $email');
    if (_useMock) {
      await Future.delayed(const Duration(milliseconds: 600));
      return const Right(null);
    }
    try {
      await _apiClient.post(
        '/Users/change-password',
        data: {
          'email': email,
          'currentPassword': currentPassword,
          'newPassword': newPassword,
        },
      );
      return const Right(null);
    } on UnauthorizedException catch (e) {
      return Left(UnauthorizedFailure(e.message));
    } on ServerException catch (e) {
      AppLogger.auth('changePassword: server failure — ${e.message}');
      return Left(ServerFailure(e.message, statusCode: e.statusCode));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      AppLogger.error('changePassword: unexpected — $e');
      return const Left(UnexpectedFailure());
    }
  }

  @override
  Future<Either<Failure, void>> forgotPassword(
      String email, {required String turnstileToken}) async {
    AppLogger.auth('forgotPassword: requesting reset for $email');
    if (_useMock) {
      await Future.delayed(const Duration(milliseconds: 800));
      return const Right(null);
    }
    try {
      await _apiClient.post(
        '/Users/forgot-password',
        data: {'email': email, 'turnstileToken': turnstileToken},
      );
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, statusCode: e.statusCode));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      AppLogger.error('forgotPassword: unexpected — $e');
      return const Left(UnexpectedFailure());
    }
  }
}
