import 'package:dartz/dartz.dart';

import '../../../core/config/app_config.dart';
import '../../../core/errors/exceptions.dart';
import '../../../core/errors/failures.dart';
import '../../../core/network/api_client.dart';
import '../../../core/utils/app_logger.dart';
import '../models/review_model.dart';

// ─── Result wrapper ───────────────────────────────────────────────────────────

class ReviewsResult {
  final List<Review> reviews;
  final double averageRating;
  final int totalCount;
  final int star5Count;
  final int star4Count;
  final int star3Count;

  const ReviewsResult({
    required this.reviews,
    required this.averageRating,
    required this.totalCount,
    required this.star5Count,
    required this.star4Count,
    required this.star3Count,
  });
}

// ─── Abstract ─────────────────────────────────────────────────────────────────

abstract class ReviewRepository {
  Future<Either<Failure, ReviewsResult>> fetchReviews(int proId);
  Future<Either<Failure, void>> respondToReview({
    required int reviewId,
    required String companyResponseText,
    required int currentUserId,
  });
  Future<Either<Failure, void>> sendReviewRequest({
    required int proId,
    required String toEmail,
    required String fromEmail,
    required String subject,
    required String message,
    String? reviewPageUrl,
  });
}

// ─── Implementation ───────────────────────────────────────────────────────────

class ReviewRepositoryImpl implements ReviewRepository {
  final ApiClient _apiClient;
  static const bool _useMock = AppConfig.useMockData;

  ReviewRepositoryImpl({required ApiClient apiClient})
      : _apiClient = apiClient;

  @override
  Future<Either<Failure, ReviewsResult>> fetchReviews(int proId) async {
    AppLogger.api('fetchReviews: proId=$proId');
    if (_useMock) {
      await Future.delayed(const Duration(milliseconds: 500));
      return Right(ReviewsResult(
        reviews: mockReviews,
        averageRating: 4.9,
        totalCount: 153,
        star5Count: 142,
        star4Count: 9,
        star3Count: 2,
      ));
    }
    try {
      // GET /api/ProReviews/pro/{proId}?pageSize=200
      // Returns ProReviewSummaryViewModel: { proId, averageRating, totalReviews,
      //   ratingDistribution (object), recentReviews (array) }
      final response = await _apiClient.get(
        '/ProReviews/pro/$proId',
        queryParams: {'pageSize': 200},
      );
      final data = response.data as Map<String, dynamic>;

      AppLogger.api('fetchReviews: keys=${data.keys.toList()}');

      final avgRating =
          (data['averageRating'] as num?)?.toDouble() ?? 0.0;
      final totalCount = (data['totalReviews'] as int?) ?? 0;

      // ratingDistribution is an object like {"5": 142, "4": 9, "3": 2, ...}
      final dist = (data['ratingDistribution'] as Map<String, dynamic>?);
      int _distCount(String key) =>
          dist == null ? 0 : (dist[key] as int?) ?? 0;

      final reviews = ((data['recentReviews'] as List<dynamic>?) ?? [])
          .map((e) => Review.fromJson(e as Map<String, dynamic>))
          .toList();

      AppLogger.api('fetchReviews: loaded ${reviews.length} reviews');

      return Right(ReviewsResult(
        reviews: reviews,
        averageRating: avgRating,
        totalCount: totalCount,
        star5Count: _distCount('5'),
        star4Count: _distCount('4'),
        star3Count: _distCount('3'),
      ));
    } on UnauthorizedException catch (e) {
      return Left(UnauthorizedFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, statusCode: e.statusCode));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      AppLogger.error('fetchReviews: unexpected — $e');
      return const Left(UnexpectedFailure());
    }
  }

  @override
  Future<Either<Failure, void>> respondToReview({
    required int reviewId,
    required String companyResponseText,
    required int currentUserId,
  }) async {
    AppLogger.api('respondToReview: reviewId=$reviewId');
    if (_useMock) {
      await Future.delayed(const Duration(milliseconds: 400));
      return const Right(null);
    }
    try {
      // PUT /api/ProReviews/{reviewId}/respond
      // Body: RespondToProReviewViewModel { companyResponseText, currentUserId }
      await _apiClient.put(
        '/ProReviews/$reviewId/respond',
        data: {
          'companyResponseText': companyResponseText,
          'currentUserId': currentUserId,
        },
      );
      return const Right(null);
    } on UnauthorizedException catch (e) {
      return Left(UnauthorizedFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, statusCode: e.statusCode));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      AppLogger.error('respondToReview: unexpected — $e');
      return const Left(UnexpectedFailure());
    }
  }

  @override
  Future<Either<Failure, void>> sendReviewRequest({
    required int proId,
    required String toEmail,
    required String fromEmail,
    required String subject,
    required String message,
    String? reviewPageUrl,
  }) async {
    AppLogger.api('sendReviewRequest: proId=$proId to=$toEmail');
    if (_useMock) {
      await Future.delayed(const Duration(milliseconds: 600));
      return const Right(null);
    }
    try {
      // POST /api/Pros/{proId}/send-review-request-email
      // Body: ProReviewRequestEmailViewModel
      //   { toEmail, fromEmail, subject, message, reviewPageUrl }
      await _apiClient.post(
        '/Pros/$proId/send-review-request-email',
        data: {
          'toEmail': toEmail,
          'fromEmail': fromEmail,
          'subject': subject,
          'message': message,
          if (reviewPageUrl != null) 'reviewPageUrl': reviewPageUrl,
        },
      );
      return const Right(null);
    } on UnauthorizedException catch (e) {
      return Left(UnauthorizedFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, statusCode: e.statusCode));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      AppLogger.error('sendReviewRequest: unexpected — $e');
      return const Left(UnexpectedFailure());
    }
  }
}
